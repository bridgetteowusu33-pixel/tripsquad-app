-- 025_chat_pin.sql
--
-- Lets the trip host toggle `pinned_at` on any message in their
-- trip. Before this, chat_messages had SELECT + INSERT + DELETE
-- (author) but no UPDATE policy, so pinning was silently blocked
-- by RLS. Constrained to `pinned_at` via a trigger that rejects
-- any other column change — keeps content immutable.

drop policy if exists "Host can pin messages" on public.chat_messages;
create policy "Host can pin messages"
  on public.chat_messages for update
  using (
    exists (
      select 1 from trips t
      where t.id = chat_messages.trip_id
        and t.host_id = auth.uid()
    )
  );

-- A narrow RPC — makes it impossible to accidentally update
-- content when pinning. Only the host flips the flag.
create or replace function toggle_pin(
  _message_id uuid,
  _pin boolean
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  trip_host uuid;
begin
  select t.host_id into trip_host
  from chat_messages m
  join trips t on t.id = m.trip_id
  where m.id = _message_id;
  if trip_host is null then
    raise exception 'message not found';
  end if;
  if trip_host <> auth.uid() then
    raise exception 'only the host can pin';
  end if;
  if _pin then
    -- Unpin the currently-pinned message first so there's always
    -- at most one pin per trip.
    update chat_messages
       set pinned_at = null
     where trip_id = (select trip_id from chat_messages where id = _message_id)
       and pinned_at is not null;
    update chat_messages
       set pinned_at = now()
     where id = _message_id;
  else
    update chat_messages
       set pinned_at = null
     where id = _message_id;
  end if;
end;
$$;

grant execute on function toggle_pin(uuid, boolean) to authenticated;
