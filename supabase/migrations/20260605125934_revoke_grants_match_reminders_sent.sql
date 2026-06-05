-- =============================================================================
-- ARENA — Hygiène : révoque les grants résiduels sur match_reminders_sent
-- =============================================================================
-- `match_reminders_sent` a la RLS activée (20260531142535_fix_m1_enable_rls)
-- mais aucune policy → tout accès non-DEFINER est déjà bloqué, donc pas
-- exploitable. Toutefois la table conservait les grants par défaut
-- INSERT/SELECT/UPDATE/DELETE pour anon ET authenticated, ce qui :
--   1. déclenche l'advisor `rls_enabled_no_policy` (faux-signal récurrent) ;
--   2. est incohérent avec `totp_attempts` (même cas, grants révoqués).
--
-- On aligne sur `totp_attempts` : table purement interne, écrite/lue
-- uniquement par la fonction DEFINER `_dispatch_match_reminders()` (cron
-- match_reminders_minute) et le service_role. Aucun rôle applicatif ne doit
-- la toucher.
-- =============================================================================

revoke all on public.match_reminders_sent from anon, authenticated;
