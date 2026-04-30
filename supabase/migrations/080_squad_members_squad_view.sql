-- Defensive: explicit SELECT policy so squad members can see their
-- whole squad. Required after migration 075 flipped trip_lockin_status
-- to security_invoker — the view counts squad_members rows under the
-- caller's RLS, and we want non-host members to see real counts, not
-- "1/1 squad locked in" from only counting their own row.
--
-- The original migration 001 policy ("Trip members can view squad")
-- only matches `host_id = auth.uid() OR user_id = auth.uid()`, which
-- would limit non-host visibility. The squad tab works in production
-- only because of a dashboard-created policy that isn't in source
-- control. This migration captures that intent in a versioned file.
--
-- Idempotent: drops by name first.

DROP POLICY IF EXISTS "Squad members can view their squad" ON public.squad_members;

CREATE POLICY "Squad members can view their squad"
  ON public.squad_members
  FOR SELECT
  USING (
    -- Caller is a member of the same trip (the EXISTS subquery is
    -- self-recursive but Postgres optimizes it; the inner reference
    -- to squad_members is the row being checked, the subquery looks
    -- for the caller as a fellow member).
    EXISTS (
      SELECT 1 FROM public.squad_members peer
      WHERE peer.trip_id = squad_members.trip_id
        AND peer.user_id = auth.uid()
    )
    -- Or the caller is the host of the trip.
    OR EXISTS (
      SELECT 1 FROM public.trips t
      WHERE t.id = squad_members.trip_id
        AND t.host_id = auth.uid()
    )
  );
