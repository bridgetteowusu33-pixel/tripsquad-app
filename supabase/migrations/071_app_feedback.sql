-- v1.2 — In-app feedback (replaces direct "rate tripsquad" tap)
-- Apple won't let us submit App Store ratings from our own UI. So
-- we collect in-app feedback into this table — every rating + free-
-- text comment + version. Then we use Apple's requestReview() to
-- prompt the App Store rating ONLY for users who give us 4-5 stars
-- (a "double opt-in" — we filter for happy users, App Store ratings
-- skew positive, unhappy users get a follow-up channel instead).
--
-- RLS:
--  - INSERT: any authenticated user can submit their own row
--  - SELECT: service-role only (this is private signal for us, not
--    a social surface). Users see their own write only via the
--    insert response, never via re-fetch.

CREATE TABLE IF NOT EXISTS public.app_feedback (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL,
  stars         int  NOT NULL CHECK (stars BETWEEN 1 AND 5),
  comment       text,
  app_version   text,
  build_number  text,
  platform      text,
  created_at    timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_app_feedback_created
  ON public.app_feedback (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_feedback_stars
  ON public.app_feedback (stars, created_at DESC);

ALTER TABLE public.app_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can submit their own feedback"
  ON public.app_feedback FOR INSERT
  WITH CHECK (user_id = auth.uid());
-- No SELECT/UPDATE/DELETE policies → reads are service-role only.
