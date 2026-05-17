-- Corrige l'erreur 42501 "permission denied for function is_admin"
-- côté app user au démarrage (avant hydratation de session, le rôle
-- effectif est anon). Plusieurs policies RLS (profiles_select,
-- profiles_update, streams_select, chat_messages_select, disputes_*,
-- etc.) appellent is_admin() dans leur USING/WITH CHECK — si anon n'a
-- pas EXECUTE, la policy lève 42501 au lieu d'évaluer la branche
-- "self" qui aurait permis l'opération.
--
-- is_admin() / is_super_admin() / is_blocked_pair() sont SECURITY
-- DEFINER avec check interne `where id = auth.uid()`. Quand auth.uid()
-- est NULL (anon), elles retournent simplement `false` — donner
-- EXECUTE à anon ne fuit aucune information sensible.

GRANT EXECUTE ON FUNCTION public.is_admin() TO anon;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO anon;
GRANT EXECUTE ON FUNCTION public.is_blocked_pair(uuid, uuid) TO anon;
