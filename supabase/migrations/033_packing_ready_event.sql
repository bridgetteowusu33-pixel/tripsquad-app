-- ─────────────────────────────────────────────────────────────
-- 033 — Extend trip_events.kind CHECK to include packing_ready
--
-- The original migration 002 allowed:
--   status_changed, vote_cast, chat_message, itinerary_ready,
--   member_joined, reveal, options_generated, dm_sent
--
-- This migration adds 'packing_ready' so the generate_packing_list
-- edge function can broadcast a "packing list is ready" trip_event
-- that fans out notifications to the whole squad.
-- ─────────────────────────────────────────────────────────────

alter table public.trip_events
  drop constraint if exists trip_events_kind_check;

alter table public.trip_events
  add constraint trip_events_kind_check check (kind in (
    'status_changed','vote_cast','chat_message','itinerary_ready',
    'packing_ready',
    'member_joined','reveal','options_generated','dm_sent',
    'proposal_new','proposal_approved','proposal_rejected'
  ));
