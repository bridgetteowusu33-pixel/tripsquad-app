-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 011: Ratings suite
--  1. Kudos            — positive-only squad reputation
--  2. Itinerary ratings — 👍/👎 per activity / hotel / restaurant
--  3. Destination recaps — post-trip overall rating
--  4. item_type column   — activities vs hotels vs restaurants
-- ─────────────────────────────────────────────────────────────

-- ── Item type on itinerary ───────────────────────────────────
alter table public.itinerary_items
  add column if not exists item_type text default 'activity'
  check (item_type in ('activity','hotel','restaurant'));
create index if not exists idx_itinerary_items_type
  on public.itinerary_items(trip_id, item_type);

-- ── Kudos (positive-only squad reputation) ───────────────────
create table if not exists public.kudos (
  id          uuid default gen_random_uuid() primary key,
  trip_id     uuid references public.trips(id) on delete cascade not null,
  from_user   uuid references public.profiles(id) on delete cascade not null,
  to_user     uuid references public.profiles(id) on delete cascade not null,
  kind        text not null
    check (kind in (
      'great_traveler','on_time','fair_splits','fun_energy',
      'great_planner','photo_mvp','chill_roommate'
    )),
  note        text,
  created_at  timestamptz default now(),
  unique (trip_id, from_user, to_user, kind),
  check (from_user <> to_user)
);
create index if not exists idx_kudos_to on public.kudos(to_user, kind);
alter table public.kudos enable row level security;

create policy "Trip members can read kudos for their trip"
  on kudos for select using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = kudos.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

create policy "Anyone can read kudos about a user"
  on kudos for select using (auth.uid() is not null);

create policy "Users can give kudos as themselves"
  on kudos for insert with check (auth.uid() = from_user);

create policy "Users can withdraw their own kudos"
  on kudos for delete using (auth.uid() = from_user);

-- Aggregated view: how many of each kudos kind does a user have
create or replace view public.kudos_counts as
  select to_user as user_id, kind, count(*)::int as count
  from kudos
  group by to_user, kind;

grant select on public.kudos_counts to authenticated;

-- ── Itinerary ratings (👍/👎 per item) ───────────────────────
create table if not exists public.itinerary_ratings (
  id          uuid default gen_random_uuid() primary key,
  item_id     uuid references public.itinerary_items(id) on delete cascade not null,
  user_id     uuid references public.profiles(id) on delete cascade not null,
  thumb       smallint not null check (thumb in (-1, 1)),
  note        text,
  created_at  timestamptz default now(),
  unique (item_id, user_id)
);
create index if not exists idx_itinerary_ratings_item
  on public.itinerary_ratings(item_id);
alter table public.itinerary_ratings enable row level security;

create policy "Trip members can read ratings on their items"
  on itinerary_ratings for select using (
    exists (
      select 1 from itinerary_items ii
      join trips t on t.id = ii.trip_id
      left join squad_members sm on sm.trip_id = t.id
      where ii.id = itinerary_ratings.item_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

-- Aggregated ratings visible to everyone (for future discovery)
create policy "Anyone authenticated can read aggregate ratings"
  on itinerary_ratings for select using (auth.uid() is not null);

create policy "Trip members can rate"
  on itinerary_ratings for insert with check (
    auth.uid() = user_id and exists (
      select 1 from itinerary_items ii
      join trips t on t.id = ii.trip_id
      left join squad_members sm on sm.trip_id = t.id
      where ii.id = itinerary_ratings.item_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

create policy "Users can update own rating"
  on itinerary_ratings for update using (auth.uid() = user_id);

create policy "Users can remove own rating"
  on itinerary_ratings for delete using (auth.uid() = user_id);

-- Aggregate summary per item
create or replace view public.item_rating_summary as
  select
    item_id,
    sum(case when thumb = 1  then 1 else 0 end)::int as up_count,
    sum(case when thumb = -1 then 1 else 0 end)::int as down_count,
    count(*)::int                                      as total,
    round(avg(case when thumb = 1 then 100 else 0 end)::numeric, 0)::int
      as approval_pct
  from itinerary_ratings
  group by item_id;

grant select on public.item_rating_summary to authenticated;

-- ── Destination recaps (post-trip overall rating) ────────────
create table if not exists public.destination_recaps (
  id            uuid default gen_random_uuid() primary key,
  trip_id       uuid references public.trips(id) on delete cascade not null,
  user_id       uuid references public.profiles(id) on delete cascade not null,
  destination   text not null,
  stars         smallint not null check (stars between 1 and 5),
  would_return  text not null check (would_return in ('yes','no','maybe')),
  best_part     text,
  photo_url     text,
  created_at    timestamptz default now(),
  unique (trip_id, user_id)
);
create index if not exists idx_destination_recaps_dest
  on public.destination_recaps(destination);
alter table public.destination_recaps enable row level security;

create policy "Anyone authenticated can read recaps"
  on destination_recaps for select using (auth.uid() is not null);

create policy "Users can create own recap"
  on destination_recaps for insert with check (auth.uid() = user_id);

create policy "Users can update own recap"
  on destination_recaps for update using (auth.uid() = user_id);

create policy "Users can delete own recap"
  on destination_recaps for delete using (auth.uid() = user_id);

-- Aggregate per destination
create or replace view public.destination_summary as
  select
    lower(trim(destination)) as destination_key,
    destination              as destination,
    round(avg(stars)::numeric, 1)::numeric as avg_stars,
    count(*)::int                           as recap_count,
    sum(case when would_return = 'yes' then 1 else 0 end)::int
      as would_return_count
  from destination_recaps
  group by lower(trim(destination)), destination;

grant select on public.destination_summary to authenticated;

-- ── Auto-increment trips_completed when a recap is submitted ─
-- We already had trips_completed column on profiles; bump it when
-- a user submits a recap for the first time for that trip.
create or replace function _bump_trips_completed()
returns trigger language plpgsql security definer as $$
begin
  update profiles
    set trips_completed = coalesce(trips_completed, 0) + 1
  where id = new.user_id;
  return new;
end $$;

drop trigger if exists trg_bump_trips_completed on destination_recaps;
create trigger trg_bump_trips_completed
  after insert on destination_recaps
  for each row execute function _bump_trips_completed();
