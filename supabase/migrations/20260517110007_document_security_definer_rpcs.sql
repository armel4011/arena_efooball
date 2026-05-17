-- Documente les 15 fonctions SECURITY DEFINER exposées côté REST
-- signalées par l'advisor `authenticated_security_definer_function_executable`.
--
-- Chacune a un check d'autorisation interne (`auth.uid()`, `is_admin()`,
-- ou `role = 'super_admin'`) qui rend l'exposition sûre. SECURITY DEFINER
-- est requis pour bypasser les RLS qui bloqueraient l'écriture / la
-- lecture transverse sinon.
--
-- L'advisor restera WARN par design — c'est le pattern Supabase
-- recommandé pour des RPC user-actionnable avec escalation contrôlée.
-- Ces commentaires servent à un futur reviewer humain pour identifier
-- le pattern voulu sans creuser dans chaque corps.

-- ─── Helpers (lecture transverse de profiles / friendships) ──────────────
COMMENT ON FUNCTION public.is_admin() IS
  '[SECURITY DEFINER intentional] Helper. Bypass RLS profiles pour lire role de auth.uid(). Authorization: auth.uid() implicit (returns false if NULL).';

COMMENT ON FUNCTION public.is_super_admin() IS
  '[SECURITY DEFINER intentional] Helper. Bypass RLS profiles pour lire role de auth.uid(). Authorization: auth.uid() implicit (returns false if NULL).';

COMMENT ON FUNCTION public.is_blocked_pair(p_user_a uuid, p_user_b uuid) IS
  '[SECURITY DEFINER intentional] Helper. Bypass RLS friendships pour vérifier blocage entre deux users (un tiers ne peut pas lire la table). Pas de check auth — fonction pure.';

COMMENT ON FUNCTION public.friend_pending_count() IS
  '[SECURITY DEFINER intentional] User RPC read-only. Compte les requêtes d''ami en attente côté addressee_id = auth.uid(). Bypass RLS pour permettre count direct.';

-- ─── User RPC friendships (write) ────────────────────────────────────────
COMMENT ON FUNCTION public.send_friend_request(p_target uuid) IS
  '[SECURITY DEFINER intentional] User RPC. INSERT friendships(requester=auth.uid(), addressee=p_target). Authorization: requester_id = auth.uid() (forcé par la fonction).';

COMMENT ON FUNCTION public.accept_friend_request(p_friendship_id uuid) IS
  '[SECURITY DEFINER intentional] User RPC. UPDATE friendships.status=accepted. Authorization: addressee_id = auth.uid() vérifié sur la row ciblée.';

COMMENT ON FUNCTION public.decline_friend_request(p_friendship_id uuid) IS
  '[SECURITY DEFINER intentional] User RPC. UPDATE friendships.status=declined. Authorization: addressee_id = auth.uid() vérifié sur la row ciblée.';

COMMENT ON FUNCTION public.remove_friend(p_target uuid) IS
  '[SECURITY DEFINER intentional] User RPC. DELETE friendships où la paire inclut auth.uid(). Authorization: auth.uid() forcément dans (requester_id, addressee_id) de la row.';

COMMENT ON FUNCTION public.block_user(p_target uuid) IS
  '[SECURITY DEFINER intentional] User RPC. INSERT/UPDATE friendships(state=blocked) en marquant blocked_by = auth.uid(). Authorization: blocker_id = auth.uid() (forcé).';

COMMENT ON FUNCTION public.unblock_user(p_target uuid) IS
  '[SECURITY DEFINER intentional] User RPC. UPDATE friendships pour retirer le blocage. Authorization: blocked_by = auth.uid() (seul le blocker peut débloquer).';

-- ─── Admin / Super-admin RPC (privileged actions) ────────────────────────
COMMENT ON FUNCTION public.delete_competition_cascade(p_competition_id uuid) IS
  '[SECURITY DEFINER intentional] Admin RPC. DELETE cascade sur payouts/platform_revenue/payments/competitions. Authorization: is_admin() — raises forbidden sinon. EXECUTE révoqué de anon (migration 20260517110003).';

COMMENT ON FUNCTION public.admin_run_cleanup_deleted_accounts() IS
  '[SECURITY DEFINER intentional] Super-admin RPC. Trigger l''EF cleanup-deleted-accounts via net.http_post (privileged). Authorization: profiles.role = ''super_admin'' — raises forbidden_role sinon.';

COMMENT ON FUNCTION public.admin_run_cleanup_streams() IS
  '[SECURITY DEFINER intentional] Super-admin RPC. Trigger l''EF cleanup-streams via net.http_post (privileged). Authorization: profiles.role = ''super_admin'' — raises forbidden_role sinon.';

COMMENT ON FUNCTION public.recalculate_player_stats(p_player_id uuid) IS
  '[SECURITY DEFINER intentional] Super-admin RPC. UPDATE profiles.stats pour un player. Bypass RLS profiles. Authorization: profiles.role = ''super_admin'' — raises forbidden_role sinon.';

COMMENT ON FUNCTION public.recalculate_all_player_stats() IS
  '[SECURITY DEFINER intentional] Super-admin RPC. Itère tous les players completed et appelle recalculate_player_stats. Authorization: profiles.role = ''super_admin'' — raises forbidden_role sinon.';
