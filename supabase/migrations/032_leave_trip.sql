-- ─────────────────────────────────────────────────────────────
-- 032 — Let non-hosts leave a trip
--
-- The original RLS on squad_members only allows the trip host to
-- delete rows. Non-hosts couldn't remove themselves, so the in-app
-- "leave trip" action failed silently. Add two policies:
--   1. Users can delete their own squad_members row (leave trip).
--   2. Users can delete their own votes for a trip (clean up FK
--      references when leaving).
-- Host-only "kick member" behaviour is preserved by the existing
-- "Host can manage squad" policy; the new policy only broadens
-- DELETE (and votes clean-up) to self-actions.
-- ─────────────────────────────────────────────────────────────

create policy "Users can leave trip"
  on public.squad_members for delete
  using (user_id = auth.uid());

create policy "Users can delete own votes"
  on public.votes for delete
  using (user_id = auth.uid());
