-- ════════════════════════════════════════════════════════════════════
-- Durcissement ACL — fonctions de classement/clôture INTERNES (audit 2026-06-15)
-- ════════════════════════════════════════════════════════════════════
-- P1 (régression de privilège) : `compute_competition_final_ranks`,
-- `recalculate_group_standings` et `finalize_competition_if_complete` sont des
-- fonctions SECURITY DEFINER MUTANTES, sans garde `is_admin()`, censées n'être
-- appelées QUE par des triggers et par `admin_recompute_final_ranks` (toujours
-- en contexte definer). Leurs migrations d'origine faisaient `revoke … from
-- public, anon` — mais ça NE retire PAS le grant EXECUTE par défaut du schéma
-- `public` à `authenticated`. Résultat : tout utilisateur connecté pouvait les
-- appeler via PostgREST `/rest/v1/rpc/…` et :
--   * réécrire `competition_registrations.final_rank` de n'importe quelle compétition,
--   * écraser `group_memberships` (classement live) de n'importe quel groupe,
--   * forcer une compétition en `completed` + déclencher les notifications.
--
-- Correctif : révoquer EXECUTE pour `authenticated`. Sans régression — l'owner
-- (postgres) conserve EXECUTE, donc triggers + `admin_recompute_final_ranks`
-- (SECURITY DEFINER) continuent d'invoquer ces fonctions. Validé en prod par
-- ROLLBACK (clôture single-elim : status=completed, champion=rang 1, 4 notifs).
-- `admin_recompute_final_ranks` reste exposé à authenticated (gardé `is_admin()`).
-- ════════════════════════════════════════════════════════════════════

revoke execute on function public.compute_competition_final_ranks(uuid) from authenticated;
revoke execute on function public.recalculate_group_standings(uuid)     from authenticated;
revoke execute on function public.finalize_competition_if_complete(uuid) from authenticated;

-- Fonctions de trigger : non appelables en RPC (RETURNS trigger), mais on aligne
-- l'ACL sur la convention de durcissement (supprime 2 advisors WARN
-- anon_security_definer_function_executable).
revoke execute on function public.trigger_recalc_group_standings() from anon, authenticated, public;
revoke execute on function public.trigger_finalize_competition()  from anon, authenticated, public;
