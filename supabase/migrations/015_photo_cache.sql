-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 015: Photo cache
--  Unsplash rate limit is 50 req/hr on free tier. Cache lookups
--  by query string so repeated generations reuse known photos.
-- ─────────────────────────────────────────────────────────────

create table if not exists public.photo_cache (
  query       text primary key,
  url         text,
  fetched_at  timestamptz default now()
);

alter table public.photo_cache enable row level security;
create policy "Anyone authenticated can read photo cache"
  on photo_cache for select using (auth.uid() is not null);
