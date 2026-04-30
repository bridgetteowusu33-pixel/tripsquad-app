-- v1.1 — Sentiment-router feedback (MemeScanr-style)
-- The "rate tripsquad" flow no longer asks for a star count up front.
-- Users vote a sentiment (happy / neutral / unhappy):
--   happy   → routed to Apple's InAppReview prompt, NOTHING written here
--   neutral → opens a feedback form (default category: featureRequest)
--   unhappy → opens a feedback form (default category: bug, empathy copy)
-- Only neutral + unhappy paths produce a row in this table.
--
-- Schema migration: stars becomes nullable (we no longer collect it from
-- the new flow), and we add sentiment + category enums for routing-aware
-- triage. Old (v1.0) inserts that included stars still work.

ALTER TABLE public.app_feedback
  ALTER COLUMN stars DROP NOT NULL;

ALTER TABLE public.app_feedback
  ADD COLUMN IF NOT EXISTS sentiment text
    CHECK (sentiment IN ('happy', 'neutral', 'unhappy'));

ALTER TABLE public.app_feedback
  ADD COLUMN IF NOT EXISTS category  text
    CHECK (category  IN ('bug', 'feature_request', 'general'));

ALTER TABLE public.app_feedback
  ADD COLUMN IF NOT EXISTS trigger   text;

CREATE INDEX IF NOT EXISTS idx_app_feedback_sentiment
  ON public.app_feedback (sentiment, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_feedback_category
  ON public.app_feedback (category, created_at DESC);
