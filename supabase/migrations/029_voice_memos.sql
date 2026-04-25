-- 029_voice_memos.sql
--
-- Voice memos in trip chat and DMs. Storing the audio URL + a cached
-- duration so the client can render the play button and time pill
-- without fetching the file. Files live in the `avatars` bucket under
-- `<uid>/voice/<uuid>.m4a` to satisfy the per-user folder RLS
-- already in place.

alter table public.chat_messages
  add column if not exists audio_url text,
  add column if not exists audio_duration_ms integer;

alter table public.direct_messages
  add column if not exists audio_url text,
  add column if not exists audio_duration_ms integer;
