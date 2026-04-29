-- v1.2 — Booking layer hotfix
-- target_id was declared as uuid but the redirect endpoint passes
-- "hotel:0" / "hotel:1" style hints from generate_recommendations
-- (the rec UUID isn't known at URL-build time since the rec hasn't
-- been INSERTed yet). Postgres rejects those as invalid uuid input
-- and the INSERT fails silently in fire-and-forget mode.
--
-- Make it text so the column accepts whatever target hint we want —
-- rank, kind:rank, full UUID, or the place_id from a partner. The
-- field is for analytics, not foreign-key joins.

ALTER TABLE public.affiliate_clickthroughs
  ALTER COLUMN target_id TYPE text USING target_id::text;
