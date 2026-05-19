-- ════════════════════════════════════════════════════════════════════
-- Bug fix : signup cassé par audit RPC ACL (anon revoke trop large)
-- ════════════════════════════════════════════════════════════════════
-- Test phone 2026-05-19 : "Une erreur est survenue. Réessaie" sur
-- création de compte. Logs Postgres :
--   ERROR: permission denied for function is_admin
--
-- Cause : migration 20260519160000_rpc_acl_revoke_anon_security_definer
-- a révoqué EXECUTE sur is_admin/is_super_admin/is_blocked_pair pour
-- anon. Mais ces fonctions sont utilisées par des RLS policies sur
-- 30+ tables (profiles_insert CHECK, competitions_*, phases_*,
-- groups_*, prizes_*, app_config_*, banned_words_*, invitation_codes_*).
-- Anon doit pouvoir les évaluer au signup → ERROR remonte côté flutter
-- comme UnknownAuthFailure → snackbar "Une erreur est survenue".
--
-- Fix : restaurer GRANT EXECUTE à anon. Le revoke initial visait à
-- empêcher l'énumération via POST /rest/v1/rpc/is_admin, mais l'expose
-- est minime (la fonction retourne false pour auth.uid()=NULL → un
-- attacker apprend juste que les fonctions existent, info publique
-- documentée). Documenté comme intentionnel WARN dans l'advisor.

GRANT EXECUTE ON FUNCTION public.is_admin() TO anon;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO anon;
GRANT EXECUTE ON FUNCTION public.is_blocked_pair(uuid, uuid) TO anon;

COMMENT ON FUNCTION public.is_admin() IS
  '[SECURITY DEFINER intentional] Helper. Bypass RLS profiles pour lire role de auth.uid() (returns false si NULL). EXECUTE granted to anon ET authenticated parce que utilisée par RLS policies sur profiles_insert/competitions_*/phases_*/etc — anon doit pouvoir évaluer lors du signup.';

COMMENT ON FUNCTION public.is_super_admin() IS
  '[SECURITY DEFINER intentional] Helper. Bypass RLS profiles pour lire role de auth.uid() (returns false si NULL). EXECUTE granted to anon ET authenticated (utilisée en RLS).';

COMMENT ON FUNCTION public.is_blocked_pair(uuid, uuid) IS
  '[SECURITY DEFINER intentional] Helper. Bypass RLS friendships pour vérifier blocage entre deux users. EXECUTE granted to anon (RLS chat_messages_no_blocked_pair l''utilise).';
