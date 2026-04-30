-- Security hardening — Supabase advisor warnings 2026-04-29
--
-- Bulk fix for two warning classes that hit ~110 of the 129 warnings:
--
--   1. function_search_path_mutable — every function in `public` that
--      doesn't have search_path pinned can be hijacked if an attacker
--      ever gets write access to the search_path of the calling
--      session (e.g. via SECURITY DEFINER chaining). Pin all of them
--      to `public, pg_temp` so resolution is deterministic.
--
--   2. anon_security_definer_function_executable — many of our
--      SECURITY DEFINER RPCs were granted EXECUTE to PUBLIC by
--      default, which means anon (unauthenticated) callers can hit
--      `/rest/v1/rpc/<fn>`. None of our user-action RPCs (block_user,
--      change_trip_destination, consume_reserved_pass, etc.) should
--      be callable without an authenticated session. Revoke from
--      PUBLIC + anon, keep authenticated.
--
-- Both fixes are non-functional: signed-in users keep working, Edge
-- Functions (service-role) keep working, and only the unauthenticated
-- attack surface shrinks.

-- ── 1. Pin search_path on every function in public ─────────────
DO $$
DECLARE
  fn record;
BEGIN
  FOR fn IN
    SELECT n.nspname AS schema_name,
           p.proname AS fn_name,
           pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'  -- regular functions, not aggregates/windows
      -- Skip if search_path is already configured
      AND NOT EXISTS (
        SELECT 1 FROM unnest(coalesce(p.proconfig, '{}')) cfg
        WHERE cfg LIKE 'search_path=%'
      )
  LOOP
    EXECUTE format(
      'ALTER FUNCTION %I.%I(%s) SET search_path = public, pg_temp',
      fn.schema_name, fn.fn_name, fn.args
    );
  END LOOP;
END $$;

-- ── 2. Revoke anon EXECUTE on SECURITY DEFINER functions ───────
-- Authenticated callers keep access; anon does not. Service-role
-- bypasses GRANTs anyway so Edge Functions are unaffected.
DO $$
DECLARE
  fn record;
BEGIN
  FOR fn IN
    SELECT n.nspname AS schema_name,
           p.proname AS fn_name,
           pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prosecdef = true   -- SECURITY DEFINER only
      AND p.prokind = 'f'
  LOOP
    EXECUTE format(
      'REVOKE EXECUTE ON FUNCTION %I.%I(%s) FROM PUBLIC, anon',
      fn.schema_name, fn.fn_name, fn.args
    );
    EXECUTE format(
      'GRANT EXECUTE ON FUNCTION %I.%I(%s) TO authenticated',
      fn.schema_name, fn.fn_name, fn.args
    );
  END LOOP;
END $$;

-- ── 3. Avatars bucket: drop the broad listing policy ──────────
-- Verified: the app reads avatars exclusively via getPublicUrl(), which
-- generates `/object/public/avatars/<path>` URLs. The public-download
-- endpoint serves files directly from the bucket's public flag and
-- BYPASSES RLS entirely. The previous SELECT policy
-- (`USING (bucket_id = 'avatars')`) only mattered for the authenticated
-- download + listing endpoints — neither of which the app uses. Dropping
-- the policy:
--   - direct image URLs continue to work (public bucket flag does it)
--   - listing API stops returning data (the actual warning's concern,
--     since chat photos / voice memos / DM attachments share the bucket)
--   - service-role still has full access (Edge Functions unaffected).
DROP POLICY IF EXISTS "Avatars are publicly readable" ON storage.objects;
