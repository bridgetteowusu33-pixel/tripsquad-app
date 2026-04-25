-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 010: Profile photo avatars
-- ─────────────────────────────────────────────────────────────

alter table public.profiles
  add column if not exists avatar_url text;

-- ── Storage bucket ───────────────────────────────────────────
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152,
        array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ── Storage RLS ──────────────────────────────────────────────
drop policy if exists "Avatars are publicly readable" on storage.objects;
create policy "Avatars are publicly readable"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "Users can upload own avatar" on storage.objects;
create policy "Users can upload own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update own avatar" on storage.objects;
create policy "Users can update own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete own avatar" on storage.objects;
create policy "Users can delete own avatar"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- ── Update RPCs to return avatar_url ─────────────────────────
drop function if exists get_public_profile(uuid);
drop function if exists get_public_profiles(uuid[]);
drop function if exists search_profiles(text);

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
  visible          boolean
)
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  viewer uuid := auth.uid();
  p profiles%rowtype;
  shares_trip boolean := false;
begin
  if viewer is null then return; end if;
  select * into p from profiles where profiles.id = _user_id;
  if not found then return; end if;

  if viewer = p.id then
    return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
      p.avatar_url, p.travel_style, p.home_city, p.home_airport, p.passports,
      p.trips_completed, p.created_at, true;
    return;
  end if;

  if p.privacy_level = 'public' then
    return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
      p.avatar_url, p.travel_style, p.home_city, p.home_airport, p.passports,
      p.trips_completed, p.created_at, true;
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
        p.trips_completed, p.created_at, true;
      return;
    end if;
  end if;

  return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
    p.avatar_url, null::text, null::text, null::text, null::text[], null::int,
    null::timestamptz, false;
end $$;

create or replace function get_public_profiles(_user_ids uuid[])
returns table (
  id             uuid,
  nickname       text,
  emoji          text,
  tag            text,
  privacy_level  text,
  avatar_url     text
)
language sql
security definer
set search_path = public
stable
as $$
  select p.id, p.nickname, p.emoji, p.tag, p.privacy_level, p.avatar_url
  from profiles p
  where auth.uid() is not null
    and p.id = any(_user_ids);
$$;

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
language sql
security definer
set search_path = public
stable
as $$
  with norm as (
    select coalesce(nullif(regexp_replace(lower(coalesce(q, '')), '^@', ''), ''), '') as term
  )
  select p.id, p.nickname, p.emoji, p.tag, p.avatar_url, p.travel_style, p.privacy_level
  from profiles p, norm
  where auth.uid() is not null
    and length(norm.term) >= 2
    and (p.tag ilike '%' || norm.term || '%' or p.nickname ilike '%' || norm.term || '%')
  order by
    case when p.tag = norm.term then 0
         when p.tag ilike norm.term || '%' then 1
         else 2 end,
    p.trips_completed desc nulls last,
    p.created_at desc
  limit 12;
$$;

grant execute on function get_public_profile(uuid) to authenticated;
grant execute on function get_public_profiles(uuid[]) to authenticated;
grant execute on function search_profiles(text) to authenticated;
