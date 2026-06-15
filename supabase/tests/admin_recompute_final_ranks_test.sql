-- ════════════════════════════════════════════════════════════════════
-- pgTAP — ACL de la RPC admin_recompute_final_ranks
-- ════════════════════════════════════════════════════════════════════
-- La RPC (20260615160000) expose compute_competition_final_ranks à la console
-- admin (bouton « Recalculer »). On vérifie l'existence + l'ACL : exécutable
-- par `authenticated` (la garde is_admin() filtre ensuite), interdite à `anon`.
-- (La logique de classement elle-même est couverte par competition_finalize_test.)
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(3);

select has_function('public', 'admin_recompute_final_ranks', array['uuid']);
select ok(
  has_function_privilege('authenticated', 'public.admin_recompute_final_ranks(uuid)', 'execute'),
  'authenticated peut exécuter la RPC (garde is_admin interne)');
select ok(
  not has_function_privilege('anon', 'public.admin_recompute_final_ranks(uuid)', 'execute'),
  'anon ne peut PAS exécuter la RPC');

select * from finish();
rollback;
