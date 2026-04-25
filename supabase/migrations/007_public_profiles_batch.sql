-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 007: Batch public-profile lookup
--  The `profiles` SELECT policy restricts users to their own row.
--  This RPC returns a minimal public subset for many ids at once,
--  used by DM inbox, DM thread header, chat @mentions, etc.
-- ─────────────────────────────────────────────────────────────

create or replace function get_public_profiles(_user_ids uuid[])
returns table (
  id             uuid,
  nickname       text,
  emoji          text,
  tag            text,
  privacy_level  text
)
language sql
security definer
set search_path = public
stable
as $$
  select p.id, p.nickname, p.emoji, p.tag, p.privacy_level
  from profiles p
  where auth.uid() is not null
    and p.id = any(_user_ids);
$$;

grant execute on function get_public_profiles(uuid[]) to authenticated;
