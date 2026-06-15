-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Clôture auto d'une compétition + classement final (final_rank)
-- ════════════════════════════════════════════════════════════════════
-- Couvre 20260615140000_auto_finalize_competition.sql :
--   * tant qu'il reste un match non terminé → la compétition reste ongoing ;
--   * au dernier match terminé → status passe à completed + final_rank calculé ;
--   * single_elimination : champion=1, finaliste=2, demi-finalistes 3/4
--     (départagés par les buts faute de match 3e place) ;
--   * round_robin : final_rank = position au classement.
--
-- Superuser (bypass RLS), tout annulé par le rollback final.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(10);

-- ─── Fixtures communes ──────────────────────────────────────────────
insert into auth.users(id) values
  ('a1a1a1a1-0000-0000-0000-000000000001'),('a1a1a1a1-0000-0000-0000-000000000002'),
  ('a1a1a1a1-0000-0000-0000-000000000003'),('a1a1a1a1-0000-0000-0000-000000000004');
insert into profiles(id,username,email,country_code,referral_code,role) values
  ('a1a1a1a1-0000-0000-0000-000000000001','fin_a','fa@ci.invalid','CI','FINA','player'),
  ('a1a1a1a1-0000-0000-0000-000000000002','fin_b','fb@ci.invalid','CI','FINB','player'),
  ('a1a1a1a1-0000-0000-0000-000000000003','fin_c','fc@ci.invalid','CI','FINC','player'),
  ('a1a1a1a1-0000-0000-0000-000000000004','fin_d','fd@ci.invalid','CI','FIND','player');

-- ═══ SINGLE ELIMINATION (A,B,C,D) ═══════════════════════════════════
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency) values
  ('c1c1c1c1-0000-0000-0000-000000000001','SE','efootball','single_elimination','ongoing',now()-interval '1 hour',4,0,'XOF');
insert into competition_registrations(competition_id,player_id,status) values
  ('c1c1c1c1-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000001','confirmed'),
  ('c1c1c1c1-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000002','confirmed'),
  ('c1c1c1c1-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000003','confirmed'),
  ('c1c1c1c1-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000004','confirmed');
insert into phases(id,competition_id,phase_order,type,status) values
  ('f1f1f1f1-0000-0000-0000-000000000001','c1c1c1c1-0000-0000-0000-000000000001',1,'knockout','in_progress');
insert into matches(id,competition_id,phase_id,round,player1_id,player2_id,status) values
  ('d1d1d1d1-0000-0000-0000-000000000001','c1c1c1c1-0000-0000-0000-000000000001','f1f1f1f1-0000-0000-0000-000000000001',1,'a1a1a1a1-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000002','scheduled'),
  ('d1d1d1d1-0000-0000-0000-000000000002','c1c1c1c1-0000-0000-0000-000000000001','f1f1f1f1-0000-0000-0000-000000000001',1,'a1a1a1a1-0000-0000-0000-000000000003','a1a1a1a1-0000-0000-0000-000000000004','scheduled'),
  ('d1d1d1d1-0000-0000-0000-000000000003','c1c1c1c1-0000-0000-0000-000000000001','f1f1f1f1-0000-0000-0000-000000000001',2,'a1a1a1a1-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000003','pending');
insert into bracket_nodes(competition_id,phase_id,round_number,position_in_round,total_rounds,match_id,is_grand_final) values
  ('c1c1c1c1-0000-0000-0000-000000000001','f1f1f1f1-0000-0000-0000-000000000001',1,0,2,'d1d1d1d1-0000-0000-0000-000000000001',false),
  ('c1c1c1c1-0000-0000-0000-000000000001','f1f1f1f1-0000-0000-0000-000000000001',1,1,2,'d1d1d1d1-0000-0000-0000-000000000002',false),
  ('c1c1c1c1-0000-0000-0000-000000000001','f1f1f1f1-0000-0000-0000-000000000001',2,0,2,'d1d1d1d1-0000-0000-0000-000000000003',true);

-- Demies : A bat B 2-1, C bat D 3-0 (finale encore en attente)
update matches set status='completed',score1=2,score2=1,winner_id='a1a1a1a1-0000-0000-0000-000000000001' where id='d1d1d1d1-0000-0000-0000-000000000001';
update matches set status='completed',score1=3,score2=0,winner_id='a1a1a1a1-0000-0000-0000-000000000003' where id='d1d1d1d1-0000-0000-0000-000000000002';

select is((select status::text from competitions where id='c1c1c1c1-0000-0000-0000-000000000001'),
  'ongoing', 'finale en attente → compétition reste ongoing');

-- Finale : A bat C 1-0 → clôture
update matches set status='completed',score1=1,score2=0,winner_id='a1a1a1a1-0000-0000-0000-000000000001' where id='d1d1d1d1-0000-0000-0000-000000000003';

select is((select status::text from competitions where id='c1c1c1c1-0000-0000-0000-000000000001'),
  'completed', 'dernier match terminé → compétition completed');
select is((select final_rank from competition_registrations where competition_id='c1c1c1c1-0000-0000-0000-000000000001' and player_id='a1a1a1a1-0000-0000-0000-000000000001'),
  1, 'champion (A) = rang 1');
select is((select final_rank from competition_registrations where competition_id='c1c1c1c1-0000-0000-0000-000000000001' and player_id='a1a1a1a1-0000-0000-0000-000000000003'),
  2, 'finaliste (C) = rang 2');
select is((select final_rank from competition_registrations where competition_id='c1c1c1c1-0000-0000-0000-000000000001' and player_id='a1a1a1a1-0000-0000-0000-000000000002'),
  3, 'demi-finaliste B = rang 3 (départage buts)');
select is((select final_rank from competition_registrations where competition_id='c1c1c1c1-0000-0000-0000-000000000001' and player_id='a1a1a1a1-0000-0000-0000-000000000004'),
  4, 'demi-finaliste D = rang 4');

-- ═══ ROUND ROBIN (A,B,C) ════════════════════════════════════════════
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency) values
  ('c2c2c2c2-0000-0000-0000-000000000001','RR','efootball','round_robin','registration_closed',now()-interval '1 hour',3,0,'XOF');
insert into competition_registrations(competition_id,player_id,status) values
  ('c2c2c2c2-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000001','confirmed'),
  ('c2c2c2c2-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000002','confirmed'),
  ('c2c2c2c2-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000003','confirmed');
select public.generate_round_robin_bracket('c2c2c2c2-0000-0000-0000-000000000001');

-- Tous les matchs : vainqueur = plus petit uuid (a1 > a2 > a3 en priorité).
update matches set
  winner_id = least(player1_id, player2_id),
  score1 = case when player1_id < player2_id then 1 else 0 end,
  score2 = case when player2_id < player1_id then 1 else 0 end,
  status = 'completed'
where competition_id='c2c2c2c2-0000-0000-0000-000000000001';

select is((select status::text from competitions where id='c2c2c2c2-0000-0000-0000-000000000001'),
  'completed', 'round-robin terminé → completed');
select is((select final_rank from competition_registrations where competition_id='c2c2c2c2-0000-0000-0000-000000000001' and player_id='a1a1a1a1-0000-0000-0000-000000000001'),
  1, 'round-robin : A (2 victoires) = rang 1');
select is((select final_rank from competition_registrations where competition_id='c2c2c2c2-0000-0000-0000-000000000001' and player_id='a1a1a1a1-0000-0000-0000-000000000002'),
  2, 'round-robin : B = rang 2');
select is((select final_rank from competition_registrations where competition_id='c2c2c2c2-0000-0000-0000-000000000001' and player_id='a1a1a1a1-0000-0000-0000-000000000003'),
  3, 'round-robin : C = rang 3');

select * from finish();
rollback;
