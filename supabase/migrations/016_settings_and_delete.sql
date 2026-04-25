-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 016: Settings + delete account
--  1. notification_prefs JSON on profiles (granular toggles)
--  2. delete_account RPC (App Store required per 5.1.1(v))
-- ─────────────────────────────────────────────────────────────

alter table public.profiles
  add column if not exists notification_prefs jsonb default '{}'::jsonb;

update public.profiles
   set notification_prefs = jsonb_build_object(
     'trip_invites', true,
     'chat_messages', true,
     'mentions', true,
     'trip_updates', true,
     'scout_suggestions', true,
     'dm_received', true,
     'kudos_received', true
   )
 where notification_prefs = '{}'::jsonb or notification_prefs is null;

create or replace function delete_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not signed in';
  end if;
  delete from auth.users where id = me;
end $$;

grant execute on function delete_account() to authenticated;
