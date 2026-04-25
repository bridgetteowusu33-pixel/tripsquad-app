-- ─────────────────────────────────────────────────────────────
-- 051 — Allow service-role calls to moderate_message_report
--
-- Migration 050 raised "unauthenticated" when auth.uid() was null,
-- which broke the very SQL-editor workflow it was designed for —
-- service-role calls (Dashboard → SQL Editor) have no JWT and no
-- auth.uid().
--
-- New rule:
--   • auth.uid() IS NULL  → service-role / SQL editor → allow
--                           (the editor itself is gated by Supabase
--                           dashboard auth on the founder's account)
--   • auth.uid() IS NOT NULL → in-app call → require is_moderator
--   • either path → moderator_id is stamped from auth.uid() if
--     present; for service-role calls it's left null (the dashboard
--     audit log records who ran the SQL).
-- ─────────────────────────────────────────────────────────────

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
  -- Service-role / SQL editor calls have v_uid = null — let those
  -- through without a profile check (they're already gated by
  -- Supabase dashboard auth). Authenticated app calls must come
  -- from a profile flagged is_moderator.
  if v_uid is not null then
    select coalesce(is_moderator, false) into v_is_mod
      from profiles where id = v_uid;
    if not v_is_mod then
      raise exception 'not authorised to moderate';
    end if;
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
         moderator_id   = v_uid -- null for service-role / SQL editor calls; that's fine
   where id = p_report_id;
end;
$$;

grant execute on function public.moderate_message_report(uuid, text, text)
  to authenticated;
