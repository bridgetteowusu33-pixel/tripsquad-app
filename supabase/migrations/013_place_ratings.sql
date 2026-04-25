-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 013: Place-level ratings
--  Direct 👍/👎 on a Place (not tied to a specific trip item).
--  Roll up into place_stats alongside itinerary-item ratings.
-- ─────────────────────────────────────────────────────────────

create table if not exists public.place_ratings (
  id          uuid default gen_random_uuid() primary key,
  place_id    uuid references public.places(id) on delete cascade not null,
  user_id     uuid references public.profiles(id) on delete cascade not null,
  thumb       smallint not null check (thumb in (-1, 1)),
  note        text,
  created_at  timestamptz default now(),
  unique (place_id, user_id)
);
create index if not exists idx_place_ratings_place
  on public.place_ratings(place_id);
alter table public.place_ratings enable row level security;

create policy "Anyone authenticated can read place ratings"
  on place_ratings for select using (auth.uid() is not null);

create policy "Users can rate places as themselves"
  on place_ratings for insert with check (auth.uid() = user_id);

create policy "Users can update own place rating"
  on place_ratings for update using (auth.uid() = user_id);

create policy "Users can remove own place rating"
  on place_ratings for delete using (auth.uid() = user_id);

-- ── Rebuild place_stats view to union both rating sources ────
-- Drop in reverse-dep order
drop view if exists public.place_stats;

create or replace view public.place_stats as
with combined_ratings as (
  -- Ratings tied to specific itinerary items
  select
    ii.place_id,
    ir.user_id,
    ir.thumb,
    ii.trip_id
  from itinerary_ratings ir
  join itinerary_items ii on ii.id = ir.item_id
  where ii.place_id is not null
    and ii.status = 'approved'
  union all
  -- Direct place ratings
  select
    pr.place_id,
    pr.user_id,
    pr.thumb,
    null::uuid as trip_id
  from place_ratings pr
),
-- Collapse duplicates: if a user rated a place both via itinerary AND
-- directly, keep the most recent (here we just take distinct user+place).
deduped as (
  select distinct on (place_id, user_id)
    place_id, user_id, thumb, trip_id
  from combined_ratings
)
select
  p.id                                   as place_id,
  p.name,
  p.category,
  p.destination,
  p.country,
  p.flag,
  p.photo_url,
  count(distinct d.trip_id) filter (where d.trip_id is not null) as squads_count,
  count(d.*)                                                      as rating_count,
  sum(case when d.thumb =  1 then 1 else 0 end)::int              as up_count,
  sum(case when d.thumb = -1 then 1 else 0 end)::int              as down_count,
  case when count(d.*) = 0 then 0
       else round(
         avg(case when d.thumb = 1 then 100 else 0 end)::numeric, 0)::int
  end as approval_pct,
  coalesce(
    (select max(image_url) from itinerary_items ii2
     where ii2.place_id = p.id and ii2.image_url is not null),
    p.photo_url
  ) as display_photo
from places p
left join deduped d on d.place_id = p.id
group by p.id;

grant select on public.place_stats to authenticated;
