-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 012: Scout's Guide (places directory)
--  Canonical places that itinerary items link to. Ratings roll
--  up per place so the directory scales across all trips.
-- ─────────────────────────────────────────────────────────────

-- ── Places ───────────────────────────────────────────────────
create table if not exists public.places (
  id               uuid default gen_random_uuid() primary key,
  category         text not null
                     check (category in ('activity','hotel','restaurant')),
  name             text not null,
  destination      text not null,
  country          text,
  flag             text,
  address          text,
  lat              double precision,
  lng              double precision,
  photo_url        text,
  google_place_id  text unique,
  aliases          text[] default '{}',
  created_at       timestamptz default now()
);

-- Normalized form for matching (no uniqueness constraint — handled at app layer)
create index if not exists idx_places_norm on public.places(
  category,
  (lower(trim(regexp_replace(destination, '\s+', ' ', 'g')))),
  (lower(trim(regexp_replace(name, '\s+', ' ', 'g'))))
);
create index if not exists idx_places_dest on public.places(destination);
create index if not exists idx_places_category on public.places(category);

alter table public.places enable row level security;

create policy "Anyone authenticated can read places"
  on places for select using (auth.uid() is not null);

create policy "Anyone authenticated can insert places"
  on places for insert with check (auth.uid() is not null);

create policy "Anyone authenticated can update places"
  on places for update using (auth.uid() is not null);

-- Deliberately no delete policy — places are shared data, don't let one
-- user nuke a restaurant everyone else rated.

-- ── Place link column on itinerary ───────────────────────────
alter table public.itinerary_items
  add column if not exists place_id uuid references public.places(id)
    on delete set null;
create index if not exists idx_itinerary_items_place
  on public.itinerary_items(place_id);

-- ── Normalization helpers ────────────────────────────────────
create or replace function _norm_text(s text) returns text
  language sql immutable as $$
    select lower(trim(regexp_replace(coalesce(s, ''), '\s+', ' ', 'g')))
$$;

-- Insert or find an existing matching place. Matches on (category,
-- destination, normalized name). Safe to call many times.
create or replace function upsert_place(
  _name text,
  _destination text,
  _category text,
  _country text default null,
  _flag text default null
) returns uuid
  language plpgsql security definer set search_path = public as $$
declare
  existing_id uuid;
  new_id uuid;
  n_name text := _norm_text(_name);
  n_dest text := _norm_text(_destination);
begin
  if n_name = '' or n_dest = '' then return null; end if;

  select id into existing_id
  from places
  where category = _category
    and _norm_text(destination) = n_dest
    and (_norm_text(name) = n_name or n_name = any(array(select _norm_text(a) from unnest(aliases) a)))
  limit 1;

  if existing_id is not null then return existing_id; end if;

  insert into places(category, name, destination, country, flag)
  values (_category, _name, _destination, _country, _flag)
  returning id into new_id;
  return new_id;
end $$;

-- Trigger: auto-link newly inserted/updated itinerary_items to a place
create or replace function _link_itinerary_place()
returns trigger language plpgsql security definer
set search_path = public as $$
declare
  dest text;
  country_name text;
  trip_flag text;
begin
  if new.place_id is not null then return new; end if;
  if new.title is null or new.title = '' then return new; end if;

  select selected_destination, selected_flag
    into dest, trip_flag
  from trips where id = new.trip_id;

  if dest is null then return new; end if;

  new.place_id := upsert_place(
    new.title, dest, coalesce(new.item_type, 'activity'), null, trip_flag
  );
  return new;
end $$;

drop trigger if exists trg_link_itinerary_place on public.itinerary_items;
create trigger trg_link_itinerary_place
  before insert or update of title, item_type on public.itinerary_items
  for each row execute function _link_itinerary_place();

-- Backfill existing itinerary_items
update public.itinerary_items ii
  set place_id = upsert_place(
    ii.title,
    t.selected_destination,
    coalesce(ii.item_type, 'activity'),
    null,
    t.selected_flag
  )
from public.trips t
where t.id = ii.trip_id
  and ii.place_id is null
  and ii.title is not null
  and t.selected_destination is not null;

-- ── Aggregated place stats view ──────────────────────────────
create or replace view public.place_stats as
  select
    p.id                                   as place_id,
    p.name,
    p.category,
    p.destination,
    p.country,
    p.flag,
    p.photo_url,
    count(distinct ii.trip_id)             as squads_count,
    count(ir.id)                           as rating_count,
    sum(case when ir.thumb =  1 then 1 else 0 end)::int as up_count,
    sum(case when ir.thumb = -1 then 1 else 0 end)::int as down_count,
    case when count(ir.id) = 0 then 0
         else round(
           avg(case when ir.thumb = 1 then 100 else 0 end)::numeric, 0)::int
    end as approval_pct,
    coalesce(max(ii.image_url), p.photo_url) as display_photo
  from places p
  left join itinerary_items ii on ii.place_id = p.id
                                 and ii.status = 'approved'
  left join itinerary_ratings ir on ir.item_id = ii.id
  group by p.id;

grant select on public.place_stats to authenticated;

-- ── Aggregated destination hub view ──────────────────────────
create or replace view public.destination_hub as
  select
    lower(trim(p.destination)) as destination_key,
    p.destination              as destination,
    p.country,
    p.flag,
    count(distinct p.id)       as place_count,
    count(distinct case when p.category = 'activity'   then p.id end) as activity_count,
    count(distinct case when p.category = 'hotel'      then p.id end) as hotel_count,
    count(distinct case when p.category = 'restaurant' then p.id end) as restaurant_count,
    -- Pull in destination_recaps aggregate
    (select round(avg(stars)::numeric, 1)
       from destination_recaps dr
      where lower(trim(dr.destination)) = lower(trim(p.destination))) as avg_stars,
    (select count(*)
       from destination_recaps dr
      where lower(trim(dr.destination)) = lower(trim(p.destination))) as recap_count
  from places p
  group by lower(trim(p.destination)), p.destination, p.country, p.flag;

grant select on public.destination_hub to authenticated;

-- ── Helper RPC: recent recaps for a destination ──────────────
create or replace function destination_recaps_feed(_destination text)
returns table (
  id uuid,
  user_id uuid,
  user_nickname text,
  user_emoji text,
  user_avatar_url text,
  stars smallint,
  would_return text,
  best_part text,
  created_at timestamptz
)
language sql security definer set search_path = public stable as $$
  select
    dr.id, dr.user_id,
    pr.nickname, pr.emoji, pr.avatar_url,
    dr.stars, dr.would_return, dr.best_part, dr.created_at
  from destination_recaps dr
  join profiles pr on pr.id = dr.user_id
  where _norm_text(dr.destination) = _norm_text(_destination)
  order by dr.created_at desc
  limit 30;
$$;

grant execute on function destination_recaps_feed(text) to authenticated;
