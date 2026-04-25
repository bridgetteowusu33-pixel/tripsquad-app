-- ─────────────────────────────────────────────────────────────
-- 036 — Backfill existing "trip is now X" notifications
--
-- Migration 035 only changes future notifications. This one
-- retitles existing rows so the inbox reads the same as new ones.
-- Limits to rows where the title matches the old generic format
-- so we don't clobber custom titles.
-- ─────────────────────────────────────────────────────────────

update public.notifications n
set title = case
  when n.title = 'trip is now revealed' then
    'squad is going to '
      || coalesce(t.selected_flag || ' ', '')
      || coalesce(t.selected_destination, t.name) || ' 🎉'
  when n.title = 'trip is now voting' then
    t.name || ' — 3 options to vote on 🗳️'
  when n.title = 'trip is now planning' then
    'itinerary ready for '
      || coalesce(t.selected_destination, t.name) || ' 🗺️'
  when n.title = 'trip is now live' then
    t.name
      || case when t.selected_destination is not null
             then ' (' || coalesce(t.selected_flag || ' ', '')
                  || t.selected_destination || ')'
             else '' end
      || ' is live — have fun ✈️'
  when n.title = 'trip is now completed' then
    t.name
      || case when t.selected_destination is not null
             then ' (' || coalesce(t.selected_flag || ' ', '')
                  || t.selected_destination || ')'
             else '' end
      || ' wrapped — welcome home 💫'
  else n.title
end
from public.trips t
where t.id = n.trip_id
  and n.title like 'trip is now %';
