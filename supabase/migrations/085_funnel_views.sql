-- v1.2.0 — Funnel + cohort SQL views
--
-- Layer 1 of analytics: derive activation, completion, retention, and
-- revenue answers from data we already capture. No client-side
-- instrumentation needed yet — every column referenced exists in the
-- production schema today (auth.users, trips, squad_members, votes,
-- destination_recaps, booking_confirmations, affiliate_clickthroughs,
-- app_feedback, push_permission_log, scout_messages).
--
-- All views are security_invoker + revoked from anon/authenticated,
-- so they're service-role / dashboard-only. Reads via SQL editor or
-- a future admin tool.
--
-- Behavioral event tracking (Scout feature usage, sheet dismissal
-- rates, etc.) is Layer 2 (PostHog). Queued separately.

-- ─────────────────────────────────────────────────────────────
-- 1. activation_funnel
-- One row per cohort milestone. Counts UNIQUE users that reached
-- each step at any point. Columns:
--   step_index | step | users_count | conversion_from_prior_pct
-- Conversion is funnel-style (each step's users / prior step's users).
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.activation_funnel AS
WITH counts AS (
  SELECT 1 AS step_index, 'signup' AS step,
         COUNT(*)::numeric AS users_count
    FROM auth.users
  UNION ALL
  SELECT 2, 'profile_completed',
         COUNT(*) FROM public.profiles
        WHERE home_airport IS NOT NULL AND length(trim(home_airport)) > 0
  UNION ALL
  SELECT 3, 'first_trip_joined',
         (SELECT COUNT(DISTINCT user_id) FROM public.squad_members)
  UNION ALL
  SELECT 4, 'first_vote_cast',
         (SELECT COUNT(DISTINCT user_id) FROM public.votes)
  UNION ALL
  SELECT 5, 'first_trip_revealed',
         (SELECT COUNT(DISTINCT sm.user_id)
            FROM public.squad_members sm
            JOIN public.trips t ON t.id = sm.trip_id
           WHERE t.status IN ('revealed','planning','live','completed'))
  UNION ALL
  SELECT 6, 'first_booking_logged',
         (SELECT COUNT(DISTINCT user_id) FROM public.booking_confirmations)
  UNION ALL
  SELECT 7, 'first_trip_completed',
         (SELECT COUNT(DISTINCT sm.user_id)
            FROM public.squad_members sm
            JOIN public.trips t ON t.id = sm.trip_id
           WHERE t.status = 'completed')
  UNION ALL
  SELECT 8, 'first_recap_submitted',
         (SELECT COUNT(DISTINCT user_id) FROM public.destination_recaps)
)
SELECT
  step_index,
  step,
  users_count::int,
  ROUND(
    100.0 * users_count
    / NULLIF(LAG(users_count) OVER (ORDER BY step_index), 0),
    1
  ) AS conversion_from_prior_pct
FROM counts
ORDER BY step_index;

ALTER VIEW public.activation_funnel SET (security_invoker = on);
REVOKE SELECT ON public.activation_funnel FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 2. trip_status_distribution
-- How many trips are sitting in each status bucket right now.
-- Health check: 'collecting' or 'voting' that's been stale > 30 days
-- = squad ghosted. 'revealed' or 'planning' stale > 60 days = same.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.trip_status_distribution AS
SELECT
  status,
  COUNT(*)::int AS trip_count,
  COUNT(*) FILTER (WHERE updated_at < now() - INTERVAL '30 days')::int
    AS stale_30d_count,
  ROUND(AVG(EXTRACT(EPOCH FROM (now() - updated_at)) / 86400)::numeric, 1)
    AS avg_days_since_update
FROM public.trips
GROUP BY status
ORDER BY
  CASE status
    WHEN 'collecting' THEN 1
    WHEN 'voting'     THEN 2
    WHEN 'revealed'   THEN 3
    WHEN 'planning'   THEN 4
    WHEN 'live'       THEN 5
    WHEN 'completed'  THEN 6
    ELSE 99
  END;

ALTER VIEW public.trip_status_distribution SET (security_invoker = on);
REVOKE SELECT ON public.trip_status_distribution FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 3. trip_completion_rate_30d
-- Of trips CREATED in the trailing 30 days, what % have reached
-- 'completed'? Lower bound — recent trips haven't had time to finish.
-- Pair with `signup_to_first_trip_lag` for a fuller picture.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.trip_completion_rate_30d AS
SELECT
  COUNT(*) FILTER (WHERE status = 'completed')::numeric
    / NULLIF(COUNT(*), 0) * 100 AS completion_pct,
  COUNT(*) FILTER (WHERE status = 'completed')::int AS completed_count,
  COUNT(*)::int AS total_created_30d,
  now() AS computed_at
FROM public.trips
WHERE created_at >= now() - INTERVAL '30 days';

ALTER VIEW public.trip_completion_rate_30d SET (security_invoker = on);
REVOKE SELECT ON public.trip_completion_rate_30d FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 4. signup_to_first_trip_lag
-- Time from auth.users.created_at to the user's first trip
-- (host or squad member). p50 / p90 / p99 in days.
-- High lag = we're losing users between sign-up and starting a trip.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.signup_to_first_trip_lag AS
WITH first_trip AS (
  SELECT
    sm.user_id,
    MIN(sm.created_at) AS first_trip_at
  FROM public.squad_members sm
  GROUP BY sm.user_id
)
SELECT
  PERCENTILE_CONT(0.5) WITHIN GROUP (
    ORDER BY EXTRACT(EPOCH FROM (ft.first_trip_at - u.created_at)) / 86400
  )::numeric(10,1) AS p50_days,
  PERCENTILE_CONT(0.9) WITHIN GROUP (
    ORDER BY EXTRACT(EPOCH FROM (ft.first_trip_at - u.created_at)) / 86400
  )::numeric(10,1) AS p90_days,
  PERCENTILE_CONT(0.99) WITHIN GROUP (
    ORDER BY EXTRACT(EPOCH FROM (ft.first_trip_at - u.created_at)) / 86400
  )::numeric(10,1) AS p99_days,
  COUNT(*)::int AS users_sampled,
  now() AS computed_at
FROM auth.users u
JOIN first_trip ft ON ft.user_id = u.id;

ALTER VIEW public.signup_to_first_trip_lag SET (security_invoker = on);
REVOKE SELECT ON public.signup_to_first_trip_lag FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 5. revenue_per_user_30d
-- Affiliate clickthroughs per user in the trailing 30 days.
-- Proxy for revenue (real revenue requires partner postback —
-- schema is ready but no postbacks yet). Top spenders + median.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.revenue_per_user_30d AS
WITH per_user AS (
  SELECT user_id, COUNT(*) AS clicks
  FROM public.affiliate_clickthroughs
  WHERE clicked_at >= now() - INTERVAL '30 days'
    AND user_id IS NOT NULL
  GROUP BY user_id
)
SELECT
  COUNT(*)::int                                       AS active_users,
  SUM(clicks)::int                                    AS total_clicks,
  ROUND(AVG(clicks)::numeric, 2)                      AS avg_clicks_per_user,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clicks)::numeric(10,1)
                                                      AS p50_clicks,
  PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY clicks)::numeric(10,1)
                                                      AS p90_clicks,
  MAX(clicks)::int                                    AS max_clicks_per_user
FROM per_user;

ALTER VIEW public.revenue_per_user_30d SET (security_invoker = on);
REVOKE SELECT ON public.revenue_per_user_30d FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 6. recommendation_engagement_30d
-- Affiliate clickthroughs grouped by kind (hotel / restaurant /
-- flight / etc.) — which Scout-rec card type actually converts.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.recommendation_engagement_30d AS
SELECT
  COALESCE(kind, 'unknown') AS kind,
  COUNT(*)::int AS clicks,
  COUNT(DISTINCT user_id)::int AS unique_users,
  ROUND(
    100.0 * COUNT(*)
      / NULLIF(SUM(COUNT(*)) OVER (), 0),
    1
  ) AS share_pct
FROM public.affiliate_clickthroughs
WHERE clicked_at >= now() - INTERVAL '30 days'
GROUP BY kind
ORDER BY clicks DESC;

ALTER VIEW public.recommendation_engagement_30d SET (security_invoker = on);
REVOKE SELECT ON public.recommendation_engagement_30d FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 7. feedback_sentiment_30d
-- App feedback router rollup. Useful as a vibe check alongside
-- the App Store rating distribution.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.feedback_sentiment_30d AS
SELECT
  COALESCE(sentiment, 'unknown') AS sentiment,
  COALESCE(category, 'unknown')  AS category,
  COUNT(*)::int                  AS submissions
FROM public.app_feedback
WHERE created_at >= now() - INTERVAL '30 days'
GROUP BY sentiment, category
ORDER BY submissions DESC;

ALTER VIEW public.feedback_sentiment_30d SET (security_invoker = on);
REVOKE SELECT ON public.feedback_sentiment_30d FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 8. active_users_rolling
-- DAU / WAU / MAU using union of activity signals (chat messages,
-- votes, scout messages, booking confirmations, recap submissions).
-- A user counts as "active on day X" if they took ANY of these
-- actions on that day. Returns single row.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.active_users_rolling AS
WITH activity AS (
  -- Timestamp columns differ across tables (`created_at` vs
  -- `confirmed_at`); aliasing to a single name lets the rollup query
  -- be written once.
  SELECT user_id, created_at   AS at FROM public.chat_messages WHERE user_id IS NOT NULL
  UNION ALL
  SELECT user_id, created_at   AS at FROM public.votes
  UNION ALL
  SELECT user_id, created_at   AS at FROM public.scout_messages
  UNION ALL
  SELECT user_id, confirmed_at AS at FROM public.booking_confirmations
  UNION ALL
  SELECT user_id, created_at   AS at FROM public.destination_recaps
)
SELECT
  COUNT(DISTINCT user_id) FILTER
    (WHERE at >= now() - INTERVAL '1 day')::int  AS dau,
  COUNT(DISTINCT user_id) FILTER
    (WHERE at >= now() - INTERVAL '7 days')::int AS wau,
  COUNT(DISTINCT user_id) FILTER
    (WHERE at >= now() - INTERVAL '30 days')::int AS mau,
  ROUND(
    100.0 * COUNT(DISTINCT user_id) FILTER (WHERE at >= now() - INTERVAL '1 day')
    / NULLIF(COUNT(DISTINCT user_id) FILTER (WHERE at >= now() - INTERVAL '30 days'), 0),
    1
  ) AS dau_mau_pct,
  now() AS computed_at
FROM activity;

ALTER VIEW public.active_users_rolling SET (security_invoker = on);
REVOKE SELECT ON public.active_users_rolling FROM anon, authenticated;
