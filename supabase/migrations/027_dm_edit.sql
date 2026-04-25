-- 027_dm_edit.sql
--
-- Mirror of 026 for DMs: senders can edit their own direct
-- messages. `edited_at` surfaces an "edited" hint in the client.

alter table public.direct_messages
  add column if not exists edited_at timestamptz;

drop policy if exists "Sender can edit own dm"
  on public.direct_messages;
create policy "Sender can edit own dm"
  on public.direct_messages for update
  using (auth.uid() = from_user);
