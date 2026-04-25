-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 008: Itinerary proposal flow
--
--  Non-host members can propose activities. Host approves or
--  rejects. Host-added activities auto-approve.
-- ─────────────────────────────────────────────────────────────

alter table public.itinerary_items
  add column if not exists status text default 'approved'
    check (status in ('proposed', 'approved', 'rejected')),
  add column if not exists proposed_by uuid references public.profiles(id) on delete set null,
  add column if not exists rejected_reason text,
  add column if not exists reviewed_at timestamptz,
  add column if not exists reviewed_by uuid references public.profiles(id) on delete set null;

create index if not exists idx_itinerary_items_status
  on public.itinerary_items(trip_id, status);

-- ─────────────────────────────────────────────────────────────
-- Auto-status trigger:
-- If the insert is by the trip host, status = approved.
-- Otherwise, status = proposed, proposed_by = caller.
-- ─────────────────────────────────────────────────────────────
create or replace function set_itinerary_item_status()
returns trigger language plpgsql security definer as $$
declare
  is_host boolean;
begin
  -- Default to approved if caller is missing (service role / edge function)
  if auth.uid() is null then
    new.status := coalesce(new.status, 'approved');
    return new;
  end if;

  select (t.host_id = auth.uid()) into is_host
  from trips t where t.id = new.trip_id;

  if is_host is true then
    new.status := 'approved';
    new.reviewed_by := auth.uid();
    new.reviewed_at := now();
  else
    new.status := 'proposed';
    new.proposed_by := auth.uid();
    new.created_by := auth.uid();
  end if;
  return new;
end $$;

drop trigger if exists trg_set_itinerary_item_status on public.itinerary_items;
create trigger trg_set_itinerary_item_status
  before insert on public.itinerary_items
  for each row execute function set_itinerary_item_status();

-- ─────────────────────────────────────────────────────────────
-- Approve / reject RPCs (host only)
-- ─────────────────────────────────────────────────────────────
create or replace function approve_itinerary_item(_item_id uuid)
returns void language plpgsql security definer as $$
declare
  item record;
  is_host boolean;
begin
  select i.*, (t.host_id = auth.uid()) as viewer_is_host
  into item
  from itinerary_items i join trips t on t.id = i.trip_id
  where i.id = _item_id;

  if item is null then raise exception 'not found'; end if;
  if not item.viewer_is_host then raise exception 'only the host can approve'; end if;

  update itinerary_items
     set status = 'approved',
         reviewed_by = auth.uid(),
         reviewed_at = now()
   where id = _item_id;

  -- Notify the proposer
  if item.proposed_by is not null and item.proposed_by <> auth.uid() then
    insert into notifications (user_id, trip_id, kind, title, body)
    values (
      item.proposed_by, item.trip_id, 'proposal_approved',
      'your proposal was approved ✨',
      item.title
    );
  end if;

  -- Log event for activity ticker
  insert into trip_events (trip_id, kind, actor_user_id, payload)
  values (item.trip_id, 'itinerary_ready', auth.uid(),
          jsonb_build_object('title', 'approved: ' || item.title));
end $$;

create or replace function reject_itinerary_item(_item_id uuid, _reason text)
returns void language plpgsql security definer as $$
declare
  item record;
begin
  select i.*, (t.host_id = auth.uid()) as viewer_is_host
  into item
  from itinerary_items i join trips t on t.id = i.trip_id
  where i.id = _item_id;

  if item is null then raise exception 'not found'; end if;
  if not item.viewer_is_host then raise exception 'only the host can reject'; end if;

  update itinerary_items
     set status = 'rejected',
         reviewed_by = auth.uid(),
         reviewed_at = now(),
         rejected_reason = _reason
   where id = _item_id;

  if item.proposed_by is not null and item.proposed_by <> auth.uid() then
    insert into notifications (user_id, trip_id, kind, title, body)
    values (
      item.proposed_by, item.trip_id, 'proposal_rejected',
      'host didn''t go with your suggestion',
      coalesce(_reason, item.title)
    );
  end if;
end $$;

grant execute on function approve_itinerary_item(uuid) to authenticated;
grant execute on function reject_itinerary_item(uuid, text) to authenticated;

-- ─────────────────────────────────────────────────────────────
-- Notify host when a non-host proposes an activity.
-- Runs AFTER insert so status is already set.
-- ─────────────────────────────────────────────────────────────
create or replace function notify_host_on_proposal()
returns trigger language plpgsql security definer as $$
declare
  host_id uuid;
  proposer_tag text;
begin
  if new.status <> 'proposed' or new.proposed_by is null then
    return new;
  end if;
  select t.host_id into host_id from trips t where t.id = new.trip_id;
  if host_id is null or host_id = new.proposed_by then return new; end if;

  select tag into proposer_tag from profiles where id = new.proposed_by;

  insert into notifications (user_id, trip_id, kind, title, body)
  values (
    host_id, new.trip_id, 'proposal_new',
    coalesce('@' || proposer_tag, 'someone') || ' proposed an activity ✦',
    new.title
  );
  return new;
end $$;

drop trigger if exists trg_notify_host_on_proposal on public.itinerary_items;
create trigger trg_notify_host_on_proposal
  after insert on public.itinerary_items
  for each row execute function notify_host_on_proposal();

-- ─────────────────────────────────────────────────────────────
-- RLS: everyone in trip can read approved + their own proposed.
-- Host sees everything.
-- ─────────────────────────────────────────────────────────────
drop policy if exists "Trip members can read itinerary" on itinerary_items;
create policy "Members read approved + own proposed"
  on itinerary_items for select using (
    (
      -- You're a member or host of this trip
      exists (
        select 1 from trips t
        left join squad_members sm on sm.trip_id = t.id
        where t.id = itinerary_items.trip_id
          and (t.host_id = auth.uid() or sm.user_id = auth.uid())
      )
    )
    and (
      status = 'approved'
      or proposed_by = auth.uid()
      or exists (select 1 from trips t
                 where t.id = itinerary_items.trip_id
                   and t.host_id = auth.uid())
    )
  );
