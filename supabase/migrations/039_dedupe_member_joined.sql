-- ─────────────────────────────────────────────────────────────
-- 039 — Throttle member_joined notification storms
--
-- Each squad_members insert fired a member_joined trip_event that
-- fanned out to every other squad member. In testing (and in
-- practice when multiple friends respond close together) that's
-- noisy — the host got a push per joiner. Collapse them.
--
-- Strategy: keep writing the trip_event (needed for the activity
-- ticker — we WANT each join visible in the event log). But when
-- the fan_out_trip_event trigger creates notification rows, skip
-- 'member_joined' recipients who already got one for the same trip
-- in the last 10 minutes.
-- ─────────────────────────────────────────────────────────────

create or replace function fan_out_trip_event()
returns trigger language plpgsql security definer as $$
begin
  insert into public.notifications
    (user_id, trip_id, event_id, kind, title, body)
  select sm.user_id,
         new.trip_id,
         new.id,
         new.kind,
         coalesce(new.payload->>'title', new.kind),
         new.payload->>'body'
    from public.squad_members sm
   where sm.trip_id = new.trip_id
     and sm.user_id is not null
     and sm.user_id <> coalesce(
       new.actor_user_id,
       '00000000-0000-0000-0000-000000000000'::uuid
     )
     -- Throttle member_joined: skip if this recipient already got
     -- one for this trip in the last 10 minutes.
     and (
       new.kind <> 'member_joined'
       or not exists (
         select 1 from public.notifications n
          where n.user_id = sm.user_id
            and n.trip_id = new.trip_id
            and n.kind = 'member_joined'
            and n.created_at > now() - interval '10 minutes'
       )
     );

  -- Same treatment for the host, if they're tracked outside squad_members.
  insert into public.notifications
    (user_id, trip_id, event_id, kind, title, body)
  select t.host_id,
         new.trip_id,
         new.id,
         new.kind,
         coalesce(new.payload->>'title', new.kind),
         new.payload->>'body'
    from public.trips t
   where t.id = new.trip_id
     and t.host_id is not null
     and t.host_id <> coalesce(
       new.actor_user_id,
       '00000000-0000-0000-0000-000000000000'::uuid
     )
     and not exists (
       select 1 from public.squad_members sm2
        where sm2.trip_id = new.trip_id and sm2.user_id = t.host_id
     )
     and (
       new.kind <> 'member_joined'
       or not exists (
         select 1 from public.notifications n
          where n.user_id = t.host_id
            and n.trip_id = new.trip_id
            and n.kind = 'member_joined'
            and n.created_at > now() - interval '10 minutes'
       )
     );

  return new;
end;
$$;
