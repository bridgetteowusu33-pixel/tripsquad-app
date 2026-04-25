-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 009: Change trip destination post-vote
--
--  Host-only RPC that swaps the trip's selected destination,
--  clears the current itinerary so it can be regenerated, and
--  notifies every squad member.
-- ─────────────────────────────────────────────────────────────

create or replace function change_trip_destination(
  _trip_id         uuid,
  _destination     text,
  _flag            text default null,
  _country         text default null,
  _clear_itinerary boolean default true
) returns void language plpgsql security definer as $$
declare
  t record;
begin
  select * into t from trips where id = _trip_id;
  if t is null then raise exception 'trip not found'; end if;
  if t.host_id <> auth.uid() then
    raise exception 'only the host can change destination';
  end if;
  if _destination is null or length(trim(_destination)) = 0 then
    raise exception 'destination is required';
  end if;

  -- Wipe existing itinerary so stale activities don't linger
  if _clear_itinerary then
    delete from itinerary_items where trip_id = _trip_id;
  end if;

  update trips
     set selected_destination = trim(_destination),
         selected_flag = coalesce(_flag, selected_flag),
         -- Status: if already revealed/planning, stay in planning so the
         -- host can regenerate. If still in voting/collecting, bump to revealed.
         status = case
           when status in ('collecting','voting') then 'revealed'
           else status
         end,
         updated_at = now()
   where id = _trip_id;

  -- Log an event so the activity ticker + push fan-out picks it up
  insert into trip_events (trip_id, kind, actor_user_id, payload)
  values (
    _trip_id,
    'status_changed',  -- reuses existing kind to pass the check constraint
    auth.uid(),
    jsonb_build_object(
      'title', 'destination changed to ' || _destination,
      'destination', _destination,
      'flag', _flag,
      'country', _country,
      'changed_by', auth.uid()
    )
  );
end $$;

grant execute on function change_trip_destination(uuid, text, text, text, boolean)
  to authenticated;
