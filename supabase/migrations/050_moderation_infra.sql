-- ─────────────────────────────────────────────────────────────
-- 050 — Light moderation infrastructure
--
-- v1.0 launch posture: no admin app, no in-app moderation UI.
-- Reports are reviewed via the Supabase Dashboard SQL editor by
-- the founder (or any user flagged is_moderator=true). Apple
-- guideline 1.2 wants:
--   • Report mechanism                  ✓ already shipped
--   • Block mechanism                    ✓ already shipped
--   • Way to remove objectionable content ← THIS migration
--   • 24-hour SLA on review              ← documented in App Review notes
--
-- Adds:
--   1. profiles.is_moderator boolean — flips on for founder
--   2. message_reports.reviewed_at, action_taken, moderator_note,
--      moderator_id — moderation state per report
--   3. moderate_message_report(report_id, action, note) RPC —
--      authorised moderators call from the SQL editor to hide a
--      message + stamp the report as reviewed
--
-- Hide approach: overwrite the message content + clear media URLs
-- in chat_messages / direct_messages. Realtime pushes the update;
-- everyone sees `[message removed by moderator]` instantly. No
-- Dart-side model changes needed.
-- ─────────────────────────────────────────────────────────────

-- ── 1. Moderator flag on profiles ─────────────────────────────
alter table public.profiles
  add column if not exists is_moderator boolean default false;

-- Flip it on for the founder's account.
update public.profiles
   set is_moderator = true
 where id = 'ddcb2c46-83c2-4b95-8866-af4f8618d8ba';

-- ── 2. Moderation state on message_reports ────────────────────
alter table public.message_reports
  add column if not exists reviewed_at    timestamptz,
  add column if not exists action_taken   text,
  add column if not exists moderator_note text,
  add column if not exists moderator_id   uuid
    references auth.users(id) on delete set null;

create index if not exists idx_message_reports_pending
  on public.message_reports(created_at desc)
  where reviewed_at is null;

-- ── 3. moderate_message_report RPC ────────────────────────────
-- action ∈ {'hide', 'no_action'}
--
-- 'hide'      — replaces the offending message's content with a
--               placeholder, nulls media URLs, stamps the report
--               as reviewed.
-- 'no_action' — stamps the report as reviewed but leaves the
--               message intact (false-flag dismissal path).

create or replace function public.moderate_message_report(
  p_report_id uuid,
  p_action    text,
  p_note      text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid    uuid := auth.uid();
  v_is_mod boolean;
  v_report record;
begin
  if v_uid is null then
    raise exception 'unauthenticated';
  end if;

  select coalesce(is_moderator, false) into v_is_mod
    from profiles where id = v_uid;
  if not v_is_mod then
    raise exception 'not authorised to moderate';
  end if;

  if p_action not in ('hide', 'no_action') then
    raise exception 'invalid action %, expected hide or no_action',
                    p_action;
  end if;

  select * into v_report from message_reports where id = p_report_id;
  if v_report.id is null then
    raise exception 'report % not found', p_report_id;
  end if;

  if p_action = 'hide' then
    if v_report.chat_message_id is not null then
      update chat_messages
         set content   = '[message removed by moderator]',
             image_url = null,
             audio_url = null
       where id = v_report.chat_message_id;
    end if;
    if v_report.dm_message_id is not null then
      update direct_messages
         set content   = '[message removed by moderator]',
             image_url = null
       where id = v_report.dm_message_id;
    end if;
  end if;

  update message_reports
     set reviewed_at    = now(),
         action_taken   = p_action,
         moderator_note = p_note,
         moderator_id   = v_uid
   where id = p_report_id;
end;
$$;

grant execute on function public.moderate_message_report(uuid, text, text)
  to authenticated;

-- ── 4. Convenience view for the SQL editor ────────────────────
-- Pending reports with the message body inline so a moderator can
-- read what was reported without writing the join every time.
create or replace view public.pending_reports as
  select
    r.id              as report_id,
    r.created_at      as reported_at,
    r.reason,
    r.details,
    coalesce(c.content, d.content) as message_content,
    case when c.id is not null then 'chat'
         when d.id is not null then 'dm'
         else 'unknown' end        as message_kind,
    coalesce(c.user_id, d.from_user) as author_id
  from public.message_reports r
  left join public.chat_messages   c on c.id = r.chat_message_id
  left join public.direct_messages d on d.id = r.dm_message_id
 where r.reviewed_at is null
 order by r.created_at desc;

grant select on public.pending_reports to authenticated;
