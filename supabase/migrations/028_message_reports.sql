-- 028_message_reports.sql
--
-- User-generated content reporting for App Store compliance
-- guideline 1.2. Backs the "report" action in chat + DM long-press
-- sheets. At least one of chat_message_id / dm_message_id must be
-- set; the check constraint enforces that. Both cascades are
-- deliberate: if the underlying message is deleted we keep the
-- report row (null FK) so moderation still has a trail.

create table if not exists public.message_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  chat_message_id uuid references public.chat_messages(id) on delete set null,
  dm_message_id uuid references public.direct_messages(id) on delete set null,
  reason text not null,
  details text,
  created_at timestamptz default now(),
  constraint message_reports_one_target check (
    (chat_message_id is not null) or (dm_message_id is not null)
  )
);

alter table public.message_reports enable row level security;

drop policy if exists "Reporter can insert own report"
  on public.message_reports;
create policy "Reporter can insert own report"
  on public.message_reports for insert
  with check (auth.uid() = reporter_id);

drop policy if exists "Reporter can view own reports"
  on public.message_reports;
create policy "Reporter can view own reports"
  on public.message_reports for select
  using (auth.uid() = reporter_id);

create index if not exists message_reports_reporter_idx
  on public.message_reports(reporter_id);
create index if not exists message_reports_chat_idx
  on public.message_reports(chat_message_id)
  where chat_message_id is not null;
create index if not exists message_reports_dm_idx
  on public.message_reports(dm_message_id)
  where dm_message_id is not null;
