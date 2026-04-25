-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 002: Tags, Trip Events, Notifications, DMs, Push
--  Foundation for "every user linked to a trip receives all updates"
-- ─────────────────────────────────────────────────────────────

-- ── PROFILES: tag + privacy + stats ──────────────────────────
alter table public.profiles add column if not exists tag text unique;
alter table public.profiles add column if not exists privacy_level text default 'private'
  check (privacy_level in ('private', 'friends', 'public'));
alter table public.profiles add column if not exists last_handle_change timestamptz;
alter table public.profiles add column if not exists trips_completed int default 0;
create index if not exists idx_profiles_tag on public.profiles(tag);

-- ── HANDLE HISTORY ───────────────────────────────────────────
create table if not exists public.handle_history (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.profiles(id) on delete cascade,
  old_handle  text not null,
  new_handle  text not null,
  changed_at  timestamptz default now()
);
alter table public.handle_history enable row level security;
create policy "Users can view own handle history"
  on handle_history for select using (auth.uid() = user_id);

-- ── SQUAD MEMBERS: add tag column ────────────────────────────
alter table public.squad_members add column if not exists tag text;
create index if not exists idx_squad_members_tag on public.squad_members(tag);

-- ── TRIP EVENTS (authoritative feed) ─────────────────────────
create table if not exists public.trip_events (
  id              uuid default gen_random_uuid() primary key,
  trip_id         uuid references public.trips(id) on delete cascade not null,
  kind            text not null
                    check (kind in (
                      'status_changed','vote_cast','chat_message','itinerary_ready',
                      'member_joined','reveal','options_generated','dm_sent'
                    )),
  actor_user_id   uuid references public.profiles(id) on delete set null,
  actor_tag       text,
  payload         jsonb,
  created_at      timestamptz default now()
);
create index if not exists idx_trip_events_trip on public.trip_events(trip_id, created_at desc);
alter table public.trip_events enable row level security;
create policy "Trip members can read events"
  on trip_events for select using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = trip_events.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );
-- Allow authenticated users + service role to log events
create policy "Authenticated can log events"
  on trip_events for insert with check (auth.uid() is not null or auth.role() = 'service_role');

-- ── NOTIFICATIONS (per-user inbox) ───────────────────────────
create table if not exists public.notifications (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.profiles(id) on delete cascade not null,
  trip_id     uuid references public.trips(id) on delete cascade,
  event_id    uuid references public.trip_events(id) on delete cascade,
  kind        text not null,
  title       text not null,
  body        text,
  read_at     timestamptz,
  created_at  timestamptz default now()
);
create index if not exists idx_notifications_user_unread on public.notifications(user_id, read_at);
create index if not exists idx_notifications_user_created on public.notifications(user_id, created_at desc);
alter table public.notifications enable row level security;
create policy "Users can read own notifications"
  on notifications for select using (auth.uid() = user_id);
create policy "Users can update own notifications"
  on notifications for update using (auth.uid() = user_id);

-- ── DIRECT MESSAGES ──────────────────────────────────────────
create table if not exists public.direct_messages (
  id          uuid default gen_random_uuid() primary key,
  from_user   uuid references public.profiles(id) on delete cascade not null,
  to_user     uuid references public.profiles(id) on delete cascade not null,
  content     text not null,
  read_at     timestamptz,
  created_at  timestamptz default now()
);
create index if not exists idx_dm_recipient on public.direct_messages(to_user, created_at desc);
create index if not exists idx_dm_pair on public.direct_messages(from_user, to_user, created_at desc);
alter table public.direct_messages enable row level security;
create policy "Users can read own DMs"
  on direct_messages for select using (auth.uid() = from_user or auth.uid() = to_user);
create policy "Users can send DMs"
  on direct_messages for insert with check (auth.uid() = from_user);
create policy "Recipients can mark read"
  on direct_messages for update using (auth.uid() = to_user);

-- ── PUSH TOKENS ──────────────────────────────────────────────
create table if not exists public.push_tokens (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.profiles(id) on delete cascade not null,
  platform    text not null check (platform in ('ios','android')),
  token       text not null,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now(),
  unique (user_id, token)
);
alter table public.push_tokens enable row level security;
create policy "Users manage own push tokens"
  on push_tokens for all using (auth.uid() = user_id);

-- ── SCOUT MESSAGES (1:1 user ↔ Scout persistent history) ─────
create table if not exists public.scout_messages (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.profiles(id) on delete cascade not null,
  role        text not null check (role in ('user','assistant')),
  content     text not null,
  created_at  timestamptz default now()
);
create index if not exists idx_scout_messages_user on public.scout_messages(user_id, created_at desc);
alter table public.scout_messages enable row level security;
create policy "Users manage own Scout history"
  on scout_messages for all using (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────
-- FAN-OUT TRIGGER
-- On trip_event insert, write a notification row per squad member
-- (except the actor themselves). This is the single source of
-- truth that drives ✉️ badge, activity ticker, and push pipeline.
-- ─────────────────────────────────────────────────────────────
create or replace function fan_out_trip_event()
returns trigger language plpgsql security definer as $$
begin
  insert into public.notifications (user_id, trip_id, event_id, kind, title, body)
  select sm.user_id,
         new.trip_id,
         new.id,
         new.kind,
         coalesce(new.payload->>'title', new.kind),
         new.payload->>'body'
  from public.squad_members sm
  where sm.trip_id = new.trip_id
    and sm.user_id is not null
    and sm.user_id <> coalesce(new.actor_user_id, '00000000-0000-0000-0000-000000000000'::uuid);

  -- Also notify host if they aren't in squad_members table as a member
  insert into public.notifications (user_id, trip_id, event_id, kind, title, body)
  select t.host_id,
         new.trip_id,
         new.id,
         new.kind,
         coalesce(new.payload->>'title', new.kind),
         new.payload->>'body'
  from public.trips t
  where t.id = new.trip_id
    and t.host_id is not null
    and t.host_id <> coalesce(new.actor_user_id, '00000000-0000-0000-0000-000000000000'::uuid)
    and not exists (
      select 1 from public.squad_members sm2
      where sm2.trip_id = new.trip_id and sm2.user_id = t.host_id
    );

  return new;
end;
$$;

drop trigger if exists trg_fan_out_trip_event on public.trip_events;
create trigger trg_fan_out_trip_event
  after insert on public.trip_events
  for each row execute function fan_out_trip_event();

-- ─────────────────────────────────────────────────────────────
-- CHAT → TRIP EVENT bridge
-- Any chat message auto-logs a chat_message trip_event so the
-- fan-out trigger delivers notifications to every squad member.
-- ─────────────────────────────────────────────────────────────
create or replace function log_chat_as_trip_event()
returns trigger language plpgsql security definer as $$
begin
  insert into public.trip_events (trip_id, kind, actor_user_id, payload)
  values (
    new.trip_id,
    'chat_message',
    new.user_id,
    jsonb_build_object(
      'title', coalesce(new.nickname, 'someone') || ' sent a message',
      'body',  left(new.content, 140),
      'chat_message_id', new.id,
      'is_ai', new.is_ai
    )
  );
  return new;
end;
$$;

drop trigger if exists trg_log_chat_as_trip_event on public.chat_messages;
create trigger trg_log_chat_as_trip_event
  after insert on public.chat_messages
  for each row execute function log_chat_as_trip_event();

-- ─────────────────────────────────────────────────────────────
-- VOTE → TRIP EVENT bridge
-- Extends existing on_vote_insert: log each vote as a trip_event
-- ─────────────────────────────────────────────────────────────
create or replace function log_vote_as_trip_event()
returns trigger language plpgsql security definer as $$
declare
  v_tag text;
begin
  select tag into v_tag from public.profiles where id = new.user_id;
  insert into public.trip_events (trip_id, kind, actor_user_id, actor_tag, payload)
  values (
    new.trip_id,
    'vote_cast',
    new.user_id,
    v_tag,
    jsonb_build_object(
      'title', coalesce('@' || v_tag, 'someone') || ' voted',
      'option_id', new.option_id
    )
  );
  return new;
end;
$$;

drop trigger if exists trg_log_vote_as_trip_event on public.votes;
create trigger trg_log_vote_as_trip_event
  after insert on public.votes
  for each row execute function log_vote_as_trip_event();

-- ─────────────────────────────────────────────────────────────
-- TRIP STATUS → TRIP EVENT bridge
-- Any change to trips.status emits a status_changed event.
-- ─────────────────────────────────────────────────────────────
create or replace function log_status_as_trip_event()
returns trigger language plpgsql security definer as $$
begin
  if new.status is distinct from old.status then
    insert into public.trip_events (trip_id, kind, actor_user_id, payload)
    values (
      new.id,
      case
        when new.status = 'revealed' then 'reveal'
        when new.status = 'planning' then 'itinerary_ready'
        when new.status = 'voting'   then 'options_generated'
        else 'status_changed'
      end,
      null,
      jsonb_build_object(
        'title', 'trip is now ' || new.status,
        'from',  old.status,
        'to',    new.status,
        'trip_name', new.name
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_log_status_as_trip_event on public.trips;
create trigger trg_log_status_as_trip_event
  after update on public.trips
  for each row execute function log_status_as_trip_event();

-- ─────────────────────────────────────────────────────────────
-- SQUAD MEMBER JOINED → TRIP EVENT bridge
-- ─────────────────────────────────────────────────────────────
create or replace function log_member_joined_as_trip_event()
returns trigger language plpgsql security definer as $$
begin
  insert into public.trip_events (trip_id, kind, actor_user_id, actor_tag, payload)
  values (
    new.trip_id,
    'member_joined',
    new.user_id,
    new.tag,
    jsonb_build_object(
      'title', coalesce(new.nickname, 'someone') || ' joined the squad',
      'nickname', new.nickname,
      'emoji', new.emoji
    )
  );
  return new;
end;
$$;

drop trigger if exists trg_log_member_joined on public.squad_members;
create trigger trg_log_member_joined
  after insert on public.squad_members
  for each row execute function log_member_joined_as_trip_event();

-- ─────────────────────────────────────────────────────────────
-- DM → NOTIFICATION (DMs don't go through trip_events)
-- Directly insert a notification for the recipient.
-- ─────────────────────────────────────────────────────────────
create or replace function notify_dm_recipient()
returns trigger language plpgsql security definer as $$
declare
  v_from_tag text;
begin
  select tag into v_from_tag from public.profiles where id = new.from_user;
  insert into public.notifications (user_id, kind, title, body)
  values (
    new.to_user,
    'dm_received',
    coalesce('@' || v_from_tag, 'someone') || ' sent you a message',
    left(new.content, 140)
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_dm_recipient on public.direct_messages;
create trigger trg_notify_dm_recipient
  after insert on public.direct_messages
  for each row execute function notify_dm_recipient();

-- ── REALTIME ─────────────────────────────────────────────────
alter publication supabase_realtime add table trip_events;
alter publication supabase_realtime add table notifications;
alter publication supabase_realtime add table direct_messages;
alter publication supabase_realtime add table scout_messages;

-- ── UPDATED_AT for push_tokens ───────────────────────────────
create trigger push_tokens_updated_at before update on push_tokens
  for each row execute function update_updated_at();
