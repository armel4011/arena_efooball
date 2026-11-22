-- Audit 2026-11-22 (P3) — Retire le grant SELECT superflu de `birth_date` à anon.
--
-- `anon` n'a aucune ligne lisible sur `profiles` (policy `profiles_select` =
-- self OR is_admin) et `public_profiles` n'expose pas la colonne : le grant
-- SELECT à anon sur birth_date ne sert donc à rien et élargit inutilement la
-- surface PII si la policy venait à changer. On conserve INSERT/UPDATE (le
-- parcours d'inscription écrit birth_date), et SELECT reste accordé à
-- `authenticated` (lecture de son propre profil).
revoke select (birth_date) on public.profiles from anon;
