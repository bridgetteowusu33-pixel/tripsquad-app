-- v1.2.0 — Anchor flight robustness
--
-- Two real bugs in the anchor flight election from migration 062:
--
-- (1) If the anchor un-books or cancels (DELETE the row, or UPDATE state
--     away from 'booked'), nobody else gets promoted. The trip ends up
--     with bookers but no anchor; the "match arrival" hint goes blank.
--
-- (2) The Flutter client did SELECT-then-UPSERT non-atomically. Two
--     squad members tapping "I booked" within the same second both
--     observed prior_anchor_count=0, both tried to write is_anchor=true,
--     and the partial unique index `(trip_id) WHERE is_anchor=true`
--     rejected the loser's commit — meaning their booking failed
--     entirely instead of just losing the anchor flag.
--
-- Fixes:
--
--   * Trigger _maybe_promote_next_anchor — fires AFTER UPDATE/DELETE
--     on member_arrival_plans. If the affected row WAS the anchor and
--     no longer is, promote the next earliest non-anchor 'booked' row.
--
--   * RPC book_my_flight — atomic: locks the trip row FOR UPDATE,
--     elects the anchor, upserts the member_arrival_plans row, and
--     records the booking_confirmation row. Loser of the race still
--     books — they just don't get the anchor flag.

-- ─── 1. Auto-promote next anchor on cancellation ────────────────
CREATE OR REPLACE FUNCTION public._maybe_promote_next_anchor()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  was_anchor boolean := false;
  trip uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    was_anchor := OLD.is_anchor;
    trip := OLD.trip_id;
  ELSE -- UPDATE
    -- Only act if the anchor flag dropped or the user moved away
    -- from 'booked' state (e.g. went back to 'searching').
    IF OLD.is_anchor = true
       AND (NEW.is_anchor = false OR NEW.state <> 'booked') THEN
      was_anchor := true;
      trip := OLD.trip_id;
    END IF;
  END IF;

  IF NOT was_anchor THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- Promote the earliest still-booked, non-anchor row.
  UPDATE public.member_arrival_plans
     SET is_anchor = true
   WHERE id = (
     SELECT id FROM public.member_arrival_plans
      WHERE trip_id = trip
        AND state = 'booked'
        AND is_anchor = false
        AND (TG_OP <> 'UPDATE' OR id <> NEW.id)
      ORDER BY booked_at NULLS LAST, id
      LIMIT 1
   );

  RETURN COALESCE(NEW, OLD);
END $$;

DROP TRIGGER IF EXISTS trg_promote_next_anchor ON public.member_arrival_plans;
CREATE TRIGGER trg_promote_next_anchor
  AFTER UPDATE OR DELETE ON public.member_arrival_plans
  FOR EACH ROW
  EXECUTE FUNCTION public._maybe_promote_next_anchor();

-- Lockdown — internal trigger function, never called via API.
REVOKE EXECUTE ON FUNCTION public._maybe_promote_next_anchor()
  FROM PUBLIC, anon, authenticated;

-- ─── 2. Atomic anchor election RPC ──────────────────────────────
CREATE OR REPLACE FUNCTION public.book_my_flight(
  p_trip_id        uuid,
  p_outbound_at    timestamptz DEFAULT NULL,
  p_airline        text DEFAULT NULL,
  p_flight_number  text DEFAULT NULL,
  p_booking_ref    text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  uid uuid := auth.uid();
  prior_anchor_count int;
  am_i_anchor boolean;
  result_row record;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  -- Lock the trip row to serialize anchor election among concurrent
  -- bookers. Non-anchor concurrent bookers wait microseconds.
  PERFORM 1 FROM public.trips WHERE id = p_trip_id FOR UPDATE;

  -- Count existing anchors. Should be 0 or 1.
  SELECT COUNT(*) INTO prior_anchor_count
    FROM public.member_arrival_plans
   WHERE trip_id = p_trip_id
     AND state = 'booked'
     AND is_anchor = true;

  am_i_anchor := (prior_anchor_count = 0);

  -- Upsert. Anchor flag is set on first INSERT election, and PRESERVED
  -- on subsequent updates (e.g. user editing flight details). Never
  -- promotes a non-anchor to anchor on update — that would race-create
  -- duplicate anchors.
  INSERT INTO public.member_arrival_plans (
    trip_id, user_id, state, is_anchor,
    outbound_at, airline, flight_number, booking_ref, booked_at
  ) VALUES (
    p_trip_id, uid, 'booked', am_i_anchor,
    p_outbound_at, p_airline, p_flight_number, p_booking_ref, now()
  )
  ON CONFLICT (trip_id, user_id) DO UPDATE
     SET state         = 'booked',
         is_anchor     = member_arrival_plans.is_anchor, -- keep existing
         outbound_at   = COALESCE(EXCLUDED.outbound_at, member_arrival_plans.outbound_at),
         airline       = COALESCE(EXCLUDED.airline, member_arrival_plans.airline),
         flight_number = COALESCE(EXCLUDED.flight_number, member_arrival_plans.flight_number),
         booking_ref   = COALESCE(EXCLUDED.booking_ref, member_arrival_plans.booking_ref),
         booked_at     = COALESCE(member_arrival_plans.booked_at, now())
  RETURNING is_anchor, id INTO result_row;

  -- Squad-visible booking_confirmation log (for the lock-in chip).
  INSERT INTO public.booking_confirmations (trip_id, user_id, kind)
  VALUES (p_trip_id, uid, 'flight')
  ON CONFLICT DO NOTHING;

  RETURN jsonb_build_object(
    'is_anchor', result_row.is_anchor,
    'arrival_plan_id', result_row.id,
    'trip_id', p_trip_id,
    'user_id', uid
  );
END $$;

REVOKE ALL ON FUNCTION public.book_my_flight(uuid, timestamptz, text, text, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.book_my_flight(uuid, timestamptz, text, text, text)
  TO authenticated;
