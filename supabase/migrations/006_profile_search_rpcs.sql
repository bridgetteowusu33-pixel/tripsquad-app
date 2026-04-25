-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 006: Profile search + public lookup RPCs
--
--  The `profiles` RLS policy restricts SELECT to `auth.uid() = id`.
--  That makes universal search impossible. These SECURITY DEFINER
--  RPCs bypass RLS but only return a safe subset of columns and
--  respect `privacy_level` for the full-detail view.
-- ─────────────────────────────────────────────────────────────

-- ── Tag / name search ────────────────────────────────────────
create or replace function search_profiles(q text)
returns table (
  id             uuid,
  nickname       text,
  emoji          text,
  tag            text,
  travel_style   text,
  privacy_level  text
)
language sql
security definer
set search_path = public
stable
as $$
  with norm as (
    select
      coalesce(nullif(regexp_replace(lower(coalesce(q, '')), '^@', ''), ''), '') as term
  )
  select p.id, p.nickname, p.emoji, p.tag, p.travel_style, p.privacy_level
  from profiles p, norm
  where auth.uid() is not null
    and length(norm.term) >= 2
    and (
      p.tag      ilike '%' || norm.term || '%'
      or p.nickname ilike '%' || norm.term || '%'
    )
  order by
    -- exact tag match first, then prefix, then anything else
    case when p.tag = norm.term then 0
         when p.tag ilike norm.term || '%' then 1
         else 2
    end,
    p.trips_completed desc nulls last,
    p.created_at desc
  limit 12;
$$;

grant execute on function search_profiles(text) to authenticated;

-- ── Public profile lookup (privacy-aware) ────────────────────
-- Returns a row with either full details (public / friend-visible)
-- or a minimal card (private / friends-only-but-not-shared).
create or replace function get_public_profile(_user_id uuid)
returns table (
  id               uuid,
  nickname         text,
  emoji            text,
  tag              text,
  privacy_level    text,
  travel_style     text,
  home_city        text,
  home_airport     text,
  passports        text[],
  trips_completed  int,
  created_at       timestamptz,
  visible          boolean  -- true when full details are returned
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
  if viewer is null then
    return;
  end if;
  select * into p from profiles where profiles.id = _user_id;
  if not found then
    return;
  end if;

  -- Self
  if viewer = p.id then
    return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
      p.travel_style, p.home_city, p.home_airport, p.passports,
      p.trips_completed, p.created_at, true;
    return;
  end if;

  -- Public → full
  if p.privacy_level = 'public' then
    return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
      p.travel_style, p.home_city, p.home_airport, p.passports,
      p.trips_completed, p.created_at, true;
    return;
  end if;

  -- Friends → full only if viewer and target share a trip (squad or host)
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
    )
    into shares_trip;

    if shares_trip then
      return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
        p.travel_style, p.home_city, p.home_airport, p.passports,
        p.trips_completed, p.created_at, true;
      return;
    end if;
  end if;

  -- Private / friends-without-shared-trip → minimal
  return query select p.id, p.nickname, p.emoji, p.tag, p.privacy_level,
    null::text, null::text, null::text, null::text[], null::int,
    null::timestamptz, false;
end;
$$;

grant execute on function get_public_profile(uuid) to authenticated;
