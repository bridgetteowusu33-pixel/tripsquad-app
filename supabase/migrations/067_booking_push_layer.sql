-- v1.2 — Booking layer (Phase 1 day 13)
-- Push notifications for the booking surface:
--   1. Update trip_events.kind check to allow booking-layer kinds
--      (recommendations_ready, flight_booked, accommodation_booked,
--      deadline_warning, lockin_complete) — without this, every
--      booking event INSERT failed silently in our try/catch.
--   2. Add per-tier idempotency columns to trip_booking_deadlines so
--      a 24h reminder only fires once even if cron runs every 15min.
--   3. Cron-driven function notify_upcoming_deadlines() that scans
--      for deadlines approaching the 24h / 8h / 2h windows and INSERTs
--      notifications directly (the existing send_push webhook on
--      notifications INSERT delivers via FCM).
--   4. Trigger on booking_confirmations INSERT that fires a
--      `lockin_complete` trip_event the moment the squad hits 100%
--      booked for that kind. The fan-out + push pipeline does the
--      rest — every member gets a "we're really going" push.

-- ─── 1. Allow booking-layer kinds in trip_events ──────────────
ALTER TABLE public.trip_events
  DROP CONSTRAINT IF EXISTS trip_events_kind_check;
ALTER TABLE public.trip_events
  ADD CONSTRAINT trip_events_kind_check CHECK (kind IN (
    'status_changed','vote_cast','chat_message','itinerary_ready',
    'packing_ready',
    'member_joined','reveal','options_generated','dm_sent',
    'proposal_new','proposal_approved','proposal_rejected',
    'nudge_stale_invite','nudge_countdown','nudge_live_today','nudge_recap',
    -- v1.1+ stays + eats + booking layer
    'recommendations_ready',
    'flight_booked','accommodation_booked',
    'deadline_warning','lockin_complete'
  ));

-- ─── 2. Idempotency tracking for deadline warnings ────────────
ALTER TABLE public.trip_booking_deadlines
  ADD COLUMN IF NOT EXISTS warned_24h_at timestamptz,
  ADD COLUMN IF NOT EXISTS warned_8h_at  timestamptz,
  ADD COLUMN IF NOT EXISTS warned_2h_at  timestamptz;

-- ─── 3. notify_upcoming_deadlines() ───────────────────────────
-- Pattern matches 038's nudge functions: INSERT directly into
-- public.notifications (one row per squad member) so the push
-- webhook fires. Each tier has its own warned_*_at gate so we don't
-- spam every cron tick.
CREATE OR REPLACE FUNCTION public.notify_upcoming_deadlines()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  d record;
  delta interval;
  tier text;
  hours_left int;
  title_text text;
  body_text text;
BEGIN
  FOR d IN
    SELECT tbd.trip_id, tbd.kind, tbd.deadline_at,
           tbd.warned_24h_at, tbd.warned_8h_at, tbd.warned_2h_at,
           t.name AS trip_name
    FROM public.trip_booking_deadlines tbd
    JOIN public.trips t ON t.id = tbd.trip_id
    WHERE tbd.deadline_at > now()
      AND tbd.deadline_at < now() + interval '25 hours'
  LOOP
    delta := d.deadline_at - now();
    hours_left := EXTRACT(EPOCH FROM delta) / 3600;

    -- Determine which tier we're in. Higher windows take precedence
    -- so we don't double-fire a 24h then immediately a 2h.
    IF hours_left <= 2 AND d.warned_2h_at IS NULL THEN
      tier := '2h';
    ELSIF hours_left <= 8 AND d.warned_8h_at IS NULL THEN
      tier := '8h';
    ELSIF hours_left <= 24 AND d.warned_24h_at IS NULL THEN
      tier := '24h';
    ELSE
      CONTINUE;
    END IF;

    title_text := CASE
      WHEN d.kind = 'flight' THEN '✈️ flight booking deadline · ' || tier || ' left'
      ELSE '🏨 accommodation deadline · ' || tier || ' left'
    END;
    body_text := 'lock in your ' || d.kind || ' for ' || coalesce(d.trip_name, 'the trip')
                 || ' before time runs out';

    -- Fire one notification per joined squad member who hasn't yet
    -- confirmed THIS booking kind. No reminder for users already
    -- locked in.
    INSERT INTO public.notifications
      (user_id, trip_id, kind, title, body)
    SELECT sm.user_id, d.trip_id, 'deadline_warning', title_text, body_text
    FROM public.squad_members sm
    WHERE sm.trip_id = d.trip_id
      AND sm.user_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM public.booking_confirmations bc
        WHERE bc.trip_id = d.trip_id
          AND bc.user_id = sm.user_id
          AND bc.kind = d.kind
      );

    -- Same for the host if not in squad_members.
    INSERT INTO public.notifications
      (user_id, trip_id, kind, title, body)
    SELECT t.host_id, d.trip_id, 'deadline_warning', title_text, body_text
    FROM public.trips t
    WHERE t.id = d.trip_id
      AND t.host_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM public.squad_members sm
        WHERE sm.trip_id = d.trip_id AND sm.user_id = t.host_id
      )
      AND NOT EXISTS (
        SELECT 1 FROM public.booking_confirmations bc
        WHERE bc.trip_id = d.trip_id
          AND bc.user_id = t.host_id
          AND bc.kind = d.kind
      );

    -- Mark this tier as warned so we don't re-fire.
    UPDATE public.trip_booking_deadlines
       SET warned_24h_at = CASE WHEN tier = '24h' THEN now() ELSE warned_24h_at END,
           warned_8h_at  = CASE WHEN tier = '8h'  THEN now() ELSE warned_8h_at  END,
           warned_2h_at  = CASE WHEN tier = '2h'  THEN now() ELSE warned_2h_at  END
     WHERE trip_id = d.trip_id AND kind = d.kind;
  END LOOP;
END $$;

REVOKE ALL ON FUNCTION public.notify_upcoming_deadlines() FROM PUBLIC;

-- Schedule every 15 minutes. pg_cron is already enabled (see 038).
-- Unschedule first so re-running this migration is idempotent.
DO $$
BEGIN
  PERFORM cron.unschedule(jobid)
    FROM cron.job
   WHERE jobname = 'notify_upcoming_deadlines';
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
SELECT cron.schedule(
  'notify_upcoming_deadlines',
  '*/15 * * * *',
  'SELECT public.notify_upcoming_deadlines();'
);

-- ─── 4. lockin_complete trigger ───────────────────────────────
-- After a booking_confirmation lands, check if everyone in the squad
-- has now booked for that kind. If yes, fire one trip_event so the
-- existing fan-out + push pipeline tells the whole squad "we're
-- really going."
CREATE OR REPLACE FUNCTION public.maybe_fire_lockin_complete()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  squad_count int;
  booked_count int;
BEGIN
  -- Squad size: count of squad_members + 1 if host isn't in squad_members.
  SELECT COUNT(DISTINCT sm.user_id)
       + CASE WHEN EXISTS (
           SELECT 1 FROM public.trips t
           LEFT JOIN public.squad_members sm2
             ON sm2.trip_id = t.id AND sm2.user_id = t.host_id
            WHERE t.id = NEW.trip_id AND sm2.user_id IS NULL
              AND t.host_id IS NOT NULL
         ) THEN 1 ELSE 0 END
    INTO squad_count
    FROM public.squad_members sm
   WHERE sm.trip_id = NEW.trip_id
     AND sm.user_id IS NOT NULL;

  SELECT COUNT(DISTINCT user_id)
    INTO booked_count
    FROM public.booking_confirmations
   WHERE trip_id = NEW.trip_id AND kind = NEW.kind;

  -- Only fire when this confirmation pushes the count to/over the
  -- squad size, and only once per kind per trip.
  IF booked_count >= squad_count AND squad_count > 0
     AND NOT EXISTS (
       SELECT 1 FROM public.trip_events
        WHERE trip_id = NEW.trip_id
          AND kind = 'lockin_complete'
          AND payload->>'sub_kind' = NEW.kind
     )
  THEN
    INSERT INTO public.trip_events (trip_id, kind, actor_user_id, payload)
    VALUES (
      NEW.trip_id,
      'lockin_complete',
      NULL,  -- no actor exclusion — everyone gets the celebration push
      jsonb_build_object(
        'sub_kind', NEW.kind,
        'title', CASE
          WHEN NEW.kind = 'flight' THEN '🎉 squad is fully locked in for flights'
          ELSE '🎉 squad is fully booked into accommodation'
        END,
        'body', 'we''re really going.'
      )
    );
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_lockin_complete
  ON public.booking_confirmations;
CREATE TRIGGER trg_lockin_complete
  AFTER INSERT ON public.booking_confirmations
  FOR EACH ROW EXECUTE FUNCTION public.maybe_fire_lockin_complete();
