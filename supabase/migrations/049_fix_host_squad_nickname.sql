-- ─────────────────────────────────────────────────────────────
-- 049 — Replace placeholder host nicknames with real ones
--
-- Background: createTrip() auto-inserted the host into
-- squad_members with `nickname = 'You (Host)'` as a placeholder.
-- That string is rendered verbatim in the squad list, which means:
--   - Squadmates view the host as "You (Host) · host"
--     (looks like a duplicate "you")
--   - The host views their own row as "You (Host) (you) · host"
--     (rendering layer appends "(you)" + "· host" automatically)
--
-- Fix: backfill nickname (and emoji, while we're here) from
-- profiles for any existing host squad_members row that still
-- carries the placeholder. Row-by-row update keyed on user_id so
-- profiles supply the canonical name. Idempotent.
-- ─────────────────────────────────────────────────────────────

update public.squad_members sm
   set nickname = coalesce(nullif(p.nickname, ''), 'host'),
       emoji    = coalesce(sm.emoji, p.emoji)
  from public.profiles p
 where sm.user_id = p.id
   and sm.role = 'host'
   and (sm.nickname = 'You (Host)' or sm.nickname is null);
