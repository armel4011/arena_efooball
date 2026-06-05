-- Espace publicitaire sur la home utilisateur.
--
-- Le super-admin uploade UNE image de promotion (bucket public
-- `notification_images`, prefix `promo_banner/`) qui s'affiche cote user
-- sur la home. L'image est cliquable et redirige selon `redirect_type` :
--   - internal_page : une route interne de l'app (ex. /streams)
--   - web_link      : une URL web externe (https://…)
--   - whatsapp      : un numero WhatsApp (on construit wa.me cote client)
--
-- Regle produit : UNE SEULE banniere active a la fois. Garantie par un
-- index unique partiel sur (is_active) WHERE is_active. Le repo Dart
-- desactive l'ancienne avant d'inserer la nouvelle. La section home ne
-- s'affiche que s'il existe une banniere active (sinon SizedBox.shrink).

CREATE TABLE IF NOT EXISTS public.promo_banner (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url       TEXT NOT NULL,
  redirect_type   TEXT NOT NULL
                    CHECK (redirect_type IN ('internal_page', 'web_link', 'whatsapp')),
  redirect_target TEXT NOT NULL,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  updated_by      UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.promo_banner IS
  'Banniere publicitaire de la home utilisateur. Une seule active a la fois '
  '(cf. index unique partiel). Geree par le super-admin.';

-- Une seule banniere active simultanement.
CREATE UNIQUE INDEX IF NOT EXISTS promo_banner_single_active
  ON public.promo_banner (is_active)
  WHERE is_active;

-- ─── RLS ───────────────────────────────────────────────────────────────
ALTER TABLE public.promo_banner ENABLE ROW LEVEL SECURITY;

-- READ : tout le monde (l'app user doit pouvoir afficher la banniere).
DROP POLICY IF EXISTS "promo_banner_public_read" ON public.promo_banner;
CREATE POLICY "promo_banner_public_read"
  ON public.promo_banner FOR SELECT
  TO anon, authenticated
  USING (TRUE);

-- WRITE : admins uniquement (is_admin() lit auth.uid() en interne, sans arg).
DROP POLICY IF EXISTS "promo_banner_admin_insert" ON public.promo_banner;
CREATE POLICY "promo_banner_admin_insert"
  ON public.promo_banner FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "promo_banner_admin_update" ON public.promo_banner;
CREATE POLICY "promo_banner_admin_update"
  ON public.promo_banner FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "promo_banner_admin_delete" ON public.promo_banner;
CREATE POLICY "promo_banner_admin_delete"
  ON public.promo_banner FOR DELETE
  TO authenticated
  USING (public.is_admin());
