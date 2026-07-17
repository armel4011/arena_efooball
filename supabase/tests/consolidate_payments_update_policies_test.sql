-- ════════════════════════════════════════════════════════════════════
-- pgTAP — consolidation des policies UPDATE de `payments`
-- ════════════════════════════════════════════════════════════════════
-- 20260717250000 fusionne payments_admin_update + payments_self_cancel en une
-- seule policy `payments_update`. Ce test prouve qu'il ne reste qu'UNE policy
-- UPDATE et que les quatre comportements sont strictement préservés :
--   • propriétaire : awaiting_admin -> failed (annulation) → OK
--   • propriétaire : awaiting_admin -> succeeded → REFUSÉ (RLS check)
--   • super-admin global : awaiting_admin -> succeeded → OK
--   • super-admin scopé SN sur paiement CM → ligne invisible (0 update)
--
--   U    (a1) : payeur
--   SAg  (c9) : super-admin global
--   SAsn (5e) : super-admin scopé {'SN'}
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(6);

-- neutralise les triggers de payments (guards, on_payment_validated…) :
-- on teste la seule RLS UPDATE.
alter table public.payments disable trigger user;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('44000000-0000-0000-0000-0000000000a1'),
  ('44000000-0000-0000-0000-0000000000c9'),
  ('44000000-0000-0000-0000-00000000005e');
insert into profiles(id,username,email,country_code,referral_code,role,is_active,admin_allowed_countries) values
  ('44000000-0000-0000-0000-0000000000a1','pay_u','payu@ci.invalid','CM','PAYU','player',true,null),
  ('44000000-0000-0000-0000-0000000000c9','pay_sag','paysag@ci.invalid','CM','PSAG','super_admin',true,null),
  ('44000000-0000-0000-0000-00000000005e','pay_sasn','paysasn@ci.invalid','SN','PSSN','super_admin',true,array['SN']);

-- 4 compétitions distinctes : la contrainte uniq_payments_active_per_competition
-- interdit deux paiements actifs (user, competition) identiques.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code) values
  ('44000000-0000-0000-0000-0000000000f1','P1','efootball','single_elimination','ongoing','2026-08-01 10:00:00+00',8,1000,'XAF','CM'),
  ('44000000-0000-0000-0000-0000000000f2','P2','efootball','single_elimination','ongoing','2026-08-01 10:00:00+00',8,1000,'XAF','CM'),
  ('44000000-0000-0000-0000-0000000000f3','P3','efootball','single_elimination','ongoing','2026-08-01 10:00:00+00',8,1000,'XAF','CM'),
  ('44000000-0000-0000-0000-0000000000f4','P4','efootball','single_elimination','ongoing','2026-08-01 10:00:00+00',8,1000,'XAF','CM');

insert into payments(id,user_id,competition_id,amount_local,currency,provider,status,country_code) values
  ('44000000-0000-0000-0000-0000000000e1','44000000-0000-0000-0000-0000000000a1','44000000-0000-0000-0000-0000000000f1',1000,'XAF','mobile_money_manual','awaiting_admin','CM'),
  ('44000000-0000-0000-0000-0000000000e2','44000000-0000-0000-0000-0000000000a1','44000000-0000-0000-0000-0000000000f2',1000,'XAF','mobile_money_manual','awaiting_admin','CM'),
  ('44000000-0000-0000-0000-0000000000e3','44000000-0000-0000-0000-0000000000a1','44000000-0000-0000-0000-0000000000f3',1000,'XAF','mobile_money_manual','awaiting_admin','CM'),
  ('44000000-0000-0000-0000-0000000000e4','44000000-0000-0000-0000-0000000000a1','44000000-0000-0000-0000-0000000000f4',1000,'XAF','mobile_money_manual','awaiting_admin','CM');

-- ─── 1. Une seule policy UPDATE, nommée payments_update ─────────────
select is(
  (select coalesce(string_agg(polname, ',' order by polname), '')
     from pg_policy where polrelid='public.payments'::regclass and polcmd='w'),
  'payments_update',
  'payments : une seule policy UPDATE (payments_update)');

-- ─── 2. Propriétaire : annulation awaiting_admin -> failed ──────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"44000000-0000-0000-0000-0000000000a1"}';
select lives_ok(
  $$ update public.payments set status='failed' where id='44000000-0000-0000-0000-0000000000e1' $$,
  'proprietaire : annulation awaiting_admin -> failed autorisee');

-- ─── 3. Propriétaire : ne peut PAS se valider -> succeeded ──────────
select throws_ok(
  $$ update public.payments set status='succeeded' where id='44000000-0000-0000-0000-0000000000e2' $$,
  '42501', null,
  'proprietaire : passage a succeeded refuse (violation RLS)');

-- ─── 4. Super-admin global : validation awaiting_admin -> succeeded ─
set local request.jwt.claims = '{"sub":"44000000-0000-0000-0000-0000000000c9"}';
select lives_ok(
  $$ update public.payments set status='succeeded' where id='44000000-0000-0000-0000-0000000000e3' $$,
  'super-admin global : awaiting_admin -> succeeded autorise');

-- ─── 5. Super-admin scopé SN sur paiement CM : ligne invisible ─────
set local request.jwt.claims = '{"sub":"44000000-0000-0000-0000-00000000005e"}';
select lives_ok(
  $$ update public.payments set status='succeeded' where id='44000000-0000-0000-0000-0000000000e4' $$,
  'super-admin scope SN : update d''un paiement CM sans erreur (0 ligne)');

reset role;
-- ─── 6. Le paiement CM n'a pas été modifié par le super-admin SN ────
select is(
  (select status from public.payments where id='44000000-0000-0000-0000-0000000000e4'),
  'awaiting_admin',
  'paiement CM inchange : le super-admin scope SN ne l''a pas valide');

select * from finish();
rollback;
