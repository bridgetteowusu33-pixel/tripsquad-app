-- 026_chat_edit.sql
--
-- Lets a squadmate edit their own trip-chat message. We add an
-- `edited_at` timestamp so the client can render an "edited"
-- hint next to the bubble, and an UPDATE RLS policy scoped to
-- the author. The existing "Host can pin messages" policy stays
-- put; both policies can match on the same row (postgres OR's
-- them) so hosts can still pin.

alter table public.chat_messages
  add column if not exists edited_at timestamptz;

drop policy if exists "Author can edit own chat"
  on public.chat_messages;
create policy "Author can edit own chat"
  on public.chat_messages for update
  using (auth.uid() = user_id);
