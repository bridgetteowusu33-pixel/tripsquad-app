-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 004: Chat upgrades
--  Reactions, reply threads, read receipts, mentions, pinning,
--  image attachments, link previews
-- ─────────────────────────────────────────────────────────────

-- ── Reactions ────────────────────────────────────────────────
create table if not exists public.chat_reactions (
  id          uuid default gen_random_uuid() primary key,
  message_id  uuid references public.chat_messages(id) on delete cascade not null,
  user_id     uuid references public.profiles(id) on delete cascade not null,
  emoji       text not null,
  created_at  timestamptz default now(),
  unique (message_id, user_id, emoji)
);
create index if not exists idx_chat_reactions_msg
  on public.chat_reactions(message_id);
alter table public.chat_reactions enable row level security;

create policy "Trip members can read reactions"
  on chat_reactions for select using (
    exists (
      select 1 from chat_messages cm
      join trips t on t.id = cm.trip_id
      left join squad_members sm on sm.trip_id = t.id
      where cm.id = chat_reactions.message_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );
create policy "Trip members can react"
  on chat_reactions for insert with check (auth.uid() = user_id);
create policy "Users can remove own reactions"
  on chat_reactions for delete using (auth.uid() = user_id);

-- ── Thread replies, read receipts, pinning, attachments ──────
alter table public.chat_messages
  add column if not exists reply_to_id uuid references public.chat_messages(id) on delete set null,
  add column if not exists seen_by jsonb default '[]',
  add column if not exists pinned_at timestamptz,
  add column if not exists image_url text,
  add column if not exists link_preview jsonb,
  add column if not exists mentions jsonb default '[]';

create index if not exists idx_chat_messages_pinned
  on public.chat_messages(trip_id, pinned_at desc)
  where pinned_at is not null;

-- ── RPC to mark a message seen atomically ────────────────────
create or replace function mark_chat_seen(
  _message_id uuid,
  _user_id uuid
) returns void language plpgsql security definer as $$
declare
  current jsonb;
  user_text text := _user_id::text;
begin
  select seen_by into current from chat_messages where id = _message_id;
  if current is null then current := '[]'::jsonb; end if;
  if current @> to_jsonb(array[user_text]) then return; end if;
  update chat_messages
     set seen_by = current || to_jsonb(array[user_text])
   where id = _message_id;
end;
$$;

-- ── RPC to detect and notify @mentions ───────────────────────
-- Called from the client right after inserting a message.
create or replace function notify_mentions(
  _message_id uuid
) returns void language plpgsql security definer as $$
declare
  msg record;
  mentioned_tag text;
  mentioned_user record;
begin
  select * into msg from chat_messages where id = _message_id;
  if msg is null then return; end if;

  for mentioned_tag in
    select distinct (regexp_matches(msg.content, '@([a-z0-9_]{2,30})', 'g'))[1]
  loop
    for mentioned_user in
      select id, tag from profiles where tag = lower(mentioned_tag) and id <> msg.user_id
    loop
      insert into notifications (user_id, trip_id, event_id, kind, title, body)
      values (
        mentioned_user.id,
        msg.trip_id,
        null,
        'mention',
        coalesce(msg.nickname, 'someone') || ' mentioned you ✦',
        left(msg.content, 140)
      );
    end loop;
  end loop;
end;
$$;

-- Realtime
alter publication supabase_realtime add table chat_reactions;
