-- ============================================================================
-- Drapeaux « déjà vu » one-shot par utilisateur (onboarding contextuel)
-- ============================================================================
-- Certains contenus d'aide ne doivent s'afficher qu'UNE fois par utilisateur :
-- p. ex. le dialogue d'intro de rôle (DOMICILE / EXTÉRIEUR) à la 1re salle de
-- match football. On mémorise, par (utilisateur, drapeau), le fait de l'avoir
-- vu. Le drapeau est une chaîne libre côté client (`match_role_intro:home`,
-- `match_role_intro:away`, …), ce qui rend la table réutilisable pour tout
-- futur one-shot sans nouvelle migration.
--
-- Miroir serveur (par compte, multi-appareil) plutôt que SharedPreferences
-- local, cohérent avec `tutorial_video_views`.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.user_onboarding_seen (
  user_id  uuid        NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  flag     text        NOT NULL CHECK (length(flag) BETWEEN 1 AND 100),
  seen_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, flag)
);

COMMENT ON TABLE public.user_onboarding_seen IS
  'Drapeaux « deja vu » one-shot par (user, flag). Le client marque un flag '
  'via onboarding_mark_seen_once() qui renvoie true la 1re fois seulement.';

ALTER TABLE public.user_onboarding_seen ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_onboarding_seen_self_select ON public.user_onboarding_seen;
CREATE POLICY user_onboarding_seen_self_select
  ON public.user_onboarding_seen FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS user_onboarding_seen_self_insert ON public.user_onboarding_seen;
CREATE POLICY user_onboarding_seen_self_insert
  ON public.user_onboarding_seen FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- RPC atomique : marque le drapeau pour le user courant et renvoie TRUE si
-- c'était la 1re fois (ligne fraîchement insérée), FALSE si déjà vu. Le client
-- n'affiche le contenu one-shot que sur TRUE. SECURITY DEFINER -> identité via
-- auth.uid() ; le client ne fournit jamais le user_id.
CREATE OR REPLACE FUNCTION public.onboarding_mark_seen_once(p_flag text)
  RETURNS boolean
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_count integer;
begin
  if auth.uid() is null then
    return false;
  end if;
  insert into public.user_onboarding_seen (user_id, flag)
    values (auth.uid(), p_flag)
    on conflict (user_id, flag) do nothing;
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$function$;

REVOKE EXECUTE ON FUNCTION public.onboarding_mark_seen_once(text) FROM anon;
GRANT EXECUTE ON FUNCTION public.onboarding_mark_seen_once(text) TO authenticated;
