-- Vidéo tutoriel de prise en main sur la home utilisateur.
--
-- Le super-admin renseigne UNE vidéo de prise en main (titre + lien vidéo
-- externe : YouTube, Vimeo, lien direct…) qui s'affiche cote user sur la
-- home sous forme de banniere. Au tap, le lien s'ouvre en EXTERNE via
-- url_launcher (LaunchMode.externalApplication).
--
-- Regle produit : UNE SEULE video active a la fois. Garantie par un index
-- unique partiel sur (is_active) WHERE is_active. Le repo Dart desactive
-- l'ancienne avant d'inserer la nouvelle. La section home ne s'affiche que
-- s'il existe une video active (sinon SizedBox.shrink).
--
-- Calque exact de `promo_banner` (memes patterns RLS / grant / realtime).

CREATE TABLE IF NOT EXISTS public.tutorial_video (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  video_url   TEXT NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  updated_by  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.tutorial_video IS
  'Video tutoriel de prise en main de la home utilisateur. Une seule active '
  'a la fois (cf. index unique partiel). Geree par le super-admin.';

-- Une seule video active simultanement.
CREATE UNIQUE INDEX IF NOT EXISTS tutorial_video_single_active
  ON public.tutorial_video (is_active)
  WHERE is_active;

-- Advisor perf 0001_unindexed_foreign_keys : index couvrant sur la FK
-- updated_by -> profiles(id) (ON DELETE SET NULL).
CREATE INDEX IF NOT EXISTS idx_tutorial_video_updated_by
  ON public.tutorial_video (updated_by);

-- ─── RLS ───────────────────────────────────────────────────────────────
ALTER TABLE public.tutorial_video ENABLE ROW LEVEL SECURITY;

-- READ : tout le monde (l'app user doit pouvoir afficher la video).
DROP POLICY IF EXISTS "tutorial_video_public_read" ON public.tutorial_video;
CREATE POLICY "tutorial_video_public_read"
  ON public.tutorial_video FOR SELECT
  TO anon, authenticated
  USING (TRUE);

-- WRITE : admins uniquement (is_admin() lit auth.uid() en interne, sans arg).
DROP POLICY IF EXISTS "tutorial_video_admin_insert" ON public.tutorial_video;
CREATE POLICY "tutorial_video_admin_insert"
  ON public.tutorial_video FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "tutorial_video_admin_update" ON public.tutorial_video;
CREATE POLICY "tutorial_video_admin_update"
  ON public.tutorial_video FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "tutorial_video_admin_delete" ON public.tutorial_video;
CREATE POLICY "tutorial_video_admin_delete"
  ON public.tutorial_video FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ─── Realtime ──────────────────────────────────────────────────────────
-- La home doit refleter en temps reel la publication / le retrait d'une
-- video par le super-admin (StreamProvider `activeTutorialVideoProvider`).
-- Idempotent : duplicate_object est avale si la table est deja publiee.
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.tutorial_video;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
