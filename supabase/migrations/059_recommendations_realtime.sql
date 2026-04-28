-- v1.1 — Stays + Eats hotfix
-- Without REPLICA IDENTITY FULL, the supabase_realtime publication
-- can ACK the table but the subscription handshake times out from
-- the client side ("Realtime SubscribeStatus.timedOut"). Same fix
-- as migration 031 applied to itinerary_items — we want the FULL
-- row in change events so the Flutter stream gets a complete payload
-- on INSERT (and UPDATE/DELETE later).

ALTER TABLE public.trip_recommendations REPLICA IDENTITY FULL;

-- Belt-and-suspenders: re-add to the publication. Idempotent —
-- ALTER PUBLICATION ... ADD TABLE is a no-op when the table is
-- already a member.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'trip_recommendations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.trip_recommendations;
  END IF;
END $$;
