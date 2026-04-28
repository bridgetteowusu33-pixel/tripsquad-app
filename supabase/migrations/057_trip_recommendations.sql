-- v1.1 — Stays + Eats, step 2 of 3
-- trip_recommendations: Scout-generated, trip-aware, squad-aware
-- recommendations for *where to stay* (area + hotels) and *where to
-- eat* (restaurants). One row per recommendation. The "best area"
-- pick is a first-class row with kind='area' so the UI doesn't need a
-- separate fetch path.
--
-- Why a separate table from `places`:
-- `places` is a community directory of user-saved places. Mixing AI
-- output into it would pollute the directory and confuse the social
-- aggregation in `place_stats`. We keep AI suggestions here, and link
-- via place_id when there's a confirmed match (so we de-dupe with
-- community-curated places without contaminating them).

CREATE TABLE IF NOT EXISTS public.trip_recommendations (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id         uuid NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  kind            text NOT NULL CHECK (kind IN ('area', 'hotel', 'restaurant')),
  rank            int  NOT NULL DEFAULT 0,
  name            text NOT NULL,
  neighborhood    text,
  price_band      text CHECK (price_band IN ('$', '$$', '$$$', '$$$$') OR price_band IS NULL),
  cuisine         text,                              -- restaurants only
  vibe_tags       text[] DEFAULT '{}',
  reason          text,                              -- "why scout picked it"
  day_anchor      int,                               -- nearest day_number, nullable
  meal            text CHECK (meal IN ('breakfast','lunch','dinner','late-night','snack') OR meal IS NULL),
  image_url       text,
  maps_url        text,                              -- Google Maps deep link, server-populated
  booking_url     text,                              -- Booking.com search URL (hotels) — affiliate-ready
  place_id        uuid REFERENCES public.places(id), -- nullable, set on directory match
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_trip_recommendations_trip_kind_rank
  ON public.trip_recommendations (trip_id, kind, rank);

ALTER TABLE public.trip_recommendations ENABLE ROW LEVEL SECURITY;

-- Mirrors itinerary_items RLS: trip members can SELECT only.
-- Writes are service-role (the Edge Function) — no user-facing INSERT
-- policy. Future: a "save this rec" promote-to-itinerary flow can
-- write into itinerary_items, not back into this table.
CREATE POLICY "Trip members can read recommendations"
  ON public.trip_recommendations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.trips t
      LEFT JOIN public.squad_members sm ON sm.trip_id = t.id
      WHERE t.id = trip_recommendations.trip_id
        AND (t.host_id = auth.uid() OR sm.user_id = auth.uid())
    )
  );

-- Realtime: clients subscribe to this so the tab fills in as soon
-- as the Edge Function inserts rows.
ALTER PUBLICATION supabase_realtime ADD TABLE public.trip_recommendations;
