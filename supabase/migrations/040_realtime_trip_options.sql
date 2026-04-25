-- ─────────────────────────────────────────────────────────────
-- 040 — Realtime on trip_options for live vote counts
--
-- The web invite flow doesn't insert into the `votes` table — it
-- calls `increment_option_vote` RPC which bumps vote_count directly
-- on trip_options. The in-app Vote tab's realtime subscription on
-- `votes` misses those updates. Adding trip_options to the realtime
-- publication lets the client pick them up.
-- REPLICA IDENTITY FULL is not strictly required (we don't need the
-- old row on an update), but setting it keeps us consistent with
-- other mutable tables so Supabase emits the full new row.
-- ─────────────────────────────────────────────────────────────

alter table public.trip_options replica identity full;
alter publication supabase_realtime add table trip_options;
