-- ════════════════════════════════════════════════════════════════════
-- competitions.android_store_url + ios_store_url (item 1 prompt 2026-05-19)
-- ════════════════════════════════════════════════════════════════════
-- L'admin peut désormais attacher 2 liens stores au choix du jeu de
-- la compétition. Côté user, la page registration_confirm affiche 2
-- boutons "Télécharger sur Android" / "Télécharger sur iOS".

ALTER TABLE public.competitions
  ADD COLUMN IF NOT EXISTS android_store_url text,
  ADD COLUMN IF NOT EXISTS ios_store_url text;

ALTER TABLE public.competitions
  ADD CONSTRAINT competitions_android_store_url_format
  CHECK (android_store_url IS NULL OR android_store_url ~ '^https?://');

ALTER TABLE public.competitions
  ADD CONSTRAINT competitions_ios_store_url_format
  CHECK (ios_store_url IS NULL OR ios_store_url ~ '^https?://');

COMMENT ON COLUMN public.competitions.android_store_url IS
  'Play Store URL du jeu utilise dans la competition (item 1 prompt 2026-05-19). Affichee comme bouton sur registration_confirm cote user.';
COMMENT ON COLUMN public.competitions.ios_store_url IS
  'App Store URL du jeu utilise dans la competition (item 1 prompt 2026-05-19).';
