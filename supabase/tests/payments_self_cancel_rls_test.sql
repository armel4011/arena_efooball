-- ════════════════════════════════════════════════════════════════════
-- pgTAP — payments_self_cancel : annulation de paiement joueur (audit 2026-07-14)
-- ════════════════════════════════════════════════════════════════════
-- Couvre le fix P3 (20260714150000) : la policy UPDATE `payments_self_cancel`
-- rend `PaymentRepository.cancel()` effectif tout en le bornant.
--   1. le propriétaire annule SA ligne awaiting_admin -> failed ;
--   2. il ne peut PAS toucher la ligne d'un autre joueur ;
--   3. il ne peut PAS annuler une ligne déjà `succeeded` ;
--   4. il ne peut PAS se passer awaiting_admin -> succeeded (WITH CHECK → 42501),
--      ce qui aurait déclenché on_payment_validated (inscription gratuite).
--
-- Contrainte uniq_payments_active_per_competition → une compétition par paiement.
-- Rôle/identité via set_config('role') + request.jwt.claims. Superuser, rollback.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(5);

set local session_replication_role = replica;

insert into auth.users(id) values
  ('d0000000-0000-0000-0000-0000000000f1'),  -- joueur proprio
  ('d0000000-0000-0000-0000-0000000000f2');   -- autre joueur
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('d0000000-0000-0000-0000-0000000000f1','d0_p1','d0p1@ci.invalid','CM','D0P1','player',true),
  ('d0000000-0000-0000-0000-0000000000f2','d0_p2','d0p2@ci.invalid','CM','D0P2','player',true);
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code) values
  ('d0000000-0000-0000-0000-00000000c001','C1','efootball','single_elimination','registration_open',now()+interval '5 day',4,1000,'XAF','CM'),
  ('d0000000-0000-0000-0000-00000000c002','C2','efootball','single_elimination','registration_open',now()+interval '5 day',4,1000,'XAF','CM'),
  ('d0000000-0000-0000-0000-00000000c003','C3','efootball','single_elimination','registration_open',now()+interval '5 day',4,1000,'XAF','CM'),
  ('d0000000-0000-0000-0000-00000000c004','C4','efootball','single_elimination','registration_open',now()+interval '5 day',4,1000,'XAF','CM');
insert into payments(id,user_id,competition_id,amount_local,currency,status,provider) values
  ('d0000000-0000-0000-0000-0000000000a1','d0000000-0000-0000-0000-0000000000f1','d0000000-0000-0000-0000-00000000c001',1000,'XAF','awaiting_admin','mobile_money_manual'),
  ('d0000000-0000-0000-0000-0000000000b2','d0000000-0000-0000-0000-0000000000f2','d0000000-0000-0000-0000-00000000c002',1000,'XAF','awaiting_admin','mobile_money_manual'),
  ('d0000000-0000-0000-0000-0000000000c3','d0000000-0000-0000-0000-0000000000f1','d0000000-0000-0000-0000-00000000c003',1000,'XAF','succeeded','mobile_money_manual'),
  ('d0000000-0000-0000-0000-0000000000d4','d0000000-0000-0000-0000-0000000000f1','d0000000-0000-0000-0000-00000000c004',1000,'XAF','awaiting_admin','mobile_money_manual');
set local session_replication_role = default;

-- Toutes les mutations sous le rôle authenticated (proprio f1) dans un bloc, puis
-- retour superuser pour lire les résultats et asserter.
create temp table _r(scenario text, val text) on commit drop;
do $$
declare v_state text;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.jwt.claims','{"sub":"d0000000-0000-0000-0000-0000000000f1"}',true);

  update public.payments set status='failed' where id='d0000000-0000-0000-0000-0000000000a1';       -- 1 : sa ligne awaiting
  update public.payments set status='failed' where id='d0000000-0000-0000-0000-0000000000b2';       -- 2 : ligne d'autrui (bloqué)
  update public.payments set status='failed' where id='d0000000-0000-0000-0000-0000000000c3';       -- 3 : sa ligne succeeded (bloqué)
  begin
    update public.payments set status='succeeded' where id='d0000000-0000-0000-0000-0000000000d4';  -- 4 : escalade (WITH CHECK)
    v_state := 'no_error';
  exception when others then v_state := sqlstate;
  end;

  perform set_config('role','postgres',true);
  insert into _r values('4_escalade_sqlstate', v_state);
  insert into _r select '1_a1', status from payments where id='d0000000-0000-0000-0000-0000000000a1';
  insert into _r select '2_b2', status from payments where id='d0000000-0000-0000-0000-0000000000b2';
  insert into _r select '3_c3', status from payments where id='d0000000-0000-0000-0000-0000000000c3';
  insert into _r select '4b_d4', status from payments where id='d0000000-0000-0000-0000-0000000000d4';
end $$;

select is((select val from _r where scenario='1_a1'), 'failed',
  'propriétaire : annule sa ligne awaiting_admin -> failed');
select is((select val from _r where scenario='2_b2'), 'awaiting_admin',
  'ne peut pas annuler le paiement d''un autre joueur');
select is((select val from _r where scenario='3_c3'), 'succeeded',
  'ne peut pas annuler un paiement déjà succeeded');
select is((select val from _r where scenario='4_escalade_sqlstate'), '42501',
  'escalade awaiting_admin -> succeeded refusée (WITH CHECK 42501)');
select is((select val from _r where scenario='4b_d4'), 'awaiting_admin',
  'la ligne visée par l''escalade reste awaiting_admin');

select * from finish();
rollback;
