-- ════════════════════════════════════════════════════════════════════
-- pgTAP — KPI financiers : statuts payments/payouts (régression)
-- ════════════════════════════════════════════════════════════════════
-- get_super_admin_kpis (et les autres fns de reporting) filtraient sur des
-- statuts inexistants/jamais écrits → revenus & versements à 0 :
--   payments.status = 'confirmed'  (le vrai = 'succeeded')
--   payouts.status  = 'validated'  (le vrai = 'completed')
-- Ce test vérifie qu'un paiement 'succeeded' et un payout 'completed' sont bien
-- comptés, et que les statuts non terminaux ('awaiting_admin', pending) ne le
-- sont PAS. Mesure en DELTA (avant/après) car les KPI agrègent globalement.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(3);

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('7a7a7a7a-0000-0000-0000-000000000001'),
  ('7a7a7a7a-0000-0000-0000-0000000000a1'),('7a7a7a7a-0000-0000-0000-0000000000a2');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('7a7a7a7a-0000-0000-0000-000000000001','k_sa','ksa@ci.invalid','CI','KSA','super_admin',true),
  ('7a7a7a7a-0000-0000-0000-0000000000a1','k_a','ka@ci.invalid','CI','KA1','player',true),
  ('7a7a7a7a-0000-0000-0000-0000000000a2','k_b','kb@ci.invalid','CI','KA2','player',true);
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency)
values ('7b7b7b7b-0000-0000-0000-000000000001','K','efootball','single_elimination','completed',now()-interval '1 day',4,5000,'XAF');

set local request.jwt.claims = '{"sub":"7a7a7a7a-0000-0000-0000-000000000001"}';

-- Baseline AVANT insertion des montants.
create temp table _b on commit drop as
  select public.get_super_admin_kpis() as k;

-- 1 paiement encaissé (5000) + 1 NON encaissé (awaiting_admin, ignoré).
insert into payments(user_id,competition_id,amount_local,currency,status,provider,validated_at) values
  ('7a7a7a7a-0000-0000-0000-0000000000a1','7b7b7b7b-0000-0000-0000-000000000001',5000,'XAF','succeeded','mobile_money_manual',now()),
  ('7a7a7a7a-0000-0000-0000-0000000000a2','7b7b7b7b-0000-0000-0000-000000000001',5000,'XAF','awaiting_admin','mobile_money_manual',null);
-- 1 versement payé (3000) + 1 en attente (ignoré).
insert into payouts(user_id,competition_id,amount_local,currency,status,rank,payout_provider,validated_at) values
  ('7a7a7a7a-0000-0000-0000-0000000000a1','7b7b7b7b-0000-0000-0000-000000000001',3000,'XAF','completed',1,'mobile_money_manual',now()),
  ('7a7a7a7a-0000-0000-0000-0000000000a2','7b7b7b7b-0000-0000-0000-000000000001',3000,'XAF','pending_admin_validation',2,'mobile_money_manual',null);

-- ─── Assertions (delta avant/après) ─────────────────────────────────
select is(
  (public.get_super_admin_kpis()->>'total_revenue_xaf')::numeric
    - (select (k->>'total_revenue_xaf')::numeric from _b),
  5000::numeric, 'revenu = paiement succeeded (5000) ; awaiting_admin ignoré');

select is(
  (public.get_super_admin_kpis()->>'total_payouts_xaf')::numeric
    - (select (k->>'total_payouts_xaf')::numeric from _b),
  3000::numeric, 'versements = payout completed (3000) ; pending ignoré');

select is(
  (public.get_super_admin_kpis()->>'margin_30d_xaf')::numeric
    - (select (k->>'margin_30d_xaf')::numeric from _b),
  2000::numeric, 'marge 30j = 5000 encaissés - 3000 versés');

select * from finish();
rollback;
