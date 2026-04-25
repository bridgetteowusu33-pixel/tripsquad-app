-- ─────────────────────────────────────────────────────────────
-- 048 — Push when Scout replies
--
-- The `scout_chat` edge function writes Scout's replies into
-- scout_messages with role='assistant' but never inserts into
-- notifications, so send_push never fires. Result: if the user
-- backgrounds the app mid-Scout-turn, they never see a banner.
--
-- Fix: AFTER INSERT trigger on scout_messages that, when the new
-- row is an assistant reply, writes a notification row for that
-- user. send_push picks it up via the existing
-- `send_push_on_notification` trigger on notifications INSERT.
-- ─────────────────────────────────────────────────────────────

create or replace function public.notify_scout_reply()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_preview text;
begin
  -- Only push for assistant replies. User's own messages don't
  -- generate a notification.
  if new.role <> 'assistant' then
    return new;
  end if;

  -- Trim the body to a reasonable banner length. APNs banners are
  -- ~100 chars before truncation; 140 leaves headroom for emoji.
  v_preview := coalesce(new.content, '');
  if length(v_preview) > 140 then
    v_preview := substring(v_preview from 1 for 137) || '...';
  end if;

  insert into public.notifications (user_id, kind, title, body)
  values (
    new.user_id,
    'scout_reply',
    'scout replied 🧭',
    v_preview
  );

  return new;
end;
$$;

drop trigger if exists scout_reply_notify on public.scout_messages;

create trigger scout_reply_notify
  after insert on public.scout_messages
  for each row
  execute function public.notify_scout_reply();
