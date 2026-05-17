-- Couvre les 2 foreign keys signalées par l'advisor
-- `unindexed_foreign_keys` (perf advisor INFO). Sans index, un DELETE
-- ou UPDATE sur `profiles(id)` doit faire un seq_scan sur la table
-- enfant pour vérifier les références (CASCADE ou SET NULL).
--
-- Les deux colonnes sont nullable et la majorité des rows ont la
-- valeur NULL → on indexe en partial pour économiser le stockage.

CREATE INDEX IF NOT EXISTS idx_friendships_blocked_by
  ON public.friendships(blocked_by)
  WHERE blocked_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_reintegration_resolved_by
  ON public.reintegration_requests(resolved_by)
  WHERE resolved_by IS NOT NULL;
