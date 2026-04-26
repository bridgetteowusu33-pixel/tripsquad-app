-- v1.1 — fix migration 054
-- 054 used double-quoted "you're going to " for the solo branch,
-- which PostgreSQL parses as an identifier (table/column name).
-- The trigger then tried to resolve it as a column and threw
-- 42703 ("column \"you're going to \" does not exist") on every
-- trip status change — including the first solo trip create.
--
-- Fix: single-quoted string literal, with the apostrophe escaped
-- by doubling.

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

  v_label := new.name;
  if new.selected_destination is not null then
    v_label := new.name || ' ('
      || coalesce(new.selected_flag || ' ', '')
      || new.selected_destination || ')';
  end if;

  if new.status = 'revealed' then
    v_kind := 'reveal';
    v_title := case
      when v_is_solo then 'you''re going to '
      else 'squad is going to '
    end
      || coalesce(new.selected_flag || ' ', '')
      || coalesce(new.selected_destination, new.name) || ' 🎉';
  elsif new.status = 'planning' then
    return new;
  elsif new.status = 'voting' then
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
