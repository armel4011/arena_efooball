-- =============================================================================
-- ARENA — Retire le GRANT EXECUTE par défaut sur deux fonctions TRIGGER DEFINER
-- =============================================================================
-- Advisor `anon_security_definer_function_executable` : ces fonctions sont des
-- gestionnaires de trigger (returns trigger) qui, du fait du GRANT EXECUTE par
-- défaut à PUBLIC, apparaissent appelables par anon/authenticated via
-- /rest/v1/rpc. Ce n'est pas exploitable (elles échouent hors contexte trigger,
-- NEW/TG_OP absents), mais on retire l'exposition pour vider l'advisor et rester
-- aligné sur le principe « une fonction DEFINER n'est exécutable que par qui en
-- a besoin ». Les triggers continuent de les invoquer normalement : le firing
-- d'un trigger ne dépend PAS d'un GRANT EXECUTE.
-- =============================================================================

revoke execute on function public.notify_room_code_shared() from anon, authenticated, public;
revoke execute on function public._notify_support_message() from anon, authenticated, public;
