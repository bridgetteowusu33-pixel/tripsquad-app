-- v1.1 — Solo Explorer
-- Scope Scout chat messages to a specific trip (optional).
--
-- Background: today scout_messages is a single chronological feed
-- per user — works for the global Scout tab in the bottom nav.
-- For v1.1, when a user is inside a solo trip's space, the Chat
-- tab is replaced with Scout, and that Scout chat needs to be
-- distinct from their global Scout history (otherwise tomorrow's
-- "what's the budget for tokyo" pollutes next week's "where should
-- we go for spring break" conversation).
--
-- New rule: scout_messages.trip_id IS NULL means it belongs to
-- the global Scout chat. NON-NULL trip_id means it belongs to
-- that trip's in-space Scout chat.

ALTER TABLE scout_messages
  ADD COLUMN IF NOT EXISTS trip_id uuid
    REFERENCES trips(id) ON DELETE CASCADE;

-- Filter index — most lookups are "messages for trip X" or
-- "global messages for user Y" (trip_id IS NULL).
CREATE INDEX IF NOT EXISTS scout_messages_trip_id_idx
  ON scout_messages(trip_id)
  WHERE trip_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS scout_messages_user_global_idx
  ON scout_messages(user_id, created_at DESC)
  WHERE trip_id IS NULL;

-- RLS: existing policies on scout_messages are user-id-scoped
-- (you can only see your own). Trip-scoped messages are still
-- yours, so no policy change needed — the user_id check still
-- applies. The trip_id is just a sub-bucket.
