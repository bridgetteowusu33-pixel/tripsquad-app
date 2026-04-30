-- Security hardening — flagged by Supabase advisor 2026-04-29
-- Two tables in the original schema were created without RLS:
--
--  - ai_prompts: holds the Claude system prompts that drive every
--    Edge Function (scout_chat, generate_trip_options, etc.). Read
--    only by service-role Edge Functions. Without RLS, anyone with
--    the project URL + anon key could read our prompts (IP leak)
--    OR modify them to inject malicious instructions into the LLM
--    OR set active=false to brick the app.
--
--  - fund_contributions: legacy table from migration 001 for a
--    squad-fund feature that was never wired to any client or
--    Edge Function code. Locking it now; we can layer real
--    policies on top when/if the feature ships.
--
-- Both tables are server-only / unused by clients, so enabling RLS
-- with NO policies is the right move — service-role bypasses RLS,
-- so Edge Functions keep working unchanged.

ALTER TABLE public.ai_prompts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fund_contributions  ENABLE ROW LEVEL SECURITY;
