-- Security advisor info 0008 — RLS enabled, no policy.
--
-- Three tables are intentionally service-role-only (no client access):
--
--   affiliate_clickthroughs — analytics log, written by the affiliate
--     redirect Edge Function and read via SQL/dashboards. Never client.
--   ai_prompts — Claude system prompts, read by Edge Functions. Client
--     read would leak our IP; client write would inject the LLM.
--   fund_contributions — legacy table from migration 001, never wired.
--
-- The previous setup (RLS on, zero policies) achieved the right outcome
-- — clients are denied because no policy matches — but Supabase's lint
-- can't distinguish "intentionally locked down" from "forgot to add
-- policies." Adding an explicit deny-all policy clears the info AND
-- documents the access model in the schema.
--
-- Service-role bypasses RLS, so Edge Functions and dashboards continue
-- to read/write unaffected.

CREATE POLICY "service-role only — no client access"
  ON public.affiliate_clickthroughs
  AS RESTRICTIVE
  FOR ALL
  USING (false)
  WITH CHECK (false);

CREATE POLICY "service-role only — no client access"
  ON public.ai_prompts
  AS RESTRICTIVE
  FOR ALL
  USING (false)
  WITH CHECK (false);

CREATE POLICY "service-role only — no client access"
  ON public.fund_contributions
  AS RESTRICTIVE
  FOR ALL
  USING (false)
  WITH CHECK (false);
