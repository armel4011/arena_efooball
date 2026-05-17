-- Retire l'accès anon à delete_competition_cascade.
-- La fonction reste SECURITY DEFINER (légitime, action admin escaladée)
-- et conserve son check interne `if not public.is_admin() then raise`.
-- L'exposition à anon était signalée par advisor anon_security_definer_function_executable.

REVOKE EXECUTE ON FUNCTION public.delete_competition_cascade(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.delete_competition_cascade(uuid) FROM PUBLIC;
-- authenticated et service_role conservent EXECUTE
