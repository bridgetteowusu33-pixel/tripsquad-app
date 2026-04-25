-- ─────────────────────────────────────────────────────────────
-- 035 — Specific notification titles for trip status changes
--
-- The previous trigger wrote generic titles like
--   "trip is now planning"
-- which doesn't tell the squad which trip flipped. This rewrite
-- includes the trip name + flag + destination so inbox rows read
-- "Asia (🇯🇵 Tokyo) — itinerary ready" instead of a bare status.
-- Also stops emitting a duplicate trip_event for the 'planning'
-- transition, since the generate_itinerary edge function already
-- inserts its own 'itinerary_ready' event with a richer title.
-- ─────────────────────────────────────────────────────────────

create or replace function log_status_as_trip_event()
returns trigger language plpgsql security definer as $$
declare
  v_label text;
  v_kind text;
  v_title text;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  -- "Asia (🇯🇵 Tokyo)" when a destination is locked, else just "Asia"
  v_label := new.name;
  if new.selected_destination is not null then
    v_label := new.name || ' ('
      || coalesce(new.selected_flag || ' ', '')
      || new.selected_destination || ')';
  end if;

  -- Choose a specific kind + title per transition. When a transition
  -- is already covered by a dedicated event (edge function inserts
  -- its own 'itinerary_ready' when it finishes writing items), skip
  -- so the inbox doesn't get duplicate rows.
  if new.status = 'revealed' then
    v_kind := 'reveal';
    v_title := 'squad is going to '
      || coalesce(new.selected_flag || ' ', '')
      || coalesce(new.selected_destination, new.name) || ' 🎉';
  elsif new.status = 'planning' then
    -- Skip — generate_itinerary edge function emits a richer one.
    return new;
  elsif new.status = 'voting' then
    v_kind := 'options_generated';
    v_title := v_label || ' — 3 options to vote on 🗳️';
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
