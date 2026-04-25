-- 023_message_delete.sql
--
-- Allow a user to delete their own messages in trip chat + DMs.
-- The initial schema only included SELECT + INSERT policies, so
-- DELETE requests were rejected by RLS. Reactions + images on the
-- removed row are cleaned up via the existing ON DELETE CASCADE
-- foreign keys.

drop policy if exists "Owner can delete own chat"
  on public.chat_messages;
create policy "Owner can delete own chat"
  on public.chat_messages for delete
  using (auth.uid() = user_id);

drop policy if exists "Sender can delete own dm"
  on public.direct_messages;
create policy "Sender can delete own dm"
  on public.direct_messages for delete
  using (auth.uid() = from_user);
