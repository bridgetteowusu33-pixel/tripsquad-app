-- 024_replica_identity_messages.sql
--
-- Realtime needs `REPLICA IDENTITY FULL` to include the deleted
-- row's primary key in DELETE events. Without this, clients watching
-- `chat_messages.stream()` / `direct_messages.stream()` sometimes
-- missed DELETEs entirely — the message only disappeared after
-- re-subscribing.

alter table public.chat_messages   replica identity full;
alter table public.direct_messages replica identity full;
