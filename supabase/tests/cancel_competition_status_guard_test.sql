-- ════════════════════════════════════════════════════════════════════
-- pgTAP — cancel_competition : garde de statut (anti double sortie d'argent)
-- ════════════════════════════════════════════════════════════════════
-- Couvre le fix audit 2026-06-26 (20260626120100) : `cancel_competition` ne
-- doit PAS pouvoir être appelée sur une compétition déjà `completed`/`cancelled`,
-- ni sur une compétition dont des `payouts` (prix) existent déjà — sinon les
-- frais d'inscription `succeeded` repassent `refund_pending` EN PLUS des prix
-- déjà versés (la plateforme paie deux fois).
--
-- Le rôle de l'appelant est piloté par request.jwt.claims (auth.uid → is_admin).
-- Superuser, rollback final.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(9);

-- cancel_competition insère des notifications ; on coupe le dispatch FCM (pg_net).
alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('cc000000-0000-0000-0000-0000000000ad'),  -- admin
  ('cc000000-0000-0000-0000-0000000000f1'),  -- joueur 1
  ('cc000000-0000-0000-0000-0000000000f2');  -- joueur 2
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('cc000000-0000-0000-0000-0000000000ad','cc_admin','ccad@ci.invalid','CI','CCAD','admin',true),
  ('cc000000-0000-0000-0000-0000000000f1','cc_p1','ccp1@ci.invalid','CI','CCP1','player',true),
  ('cc000000-0000-0000-0000-0000000000f2','cc_p2','ccp2@ci.invalid','CI','CCP2','player',true);

-- COMP1 : déjà terminée, prix déjà versés (un payment succeeded encaissé).
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency) values
  ('cc000000-0000-0000-0000-00000000c001','DONE','efootball','single_elimination','completed',now()-interval '1 day',4,1000,'XAF');
insert into payments(user_id,competition_id,amount_local,currency,status,provider) values
  ('cc000000-0000-0000-0000-0000000000f1','cc000000-0000-0000-0000-00000000c001',1000,'XAF','succeeded','mobile_money_manual');

-- COMP2 : ongoing MAIS des payouts existent déjà (ceinture-bretelles).
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency) values
  ('cc000000-0000-0000-0000-00000000c002','PAID','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF');
insert into payments(user_id,competition_id,amount_local,currency,status,provider) values
  ('cc000000-0000-0000-0000-0000000000f1','cc000000-0000-0000-0000-00000000c002',1000,'XAF','succeeded','mobile_money_manual');
insert into payouts(user_id,competition_id,amount_local,currency,status) values
  ('cc000000-0000-0000-0000-0000000000f2','cc000000-0000-0000-0000-00000000c002',2000,'XAF','pending_admin_validation');

-- COMP3 : annulation légitime (ouverte, aucun prix), un payment succeeded à rembourser.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency) values
  ('cc000000-0000-0000-0000-00000000c003','OPEN','efootball','single_elimination','registration_closed',now()+interval '1 day',4,1000,'XAF');
insert into payments(user_id,competition_id,amount_local,currency,status,provider) values
  ('cc000000-0000-0000-0000-0000000000f1','cc000000-0000-0000-0000-00000000c003',1000,'XAF','succeeded','mobile_money_manual');

select has_function('public', 'cancel_competition', array['uuid']);

-- L'appelant est l'admin pour toute la suite.
set local request.jwt.claims = '{"sub":"cc000000-0000-0000-0000-0000000000ad"}';

-- ─── Refus : compétition déjà terminée ──────────────────────────────
select throws_ok(
  $$ select public.cancel_competition('cc000000-0000-0000-0000-00000000c001') $$,
  '42501', NULL, 'annulation refusée sur une compétition completed');
select is(
  (select status from payments where competition_id='cc000000-0000-0000-0000-00000000c001'),
  'succeeded', 'paiement de la compétition terminée NON basculé en refund_pending');

-- ─── Refus : des payouts existent déjà ──────────────────────────────
select throws_ok(
  $$ select public.cancel_competition('cc000000-0000-0000-0000-00000000c002') $$,
  '42501', NULL, 'annulation refusée si des payouts existent déjà');
select is(
  (select status from payments where competition_id='cc000000-0000-0000-0000-00000000c002'),
  'succeeded', 'paiement de la compétition avec payouts NON basculé en refund_pending');
select is(
  (select status::text from competitions where id='cc000000-0000-0000-0000-00000000c002'),
  'ongoing', 'la compétition avec payouts reste ongoing (non annulée)');

-- ─── OK : annulation légitime ───────────────────────────────────────
select lives_ok(
  $$ select public.cancel_competition('cc000000-0000-0000-0000-00000000c003') $$,
  'annulation autorisée sur une compétition non terminée sans payouts');
select is(
  (select status::text from competitions where id='cc000000-0000-0000-0000-00000000c003'),
  'cancelled', 'la compétition légitime passe bien à cancelled');
select is(
  (select status from payments where competition_id='cc000000-0000-0000-0000-00000000c003'),
  'refund_pending', 'le paiement succeeded passe en refund_pending (file de remboursement)');

select * from finish();
rollback;
