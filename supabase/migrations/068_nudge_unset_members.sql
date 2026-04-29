-- v1.2 — Phase 2 booking layer
-- nudge_unset_members(): host taps a button → squad members who
-- haven't booked yet for the given kind get a single notification
-- ("the squad is waiting on you for flights"). Existing send_push
-- webhook on notifications INSERT fires FCM.
--
-- Throttle: 24h per recipient per (trip, kind) so the host can't
-- spam — re-running within the window is a no-op.
--
-- Returns: count of notifications inserted (informational; the
-- Flutter caller surfaces this in a snackbar).
--
-- Auth: SECURITY DEFINER + explicit host check inside. Only the trip
-- host can dispatch.

CREATE OR REPLACE FUNCTION public.nudge_unset_members(
  _trip_id uuid,
  _kind text
)
RETURNS int LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  inserted int := 0;
  is_host  bool;
  trip_name text;
BEGIN
  IF _kind NOT IN ('flight', 'accommodation') THEN
    RAISE EXCEPTION 'invalid kind: %', _kind;
  END IF;

  -- Host check.
  SELECT (host_id = auth.uid()), name
    INTO is_host, trip_name
    FROM public.trips
   WHERE id = _trip_id;
  IF NOT coalesce(is_host, false) THEN
    RAISE EXCEPTION 'only the host can nudge';
  END IF;

  -- Insert one notification per joined squad member who has NOT
  -- confirmed this kind AND hasn't been nudged for this kind in the
  -- last 24h.
  WITH ins AS (
    INSERT INTO public.notifications
      (user_id, trip_id, kind, title, body)
    SELECT sm.user_id,
           _trip_id,
           'nudge_book',
           CASE
             WHEN _kind = 'flight' THEN 'the squad is waiting on your flight ✈️'
             ELSE 'the squad is waiting on your stay 🏨'
           END,
           'lock in your ' || _kind || ' for '
             || coalesce(trip_name, 'the trip') || ' so we can really go'
      FROM public.squad_members sm
     WHERE sm.trip_id = _trip_id
       AND sm.user_id IS NOT NULL
       AND sm.user_id <> auth.uid()  -- don't nudge yourself
       AND NOT EXISTS (
         SELECT 1 FROM public.booking_confirmations bc
          WHERE bc.trip_id = _trip_id
            AND bc.user_id = sm.user_id
            AND bc.kind = _kind
       )
       AND NOT EXISTS (
         SELECT 1 FROM public.notifications n
          WHERE n.user_id = sm.user_id
            AND n.trip_id = _trip_id
            AND n.kind = 'nudge_book'
            AND n.title LIKE
              CASE WHEN _kind = 'flight' THEN '%flight%' ELSE '%stay%' END
            AND n.created_at > now() - interval '24 hours'
       )
    RETURNING 1
  )
  SELECT count(*) INTO inserted FROM ins;

  RETURN inserted;
END $$;

GRANT EXECUTE ON FUNCTION public.nudge_unset_members(uuid, text) TO authenticated;
