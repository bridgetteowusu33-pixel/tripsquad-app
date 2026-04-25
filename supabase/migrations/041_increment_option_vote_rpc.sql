-- ─────────────────────────────────────────────────────────────
-- 041 — Create the missing increment_option_vote RPC
--
-- The web invite form calls /rpc/increment_option_vote after a web
-- visitor casts a vote, but the function was never defined —
-- requests 404'd silently and vote_count never moved, so in-app
-- hosts watching the Vote tab saw the counter stuck.
--
-- SECURITY DEFINER so anonymous web visitors (who only have the
-- publishable/anon key) can increment without needing a login.
-- We guard by checking the target trip is still in 'voting' status
-- to prevent vote-stuffing after reveal.
-- ─────────────────────────────────────────────────────────────

create or replace function public.increment_option_vote(option_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip_id uuid;
  v_status  text;
begin
  select o.trip_id, t.status
    into v_trip_id, v_status
    from trip_options o
    join trips t on t.id = o.trip_id
   where o.id = option_id;

  if v_trip_id is null then
    raise exception 'option not found';
  end if;
  if v_status <> 'voting' then
    raise exception 'voting is closed';
  end if;

  update trip_options
     set vote_count = coalesce(vote_count, 0) + 1
   where id = option_id;
end;
$$;

-- Accessible from the anon role so the web form's public key works.
grant execute on function public.increment_option_vote(uuid) to anon, authenticated;
