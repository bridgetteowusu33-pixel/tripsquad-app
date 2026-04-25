-- ─────────────────────────────────────────────────────────────
-- 047 — register_push_token RPC (push delivery bug fix)
--
-- Background
-- Migration 044 made push_tokens.token globally UNIQUE so a phone
-- can transfer ownership of its FCM token when a new account signs
-- in on the same device. The app performs this via an upsert with
-- ON CONFLICT (token) — but the existing RLS policy
-- "Users manage own push tokens" uses USING (auth.uid() = user_id),
-- which checks the EXISTING row on the UPDATE path of an upsert.
-- When the same token is currently owned by a different user, the
-- upsert's implicit UPDATE fails RLS with error 42501.
--
-- Visible symptom: the app silently fails to register its new FCM
-- token on every install after the first. send_push keeps pushing
-- to the stale row from the morning's install. Apple rotates the
-- device token on reinstall → APNs drops every push → user sees
-- nothing. The in-app inbox still works because notifications.*
-- has its own RLS scoped to auth.uid() = user_id on reads.
--
-- Fix
-- Route the upsert through a SECURITY DEFINER RPC that bypasses
-- push_tokens' RLS. The function clears stale rows for the caller
-- on the same platform, then upserts the current token,
-- transferring ownership if the row already exists under another
-- user. All mutation happens as the calling user and is scoped to
-- tokens belonging to that user (or to the specific token being
-- registered by auth.uid()).
-- ─────────────────────────────────────────────────────────────

create or replace function public.register_push_token(
  p_token text,
  p_platform text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'unauthenticated';
  end if;

  -- Clear any OTHER tokens this user had on this platform — iOS
  -- rotates the device token on reinstall so stale rows pile up
  -- and send_push would try both, burning an FCM call.
  delete from public.push_tokens
   where user_id = v_uid
     and platform = p_platform
     and token <> p_token;

  -- Upsert by token. When the row exists under a different user_id
  -- (previous account signed into the same device), transfer
  -- ownership by overwriting user_id + platform + updated_at.
  insert into public.push_tokens (user_id, token, platform, updated_at)
  values (v_uid, p_token, p_platform, now())
  on conflict (token) do update
    set user_id    = excluded.user_id,
        platform   = excluded.platform,
        updated_at = excluded.updated_at;
end;
$$;

grant execute on function public.register_push_token(text, text)
  to authenticated;
