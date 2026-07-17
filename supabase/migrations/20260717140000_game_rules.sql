-- ============================================================================
-- Règles du jeu par jeu (affichées sur l'écran de verrouillage de la salle)
-- ============================================================================
-- Les règles d'un jeu (eFootball, EA SPORTS FC, Dames) ne changent pas d'un
-- tournoi à l'autre : on les stocke UNE fois par jeu, éditables par l'admin,
-- lues par tous. Elles s'affichent (avec la vidéo `match_locked`) tant que la
-- salle est verrouillée, pour que le joueur révise avant le coup d'envoi.
--
-- Jusqu'ici les « règles » n'existaient pas en donnée : elles étaient noyées
-- dans `competitions.description` (texte libre, par tournoi) ou dans des
-- modèles admin stockés en SharedPreferences locales (par appareil, non
-- partagés). Cette table en fait une donnée unique, partagée et versionnée.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.game_rules (
  game        text PRIMARY KEY
                CHECK (game IN ('efootball', 'draughts', 'ea_sports_fc')),
  rules_text  text NOT NULL,
  updated_by  uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.game_rules IS
  'Règles d''un jeu, une ligne par jeu (miroir de competitions.game). '
  'Editées par l''admin, lues par tous, affichees sur l''ecran de '
  'verrouillage de la salle de match.';

-- Advisor perf 0001_unindexed_foreign_keys : index couvrant la FK updated_by.
CREATE INDEX IF NOT EXISTS idx_game_rules_updated_by
  ON public.game_rules (updated_by);

-- ─── RLS ───────────────────────────────────────────────────────────────────
ALTER TABLE public.game_rules ENABLE ROW LEVEL SECURITY;

-- READ : tout le monde (le joueur doit voir les règles sur l'écran verrouillé).
DROP POLICY IF EXISTS "game_rules_public_read" ON public.game_rules;
CREATE POLICY "game_rules_public_read"
  ON public.game_rules FOR SELECT
  TO anon, authenticated
  USING (TRUE);

-- WRITE : admins uniquement (is_admin() lit auth.uid() en interne).
DROP POLICY IF EXISTS "game_rules_admin_insert" ON public.game_rules;
CREATE POLICY "game_rules_admin_insert"
  ON public.game_rules FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "game_rules_admin_update" ON public.game_rules;
CREATE POLICY "game_rules_admin_update"
  ON public.game_rules FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "game_rules_admin_delete" ON public.game_rules;
CREATE POLICY "game_rules_admin_delete"
  ON public.game_rules FOR DELETE
  TO authenticated
  USING (public.is_admin());
