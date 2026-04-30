-- v1.2 — Phase 2.5 polish
-- Multi-device push: a user signed into iPhone AND iPad should
-- receive every push on both devices. The previous RPC (047) deleted
-- all tokens for the same (user_id, platform) before upserting the
-- new one — single-device-per-platform behavior. Most messaging
-- apps (iMessage, Slack, WhatsApp, Telegram) ping every signed-in
-- device; TripSquad is a coordination app where time-sensitive
-- moments (anchor flight booked, squad pick, deadline reminders)
-- should reach the user wherever they are.
--
-- Change: remove the platform-level DELETE. Replace with a
-- stale-token grooming step that removes only this user's tokens
-- not seen in 60 days (gives Apple's APNs token rotation enough
-- time — they typically rotate within hours-to-days, never months).
--
-- Cross-account device transfer (a different user signs in on the
-- same physical device) still works via the existing on-conflict
-- on `token`, which is globally UNIQUE.

CREATE OR REPLACE FUNCTION public.register_push_token(
  p_token text,
  p_platform text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  -- Stale-token grooming: drop this user's tokens that haven't been
  -- touched in 60 days, but only when the device that owns them is
  -- different from the token we're now registering. Conservative
  -- threshold so legitimately-used multi-device users keep all
  -- their tokens.
  DELETE FROM public.push_tokens
   WHERE user_id = v_uid
     AND token <> p_token
     AND updated_at < now() - interval '60 days';

  -- Upsert by token. When the row exists under a different user_id
  -- (previous account signed into the same device), transfer
  -- ownership by overwriting user_id + platform + updated_at.
  INSERT INTO public.push_tokens (user_id, token, platform, updated_at)
  VALUES (v_uid, p_token, p_platform, now())
  ON CONFLICT (token) DO UPDATE
    SET user_id    = EXCLUDED.user_id,
        platform   = EXCLUDED.platform,
        updated_at = EXCLUDED.updated_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.register_push_token(text, text)
  TO authenticated;
