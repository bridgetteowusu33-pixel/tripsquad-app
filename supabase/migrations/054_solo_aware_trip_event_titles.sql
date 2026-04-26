-- v1.1 — Solo Explorer
-- The log_status_as_trip_event trigger writes notification titles
-- like "squad is going to Ghana 🎉" on every status flip. For solo
-- trips this is wrong — there's no squad. Make the title mode-aware
-- so solo trips read "you're going to Ghana 🎉" and group trips
-- keep the existing copy.

create or replace function log_status_as_trip_event()
returns trigger language plpgsql security definer as $$
declare
  v_label text;
  v_kind text;
  v_title text;
  v_is_solo boolean;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  v_is_solo := (new.mode = 'solo');

  -- "Asia (🇯🇵 Tokyo)" when a destination is locked, else just "Asia"
  v_label := new.name;
  if new.selected_destination is not null then
    v_label := new.name || ' ('
      || coalesce(new.selected_flag || ' ', '')
      || new.selected_destination || ')';
  end if;

  if new.status = 'revealed' then
    v_kind := 'reveal';
    v_title := case
      when v_is_solo then "you're going to "
      else 'squad is going to '
    end
      || coalesce(new.selected_flag || ' ', '')
      || coalesce(new.selected_destination, new.name) || ' 🎉';
  elsif new.status = 'planning' then
    -- Skip — generate_itinerary edge function emits a richer one.
    return new;
  elsif new.status = 'voting' then
    -- Solo never reaches voting, but defensive: title differs anyway.
    v_kind := 'options_generated';
    v_title := v_label || case
      when v_is_solo then ' — pick a destination'
      else ' — 3 options to vote on 🗳️'
    end;
  elsif new.status = 'live' then
    v_kind := 'status_changed';
    v_title := v_label || ' is live — have fun ✈️';
  elsif new.status = 'completed' then
    v_kind := 'status_changed';
    v_title := v_label || ' wrapped — welcome home 💫';
  else
    v_kind := 'status_changed';
    v_title := v_label || ' is now ' || new.status;
  end if;

  insert into public.trip_events (trip_id, kind, actor_user_id, payload)
  values (
    new.id,
    v_kind,
    null,
    jsonb_build_object(
      'title',     v_title,
      'from',      old.status,
      'to',        new.status,
      'trip_name', new.name
    )
  );
  return new;
end;
$$;
