-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 005: First-class itinerary items
--  Replaces itinerary_days.items JSONB with a real table so
--  squad members can edit, add, reorder, comment per activity.
-- ─────────────────────────────────────────────────────────────

create table if not exists public.itinerary_items (
  id                uuid default gen_random_uuid() primary key,
  trip_id           uuid references public.trips(id) on delete cascade not null,
  day_number        int not null default 1,
  time_of_day       text check (time_of_day in ('morning','afternoon','evening','night')) default 'morning',
  start_time        time,
  end_time          time,
  title             text not null,
  description       text,
  location          text,
  lat               double precision,
  lng               double precision,
  estimated_cost_cents int,
  booking_url       text,
  image_url         text,
  order_index       int default 0,
  created_by        uuid references public.profiles(id) on delete set null,
  booked_at         timestamptz,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

create index if not exists idx_itinerary_items_trip_day
  on public.itinerary_items(trip_id, day_number, order_index);

alter table public.itinerary_items enable row level security;

create policy "Trip members can read itinerary items"
  on itinerary_items for select using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = itinerary_items.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

create policy "Trip members can add itinerary items"
  on itinerary_items for insert with check (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = itinerary_items.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

create policy "Trip members can update itinerary items"
  on itinerary_items for update using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = itinerary_items.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

create policy "Trip members can delete itinerary items"
  on itinerary_items for delete using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = itinerary_items.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

-- ── Notes per activity (squad threaded comments) ─────────────
create table if not exists public.itinerary_notes (
  id          uuid default gen_random_uuid() primary key,
  item_id     uuid references public.itinerary_items(id) on delete cascade not null,
  user_id     uuid references public.profiles(id) on delete cascade not null,
  content     text not null,
  created_at  timestamptz default now()
);

create index if not exists idx_itinerary_notes_item
  on public.itinerary_notes(item_id, created_at desc);

alter table public.itinerary_notes enable row level security;

create policy "Trip members can read notes"
  on itinerary_notes for select using (
    exists (
      select 1 from itinerary_items ii
      join trips t on t.id = ii.trip_id
      left join squad_members sm on sm.trip_id = t.id
      where ii.id = itinerary_notes.item_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

create policy "Users can add own notes"
  on itinerary_notes for insert with check (auth.uid() = user_id);

create policy "Users can delete own notes"
  on itinerary_notes for delete using (auth.uid() = user_id);

-- Realtime
alter publication supabase_realtime add table itinerary_items;
alter publication supabase_realtime add table itinerary_notes;

-- updated_at trigger
create trigger itinerary_items_updated_at
  before update on itinerary_items
  for each row execute function update_updated_at();
