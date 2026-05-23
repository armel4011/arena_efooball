-- ─────────────────────────────────────────────────────────────────────
-- Sécurité — durcit les RPCs admin_run_cleanup_* (finding #4 audit
-- 2026-05-23).
-- ─────────────────────────────────────────────────────────────────────
-- Les fonctions admin_run_cleanup_deleted_accounts() et
-- admin_run_cleanup_streams() avaient un gate interne
--   `if not exists (... role = 'super_admin') then raise 'forbidden_role'`
-- mais étaient GRANT EXECUTE TO authenticated. Donc tout user
-- authentifié pouvait spammer l'appel et déclencher des raise
-- exceptions à répétition (DoS de bruit, pas de fonctionnel).
--
-- Aucun fichier `.dart` du repo ne référence ces RPCs (grep confirmé) :
-- seuls les crons (qui tournent en `postgres`) les invoquent. On peut
-- donc revoke proprement de `authenticated` sans rien casser.
-- `service_role` conservé pour permettre un appel manuel par un admin
-- via la clé service (back-office / scripts ops).
-- ─────────────────────────────────────────────────────────────────────

revoke execute on function public.admin_run_cleanup_deleted_accounts() from authenticated;
revoke execute on function public.admin_run_cleanup_streams() from authenticated;
