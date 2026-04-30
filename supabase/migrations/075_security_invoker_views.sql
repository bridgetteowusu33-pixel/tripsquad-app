-- Security hardening — flagged by Supabase advisor 2026-04-29
-- Seven views were created with the Postgres default `security_definer`
-- semantics, which means they execute with the OWNER's permissions
-- (typically postgres superuser). Net effect: callers bypass RLS on the
-- underlying tables when reading through the view.
--
-- The fix is `security_invoker = on` (Postgres 15+) so the view runs as
-- the CALLER and respects their RLS. None of these views needed definer
-- behavior — they were aggregates / joins over tables whose RLS already
-- expresses the right access model:
--
--   destination_hub        — joins over `places` (public read)
--   place_stats            — aggregate over `place_ratings` (public read)
--   item_rating_summary    — aggregate over `place_ratings` (public read)
--   kudos_counts           — aggregate over `kudos` (public read)
--   destination_summary    — aggregate over `destination_recaps` (public read)
--   trip_lockin_status     — trip-scoped; underlying tables (squad_members,
--                            booking_confirmations) have RLS allowing trip
--                            members. Invoker mode preserves that scoping.
--   pending_reports        — admin/service-role only. Invoker mode means
--                            anon + authenticated callers see nothing,
--                            which is the correct outcome.
--
-- Edge Functions use service-role and bypass RLS, so server-side reads
-- of these views keep working unchanged.

ALTER VIEW public.destination_hub      SET (security_invoker = on);
ALTER VIEW public.place_stats          SET (security_invoker = on);
ALTER VIEW public.item_rating_summary  SET (security_invoker = on);
ALTER VIEW public.kudos_counts         SET (security_invoker = on);
ALTER VIEW public.destination_summary  SET (security_invoker = on);
ALTER VIEW public.trip_lockin_status   SET (security_invoker = on);
ALTER VIEW public.pending_reports      SET (security_invoker = on);
