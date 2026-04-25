-- ─────────────────────────────────────────────────────────────
-- 038 — Scheduled nudges (Tier 1)
--
-- Uses pg_cron to fire 3 hourly/daily jobs that INSERT notification
-- rows. The existing webhook on notifications → send_push handles
-- push delivery for free.
--
-- Nudges:
--   1. Stale invite (status=invited >24h)     — hourly
--   2. Countdown @ T-7, T-3, T-1              — daily 09:00 UTC
--   3. Live today (morning of each live day)  — daily 08:00 UTC
--   4. Recap prompt (T+2 after trip end)      — daily 10:00 UTC
--
-- Each nudge kind is inserted once per (user_id, trip_id, kind+day)
-- so we never send duplicates.
-- ─────────────────────────────────────────────────────────────

create extension if not exists pg_cron;

-- Allow the new kinds in the check constraint.
alter table public.trip_events
  drop constraint if exists trip_events_kind_check;
alter table public.trip_events
  add constraint trip_events_kind_check check (kind in (
    'status_changed','vote_cast','chat_message','itinerary_ready',
    'packing_ready',
    'member_joined','reveal','options_generated','dm_sent',
    'proposal_new','proposal_approved','proposal_rejected',
    'nudge_stale_invite','nudge_countdown','nudge_live_today','nudge_recap'
  ));

-- ── 1. Stale invite nudge ────────────────────────────────────
-- For any squad_members row status=invited created >24h ago AND
-- less than 14 days old, insert ONE notification per member.
create or replace function nudge_stale_invites()
returns void language plpgsql security definer as $$
begin
  insert into public.notifications (user_id, trip_id, kind, title, body)
  select sm.user_id,
         sm.trip_id,
         'nudge_stale_invite',
         'your squad is waiting on you for '
           || coalesce(t.name, 'a trip') || ' ✨',
         'drop your vibes so the host can get started'
    from public.squad_members sm
    join public.trips t on t.id = sm.trip_id
   where sm.status = 'invited'
     and sm.user_id is not null
     and sm.created_at < now() - interval '24 hours'
     and sm.created_at > now() - interval '14 days'
     and not exists (
       select 1 from public.notifications n
        where n.user_id = sm.user_id
          and n.trip_id = sm.trip_id
          and n.kind = 'nudge_stale_invite'
     );
end $$;

-- ── 2. Countdown nudges (T-7, T-3, T-1) ──────────────────────
create or replace function nudge_countdowns()
returns void language plpgsql security definer as $$
declare
  r record;
  v_days int;
  v_kind_day text;  -- e.g. 'nudge_countdown:7'
  v_title text;
  v_body text;
begin
  for r in
    select t.*, sm.user_id
      from public.trips t
      join public.squad_members sm on sm.trip_id = t.id
     where t.start_date is not null
       and sm.user_id is not null
       and t.status in ('planning','revealed','voting','collecting')
       and t.start_date::date in (
         (current_date + interval '7 days')::date,
         (current_date + interval '3 days')::date,
         (current_date + interval '1 day')::date
       )
  loop
    v_days := (r.start_date::date - current_date);
    v_kind_day := 'nudge_countdown:' || v_days;

    -- dedupe via title marker so we can check-exists cheaply.
    if exists (
      select 1 from public.notifications n
       where n.user_id = r.user_id
         and n.trip_id = r.id
         and n.kind = 'nudge_countdown'
         and n.body = v_kind_day
    ) then
      continue;
    end if;

    if v_days = 7 then
      v_title := coalesce(r.selected_destination, r.name)
                 || ' in 1 week ✈️ — it''s almost real';
      v_body := 'nudge_countdown:7';
    elsif v_days = 3 then
      v_title := '3 days until '
                 || coalesce(r.selected_destination, r.name)
                 || ' — time to pack?';
      v_body := 'nudge_countdown:3';
    else
      v_title := 'tomorrow. '
                 || coalesce(r.selected_destination, r.name)
                 || '. the squad is ready.';
      v_body := 'nudge_countdown:1';
    end if;

    insert into public.notifications
      (user_id, trip_id, kind, title, body)
    values
      (r.user_id, r.id, 'nudge_countdown', v_title, v_body);
  end loop;
end $$;

-- ── 3. Live today morning push ───────────────────────────────
-- For trips where today is between start_date and end_date, send
-- ONE morning push per squad member per day.
create or replace function nudge_live_today()
returns void language plpgsql security definer as $$
declare
  v_body_marker text := 'nudge_live_today:' || current_date;
begin
  insert into public.notifications (user_id, trip_id, kind, title, body)
  select sm.user_id,
         t.id,
         'nudge_live_today',
         'today in '
           || coalesce(t.selected_destination, t.name)
           || ' ✈️',
         v_body_marker
    from public.trips t
    join public.squad_members sm on sm.trip_id = t.id
   where sm.user_id is not null
     and t.start_date is not null
     and t.end_date is not null
     and current_date between t.start_date::date and t.end_date::date
     and not exists (
       select 1 from public.notifications n
        where n.user_id = sm.user_id
          and n.trip_id = t.id
          and n.kind = 'nudge_live_today'
          and n.body = v_body_marker
     );
end $$;

-- ── 4. Recap prompt (T+2 after end) ──────────────────────────
create or replace function nudge_recap()
returns void language plpgsql security definer as $$
begin
  insert into public.notifications (user_id, trip_id, kind, title, body)
  select sm.user_id,
         t.id,
         'nudge_recap',
         'missing '
           || coalesce(t.selected_destination, t.name)
           || '? tap to recap 💫',
         'nudge_recap'
    from public.trips t
    join public.squad_members sm on sm.trip_id = t.id
   where sm.user_id is not null
     and t.end_date is not null
     and t.end_date::date = (current_date - interval '2 days')::date
     and not exists (
       select 1 from public.notifications n
        where n.user_id = sm.user_id
          and n.trip_id = t.id
          and n.kind = 'nudge_recap'
     );
end $$;

-- ── Schedule the jobs ────────────────────────────────────────
-- pg_cron times are UTC. We pick times that feel "morning" in
-- much of EU/US/AFR (08:00 UTC ≈ 9am Lisbon / 4am NYC / 10am Accra).
select cron.schedule(
  'ts_nudge_stale_invites',
  '0 * * * *',              -- hourly
  $$ select public.nudge_stale_invites(); $$
);

select cron.schedule(
  'ts_nudge_countdowns',
  '0 9 * * *',              -- 09:00 UTC daily
  $$ select public.nudge_countdowns(); $$
);

select cron.schedule(
  'ts_nudge_live_today',
  '0 8 * * *',              -- 08:00 UTC daily
  $$ select public.nudge_live_today(); $$
);

select cron.schedule(
  'ts_nudge_recap',
  '0 10 * * *',             -- 10:00 UTC daily
  $$ select public.nudge_recap(); $$
);
