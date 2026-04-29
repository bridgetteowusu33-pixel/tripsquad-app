-- v1.2 — Booking Layer, step 3 of 3
-- trip_lockin_status view: derives the squad lock-in counters that
-- feed the trip-header chip ("3/6 squad locked in"), Plan tab badge,
-- and the lock-in-advance push notification trigger. Pure derivation
-- — refreshes implicitly when underlying tables change, no
-- materialization needed at this scale.
--
-- Squad size = squad_members count (does NOT include host unless
-- host has a squad_members row). Hosts always have a squad_members
-- row in current schema, so squad_size is correct.

CREATE OR REPLACE VIEW public.trip_lockin_status AS
SELECT
  t.id AS trip_id,
  COUNT(DISTINCT sm.user_id) AS squad_size,
  COUNT(DISTINCT CASE WHEN bc.kind = 'flight' THEN bc.user_id END)
    AS flights_booked,
  COUNT(DISTINCT CASE WHEN bc.kind = 'accommodation' THEN bc.user_id END)
    AS accommodation_booked,
  -- Lock-in % per kind, NULL when squad_size = 0
  CASE
    WHEN COUNT(DISTINCT sm.user_id) = 0 THEN NULL
    ELSE
      ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN bc.kind = 'flight' THEN bc.user_id END)
        / COUNT(DISTINCT sm.user_id)
      )
  END AS flight_lockin_pct,
  CASE
    WHEN COUNT(DISTINCT sm.user_id) = 0 THEN NULL
    ELSE
      ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN bc.kind = 'accommodation' THEN bc.user_id END)
        / COUNT(DISTINCT sm.user_id)
      )
  END AS accommodation_lockin_pct,
  tbd_f.deadline_at AS flight_deadline,
  tbd_a.deadline_at AS accommodation_deadline
FROM public.trips t
LEFT JOIN public.squad_members sm ON sm.trip_id = t.id
LEFT JOIN public.booking_confirmations bc ON bc.trip_id = t.id
LEFT JOIN public.trip_booking_deadlines tbd_f
  ON tbd_f.trip_id = t.id AND tbd_f.kind = 'flight'
LEFT JOIN public.trip_booking_deadlines tbd_a
  ON tbd_a.trip_id = t.id AND tbd_a.kind = 'accommodation'
GROUP BY t.id, tbd_f.deadline_at, tbd_a.deadline_at;

GRANT SELECT ON public.trip_lockin_status TO authenticated;
