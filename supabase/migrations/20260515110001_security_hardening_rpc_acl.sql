-- Phase 13.1 — Verrouillage des fonctions SECURITY DEFINER exposées en RPC.
--
-- Audit security flag : 7 fonctions SECURITY DEFINER étaient appelables
-- depuis /rest/v1/rpc/ par anon et/ou authenticated.
--
-- Stratégie :
--   - Triggers internes (auto_publish_*, on_payment_validated,
--     update_competition_player_count) : retirés de l'API publique
--     entièrement. Ils restent exécutables par le processus Postgres
--     pour leurs déclencheurs, mais ne peuvent plus être invoqués par
--     un client HTTP.
--   - is_admin() / is_super_admin() : restent appelables par
--     authenticated (utilisées dans nos policies RLS) mais retirées de
--     anon et public.
--   - delete_competition_cascade : pas touchée — déjà protégée par
--     is_admin() en interne + REVOKE/GRANT explicites dans sa migration
--     d'origine. (False positive de l'advisor générique.)

-- ─── Triggers internes (zéro accès via REST) ─────────────────────────
revoke all on function public.auto_publish_final_match() from public, anon, authenticated;
revoke all on function public.auto_publish_late_stream() from public, anon, authenticated;
revoke all on function public.on_payment_validated() from public, anon, authenticated;
revoke all on function public.update_competition_player_count() from public, anon, authenticated;

comment on function public.auto_publish_final_match() is
  'Trigger interne — pas appelable via RPC. Marque le stream de la finale '
  'comme publique automatiquement.';
comment on function public.auto_publish_late_stream() is
  'Trigger interne — pas appelable via RPC. Republie un stream en retard.';
comment on function public.on_payment_validated() is
  'Trigger interne — pas appelable via RPC. Side-effects après validation '
  'admin d''un paiement (registrations + revenue).';
comment on function public.update_competition_player_count() is
  'Trigger interne — pas appelable via RPC. Maintient '
  'competitions.current_players à jour.';

-- ─── Helpers RLS (authenticated uniquement) ──────────────────────────
revoke all on function public.is_admin() from public, anon;
revoke all on function public.is_super_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_super_admin() to authenticated;
