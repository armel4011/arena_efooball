-- Retire le trigger/fonction enforce_payment_amount ajouté par la migration
-- 20260713120000 (audit 2026-07-13, P2 « montant paiement »).
--
-- MOTIF : ce contrôle était REDONDANT. La protection existait déjà depuis la
-- migration 20260605125932 (guard_payments_amount / trg_payments_guard_amount,
-- 2026-06-05, déjà couverte par payments_payouts_rls_test.sql), qui recale
-- amount_local/currency sur le fee de la compétition pour les inserts CLIENT
-- (current_user authenticated/anon, non-admin). Le finding du 2026-07-13 était
-- un faux positif (seule la policy RLS avait été inspectée, pas les triggers).
--
-- enforce_payment_amount était en outre légèrement MOINS correct : il recalait
-- aussi les inserts admin/service, écrasant un éventuel montant posé côté admin,
-- là où guard_payments_amount exempte volontairement is_admin(). On revient donc
-- à la seule protection guard_payments_amount.

drop trigger if exists trg_enforce_payment_amount on public.payments;
drop function if exists public.enforce_payment_amount();
