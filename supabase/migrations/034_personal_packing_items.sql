-- ─────────────────────────────────────────────────────────────
-- 034 — Personal vs shared packing items
--
-- Before: ALL packing items were visible to every squad member.
-- Now:
--   * Scout-generated items (added_by IS NULL) stay shared.
--   * User-added items (added_by = some uid) are personal — only
--     the owner (and the trip host, so they can kick / clean up)
--     can see, update, or delete them.
--
-- Rationale: "I want to pack my own clothes / chargers" shouldn't
-- leak into the squad's shared list.
-- ─────────────────────────────────────────────────────────────

-- SELECT: shared scout items OR my own personal items. Host sees all.
drop policy if exists "Trip members can read packing" on public.packing_items;
create policy "Members read shared + own packing"
  on public.packing_items for select using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = packing_items.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
    and (
      added_by is null                         -- shared (scout) item
      or added_by = auth.uid()                 -- my personal item
      or exists (select 1 from trips t2        -- host sees all
                 where t2.id = packing_items.trip_id
                   and t2.host_id = auth.uid())
    )
  );

-- UPDATE: only the owner can edit their personal item. Shared items
-- stay updatable by any squad member (so anyone can mark "packed").
drop policy if exists "Trip members can update packing items" on public.packing_items;
create policy "Members update shared + own packing"
  on public.packing_items for update using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = packing_items.trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
    and (
      added_by is null
      or added_by = auth.uid()
      or exists (select 1 from trips t2
                 where t2.id = packing_items.trip_id
                   and t2.host_id = auth.uid())
    )
  );

-- DELETE: only the owner of a personal item, or the host for shared.
drop policy if exists "Trip members can delete packing items" on public.packing_items;
create policy "Owner deletes own, host deletes shared"
  on public.packing_items for delete using (
    added_by = auth.uid()
    or (
      added_by is null
      and exists (select 1 from trips t
                  where t.id = packing_items.trip_id
                    and t.host_id = auth.uid())
    )
  );
