-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 017: User blocks
--  Soft block — prevents DMs + hides from search/profile in both
--  directions. Doesn't kick anyone out of shared trips.
-- ─────────────────────────────────────────────────────────────

create table if not exists public.user_blocks (
  id          uuid default gen_random_uuid() primary key,
  blocker_id  uuid references public.profiles(id) on delete cascade not null,
  blocked_id  uuid references public.profiles(id) on delete cascade not null,
  created_at  timestamptz default now(),
  unique (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index if not exists idx_user_blocks_blocker
  on public.user_blocks(blocker_id);
create index if not exists idx_user_blocks_blocked
  on public.user_blocks(blocked_id);

alter table public.user_blocks enable row level security;

create policy "Users can see blocks where they're involved"
  on user_blocks for select
  using (auth.uid() = blocker_id or auth.uid() = blocked_id);

create policy "Users can block as themselves"
  on user_blocks for insert
  with check (auth.uid() = blocker_id);

create policy "Users can unblock their own blocks"
  on user_blocks for delete
  using (auth.uid() = blocker_id);

-- ─────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────
create or replace function is_blocked_between(_a uuid, _b uuid)
returns boolean language sql stable security definer
set search_path = public as $$
  select exists (
    select 1 from user_blocks
    where (blocker_id = _a and blocked_id = _b)
       or (blocker_id = _b and blocked_id = _a)
  );
$$;
grant execute on function is_blocked_between(uuid, uuid) to authenticated;

create or replace function block_user(_target uuid)
returns void language plpgsql security definer
set search_path = public as $$
declare
  me uuid := auth.uid();
begin
  if me is null then raise exception 'not signed in'; end if;
  if me = _target then raise exception 'cannot block yourself'; end if;
  insert into user_blocks(blocker_id, blocked_id)
  values (me, _target)
  on conflict do nothing;
end $$;
grant execute on function block_user(uuid) to authenticated;

create or replace function unblock_user(_target uuid)
returns void language plpgsql security definer
set search_path = public as $$
declare
  me uuid := auth.uid();
begin
  if me is null then raise exception 'not signed in'; end if;
  delete from user_blocks where blocker_id = me and blocked_id = _target;
end $$;
grant execute on function unblock_user(uuid) to authenticated;

-- List of users I've blocked (with their profile info)
create or replace function my_blocks()
returns table (
  id              uuid,
  user_id         uuid,
  nickname        text,
  emoji           text,
  tag             text,
  avatar_url      text,
  blocked_at      timestamptz
)
language sql security definer stable
set search_path = public as $$
  select
    ub.id,
    ub.blocked_id as user_id,
    p.nickname,
    p.emoji,
    p.tag,
    p.avatar_url,
    ub.created_at as blocked_at
  from user_blocks ub
  join profiles p on p.id = ub.blocked_id
  where ub.blocker_id = auth.uid()
  order by ub.created_at desc;
$$;
grant execute on function my_blocks() to authenticated;

-- ─────────────────────────────────────────────────────────────
-- Update search_profiles + get_public_profile to hide blocks
-- ─────────────────────────────────────────────────────────────
drop function if exists search_profiles(text);
create or replace function search_profiles(q text)
returns table (
  id             uuid,
  nickname       text,
  emoji          text,
  tag            text,
  avatar_url     text,
  travel_style   text,
  privacy_level  text
)
language sql security definer stable set search_path = public
as $$
  with norm as (
    select coalesce(
      nullif(regexp_replace(lower(coalesce(q, '')), '^@', ''), ''), ''
    ) as term
  )
  select p.id, p.nickname, p.emoji, p.tag, p.avatar_url,
         p.travel_style, p.privacy_level
  from profiles p, norm
  where auth.uid() is not null
    and length(norm.term) >= 2
    and (p.tag ilike '%' || norm.term || '%'
         or p.nickname ilike '%' || norm.term || '%')
    and not exists (
      select 1 from user_blocks
      where (blocker_id = auth.uid() and blocked_id = p.id)
         or (blocker_id = p.id and blocked_id = auth.uid())
    )
  order by
    case when p.tag = norm.term then 0
         when p.tag ilike norm.term || '%' then 1
         else 2 end,
    p.trips_completed desc nulls last,
    p.created_at desc
  limit 12;
$$;
grant execute on function search_profiles(text) to authenticated;

drop function if exists get_public_profile(uuid);
create or replace function get_public_profile(_user_id uuid)
returns table (
  id               uuid,
  nickname         text,
  emoji            text,
  tag              text,
  privacy_level    text,
  avatar_url       text,
  travel_style     text,
  home_city        text,
  home_airport     text,
  passports        text[],
  trips_completed  int,
  created_at       timestamptz,
  visible          boolean,
  blocked          boolean
)
language plpgsql security definer set search_path = public stable
as $$
declare
  viewer uuid := auth.uid();
  p profiles%rowtype;
  shares_trip boolean := false;
  block_exists boolean := false;
begin
  if viewer is null then return; end if;
  select * into p from profiles where profiles.id = _user_id;
  if not found then return; end if;

  select exists (
    select 1 from user_blocks
    where (blocker_id = viewer and blocked_id = p.id)
       or (blocker_id = p.id and blocked_id = viewer)
  ) into block_exists;

  if block_exists then
    -- Return a minimal "blocked" card so UI can render a hint
    return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
      p.avatar_url, null::text, null::text, null::text, null::text[], null::int,
      null::timestamptz, false, true;
    return;
  end if;

  if viewer = p.id then
    return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
      p.avatar_url, p.travel_style, p.home_city, p.home_airport, p.passports,
      p.trips_completed, p.created_at, true, false;
    return;
  end if;

  if p.privacy_level = 'public' then
    return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
      p.avatar_url, p.travel_style, p.home_city, p.home_airport, p.passports,
      p.trips_completed, p.created_at, true, false;
    return;
  end if;

  if p.privacy_level = 'friends' then
    select exists (
      select 1
      from squad_members sm_them
      join squad_members sm_me on sm_me.trip_id = sm_them.trip_id
      where sm_them.user_id = p.id and sm_me.user_id = viewer
    ) or exists (
      select 1 from trips t
      join squad_members sm on sm.trip_id = t.id
      where ((t.host_id = viewer and sm.user_id = p.id)
          or (t.host_id = p.id and sm.user_id = viewer))
    ) into shares_trip;

    if shares_trip then
      return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
        p.avatar_url, p.travel_style, p.home_city, p.home_airport, p.passports,
        p.trips_completed, p.created_at, true, false;
      return;
    end if;
  end if;

  return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
    p.avatar_url, null::text, null::text, null::text, null::text[], null::int,
    null::timestamptz, false, false;
end $$;
grant execute on function get_public_profile(uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────
-- Block DM inserts between blocked pairs
-- ─────────────────────────────────────────────────────────────
create or replace function _reject_dm_if_blocked()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  if exists (
    select 1 from user_blocks
    where (blocker_id = new.from_user and blocked_id = new.to_user)
       or (blocker_id = new.to_user and blocked_id = new.from_user)
  ) then
    raise exception 'cannot send — one of you has blocked the other';
  end if;
  return new;
end $$;

drop trigger if exists trg_reject_dm_if_blocked on public.direct_messages;
create trigger trg_reject_dm_if_blocked
  before insert on public.direct_messages
  for each row execute function _reject_dm_if_blocked();
