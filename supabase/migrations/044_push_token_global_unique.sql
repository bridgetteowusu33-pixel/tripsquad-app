-- ─────────────────────────────────────────────────────────────
-- 044 — One device = one active account for push delivery
--
-- The current unique constraint is (user_id, token) which lets the
-- same FCM token belong to multiple users. When a single phone is
-- used to sign into several test accounts, each sign-in adds a new
-- row instead of reassigning ownership. Notifications then fan out
-- to all those accounts and the physical device receives N pushes
-- for what is logically one event.
--
-- Fix: the device token itself is unique. The most recent sign-in
-- owns the row; previous accounts stop delivering pushes to that
-- phone (which is what the user signed out for).
--
-- We keep user_id + platform as informational fields.
-- ─────────────────────────────────────────────────────────────

-- Collapse existing duplicates by token, keep the newest row.
with ranked as (
  select id,
         row_number() over (
           partition by token
           order by updated_at desc, created_at desc
         ) as rn
    from public.push_tokens
)
delete from public.push_tokens
 where id in (select id from ranked where rn > 1);

-- Drop the old (user_id, token) unique constraint if present.
alter table public.push_tokens
  drop constraint if exists push_tokens_user_id_token_key;

-- New: token is globally unique.
alter table public.push_tokens
  add constraint push_tokens_token_key unique (token);
