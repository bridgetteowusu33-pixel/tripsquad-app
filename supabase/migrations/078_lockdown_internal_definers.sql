-- Security hardening — Supabase advisor warnings 2026-04-29 (round 2)
--
-- Lint 0029 (authenticated_security_definer_function_executable) flags
-- every SECURITY DEFINER function that signed-in users can call. The
-- advisor is asking us to confirm intent — it doesn't know which of
-- our functions are legitimate user RPCs vs. internal triggers / cron
-- jobs that ended up callable via /rest/v1/rpc/* by accident.
--
-- Audit verdict:
--   - 18 functions are PURELY internal: trigger handlers (`fan_out_*`,
--     `log_*`, `notify_*`, `_*`-prefixed helpers, `increment_vote_count`,
--     `maybe_fire_lockin_complete`) and pg_cron tasks (`nudge_countdowns`,
--     `nudge_live_today`, `nudge_recap`, `nudge_stale_invites`,
--     `notify_upcoming_deadlines`). None are called via `.rpc(...)` by
--     the Flutter app or web join page; they execute from triggers and
--     cron under elevated context that does not need GRANTs.
--   - The remaining ~25 SECURITY DEFINER functions ARE legitimate user
--     RPCs (block_user, delete_account, register_push_token, etc.).
--     Those keep authenticated EXECUTE — the advisor will continue to
--     warn about them, which is expected for SECURITY DEFINER user APIs.
--
-- Revoking from authenticated does NOT break the trigger/cron paths —
-- those run as the table owner / cron superuser, both of which bypass
-- the GRANT system entirely.

DO $$
DECLARE
  fn text;
  fn_args text;
  internal_fns text[] := ARRAY[
    -- Trigger handlers (defined as triggers in migrations 001/002/008/
    -- 011/012/017/048/067; never RPC-called)
    '_bump_trips_completed',
    '_link_itinerary_place',
    '_reject_dm_if_blocked',
    'fan_out_trip_event',
    'log_chat_as_trip_event',
    'log_member_joined_as_trip_event',
    'log_status_as_trip_event',
    'log_vote_as_trip_event',
    'notify_dm_recipient',
    'notify_host_on_proposal',
    'notify_scout_reply',
    'maybe_fire_lockin_complete',
    'increment_vote_count',
    -- pg_cron jobs
    'notify_upcoming_deadlines',
    'nudge_countdowns',
    'nudge_live_today',
    'nudge_recap',
    'nudge_stale_invites'
  ];
BEGIN
  FOREACH fn IN ARRAY internal_fns LOOP
    -- One name may have multiple arities; revoke on every match.
    FOR fn_args IN
      SELECT pg_get_function_identity_arguments(p.oid)
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public' AND p.proname = fn
    LOOP
      EXECUTE format(
        'REVOKE EXECUTE ON FUNCTION public.%I(%s) FROM PUBLIC, authenticated, anon',
        fn, fn_args
      );
    END LOOP;
  END LOOP;
END $$;
