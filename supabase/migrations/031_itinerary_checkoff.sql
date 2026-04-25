-- 031_itinerary_checkoff.sql
--
-- Live Trip Mode: squad-synced check-offs on the Today tab. Until
-- now the Today tab kept toggles in SharedPreferences per-device, so
-- squad members couldn't see each other's progress. This migration
-- promotes check-offs to server state + real-time broadcast.
--
-- Columns:
--   checked_off_at  — null = not checked, timestamptz = when it was
--   checked_off_by  — which squad member flipped it (for audit + UI)

alter table public.itinerary_items
  add column if not exists checked_off_at timestamptz,
  add column if not exists checked_off_by uuid references auth.users(id) on delete set null;

-- The RPC any squad member on the trip can call to toggle an item.
-- Security definer + membership check means we don't need to widen
-- UPDATE RLS on itinerary_items (which is more restrictive — only
-- owner / approver). Returns the new checked_off_at (null if unchecked).
create or replace function public.toggle_itinerary_check(_item_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  caller uuid := auth.uid();
  trip_id_v uuid;
  is_member boolean;
  was_checked timestamptz;
  new_ts timestamptz;
begin
  if caller is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;

  select trip_id, checked_off_at into trip_id_v, was_checked
    from itinerary_items
    where id = _item_id;

  if trip_id_v is null then
    raise exception 'item not found' using errcode = 'P0002';
  end if;

  -- membership check: must be on the squad for this trip
  select exists (
    select 1 from squad_members
    where trip_id = trip_id_v and user_id = caller
  ) into is_member;

  if not is_member then
    raise exception 'not a squad member' using errcode = '42501';
  end if;

  if was_checked is null then
    new_ts := now();
    update itinerary_items
      set checked_off_at = new_ts, checked_off_by = caller
      where id = _item_id;
  else
    new_ts := null;
    update itinerary_items
      set checked_off_at = null, checked_off_by = null
      where id = _item_id;
  end if;

  return new_ts;
end;
$$;

grant execute on function public.toggle_itinerary_check(uuid) to authenticated;

-- itinerary_items should already be in the realtime publication (see
-- migration 008). Belt-and-suspenders: re-add with REPLICA IDENTITY
-- FULL so UPDATE events broadcast the full row, including the new
-- checked_off_at column, to subscribed clients.
alter table public.itinerary_items replica identity full;
