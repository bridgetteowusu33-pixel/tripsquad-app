-- ─────────────────────────────────────────────────────────────
-- 046 — Trip Passes (v1 paywall)
--
-- v1 free tier: a host may have ONE active trip at a time. Beyond
-- that they need a Trip Pass — a one-time consumable that unlocks
-- one additional concurrent active-trip slot. Passes don't expire
-- and don't renew; each pass is consumed exactly once by one trip.
--
-- Slot-assigned concurrency model:
--   1. reserve_trip_pass(user)      — FOR UPDATE SKIP LOCKED, stamps
--                                      reserved_at = now(). Prevents
--                                      two parallel wizards from
--                                      double-claiming the same row.
--   2. consume_reserved_pass(pass, trip) — binds the pass to the
--                                      successfully-created trip.
--   3. release_reserved_pass(pass)  — unreserves on wizard cancel.
--   4. release_stale_reservations() — sweep for reservations older
--                                      than 5 min (pg_cron wires up
--                                      the schedule separately).
-- ─────────────────────────────────────────────────────────────

create table if not exists public.trip_passes (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  -- Apple receipt transactionIdentifier. UNIQUE so duplicate restore
  -- calls can't mint a second row for the same real-world purchase.
  purchase_token   text not null unique,
  purchased_at     timestamptz default now(),
  -- Soft lock held for up to 5 minutes while the host completes the
  -- trip-creation wizard. Cleared by consume_reserved_pass (success),
  -- release_reserved_pass (cancel), or release_stale_reservations
  -- (timeout).
  reserved_at      timestamptz,
  consumed_at      timestamptz,
  consumed_trip_id uuid references public.trips(id) on delete set null,
  product_id       text not null default 'tripsquad.trippass',
  price_paid_cents integer,
  currency         text
);

-- Hot path: "does this user have an available pass?" — partial index
-- on (not reserved AND not consumed) keeps the scan tiny even after
-- a user has burned through many passes.
create index if not exists idx_trip_passes_user_available
  on public.trip_passes(user_id)
  where consumed_at is null and reserved_at is null;

-- Sweep path: fast lookup of stale reservations.
create index if not exists idx_trip_passes_reserved_stale
  on public.trip_passes(reserved_at)
  where reserved_at is not null and consumed_at is null;

alter table public.trip_passes enable row level security;

-- Users see their own passes (for the settings count + restore UI).
-- Inserts happen via service-role inside the RC service's
-- purchase-and-record flow; no user-initiated insert policy needed
-- because the RPCs that mutate passes are SECURITY DEFINER.
create policy "users read own trip passes"
  on public.trip_passes for select
  using (auth.uid() = user_id);

create policy "users insert own trip passes"
  on public.trip_passes for insert
  with check (auth.uid() = user_id);

-- ─── RPCs ─────────────────────────────────────────────────────

-- Reserve one unspent pass. Returns the pass_id on success or NULL
-- when the user has none available. FOR UPDATE SKIP LOCKED ensures
-- two concurrent callers never reserve the same row.
create or replace function public.reserve_trip_pass(p_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pass_id uuid;
begin
  select id
    into v_pass_id
    from public.trip_passes
   where user_id = p_user_id
     and reserved_at is null
     and consumed_at is null
   order by purchased_at asc
   limit 1
   for update skip locked;

  if v_pass_id is null then
    return null;
  end if;

  update public.trip_passes
     set reserved_at = now()
   where id = v_pass_id;

  return v_pass_id;
end;
$$;
grant execute on function public.reserve_trip_pass(uuid) to authenticated;

-- Bind a reserved pass to the successfully-created trip. Idempotent:
-- calling with an already-consumed pass is a no-op on that field.
create or replace function public.consume_reserved_pass(
  p_pass_id uuid,
  p_trip_id uuid
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.trip_passes
     set consumed_at      = coalesce(consumed_at, now()),
         consumed_trip_id = coalesce(consumed_trip_id, p_trip_id)
   where id = p_pass_id
     and user_id = auth.uid();
end;
$$;
grant execute on function public.consume_reserved_pass(uuid, uuid) to authenticated;

-- Clear a reservation without consuming. Called when the wizard is
-- cancelled or trip-creation fails.
create or replace function public.release_reserved_pass(p_pass_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.trip_passes
     set reserved_at = null
   where id = p_pass_id
     and user_id = auth.uid()
     and consumed_at is null;
end;
$$;
grant execute on function public.release_reserved_pass(uuid) to authenticated;

-- Sweep stale reservations. Wired to pg_cron separately — this just
-- ships the function.
create or replace function public.release_stale_reservations()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  with released as (
    update public.trip_passes
       set reserved_at = null
     where reserved_at is not null
       and reserved_at < now() - interval '5 minutes'
       and consumed_at is null
    returning 1
  )
  select count(*) into v_count from released;
  return v_count;
end;
$$;
-- NOT granted to authenticated — intended to run via pg_cron as the
-- table owner. If a human needs to run it ad-hoc, do it through the
-- Supabase SQL editor or a service-role connection.

-- Count helpers — these back the UI "trip passes: N" row and the
-- pre-paywall can-create-trip gate.
create or replace function public.count_unspent_trip_passes(p_user_id uuid)
returns integer
language sql
security definer
set search_path = public
as $$
  select count(*)::integer
    from public.trip_passes
   where user_id = p_user_id
     and consumed_at is null
     and reserved_at is null;
$$;
grant execute on function public.count_unspent_trip_passes(uuid) to authenticated;

create or replace function public.count_active_trips_as_host(p_user_id uuid)
returns integer
language sql
security definer
set search_path = public
as $$
  select count(*)::integer
    from public.trips
   where host_id = p_user_id
     and status in ('draft', 'collecting', 'voting',
                    'revealed', 'planning', 'live');
$$;
grant execute on function public.count_active_trips_as_host(uuid) to authenticated;
