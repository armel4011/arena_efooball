-- ════════════════════════════════════════════════════════════════════
-- pgTAP — claim_payout + mark_payout_paid (pipeline argent, dette T-1 audit)
-- ════════════════════════════════════════════════════════════════════
-- Étapes finales du versement, jusqu'ici sans test serveur :
--   claim_payout(payout, phone, method) : le GAGNANT saisit son numéro de
--     retrait. Owner-only, statut 'pending_admin_validation', méthode ∈
--     {MTN_MOMO, ORANGE_MONEY}, numéro requis.
--   mark_payout_paid(payout) : le SUPER-ADMIN marque payé (après virement réel).
--     Super-admin only, exige un numéro réclamé, refuse le double-paiement.
-- Couvre autorisation, validation d'entrée, transitions d'état, idempotence,
-- et la notification 'payout_paid' au gagnant.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(16);

alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('7e7e7e7e-0000-0000-0000-000000000001'),  -- super-admin
  ('7e7e7e7e-0000-0000-0000-0000000000a1'),  -- gagnant (owner de PA)
  ('7e7e7e7e-0000-0000-0000-0000000000a2'),  -- autre joueur (owner de PB déjà payé)
  ('7e7e7e7e-0000-0000-0000-0000000000a3');  -- joueur (PC non réclamé)
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('7e7e7e7e-0000-0000-0000-000000000001','cp_sa','cpsa@ci.invalid','CI','CPSA','super_admin',true),
  ('7e7e7e7e-0000-0000-0000-0000000000a1','cp_a','cpa@ci.invalid','CI','CPA1','player',true),
  ('7e7e7e7e-0000-0000-0000-0000000000a2','cp_b','cpb@ci.invalid','CI','CPA2','player',true),
  ('7e7e7e7e-0000-0000-0000-0000000000a3','cp_c','cpc@ci.invalid','CI','CPA3','player',true);
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency) values
  ('7f7f7f7f-0000-0000-0000-000000000001','CP1','efootball','single_elimination','completed',now()-interval '1 day',4,1000,'XAF'),
  ('7f7f7f7f-0000-0000-0000-000000000002','CP2','efootball','single_elimination','completed',now()-interval '1 day',4,1000,'XAF');
-- PA : à réclamer puis payer ; PB : déjà 'completed' ; PC : pending non réclamé.
-- (index unique payouts(competition_id,user_id) ⇒ 1 payout par (comp,user))
insert into payouts(id,user_id,competition_id,amount_local,currency,status,rank,payout_provider) values
  ('70707070-0000-0000-0000-0000000000A0','7e7e7e7e-0000-0000-0000-0000000000a1','7f7f7f7f-0000-0000-0000-000000000001',50000,'XAF','pending_admin_validation',1,'mobile_money_manual'),
  ('70707070-0000-0000-0000-0000000000B0','7e7e7e7e-0000-0000-0000-0000000000a2','7f7f7f7f-0000-0000-0000-000000000001',20000,'XAF','completed',2,'mobile_money_manual'),
  ('70707070-0000-0000-0000-0000000000C0','7e7e7e7e-0000-0000-0000-0000000000a3','7f7f7f7f-0000-0000-0000-000000000002',30000,'XAF','pending_admin_validation',1,'mobile_money_manual');

-- ════════ claim_payout ════════════════════════════════════════════
set local request.jwt.claims = '{"sub":"7e7e7e7e-0000-0000-0000-0000000000a1"}';
select throws_ok(
  $$ select public.claim_payout('00000000-0000-0000-0000-000000000000','650111222','MTN_MOMO') $$,
  'P0002', null, 'claim : versement inexistant rejeté');

set local request.jwt.claims = '{"sub":"7e7e7e7e-0000-0000-0000-0000000000a2"}';
select throws_ok(
  $$ select public.claim_payout('70707070-0000-0000-0000-0000000000A0','650111222','MTN_MOMO') $$,
  '42501', null, 'claim : on ne peut pas réclamer le gain d''un autre');

set local request.jwt.claims = '{"sub":"7e7e7e7e-0000-0000-0000-0000000000a1"}';
select throws_ok(
  $$ select public.claim_payout('70707070-0000-0000-0000-0000000000A0','650111222','PAYPAL') $$,
  '22023', null, 'claim : méthode de retrait invalide rejetée');
select throws_ok(
  $$ select public.claim_payout('70707070-0000-0000-0000-0000000000A0','   ','MTN_MOMO') $$,
  '22023', null, 'claim : numéro de retrait vide rejeté');

set local request.jwt.claims = '{"sub":"7e7e7e7e-0000-0000-0000-0000000000a2"}';
select throws_ok(
  $$ select public.claim_payout('70707070-0000-0000-0000-0000000000B0','650111222','MTN_MOMO') $$,
  '42501', null, 'claim : un versement déjà payé n''est plus réclamable');

-- Réclamation valide par le gagnant.
set local request.jwt.claims = '{"sub":"7e7e7e7e-0000-0000-0000-0000000000a1"}';
select lives_ok(
  $$ select public.claim_payout('70707070-0000-0000-0000-0000000000A0','650111222','MTN_MOMO') $$,
  'claim : réclamation valide par le gagnant acceptée');
select is(
  (select payee_phone from payouts where id='70707070-0000-0000-0000-0000000000A0'),
  '650111222', 'claim : numéro de retrait enregistré');
select is(
  (select claimed_at is not null from payouts where id='70707070-0000-0000-0000-0000000000A0'),
  true, 'claim : claimed_at horodaté');

-- ════════ mark_payout_paid ════════════════════════════════════════
set local request.jwt.claims = '{"sub":"7e7e7e7e-0000-0000-0000-000000000001"}';
select throws_ok(
  $$ select public.mark_payout_paid('00000000-0000-0000-0000-000000000000') $$,
  'P0002', null, 'mark : versement inexistant rejeté');
select throws_ok(
  $$ select public.mark_payout_paid('70707070-0000-0000-0000-0000000000C0') $$,
  '42501', null, 'mark : versement non réclamé (sans numéro) refusé');

-- Marquage payé valide après réclamation.
select lives_ok(
  $$ select public.mark_payout_paid('70707070-0000-0000-0000-0000000000A0') $$,
  'mark : marquage payé valide accepté');
select is(
  (select status from payouts where id='70707070-0000-0000-0000-0000000000A0'),
  'completed', 'mark : statut passe à completed');
select is(
  (select validated_at is not null from payouts where id='70707070-0000-0000-0000-0000000000A0'),
  true, 'mark : validated_at horodaté');
select is(
  (select count(*)::int from notifications
     where type='payout_paid' and user_id='7e7e7e7e-0000-0000-0000-0000000000a1'),
  1, 'mark : le gagnant reçoit une notification payout_paid');

select throws_ok(
  $$ select public.mark_payout_paid('70707070-0000-0000-0000-0000000000A0') $$,
  '42501', null, 'mark : double-paiement refusé (déjà completed)');

-- Gate super-admin.
set local request.jwt.claims = '{"sub":"7e7e7e7e-0000-0000-0000-0000000000a1"}';
select throws_ok(
  $$ select public.mark_payout_paid('70707070-0000-0000-0000-0000000000C0') $$,
  '42501', null, 'mark : un non-super-admin ne peut pas marquer payé');

select * from finish();
rollback;
