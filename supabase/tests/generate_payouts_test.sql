-- ════════════════════════════════════════════════════════════════════
-- pgTAP — generate_payouts (versements / argent)
-- ════════════════════════════════════════════════════════════════════
-- Couvre la fonction F-1 `generate_payouts(uuid)` : la plus à risque (argent),
-- jusque-là sans test de CALCUL (seule la RLS payouts l'était).
--   * gate super-admin (is_super_admin) ;
--   * refus si compétition non `completed` ;
--   * calcul des montants par rang depuis `prize_distribution` + `final_rank`
--     (rangs sans prix ignorés) ;
--   * statut `pending_admin_validation`, notification `payout_available` ;
--   * idempotence (2e appel → 0) ;
--   * garde anti-échec-silencieux (prix prévus mais classement non publié).
--
-- Le rôle de l'appelant est piloté par `request.jwt.claims` (auth.uid →
-- is_super_admin). Le trigger de dispatch FCM est désactivé (pg_net).
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(10);

alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('5a5a5a5a-0000-0000-0000-000000000001'),  -- super-admin
  ('5a5a5a5a-0000-0000-0000-0000000000a1'),('5a5a5a5a-0000-0000-0000-0000000000a2'),
  ('5a5a5a5a-0000-0000-0000-0000000000a3'),('5a5a5a5a-0000-0000-0000-0000000000a4');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('5a5a5a5a-0000-0000-0000-000000000001','pay_sa','sa@ci.invalid','CI','PSA','super_admin',true),
  ('5a5a5a5a-0000-0000-0000-0000000000a1','pay_a','pa@ci.invalid','CI','PA1','player',true),
  ('5a5a5a5a-0000-0000-0000-0000000000a2','pay_b','pb@ci.invalid','CI','PA2','player',true),
  ('5a5a5a5a-0000-0000-0000-0000000000a3','pay_c','pc@ci.invalid','CI','PA3','player',true),
  ('5a5a5a5a-0000-0000-0000-0000000000a4','pay_d','pd@ci.invalid','CI','PA4','player',true);

-- c1 : terminée, prix [50000, 20000, 0, 0], classement publié (rangs 1-4)
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,prize_distribution) values
  ('5b5b5b5b-0000-0000-0000-000000000001','PAY','efootball','single_elimination','completed',now()-interval '1 day',4,1000,'XAF','[50000, 20000, 0, 0]'::jsonb),
  -- c2 : encore en cours
  ('5b5b5b5b-0000-0000-0000-000000000002','PAYONG','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF','[50000, 0, 0, 0]'::jsonb),
  -- c3 : terminée, prix prévus, MAIS classement non publié (final_rank null)
  ('5b5b5b5b-0000-0000-0000-000000000003','PAYNORANK','efootball','single_elimination','completed',now()-interval '1 hour',4,1000,'XAF','[50000, 0, 0, 0]'::jsonb);
insert into competition_registrations(competition_id,player_id,status,final_rank) values
  ('5b5b5b5b-0000-0000-0000-000000000001','5a5a5a5a-0000-0000-0000-0000000000a1','confirmed',1),
  ('5b5b5b5b-0000-0000-0000-000000000001','5a5a5a5a-0000-0000-0000-0000000000a2','confirmed',2),
  ('5b5b5b5b-0000-0000-0000-000000000001','5a5a5a5a-0000-0000-0000-0000000000a3','confirmed',3),
  ('5b5b5b5b-0000-0000-0000-000000000001','5a5a5a5a-0000-0000-0000-0000000000a4','confirmed',4),
  ('5b5b5b5b-0000-0000-0000-000000000003','5a5a5a5a-0000-0000-0000-0000000000a1','confirmed',null);

-- ─── Gate super-admin : un joueur ne peut PAS générer ───────────────
set local request.jwt.claims = '{"sub":"5a5a5a5a-0000-0000-0000-0000000000a1"}';
select throws_ok(
  $$ select public.generate_payouts('5b5b5b5b-0000-0000-0000-000000000001') $$,
  '42501', null, 'un non-super-admin ne peut pas générer les versements');

-- ─── Désormais en super-admin ───────────────────────────────────────
set local request.jwt.claims = '{"sub":"5a5a5a5a-0000-0000-0000-000000000001"}';

-- compétition non terminée → refus
select throws_ok(
  $$ select public.generate_payouts('5b5b5b5b-0000-0000-0000-000000000002') $$,
  '42501', null, 'refus si la compétition n''est pas terminée');

-- prix prévus mais classement non publié → erreur explicite
select throws_ok(
  $$ select public.generate_payouts('5b5b5b5b-0000-0000-0000-000000000003') $$,
  'P0002', null, 'erreur si prix prévus mais classement non publié');

-- ─── Génération nominale ────────────────────────────────────────────
select is(
  public.generate_payouts('5b5b5b5b-0000-0000-0000-000000000001'),
  2, 'génère 2 versements (rangs 1-2 récompensés ; 3-4 à 0 ignorés)');

select is(
  (select amount_local from payouts where competition_id='5b5b5b5b-0000-0000-0000-000000000001' and rank=1),
  50000::numeric, 'rang 1 → 50000');
select is(
  (select user_id from payouts where competition_id='5b5b5b5b-0000-0000-0000-000000000001' and rank=1),
  '5a5a5a5a-0000-0000-0000-0000000000a1'::uuid, 'rang 1 = le joueur classé 1er');
select is(
  (select amount_local from payouts where competition_id='5b5b5b5b-0000-0000-0000-000000000001' and rank=2),
  20000::numeric, 'rang 2 → 20000');
select is(
  (select count(*)::int from payouts where competition_id='5b5b5b5b-0000-0000-0000-000000000001'),
  2, 'exactement 2 payouts (aucun pour les rangs non récompensés)');
select is(
  (select status from payouts where competition_id='5b5b5b5b-0000-0000-0000-000000000001' and rank=1),
  'pending_admin_validation', 'payout en attente de validation super-admin');
select is(
  (select count(*)::int from notifications
     where type='payout_available' and user_id='5a5a5a5a-0000-0000-0000-0000000000a1'
       and data->>'competition_id'='5b5b5b5b-0000-0000-0000-000000000001'),
  1, 'le gagnant reçoit une notification payout_available');

-- ─── Idempotence : 2e appel ne regénère rien ────────────────────────
select is(
  public.generate_payouts('5b5b5b5b-0000-0000-0000-000000000001'),
  0, 'idempotent : 0 au 2e appel (payouts déjà générés)');

select * from finish();
rollback;
