-- =============================================================================
-- ARENA — Phase 0 — Hotfix RLS profiles
-- Corrige l'erreur "permission denied for function is_admin" rencontrée par
-- les clients anon/authenticated lors d'un SELECT sur public.profiles (et
-- toute autre table dont une policy "for all" admin référence is_admin()).
--
-- Cause : les helpers public.is_admin() / public.is_super_admin() n'avaient
-- pas de GRANT EXECUTE pour les rôles anon/authenticated. Comme une policy
-- permissive "for all" applicable à la requête est évaluée même quand une
-- autre policy permissive matche déjà, Postgres tente d'exécuter is_admin()
-- pour le rôle courant et échoue faute de droit.
-- =============================================================================
-- Dépend de : 20260505100005
-- =============================================================================

-- 1. Donne le droit d'exécuter les helpers aux rôles client.
--    Sûr : les fonctions sont SECURITY DEFINER avec search_path verrouillé
--    et renvoient un simple booléen. Pour anon, auth.uid() est NULL donc
--    is_admin() renvoie systématiquement false.
grant execute on function public.is_admin()       to anon, authenticated;
grant execute on function public.is_super_admin() to anon, authenticated;

-- 2. Restreint les policies admin "for all" au rôle authenticated.
--    Évite d'évaluer is_admin() pour les requêtes anon (perf + clarté).
--    On recrée les policies avec la même logique mais scope `to authenticated`.

-- profiles
-- NB: appel wrappé dans (select …) pour éviter une évaluation par ligne
-- (best practice Supabase : la fonction est appelée une fois et cachée
-- pour toute la requête au lieu d'être ré-exécutée à chaque ligne).
drop policy if exists "profiles_admin_all" on public.profiles;
create policy "profiles_admin_all"
  on public.profiles for all
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));
