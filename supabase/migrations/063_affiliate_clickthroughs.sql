-- v1.2 — Booking Layer, step 2 of 3
-- affiliate_clickthroughs: every outbound link goes through the
-- `affiliate_redirect` Edge Function and lands a row here. Powers
-- four things:
--   1. Revenue attribution when a partner postback says "this user
--      booked, here's your commission" — we cross-reference click_id.
--   2. Product analytics: which recs convert, which deadlines work.
--   3. Eligibility evidence for direct partner applications (Stage 2
--      of the affiliate ladder requires us to bring traffic data).
--   4. Fraud signals (duplicate clicks, bot traffic).

CREATE TABLE IF NOT EXISTS public.affiliate_clickthroughs (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id      uuid REFERENCES public.trips(id) ON DELETE SET NULL,
  user_id      uuid,
  partner      text NOT NULL,         -- 'booking_com' | 'skyscanner' | 'google_flights' | 'expedia' | 'kayak'
  kind         text NOT NULL CHECK (kind IN ('hotel','flight','activity')),
  target_id    uuid,                  -- trip_recommendation.id or member_arrival_plan.id
  query        jsonb DEFAULT '{}'::jsonb,  -- the search params we sent
  click_id     text UNIQUE,           -- our own ID we pass to the partner; comes back on postback
  user_agent   text,
  ip_hash      text,                  -- hashed for fraud signals; never raw IP
  clicked_at   timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_affiliate_clickthroughs_trip
  ON public.affiliate_clickthroughs (trip_id, clicked_at DESC);

CREATE INDEX IF NOT EXISTS idx_affiliate_clickthroughs_partner_time
  ON public.affiliate_clickthroughs (partner, clicked_at DESC);

CREATE INDEX IF NOT EXISTS idx_affiliate_clickthroughs_click_id
  ON public.affiliate_clickthroughs (click_id);

ALTER TABLE public.affiliate_clickthroughs ENABLE ROW LEVEL SECURITY;

-- No client-side reads. This is a server-only analytics table —
-- writes happen via the affiliate_redirect Edge Function (service
-- role) and reads happen via SQL/dashboards. No policies = denied
-- for anon and authenticated roles.
