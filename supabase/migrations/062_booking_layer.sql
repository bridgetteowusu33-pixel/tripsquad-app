-- v1.2 — Booking Layer, step 1 of 3
-- The squad-coordination layer that turns Stays + Eats picks into
-- bookings. Three new tables:
--
--  - member_arrival_plans: per squad member's flight context. Holds
--    departure city, arrival ETA, anchor flag (first booker becomes
--    the anchor — others' searches match this arrival ±2h).
--
--  - trip_booking_deadlines: host-set deadlines per booking kind so
--    we can show countdowns + send nudges. Optional per trip.
--
--  - booking_confirmations: self-reported "I booked this" log. Drives
--    the squad lock-in counter in the trip header even when we have
--    zero partner-API integration. Squad-visible so trust signals
--    are real.

-- ─── member_arrival_plans ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.member_arrival_plans (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id         uuid NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  user_id         uuid NOT NULL,
  departure_city  text,
  departure_iata  text,            -- 3-letter airport code, normalized
  arrival_iata    text,            -- derived from trip destination
  outbound_at     timestamptz,     -- locked when booked
  airline         text,
  flight_number   text,
  booking_ref     text,            -- user-pasted confirmation, optional
  state           text NOT NULL DEFAULT 'not_set'
                  CHECK (state IN ('not_set','searching','booked','cancelled')),
  is_anchor       boolean NOT NULL DEFAULT false,
  booked_at       timestamptz,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now(),
  UNIQUE (trip_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_member_arrival_plans_trip
  ON public.member_arrival_plans (trip_id);

-- Only one anchor per trip. Enforced via partial unique index so that
-- updates that flip is_anchor are atomic.
CREATE UNIQUE INDEX IF NOT EXISTS idx_member_arrival_plans_one_anchor
  ON public.member_arrival_plans (trip_id) WHERE is_anchor = true;

ALTER TABLE public.member_arrival_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trip members read arrival plans"
  ON public.member_arrival_plans FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.trips t
      LEFT JOIN public.squad_members sm ON sm.trip_id = t.id
      WHERE t.id = member_arrival_plans.trip_id
        AND (t.host_id = auth.uid() OR sm.user_id = auth.uid())
    )
  );

-- Members can manage their OWN row only.
CREATE POLICY "Members manage their own arrival plan"
  ON public.member_arrival_plans FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Realtime: clients subscribe to see when other squad members book.
ALTER TABLE public.member_arrival_plans REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.member_arrival_plans;

-- ─── trip_booking_deadlines ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.trip_booking_deadlines (
  trip_id      uuid NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  kind         text NOT NULL CHECK (kind IN ('flight','accommodation')),
  deadline_at  timestamptz NOT NULL,
  set_by       uuid,
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now(),
  PRIMARY KEY (trip_id, kind)
);

ALTER TABLE public.trip_booking_deadlines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trip members read deadlines"
  ON public.trip_booking_deadlines FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.trips t
      LEFT JOIN public.squad_members sm ON sm.trip_id = t.id
      WHERE t.id = trip_booking_deadlines.trip_id
        AND (t.host_id = auth.uid() OR sm.user_id = auth.uid())
    )
  );

-- Only the host can set/edit deadlines.
CREATE POLICY "Host writes deadlines"
  ON public.trip_booking_deadlines FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.trips t
      WHERE t.id = trip_booking_deadlines.trip_id
        AND t.host_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.trips t
      WHERE t.id = trip_booking_deadlines.trip_id
        AND t.host_id = auth.uid()
    )
  );

ALTER TABLE public.trip_booking_deadlines REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.trip_booking_deadlines;

-- ─── booking_confirmations ────────────────────────────────────
-- Squad-visible "I booked this" log. Each row = one member's
-- confirmation for one kind (flight or accommodation). Multiple
-- members can confirm the same recommendation_id (group hotel) —
-- that's how we count "3 of 6 booked into Casa Mariana."
CREATE TABLE IF NOT EXISTS public.booking_confirmations (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id             uuid NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  user_id             uuid NOT NULL,
  kind                text NOT NULL CHECK (kind IN ('flight','accommodation')),
  recommendation_id   uuid REFERENCES public.trip_recommendations(id) ON DELETE SET NULL,
  arrival_plan_id     uuid REFERENCES public.member_arrival_plans(id) ON DELETE SET NULL,
  total_cents         int,
  currency            text DEFAULT 'USD',
  notes               text,
  confirmed_at        timestamptz DEFAULT now(),
  -- One confirmation per (member, kind) per trip — re-confirming
  -- replaces the prior one rather than creating duplicates.
  UNIQUE (trip_id, user_id, kind)
);

CREATE INDEX IF NOT EXISTS idx_booking_confirmations_trip_kind
  ON public.booking_confirmations (trip_id, kind);

ALTER TABLE public.booking_confirmations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trip members read confirmations"
  ON public.booking_confirmations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.trips t
      LEFT JOIN public.squad_members sm ON sm.trip_id = t.id
      WHERE t.id = booking_confirmations.trip_id
        AND (t.host_id = auth.uid() OR sm.user_id = auth.uid())
    )
  );

CREATE POLICY "Members manage their own confirmations"
  ON public.booking_confirmations FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

ALTER TABLE public.booking_confirmations REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_confirmations;

-- ─── updated_at trigger (shared pattern) ──────────────────────
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE TRIGGER member_arrival_plans_touch
  BEFORE UPDATE ON public.member_arrival_plans
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER trip_booking_deadlines_touch
  BEFORE UPDATE ON public.trip_booking_deadlines
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
