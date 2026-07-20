-- ─────────────────────────────────────────────────────────────────────
-- Audit 2026-07-20 (perf) — consolider les policies de app_release_config.
-- ─────────────────────────────────────────────────────────────────────
-- L'advisor `multiple_permissive_policies` signale 2 policies PERMISSIVE en
-- SELECT sur app_release_config : chaque SELECT évalue les deux.
--   • app_release_config_select        FOR SELECT  USING (true)
--   • app_release_config_write_admin   FOR ALL     USING (is_super_admin())
-- La policy ALL couvre aussi le SELECT — en pur doublon de `_select` (qui
-- autorise déjà toute lecture, c'est voulu : l'app lit la config de release
-- même pré-auth). On remplace `_write_admin` (ALL) par des policies bornées
-- aux ÉCRITURES → un seul chemin d'évaluation en lecture.
--
-- Comportement inchangé : lecture par tous (via `_select`), écriture réservée
-- au super-admin (via les 3 policies ci-dessous). Le `(select is_super_admin())`
-- garde l'optimisation initplan.

drop policy if exists app_release_config_write_admin  on public.app_release_config;
drop policy if exists app_release_config_insert_admin on public.app_release_config;
drop policy if exists app_release_config_update_admin on public.app_release_config;
drop policy if exists app_release_config_delete_admin on public.app_release_config;

create policy app_release_config_insert_admin on public.app_release_config
  for insert to public
  with check ((select public.is_super_admin()));

create policy app_release_config_update_admin on public.app_release_config
  for update to public
  using ((select public.is_super_admin()))
  with check ((select public.is_super_admin()));

create policy app_release_config_delete_admin on public.app_release_config
  for delete to public
  using ((select public.is_super_admin()));
