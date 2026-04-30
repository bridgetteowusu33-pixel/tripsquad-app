-- Hotfix for migration 080.
--
-- Migration 080 added a SELECT policy on squad_members whose USING
-- clause queried squad_members itself, which triggers infinite RLS
-- recursion (Postgres re-evaluates the policy for every row of the
-- inner subquery). Symptom: home tab errors with
--   "infinite recursion detected in policy for relation squad_members"
-- on any read of squad_members or anything that joins it.
--
-- Fix: drop the recursive policy, then replace with one that uses a
-- SECURITY DEFINER helper function. The helper bypasses RLS on its
-- own internal query (because definer functions run as the function
-- owner), so the recursion stops there.

DROP POLICY IF EXISTS "Squad members can view their squad" ON public.squad_members;

-- Helper: does the caller have a squad_members row in this trip?
-- Definer + revoked-from-anon. This function is the building block
-- for any "trip-member" gate elsewhere in the schema too.
CREATE OR REPLACE FUNCTION public._caller_is_in_trip(_trip_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.squad_members
    WHERE trip_id = _trip_id
      AND user_id = auth.uid()
  );
$$;

REVOKE EXECUTE ON FUNCTION public._caller_is_in_trip(uuid) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public._caller_is_in_trip(uuid) TO   authenticated;

-- Recreate the policy using the helper — no recursion.
CREATE POLICY "Squad members can view their squad"
  ON public.squad_members
  FOR SELECT
  USING (
    public._caller_is_in_trip(trip_id)
    OR EXISTS (
      SELECT 1 FROM public.trips t
      WHERE t.id = squad_members.trip_id
        AND t.host_id = auth.uid()
    )
  );
