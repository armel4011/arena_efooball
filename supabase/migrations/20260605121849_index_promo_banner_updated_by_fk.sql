-- Advisor perf 0001_unindexed_foreign_keys.
--
-- La FK `promo_banner.updated_by -> profiles(id)` n'avait pas d'index
-- couvrant. Sans index, un DELETE/UPDATE sur `profiles` doit scanner tout
-- `promo_banner` pour faire respecter `ON DELETE SET NULL`, et toute
-- jointure sur `updated_by` est sous-optimale. Table a faible cardinalite
-- (une banniere active a la fois) donc l'impact est minime, mais on ferme
-- l'advisor proprement.
--
-- NB : le seul autre item ERROR de l'advisor securite
-- (security_definer_view sur public.public_profiles) est INTENTIONNEL et
-- assume (cf. 20260601130000 : security_invoker=false volontaire pour
-- exposer les colonnes non-PII en cross-user malgre la RLS self+admin).
-- Aucune migration ne doit le "corriger".

CREATE INDEX IF NOT EXISTS idx_promo_banner_updated_by
  ON public.promo_banner (updated_by);
