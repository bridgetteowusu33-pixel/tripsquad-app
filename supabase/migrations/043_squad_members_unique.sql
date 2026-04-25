-- ─────────────────────────────────────────────────────────────
-- 043 — Deduplicate squad_members per (trip_id, user_id)
--
-- During testing a single user could end up with N squad_members
-- rows for the same trip (joined via web, re-joined by tag, etc.).
-- Every row the user owns got its own notification on fan-out, so
-- "itinerary ready" arrived N times.
--
-- Step 1: collapse duplicates, keeping the newest row (most
--          progressed status, newest responded_at).
-- Step 2: add a partial unique index so the same pair can never
--          exist twice again. Partial because user_id can be null
--          (legacy web-link joiners without an account).
-- ─────────────────────────────────────────────────────────────

-- Step 1 — kill duplicates. Keep the newest row per (trip_id, user_id).
with ranked as (
  select id,
         row_number() over (
           partition by trip_id, user_id
           order by
             -- Prefer higher status (voted > submitted > invited).
             case status
               when 'voted'     then 2
               when 'submitted' then 1
               else 0
             end desc,
             coalesce(responded_at, created_at) desc,
             created_at desc
         ) as rn
    from public.squad_members
   where user_id is not null
)
delete from public.squad_members
 where id in (select id from ranked where rn > 1);

-- Step 2 — prevent future duplicates.
create unique index if not exists idx_squad_members_unique_user_per_trip
  on public.squad_members(trip_id, user_id)
  where user_id is not null;
