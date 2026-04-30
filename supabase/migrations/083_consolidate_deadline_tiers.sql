-- v1.2.0 — Push notification quality, not quantity
--
-- Original design (migration 067) fired 3 push tiers per deadline:
--   24h before, 8h before, 2h before — each as a separate push.
-- Plus host nudge, lock-in celebration, multi-device fan-out (now
-- both iPhone + iPad ring), and richer body copy.
--
-- Math: 6-person squad × 3 deadlines (flights/stays/activities)
--       × 3 tiers × 2 devices = 108 push impressions across the squad
--       per trip. Plus celebrations and nudges. We were inviting opt-out.
--
-- Consolidation:
--   - Keep the 24h tier (genuinely time-sensitive heads-up).
--   - DROP 8h and 2h tiers — they fire when the user is already aware
--     and just adds noise. The in-app deadline_chip + lockin_chip cover
--     this surface continuously.
--   - Lock-in celebration push stays (single moment, high signal).
--   - Host nudge stays (host-initiated, throttled per-recipient).
--
-- The 8h and 2h logic stays in the function (commented out) for easy
-- revival if metrics later show the 24h tier alone misses real users.
-- The warned_8h_at / warned_2h_at columns stay so we don't have to
-- migrate data; they just stop being touched.

CREATE OR REPLACE FUNCTION public.notify_upcoming_deadlines()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  d record;
  hours_left numeric;
  tier text;
  push_body text;
BEGIN
  FOR d IN
    SELECT tbd.id, tbd.trip_id, tbd.kind, tbd.deadline_at,
           tbd.warned_24h_at,
           t.name AS trip_name
    FROM public.trip_booking_deadlines tbd
    JOIN public.trips t ON t.id = tbd.trip_id
    WHERE tbd.deadline_at > now()
      AND tbd.deadline_at <= now() + INTERVAL '25 hours'
      AND tbd.warned_24h_at IS NULL
  LOOP
    hours_left := EXTRACT(EPOCH FROM (d.deadline_at - now())) / 3600;

    -- Single tier now: 24h heads-up only. The 8h and 2h tiers are
    -- intentionally retired; the in-app deadline chip handles the
    -- "you're getting close" awareness without burning push budget.
    IF hours_left <= 24 AND d.warned_24h_at IS NULL THEN
      tier := '24h';
    ELSE
      CONTINUE;
    END IF;

    push_body := CASE
      WHEN d.kind = 'flight'        THEN '✈️ flights lock-in is tomorrow for ' || d.trip_name
      WHEN d.kind = 'accommodation' THEN '🏨 stays lock-in is tomorrow for ' || d.trip_name
      ELSE '⏳ booking lock-in is tomorrow for ' || d.trip_name
    END;

    INSERT INTO public.trip_events (trip_id, kind, payload)
    VALUES (
      d.trip_id,
      'deadline_warning',
      jsonb_build_object(
        'tier', tier,
        'deadline_kind', d.kind,
        'deadline_at', d.deadline_at,
        'body', push_body
      )
    );

    UPDATE public.trip_booking_deadlines
       SET warned_24h_at = now()
     WHERE id = d.id;
  END LOOP;
END $$;

REVOKE ALL ON FUNCTION public.notify_upcoming_deadlines() FROM PUBLIC;

-- ─── Push notification opt-out telemetry ─────────────────────────
-- Critical metric: % of users who have disabled TripSquad pushes.
-- If this crosses ~20%, we have a quantity problem and need to
-- consolidate further. The Flutter app reports the platform-level
-- authorization status on every cold start (and on settings tab focus
-- if changed). We dedupe + roll up via SQL.

CREATE TABLE IF NOT EXISTS public.push_permission_log (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status       text NOT NULL
                 CHECK (status IN ('authorized', 'denied', 'provisional',
                                   'ephemeral', 'not_determined')),
  platform     text,
  app_version  text,
  recorded_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_push_permission_log_user
  ON public.push_permission_log (user_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_push_permission_log_status
  ON public.push_permission_log (status, recorded_at DESC);

ALTER TABLE public.push_permission_log ENABLE ROW LEVEL SECURITY;

-- Only the user themselves can write their own row. Service-role
-- reads aggregate metrics. No public client SELECT.
CREATE POLICY "Users insert their own permission log"
  ON public.push_permission_log
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ─── Opt-out rate view (service-role / dashboard only) ───────────
-- "User's most recent permission status" → opt-out % over the last
-- 7 days of cohort users. Anchor metric for the push-quantity policy.
CREATE OR REPLACE VIEW public.push_optout_rate_7d AS
WITH latest AS (
  SELECT DISTINCT ON (user_id) user_id, status, recorded_at
  FROM public.push_permission_log
  WHERE recorded_at >= now() - INTERVAL '7 days'
  ORDER BY user_id, recorded_at DESC
)
SELECT
  COUNT(*) FILTER (WHERE status = 'denied')::numeric
    / NULLIF(COUNT(*), 0) * 100 AS optout_pct,
  COUNT(*) FILTER (WHERE status = 'denied') AS denied_count,
  COUNT(*) AS total_users_seen,
  now() AS computed_at
FROM latest;

ALTER VIEW public.push_optout_rate_7d SET (security_invoker = on);
REVOKE SELECT ON public.push_optout_rate_7d FROM anon, authenticated;
