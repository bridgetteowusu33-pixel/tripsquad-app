-- ─────────────────────────────────────────────────────────────
-- 045 — Entitlements audit + Trip Pass + AI gen counter
--
-- Adds:
--  * entitlements — mirrors RevenueCat purchases locally for
--    analytics + "Manage plan" UI. RevenueCat is still the source of
--    truth for active-subscription checks.
--  * trips.trip_pass — one-time unlock for a specific trip (Trip
--    Pass IAP). Lifts squad + AI caps on that trip only.
--  * trips.ai_gen_count — free-tier meter for AI generations.
--  * increment_trip_ai_gen(tripId) — SECURITY DEFINER RPC called
--    after each successful generation.
-- ─────────────────────────────────────────────────────────────

create table if not exists public.entitlements (
  id              uuid default gen_random_uuid() primary key,
  user_id         uuid not null references public.profiles(id) on delete cascade,
  product_id      text not null,
  purchase_token  text,
  trip_id         uuid references public.trips(id) on delete set null,
  expires_at      timestamptz,
  created_at      timestamptz default now()
);
create index if not exists idx_entitlements_user on public.entitlements(user_id, created_at desc);
create index if not exists idx_entitlements_product on public.entitlements(product_id);
alter table public.entitlements enable row level security;
create policy "Users read own entitlements"
  on public.entitlements for select using (auth.uid() = user_id);
create policy "Users insert own entitlements"
  on public.entitlements for insert with check (auth.uid() = user_id);

alter table public.trips
  add column if not exists trip_pass boolean default false,
  add column if not exists ai_gen_count int default 0;

-- Only the host can mark a trip as Trip-Pass-unlocked.
create or replace function increment_trip_ai_gen(_trip_id uuid)
returns void language plpgsql security definer as $$
begin
  update public.trips
     set ai_gen_count = coalesce(ai_gen_count, 0) + 1
   where id = _trip_id;
end;
$$;
grant execute on function public.increment_trip_ai_gen(uuid) to authenticated;
