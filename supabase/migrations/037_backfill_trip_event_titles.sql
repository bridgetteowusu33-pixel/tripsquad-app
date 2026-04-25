-- ─────────────────────────────────────────────────────────────
-- 037 — Backfill existing trip_events.payload.title
--
-- The home "activity ticker" reads titles directly from the
-- trip_events.payload JSON, separate from the notifications table
-- that migration 036 backfilled. Rewrite those too so home/inbox
-- stay in sync.
-- ─────────────────────────────────────────────────────────────

update public.trip_events e
set payload = jsonb_set(
  coalesce(e.payload, '{}'::jsonb),
  '{title}',
  to_jsonb(case
    when (e.payload->>'title') = 'trip is now revealed' then
      'squad is going to '
        || coalesce(t.selected_flag || ' ', '')
        || coalesce(t.selected_destination, t.name) || ' 🎉'
    when (e.payload->>'title') = 'trip is now voting' then
      t.name || ' — 3 options to vote on 🗳️'
    when (e.payload->>'title') = 'trip is now planning' then
      'itinerary ready for '
        || coalesce(t.selected_destination, t.name) || ' 🗺️'
    when (e.payload->>'title') = 'trip is now live' then
      t.name
        || case when t.selected_destination is not null
               then ' (' || coalesce(t.selected_flag || ' ', '')
                    || t.selected_destination || ')'
               else '' end
        || ' is live — have fun ✈️'
    when (e.payload->>'title') = 'trip is now completed' then
      t.name
        || case when t.selected_destination is not null
               then ' (' || coalesce(t.selected_flag || ' ', '')
                    || t.selected_destination || ')'
               else '' end
        || ' wrapped — welcome home 💫'
    else e.payload->>'title'
  end)
)
from public.trips t
where t.id = e.trip_id
  and (e.payload->>'title') like 'trip is now %';
