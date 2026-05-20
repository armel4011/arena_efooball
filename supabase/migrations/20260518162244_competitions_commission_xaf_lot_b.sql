-- ════════════════════════════════════════════════════════════════════
-- LOT B — Commission ARENA en montant absolu XAF (item 9)
-- ════════════════════════════════════════════════════════════════════
-- L'admin saisit la commission en montant (ex. 5000 XAF), plus en
-- pourcentage. `commission_pct` est gardée pour compat + sert de
-- valeur dérivée affichée en interne uniquement (jamais côté joueur).

ALTER TABLE competitions
  ADD COLUMN IF NOT EXISTS commission_xaf numeric NOT NULL DEFAULT 0;

COMMENT ON COLUMN competitions.commission_xaf IS
  'Commission ARENA en montant absolu (devise = registration_currency). Lot B — remplace l''ancien commission_pct côté UX.';

-- Backfill depuis l'ancien % (round(prize_pool_local * commission_pct / 100))
UPDATE competitions
   SET commission_xaf = ROUND(prize_pool_local * commission_pct / 100)
 WHERE commission_xaf = 0 AND commission_pct > 0 AND prize_pool_local > 0;
