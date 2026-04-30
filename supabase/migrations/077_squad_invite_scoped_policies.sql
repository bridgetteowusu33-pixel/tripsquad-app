-- Security hardening — Supabase advisor warnings 2026-04-29
--
-- The two `WITH CHECK (true)` policies on squad_members
-- (`anon_squad_insert`, `squad_insert`) were created via the dashboard
-- to support the public web invite flow at gettripsquad.com/join/<token>,
-- where anon visitors POST a squad_members row directly via PostgREST
-- using the trip_id they look up from `invite_token`.
--
-- The intent was right but the policy was too broad — it allowed
-- inserting ANY squad_members row for ANY trip, not just trips that
-- have an active invite token. Replace with a scoped policy that
-- requires the target trip to actually be invitable.
--
-- The existing "Host can manage squad" policy (migration 001) keeps
-- handling the in-app "host adds member by tag" path, so we don't need
-- to maintain a parallel authenticated-user policy here.

DROP POLICY IF EXISTS anon_squad_insert ON public.squad_members;
DROP POLICY IF EXISTS squad_insert      ON public.squad_members;

CREATE POLICY "Web invite can insert via active token"
  ON public.squad_members
  FOR INSERT
  WITH CHECK (
    -- Insert is allowed only when the target trip has an invite token
    -- set (which is how the web form found this trip in the first place).
    -- Tightens "anyone can insert anywhere" to "anyone can insert into
    -- a trip that's accepting invitees."
    EXISTS (
      SELECT 1 FROM public.trips t
      WHERE t.id = squad_members.trip_id
        AND t.invite_token IS NOT NULL
    )
  );

-- ── Lock down the moderation view from regular API access ─────
-- pending_reports is admin-only signal. Migration 075 flipped it to
-- security_invoker (so it respects caller RLS), and now we revoke
-- direct API access too — service-role still works for dashboards
-- and admin tooling.
REVOKE SELECT ON public.pending_reports FROM anon, authenticated;
