-- ════════════════════════════════════════════════════════════════════
-- pgTAP — cancel_competition : cloisonnement pays (audit 2026-07-14)
-- ════════════════════════════════════════════════════════════════════
-- Couvre le fix P2 (20260714120000) : `cancel_competition` déclenche la file de
-- remboursement (succeeded → refund_pending) et doit donc être bornée au
-- périmètre pays de l'appelant, comme ses sœurs financières (generate_payouts,
-- mark_payout_paid, set_competition_payment_options).
--
--   • un admin scopé {CM} NE peut PAS annuler une compétition SN (throw 42501,
--     aucun paiement basculé) ;
--   • le même admin PEUT annuler une compétition CM (refund_pending) ;
--   • un admin sans restriction (admin_allowed_countries NULL) conserve l'accès
--     total : il annule une compétition de n'importe quel pays.
--
-- competitions.country_code est NOT NULL → pas de cas « sans pays » à couvrir.
-- Le rôle/scope de l'appelant est piloté par profiles.admin_allowed_countries +
-- request.jwt.claims (auth.uid). Superuser, rollback final.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(9);

-- cancel_competition insère des notifications ; on coupe le dispatch FCM (pg_net).
alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('cd000000-0000-0000-0000-0000000000ad'),  -- admin scopé {CM}
  ('cd000000-0000-0000-0000-0000000000a6'),  -- admin global (scope NULL)
  ('cd000000-0000-0000-0000-0000000000f1');   -- joueur

insert into profiles(id,username,email,country_code,referral_code,role,is_active,admin_allowed_countries) values
  ('cd000000-0000-0000-0000-0000000000ad','cd_admin_cm','cdad@ci.invalid','CM','CDAD','admin',true, array['CM']),
  ('cd000000-0000-0000-0000-0000000000a6','cd_admin_gl','cdag@ci.invalid','CM','CDAG','admin',true, NULL),
  ('cd000000-0000-0000-0000-0000000000f1','cd_p1','cdp1@ci.invalid','CM','CDP1','player',true, NULL);

-- COMP_SN : hors périmètre de l'admin {CM}. Un paiement succeeded à protéger.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code) values
  ('cd000000-0000-0000-0000-00000000c051','SN','efootball','single_elimination','registration_closed',now()+interval '1 day',4,1000,'XAF','SN');
insert into payments(user_id,competition_id,amount_local,currency,status,provider) values
  ('cd000000-0000-0000-0000-0000000000f1','cd000000-0000-0000-0000-00000000c051',1000,'XAF','succeeded','mobile_money_manual');

-- COMP_CM : dans le périmètre de l'admin {CM}.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code) values
  ('cd000000-0000-0000-0000-00000000c0c1','CM','efootball','single_elimination','registration_closed',now()+interval '1 day',4,1000,'XAF','CM');
insert into payments(user_id,competition_id,amount_local,currency,status,provider) values
  ('cd000000-0000-0000-0000-0000000000f1','cd000000-0000-0000-0000-00000000c0c1',1000,'XAF','succeeded','mobile_money_manual');

select has_function('public', 'cancel_competition', array['uuid']);

-- ─── Admin scopé {CM} ───────────────────────────────────────────────
set local request.jwt.claims = '{"sub":"cd000000-0000-0000-0000-0000000000ad"}';

-- Refus : compétition d'un autre pays (SN).
select throws_ok(
  $$ select public.cancel_competition('cd000000-0000-0000-0000-00000000c051') $$,
  '42501', NULL, 'admin {CM} : annulation refusée sur une compétition SN');
select is(
  (select status from payments where competition_id='cd000000-0000-0000-0000-00000000c051'),
  'succeeded', 'paiement SN NON basculé en refund_pending');
select is(
  (select status::text from competitions where id='cd000000-0000-0000-0000-00000000c051'),
  'registration_closed', 'la compétition SN reste non annulée');

-- OK : compétition de son pays (CM).
select lives_ok(
  $$ select public.cancel_competition('cd000000-0000-0000-0000-00000000c0c1') $$,
  'admin {CM} : annulation autorisée sur une compétition CM');
select is(
  (select status::text from competitions where id='cd000000-0000-0000-0000-00000000c0c1'),
  'cancelled', 'la compétition CM passe à cancelled');
select is(
  (select status from payments where competition_id='cd000000-0000-0000-0000-00000000c0c1'),
  'refund_pending', 'le paiement CM passe en refund_pending');

-- ─── Admin global (scope NULL) : accès total inchangé ───────────────
set local request.jwt.claims = '{"sub":"cd000000-0000-0000-0000-0000000000a6"}';

-- OK : un admin sans restriction annule la compétition SN (hors CM).
select lives_ok(
  $$ select public.cancel_competition('cd000000-0000-0000-0000-00000000c051') $$,
  'admin global : annulation autorisée sur une compétition de n''importe quel pays');
select is(
  (select status::text from competitions where id='cd000000-0000-0000-0000-00000000c051'),
  'cancelled', 'la compétition SN passe à cancelled sous un admin global');

select * from finish();
rollback;
