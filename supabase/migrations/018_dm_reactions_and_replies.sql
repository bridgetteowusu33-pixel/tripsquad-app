-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 018: DM replies + reactions
--
--  Brings direct_messages to parity with the trip chat:
--  - reply_to_id column for threading
--  - direct_message_reactions table for emoji reactions
--  Both tables added to the realtime publication so the UI sees
--  reactions + threads updating live.
-- ─────────────────────────────────────────────────────────────

-- 1. Thread replies on DMs
alter table public.direct_messages
  add column if not exists reply_to_id uuid
    references public.direct_messages(id) on delete set null;

create index if not exists idx_direct_messages_reply
  on public.direct_messages(reply_to_id)
  where reply_to_id is not null;

-- 2. Reactions table (one row per user+message+emoji)
create table if not exists public.direct_message_reactions (
  id          uuid default gen_random_uuid() primary key,
  message_id  uuid references public.direct_messages(id)
                on delete cascade not null,
  user_id     uuid references public.profiles(id)
                on delete cascade not null,
  emoji       text not null,
  created_at  timestamptz default now(),
  unique (message_id, user_id, emoji)
);

create index if not exists idx_dm_reactions_msg
  on public.direct_message_reactions(message_id);

alter table public.direct_message_reactions enable row level security;

-- Anyone party to the DM (sender OR recipient) can read reactions.
create policy "DM party can read reactions"
  on direct_message_reactions for select
  using (
    exists (
      select 1 from direct_messages dm
      where dm.id = direct_message_reactions.message_id
        and (dm.from_user = auth.uid() or dm.to_user = auth.uid())
    )
  );

-- Anyone party to the DM can add their own reactions.
create policy "DM party can add own reactions"
  on direct_message_reactions for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from direct_messages dm
      where dm.id = direct_message_reactions.message_id
        and (dm.from_user = auth.uid() or dm.to_user = auth.uid())
    )
  );

-- Users can remove their own reactions.
create policy "Users can remove own DM reactions"
  on direct_message_reactions for delete
  using (auth.uid() = user_id);

-- Realtime
alter publication supabase_realtime add table direct_message_reactions;
