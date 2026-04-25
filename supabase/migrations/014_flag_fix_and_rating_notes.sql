-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Migration 014
--  1. Fix change_trip_destination so new flag always applies
--  2. RPC to fetch place ratings with voter profile + notes
-- ─────────────────────────────────────────────────────────────

create or replace function change_trip_destination(
  _trip_id         uuid,
  _destination     text,
  _flag            text default null,
  _country         text default null,
  _clear_itinerary boolean default true
) returns void language plpgsql security definer as $$
declare
  t record;
  new_flag text;
begin
  select * into t from trips where id = _trip_id;
  if t is null then raise exception 'trip not found'; end if;
  if t.host_id <> auth.uid() then
    raise exception 'only the host can change destination';
  end if;
  if _destination is null or length(trim(_destination)) = 0 then
    raise exception 'destination is required';
  end if;

  -- Always overwrite the flag on destination change. Caller should pass
  -- a flag (picked or looked up client-side). Fall back to 🌍 if none.
  -- Never silently keep the old flag — that was the Lisbon-keeps-Colombia
  -- bug.
  new_flag := coalesce(nullif(trim(_flag), ''), '🌍');

  if _clear_itinerary then
    delete from itinerary_items where trip_id = _trip_id;
  end if;

  update trips
     set selected_destination = trim(_destination),
         selected_flag = new_flag,
         status = case
           when status in ('collecting','voting') then 'revealed'
           else status
         end,
         updated_at = now()
   where id = _trip_id;

  insert into trip_events (trip_id, kind, actor_user_id, payload)
  values (
    _trip_id,
    'status_changed',
    auth.uid(),
    jsonb_build_object(
      'title', 'destination changed to ' || _destination,
      'destination', _destination,
      'flag', new_flag,
      'country', _country,
      'changed_by', auth.uid()
    )
  );
end $$;

-- ─────────────────────────────────────────────────────────────
-- Place ratings feed: union of direct place_ratings + ratings on
-- itinerary_items linked to the place. Includes voter profile + notes.
-- ─────────────────────────────────────────────────────────────
create or replace function place_ratings_feed(_place_id uuid)
returns table (
  id              uuid,
  user_id         uuid,
  user_nickname   text,
  user_emoji      text,
  user_avatar_url text,
  thumb           smallint,
  note            text,
  source          text,
  created_at      timestamptz
)
language sql security definer set search_path = public stable as $$
  select id, user_id, user_nickname, user_emoji, user_avatar_url,
         thumb, note, source, created_at
  from (
    select
      pr.id,
      pr.user_id,
      p.nickname       as user_nickname,
      p.emoji          as user_emoji,
      p.avatar_url     as user_avatar_url,
      pr.thumb,
      pr.note,
      'direct'::text   as source,
      pr.created_at
    from place_ratings pr
    join profiles p on p.id = pr.user_id
    where pr.place_id = _place_id
      and auth.uid() is not null

    union all

    select
      ir.id,
      ir.user_id,
      p.nickname       as user_nickname,
      p.emoji          as user_emoji,
      p.avatar_url     as user_avatar_url,
      ir.thumb,
      ir.note,
      'itinerary'::text as source,
      ir.created_at
    from itinerary_ratings ir
    join itinerary_items ii on ii.id = ir.item_id
    join profiles p on p.id = ir.user_id
    where ii.place_id = _place_id
      and ii.status = 'approved'
      and auth.uid() is not null
  ) combined
  order by created_at desc
  limit 50;
$$;

grant execute on function place_ratings_feed(uuid) to authenticated;
