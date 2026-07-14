-- ════════════════════════════════════════════════════════════════════
-- FIX P3 (audit 2026-07-13, livré 2026-07-14) — annulation de paiement joueur
-- ════════════════════════════════════════════════════════════════════
-- `PaymentRepository.cancel()` fait `UPDATE payments SET status='failed'` sur
-- SA propre ligne, mais `payments` n'avait AUCUNE policy UPDATE côté joueur
-- (seule `payments_admin_update` réservée au super-admin). Résultat : l'UPDATE
-- passait le filtre RLS à 0 ligne, SANS erreur → le joueur voyait « annulé »
-- (navigation home) alors que la ligne restait `awaiting_admin` et pouvait
-- encore être validée par un admin plus tard.
--
-- Correctif : policy UPDATE ciblée permettant au PROPRIÉTAIRE de passer SA ligne
-- de `awaiting_admin` (pas encore encaissée) → `failed` UNIQUEMENT.
--   USING      : c'est bien sa ligne ET elle est encore `awaiting_admin`
--   WITH CHECK : la seule transition autorisée est vers `failed`
-- Un joueur ne peut donc PAS :
--   • annuler une ligne `succeeded`/`rejected`/… (USING échoue) ;
--   • toucher la ligne d'un autre joueur (USING échoue) ;
--   • se passer `awaiting_admin → succeeded` (WITH CHECK échoue) — ce qui aurait
--     déclenché `on_payment_validated` et créé une inscription confirmée GRATUITE.
--
-- Le trigger AFTER UPDATE `on_payment_validated` ne réagit qu'à `succeeded`,
-- donc la transition → `failed` est inerte (aucune inscription créée).
-- ════════════════════════════════════════════════════════════════════

create policy payments_self_cancel
  on public.payments
  for update
  to authenticated
  using (
    (select auth.uid()) = user_id
    and status = 'awaiting_admin'
  )
  with check (
    (select auth.uid()) = user_id
    and status = 'failed'
  );

comment on policy payments_self_cancel on public.payments is
  'Le proprietaire peut annuler SA ligne awaiting_admin -> failed uniquement '
  '(audit 2026-07-14). Rend PaymentRepository.cancel() effectif ; interdit '
  'l''auto-passage succeeded (escalade inscription gratuite).';
