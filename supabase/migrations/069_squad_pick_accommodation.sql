-- v1.2 — Phase 2.5 booking layer
-- Squad accommodation pick: host designates ONE of Scout's hotel
-- recommendations as "the squad's place to stay." Squadmates confirm
-- they're in (lock-in counter climbs); members who can't can still
-- tap a different hotel as their personal alternative.
--
-- Two columns on trips so the squad-pick is just a property of the
-- trip itself (matches existing model: trips.selected_destination,
-- trips.estimated_budget, etc.). RLS already covers host writes
-- (trips "Host full access" policy from migration 001).
--
-- Plus a new trip_events.kind 'squad_pick_set' so push-on-pick
-- works through the existing fan_out_trip_event pipeline.

ALTER TABLE public.trips
  ADD COLUMN IF NOT EXISTS squad_pick_accommodation_id uuid
    REFERENCES public.trip_recommendations(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS squad_pick_set_at timestamptz;

-- Allow the new event kind. Keep all prior kinds in the list so
-- existing inserts don't break.
ALTER TABLE public.trip_events
  DROP CONSTRAINT IF EXISTS trip_events_kind_check;
ALTER TABLE public.trip_events
  ADD CONSTRAINT trip_events_kind_check CHECK (kind IN (
    'status_changed','vote_cast','chat_message','itinerary_ready',
    'packing_ready',
    'member_joined','reveal','options_generated','dm_sent',
    'proposal_new','proposal_approved','proposal_rejected',
    'nudge_stale_invite','nudge_countdown','nudge_live_today','nudge_recap',
    'recommendations_ready',
    'flight_booked','accommodation_booked',
    'deadline_warning','lockin_complete',
    -- Phase 2.5
    'squad_pick_set'
  ));
