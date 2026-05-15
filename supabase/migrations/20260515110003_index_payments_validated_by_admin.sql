-- Phase 13.3 — Index sur la FK payments.validated_by_admin_id.
-- Advisor `unindexed_foreign_keys` : un DELETE sur profiles (super-admin)
-- ou un JOIN admin_audit_log → payments doit scanner toute la table
-- payments sans cet index. Coût négligeable d'écriture vs gain à l'échelle.

create index if not exists idx_payments_validated_by_admin
  on public.payments (validated_by_admin_id)
  where validated_by_admin_id is not null;

comment on index public.idx_payments_validated_by_admin is
  'Couvre la FK payments_validated_by_admin_id_fkey. Partial pour ne pas '
  'gonfler avec les paiements non encore validés.';
