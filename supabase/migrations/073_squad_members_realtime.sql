-- v1.1 — Squad members realtime
-- The `squad_members` table was never added to the supabase_realtime
-- publication. That means INSERT/UPDATE/DELETE events on it didn't fan
-- out to subscribed clients. The Flutter `watchSquad` stream was only
-- ever updated when the page re-mounted or the provider was manually
-- invalidated — so kicking a member or having a member self-leave did
-- not visibly disappear from other squad members' devices in real time.
--
-- Idempotent: ALTER PUBLICATION ADD TABLE errors when the table is
-- already a member, so we wrap in a DO block + duplicate_object catch
-- (mirrors migration 059's pattern).

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.squad_members;
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END $$;

-- DELETEs on a table only carry the primary key by default; that is
-- enough for the Flutter client-side dedupe, but bump replica identity
-- to FULL so subscribers can see the OLD row (useful for any future
-- per-user filter logic on the client).
ALTER TABLE public.squad_members REPLICA IDENTITY FULL;
