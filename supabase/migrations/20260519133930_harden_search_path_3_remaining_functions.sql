-- ════════════════════════════════════════════════════════════════════
-- Phase 3/4 — Harden search_path sur 3 fonctions custom restantes
-- ════════════════════════════════════════════════════════════════════
-- L'advisor `function_search_path_mutable` flagge ces 3 functions qui
-- n'ont pas `SET search_path = ...` explicite. Risque : un attacker
-- avec privilège CREATE sur n'importe quel schéma peut shadow une
-- fonction sans schéma préfixe (table_name au lieu de public.table_name)
-- pour intercepter les appels. Mitigation : forcer `public` en search_path.

ALTER FUNCTION public.next_power_of_two(integer) SET search_path = public;
ALTER FUNCTION public.gen_referral_code() SET search_path = public;
ALTER FUNCTION public.ensure_referral_code() SET search_path = public;
