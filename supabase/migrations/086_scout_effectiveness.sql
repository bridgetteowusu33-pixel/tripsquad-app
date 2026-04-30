-- v1.2.0 — Scout 2.0 effectiveness measurement layer
--
-- Layer 1.5 of analytics. Adds event-level Scout call logging plus
-- four views that answer Scout-2.0-specific questions Layer 1 can't:
--
--   Q1. Do users with more accumulated context engage with Scout
--       differently than new users?  →  scout_engagement_by_context_richness
--   Q2. Is dislikes auto-inference precision acceptable? Are users
--       removing inferred dislikes a lot?  →  dislikes_inference_precision
--   Q3. Does tone selector usage correlate with retention?
--       →  scout_tone_distribution + scout_tone_engagement
--   Q4. Does "opinions over surveys" produce more or fewer follow-up
--       messages per conversation?  →  scout_conversation_depth
--
-- Plus the durable foundation: scout_call_log captures EVERY Scout API
-- call with the metadata needed to answer future questions we can't
-- predict yet ("did users who got better Scout responses retain
-- better?"). Privacy: lengths only — no message content stored.

-- ─────────────────────────────────────────────────────────────
-- 1. scout_call_log — event-level Scout call data
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.scout_call_log (
  id                          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                     uuid NOT NULL,
  trip_id                     uuid REFERENCES public.trips(id) ON DELETE SET NULL,
  is_private                  boolean DEFAULT false,
  tone                        text   CHECK (tone IN ('standard','chill','terse')),
  user_context_depth          int,    -- count of distinct USER CONTEXT lines populated (0-7)
  message_count_in_session    int,    -- count of this user's scout_messages in last 30min before this call
  input_length                int,    -- request content character count (NOT the content)
  response_length             int,    -- reply character count
  response_latency_ms         int,    -- server-measured Anthropic call latency
  has_image                   boolean DEFAULT false,
  prompt_version              text,   -- 'v1.2.0_sharper', etc. — enables A/B compare
  dislike_inference_triggered boolean DEFAULT false,
  dislikes_inferred_count     int     DEFAULT 0,
  created_at                  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_scout_call_log_user
  ON public.scout_call_log (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scout_call_log_trip
  ON public.scout_call_log (trip_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scout_call_log_tone
  ON public.scout_call_log (tone, created_at DESC);

ALTER TABLE public.scout_call_log ENABLE ROW LEVEL SECURITY;
-- No client policies — service-role-only write + read.
CREATE POLICY "service-role only — no client access"
  ON public.scout_call_log
  AS RESTRICTIVE
  FOR ALL
  USING (false) WITH CHECK (false);

-- ─────────────────────────────────────────────────────────────
-- 2. dislike_inferences — Haiku-extracted dislike provenance
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.dislike_inferences (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL,
  item            text NOT NULL,
  source_call_id  uuid REFERENCES public.scout_call_log(id) ON DELETE SET NULL,
  inferred_at     timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_dislike_inferences_user
  ON public.dislike_inferences (user_id, inferred_at DESC);

ALTER TABLE public.dislike_inferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "service-role only — no client access"
  ON public.dislike_inferences
  AS RESTRICTIVE
  FOR ALL
  USING (false) WITH CHECK (false);

-- ─────────────────────────────────────────────────────────────
-- 3. profiles.scout_tone + scout_tone_set_at + scout_tone_changes log
-- Server-side mirror of the SharedPreferences value so we can ask
-- "are tone-switchers more retained" in SQL.
-- ─────────────────────────────────────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS scout_tone         text DEFAULT 'standard'
                              CHECK (scout_tone IN ('standard','chill','terse')),
  ADD COLUMN IF NOT EXISTS scout_tone_set_at  timestamptz;

CREATE TABLE IF NOT EXISTS public.scout_tone_changes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL,
  from_tone   text,
  to_tone     text NOT NULL,
  changed_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_scout_tone_changes_user
  ON public.scout_tone_changes (user_id, changed_at DESC);

ALTER TABLE public.scout_tone_changes ENABLE ROW LEVEL SECURITY;
-- Users can write their own row (no need for service role on this path).
CREATE POLICY "Users log their own tone changes"
  ON public.scout_tone_changes
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────
-- 4. scout_engagement_by_context_richness   (Q1)
-- Per-user richness score = count of completed trips + dislikes
-- count + 4-5★ recap count. Bucket users low / med / high. Show
-- avg scout_messages per bucket.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.scout_engagement_by_context_richness AS
WITH user_richness AS (
  SELECT
    p.id AS user_id,
    COALESCE(p.trips_completed, 0)
      + COALESCE(array_length(p.dislikes, 1), 0)
      + COALESCE((SELECT COUNT(*) FROM public.destination_recaps r
                   WHERE r.user_id = p.id AND r.stars >= 4), 0)
      AS richness
  FROM public.profiles p
),
bucketed AS (
  SELECT user_id,
         CASE
           WHEN richness = 0       THEN 'cold (0)'
           WHEN richness BETWEEN 1 AND 3 THEN 'warming (1-3)'
           WHEN richness BETWEEN 4 AND 7 THEN 'engaged (4-7)'
           ELSE 'rich (8+)'
         END AS bucket,
         richness
  FROM user_richness
),
calls AS (
  SELECT user_id, COUNT(*) AS call_count
  FROM public.scout_call_log
  WHERE created_at >= now() - INTERVAL '30 days'
  GROUP BY user_id
)
SELECT
  b.bucket,
  COUNT(*)::int                                          AS users_in_bucket,
  ROUND(AVG(c.call_count)::numeric, 1)                   AS avg_scout_calls_30d,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY c.call_count)::numeric(10,1)
                                                          AS p50_scout_calls_30d,
  COUNT(c.user_id)::int                                  AS active_users_in_bucket
FROM bucketed b
LEFT JOIN calls c USING (user_id)
GROUP BY b.bucket
ORDER BY
  CASE b.bucket
    WHEN 'cold (0)'      THEN 1
    WHEN 'warming (1-3)' THEN 2
    WHEN 'engaged (4-7)' THEN 3
    WHEN 'rich (8+)'     THEN 4
  END;

ALTER VIEW public.scout_engagement_by_context_richness SET (security_invoker = on);
REVOKE SELECT ON public.scout_engagement_by_context_richness FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 5. dislikes_inference_precision   (Q2)
-- Of dislikes Haiku has inferred over the last 30 days, what % are
-- still in the user's profiles.dislikes array? Removed = false
-- positive. Precision proxy = still_present_pct.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.dislikes_inference_precision AS
WITH inferences AS (
  SELECT di.user_id, lower(di.item) AS item
  FROM public.dislike_inferences di
  WHERE di.inferred_at >= now() - INTERVAL '30 days'
),
current_dislikes AS (
  SELECT p.id AS user_id, lower(unnest(p.dislikes)) AS item
  FROM public.profiles p
  WHERE p.dislikes IS NOT NULL AND array_length(p.dislikes, 1) > 0
)
SELECT
  COUNT(*)::int                                     AS total_inferences_30d,
  COUNT(cd.item)::int                               AS still_present_count,
  ROUND(
    100.0 * COUNT(cd.item) / NULLIF(COUNT(*), 0),
    1
  )                                                 AS still_present_pct,
  ROUND(
    100.0 * (COUNT(*) - COUNT(cd.item)) / NULLIF(COUNT(*), 0),
    1
  )                                                 AS removed_pct,
  now() AS computed_at
FROM inferences i
LEFT JOIN current_dislikes cd
  ON cd.user_id = i.user_id AND cd.item = i.item;

ALTER VIEW public.dislikes_inference_precision SET (security_invoker = on);
REVOKE SELECT ON public.dislikes_inference_precision FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 6. scout_tone_distribution   (Q3 part 1)
-- Current tone breakdown across users who've used Scout.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.scout_tone_distribution AS
SELECT
  COALESCE(scout_tone, 'standard') AS tone,
  COUNT(*)::int                    AS users,
  ROUND(
    100.0 * COUNT(*)
      / NULLIF(SUM(COUNT(*)) OVER (), 0),
    1
  )                                AS share_pct
FROM public.profiles
GROUP BY scout_tone
ORDER BY users DESC;

ALTER VIEW public.scout_tone_distribution SET (security_invoker = on);
REVOKE SELECT ON public.scout_tone_distribution FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 7. scout_tone_engagement   (Q3 part 2)
-- Avg Scout calls per user, grouped by their CURRENT tone. A proxy
-- for "did changing tone correlate with stickier usage" — the
-- scout_tone_changes log enables a more rigorous version later.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.scout_tone_engagement AS
WITH per_user AS (
  SELECT
    p.id AS user_id,
    COALESCE(p.scout_tone, 'standard') AS tone,
    (SELECT COUNT(*) FROM public.scout_call_log c
      WHERE c.user_id = p.id
        AND c.created_at >= now() - INTERVAL '30 days') AS calls_30d
  FROM public.profiles p
)
SELECT
  tone,
  COUNT(*)::int                                       AS users,
  ROUND(AVG(calls_30d)::numeric, 1)                   AS avg_calls_30d,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY calls_30d)::numeric(10,1)
                                                       AS p50_calls_30d,
  PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY calls_30d)::numeric(10,1)
                                                       AS p90_calls_30d
FROM per_user
GROUP BY tone
ORDER BY users DESC;

ALTER VIEW public.scout_tone_engagement SET (security_invoker = on);
REVOKE SELECT ON public.scout_tone_engagement FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 8. scout_conversation_depth   (Q4)
-- Conversation = chain of scout_messages from one user with no gap
-- > 30min. For each conversation, count user-role messages.
-- Distribution shows whether "opinions over surveys" produces
-- shorter (clearer) or longer (deeper) conversations.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.scout_conversation_depth AS
WITH ordered AS (
  SELECT
    user_id,
    role,
    created_at,
    LAG(created_at) OVER (PARTITION BY user_id ORDER BY created_at) AS prev_at
  FROM public.scout_messages
  WHERE created_at >= now() - INTERVAL '30 days'
),
session_marks AS (
  SELECT
    *,
    CASE
      WHEN prev_at IS NULL
        OR created_at - prev_at > INTERVAL '30 minutes'
      THEN 1 ELSE 0
    END AS new_session
  FROM ordered
),
session_ids AS (
  SELECT
    *,
    SUM(new_session) OVER (PARTITION BY user_id ORDER BY created_at) AS session_id
  FROM session_marks
),
per_session AS (
  SELECT user_id, session_id,
         COUNT(*) FILTER (WHERE role = 'user')::int AS user_msgs
  FROM session_ids
  GROUP BY user_id, session_id
)
SELECT
  COUNT(*)::int                                          AS sessions_30d,
  ROUND(AVG(user_msgs)::numeric, 1)                      AS avg_user_msgs_per_session,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY user_msgs)::numeric(10,1)
                                                          AS p50_user_msgs,
  PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY user_msgs)::numeric(10,1)
                                                          AS p90_user_msgs,
  COUNT(*) FILTER (WHERE user_msgs = 1)::int             AS one_shot_sessions,
  COUNT(*) FILTER (WHERE user_msgs >= 5)::int            AS deep_sessions
FROM per_session;

ALTER VIEW public.scout_conversation_depth SET (security_invoker = on);
REVOKE SELECT ON public.scout_conversation_depth FROM anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 9. scout_call_health   (durable infrastructure view)
-- p50/p95 response latency by tone, plus call volume. Watch for
-- regressions when prompts change (compare prompt_version columns).
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.scout_call_health_30d AS
SELECT
  COALESCE(prompt_version, 'unknown') AS prompt_version,
  COALESCE(tone, 'standard')          AS tone,
  COUNT(*)::int                       AS calls,
  ROUND(AVG(response_latency_ms)::numeric, 0)::int  AS avg_latency_ms,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY response_latency_ms)::int
                                       AS p50_latency_ms,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_latency_ms)::int
                                       AS p95_latency_ms,
  ROUND(AVG(response_length)::numeric, 0)::int     AS avg_response_chars,
  ROUND(AVG(user_context_depth)::numeric, 1)       AS avg_ctx_depth,
  COUNT(*) FILTER (WHERE has_image) ::int           AS image_calls
FROM public.scout_call_log
WHERE created_at >= now() - INTERVAL '30 days'
GROUP BY prompt_version, tone
ORDER BY calls DESC;

ALTER VIEW public.scout_call_health_30d SET (security_invoker = on);
REVOKE SELECT ON public.scout_call_health_30d FROM anon, authenticated;
