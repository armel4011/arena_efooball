-- Alignement repo ↔ prod (audit sécu 2026-05-23).
--
-- La migration 20260518170817_admin_filter_users_multi_competition_c2
-- a ajouté une 10-arg overload de admin_filter_users (avec
-- p_competition_ids uuid[]) sans dropper la 9-arg pré-existante créée
-- en 20260515130001. Les 2 ont coexisté en prod jusqu'au 2026-05-23.
--
-- Effet bord du hardening DEFINER (20260523100000) : CREATE OR REPLACE
-- a remplacé la 10-arg mais laissé la 9-arg en SECURITY INVOKER. Un
-- appelant Dart passe toujours 10 paramètres nommés, donc la 9-arg
-- n'était pas atteignable côté app ; mais un client REST/RPC custom
-- aurait pu invoquer la 9-arg en passant exactement les 9 premiers
-- params, et donc contourner le gate is_admin() du body.
--
-- Cette migration a été appliquée manuellement en prod via la
-- Management API le 2026-05-23 (la commande db push n'a pas pu être
-- utilisée à cause d'une divergence d'historique MCP/CLI — 60
-- migrations remote-only). On la versionne ici pour garantir que tout
-- nouveau staging passe par le même état final.

DROP FUNCTION IF EXISTS public.admin_filter_users(
  p_country_code text,
  p_status text,
  p_search text,
  p_won boolean,
  p_paid boolean,
  p_rewarded boolean,
  p_disputed boolean,
  p_guilty_min integer,
  p_limit integer
);
