-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 003: Packing Items (first-class table)
--  Replaces `itinerary_days.packing` JSONB with a real table so
--  every squad member sees live updates of who's packed what.
-- ─────────────────────────────────────────────────────────────

create table if not exists public.packing_items (
  id            uuid default gen_random_uuid() primary key,
  trip_id       uuid references public.trips(id) on delete cascade not null,
  label         text not null,
  category      text not null default 'extras',
  emoji         text,
  is_shared     boolean default false,
  added_by      uuid references public.profiles(id) on delete set null,
  claimed_by    uuid references public.profiles(id) on delete set null,
  packed_by     jsonb default '[]',  -- array of user_ids (text)
  order_index   int default 0,
  created_at    timestamptz default now()
);

create index if not exists idx_packing_items_trip
  on public.packing_items(trip_id, category, order_index);

alter table public.packing_items enable row level security;

create policy "Trip members can read packing"
  on packing_items for select using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = packing_items.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

create policy "Trip members can add packing items"
  on packing_items for insert with check (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = packing_items.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

create policy "Trip members can update packing items"
  on packing_items for update using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = packing_items.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

create policy "Trip members can delete packing items"
  on packing_items for delete using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = packing_items.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

-- Realtime
alter publication supabase_realtime add table packing_items;

-- Helper RPCs for atomic packed_by array toggle
create or replace function toggle_packed(
  _item_id uuid,
  _user_id uuid
) returns void language plpgsql security definer as $$
declare
  current jsonb;
  user_text text := _user_id::text;
begin
  select packed_by into current from packing_items where id = _item_id;
  if current is null then current := '[]'::jsonb; end if;

  if current @> to_jsonb(array[user_text]) then
    update packing_items
       set packed_by = (select coalesce(jsonb_agg(v), '[]'::jsonb)
                         from jsonb_array_elements_text(current) as v
                         where v <> user_text)
     where id = _item_id;
  else
    update packing_items
       set packed_by = current || to_jsonb(array[user_text])
     where id = _item_id;
  end if;
end;
$$;
