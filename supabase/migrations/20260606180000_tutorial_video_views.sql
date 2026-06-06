-- ============================================================================
-- Fenêtre d'affichage de la bannière tuto basée sur la PREMIÈRE IMPRESSION
-- ============================================================================
-- La bannière reste affichée `display_days` jours à partir du moment où
-- l'utilisateur la voit pour la PREMIÈRE FOIS (et non l'âge de son compte).
-- On mémorise, par (user, vidéo), l'instant de première vue. Une nouvelle
-- vidéo publiée (nouvel id) redémarre donc le compte à rebours pour tous.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.tutorial_video_views (
  user_id           uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  tutorial_video_id uuid NOT NULL REFERENCES public.tutorial_video (id) ON DELETE CASCADE,
  first_seen_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, tutorial_video_id)
);

COMMENT ON TABLE public.tutorial_video_views IS
  'Instant de premiere impression de la banniere tuto, par (user, video). '
  'La banniere s''affiche display_days jours apres first_seen_at.';

-- FK tutorial_video_id non couverte par la PK (qui commence par user_id).
CREATE INDEX IF NOT EXISTS idx_tutorial_video_views_video
  ON public.tutorial_video_views (tutorial_video_id);

ALTER TABLE public.tutorial_video_views ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tutorial_video_views_self_select ON public.tutorial_video_views;
CREATE POLICY tutorial_video_views_self_select
  ON public.tutorial_video_views FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS tutorial_video_views_self_insert ON public.tutorial_video_views;
CREATE POLICY tutorial_video_views_self_insert
  ON public.tutorial_video_views FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- RPC atomique : enregistre la 1re impression si absente, renvoie l'instant
-- de 1re impression (existant OU fraichement cree). SECURITY DEFINER ->
-- identite via auth.uid() ; le client ne fournit jamais le user_id.
CREATE OR REPLACE FUNCTION public.tutorial_record_and_get_view(p_tutorial_id uuid)
  RETURNS timestamptz
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_ts timestamptz;
begin
  if auth.uid() is null then
    return null;
  end if;
  insert into public.tutorial_video_views (user_id, tutorial_video_id)
    values (auth.uid(), p_tutorial_id)
    on conflict (user_id, tutorial_video_id) do nothing;
  select first_seen_at into v_ts
    from public.tutorial_video_views
    where user_id = auth.uid() and tutorial_video_id = p_tutorial_id;
  return v_ts;
end;
$function$;

REVOKE EXECUTE ON FUNCTION public.tutorial_record_and_get_view(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.tutorial_record_and_get_view(uuid) TO authenticated;
