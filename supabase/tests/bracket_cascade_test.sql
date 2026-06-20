-- ════════════════════════════════════════════════════════════════════
-- pgTAP — cascade_match_winner : avancement du bracket
-- ════════════════════════════════════════════════════════════════════
-- Couvre `cascade_match_winner` (20260606150000 + 20260613120000), qui
-- propage le gagnant d'un match au match suivant du bracket :
--   * chemin bracket_nodes.next_node_id (générateur Dart, qui ne pose PAS
--     matches.next_match_id) — c'était le bug : les brackets Dart se figeaient ;
--   * ciblage du bon slot via `next_position` (player1 vs player2) ;
--   * un match `forfeited` (pas seulement `completed`) propage aussi ;
--   * chemin direct `matches.next_match_id` (générateur SQL), prioritaire ;
--   * le trigger de scheduling (`z_…`) s'exécute APRÈS la cascade → le match
--     suivant passe `scheduled` une fois ses 2 joueurs présents.
--
-- Exécuté en superuser (bypass RLS / guards) ; rollback final.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(7);

-- Dispatch FCM des notifications (pg_net) coupé pour les tests.
alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Fixtures : joueurs ─────────────────────────────────────────────
insert into auth.users(id) values
  ('b6000000-0000-0000-0000-0000000000a1'),('b6000000-0000-0000-0000-0000000000a2'),
  ('b6000000-0000-0000-0000-0000000000a3'),('b6000000-0000-0000-0000-0000000000a4'),
  ('b6000000-0000-0000-0000-0000000000a5'),('b6000000-0000-0000-0000-0000000000a6');
insert into profiles(id,username,email,country_code,referral_code,role) values
  ('b6000000-0000-0000-0000-0000000000a1','br_a','bra@ci.invalid','CI','BRKA','player'),
  ('b6000000-0000-0000-0000-0000000000a2','br_b','brb@ci.invalid','CI','BRKB','player'),
  ('b6000000-0000-0000-0000-0000000000a3','br_c','brc@ci.invalid','CI','BRKC','player'),
  ('b6000000-0000-0000-0000-0000000000a4','br_d','brd@ci.invalid','CI','BRKD','player'),
  ('b6000000-0000-0000-0000-0000000000a5','br_e','bre@ci.invalid','CI','BRKE','player'),
  ('b6000000-0000-0000-0000-0000000000a6','br_f','brf@ci.invalid','CI','BRKF','player');

-- ════════════════════════════════════════════════════════════════════
-- COMP1 — chemin bracket_nodes (générateur Dart, next_match_id NULL)
-- 2 demi-finales (round 1) → finale (round 2).
-- ════════════════════════════════════════════════════════════════════
insert into competitions(id,name,game,format,start_date,max_players,registration_fee,registration_currency) values
  ('b6000000-0000-0000-0000-0000000000c1','BRK1','efootball','single_elimination',now()+interval '1 day',4,0,'XOF');
insert into phases(id,competition_id,phase_order,type,status) values
  ('b6000000-0000-0000-0000-0000000000e1','b6000000-0000-0000-0000-0000000000c1',1,'knockout','ongoing');

-- Matchs (next_match_id volontairement NULL → force le repli bracket_nodes).
insert into matches(id,competition_id,round,player1_id,player2_id,status) values
  ('b6000000-0000-0000-0000-0000000000d1','b6000000-0000-0000-0000-0000000000c1',1,
   'b6000000-0000-0000-0000-0000000000a1','b6000000-0000-0000-0000-0000000000a2','scheduled'),  -- sf1 A/B
  ('b6000000-0000-0000-0000-0000000000d2','b6000000-0000-0000-0000-0000000000c1',1,
   'b6000000-0000-0000-0000-0000000000a3','b6000000-0000-0000-0000-0000000000a4','scheduled');  -- sf2 C/D
insert into matches(id,competition_id,round,status) values
  ('b6000000-0000-0000-0000-0000000000d3','b6000000-0000-0000-0000-0000000000c1',2,'pending');   -- finale

-- bracket_nodes : finale d'abord (référencée par next_node_id), puis sf1/sf2.
insert into bracket_nodes(id,competition_id,phase_id,round_number,position_in_round,total_rounds,match_id,next_node_id,next_position) values
  ('b6000000-0000-0000-0000-0000000000f3','b6000000-0000-0000-0000-0000000000c1','b6000000-0000-0000-0000-0000000000e1',2,1,2,'b6000000-0000-0000-0000-0000000000d3',null,null),
  ('b6000000-0000-0000-0000-0000000000f1','b6000000-0000-0000-0000-0000000000c1','b6000000-0000-0000-0000-0000000000e1',1,1,2,'b6000000-0000-0000-0000-0000000000d1','b6000000-0000-0000-0000-0000000000f3','player1'),
  ('b6000000-0000-0000-0000-0000000000f2','b6000000-0000-0000-0000-0000000000c1','b6000000-0000-0000-0000-0000000000e1',1,2,2,'b6000000-0000-0000-0000-0000000000d2','b6000000-0000-0000-0000-0000000000f3','player2');

-- ─── sf1 : A gagne (completed) → finale.player1 = A ─────────────────
update matches set status='completed', score1=2, score2=0,
  winner_id='b6000000-0000-0000-0000-0000000000a1'
  where id='b6000000-0000-0000-0000-0000000000d1';

select is((select player1_id from matches where id='b6000000-0000-0000-0000-0000000000d3'),
  'b6000000-0000-0000-0000-0000000000a1'::uuid,
  'cascade (bracket_nodes) : le gagnant de sf1 occupe finale.player1');
select is((select player2_id from matches where id='b6000000-0000-0000-0000-0000000000d3'),
  null::uuid,
  'ciblage de slot : player2 reste NULL tant que sf2 n''est pas jouée');
select is((select status::text from matches where id='b6000000-0000-0000-0000-0000000000d3'),
  'pending',
  'finale encore pending (un seul demi-finaliste connu → pas de scheduling)');

-- ─── sf2 : D gagne par FORFAIT (forfeited) → finale.player2 = D ──────
update matches set status='forfeited',
  winner_id='b6000000-0000-0000-0000-0000000000a4'
  where id='b6000000-0000-0000-0000-0000000000d2';

select is((select player2_id from matches where id='b6000000-0000-0000-0000-0000000000d3'),
  'b6000000-0000-0000-0000-0000000000a4'::uuid,
  'cascade : un match FORFEITED propage aussi son gagnant (finale.player2 = D)');
select is((select status::text from matches where id='b6000000-0000-0000-0000-0000000000d3'),
  'scheduled',
  'scheduling (z_, après la cascade) : finale passe scheduled une fois ses 2 joueurs présents');

-- ════════════════════════════════════════════════════════════════════
-- COMP2 — chemin direct matches.next_match_id (générateur SQL, prioritaire)
-- next_node_id volontairement NULL pour prouver que le champ direct suffit.
-- ════════════════════════════════════════════════════════════════════
insert into competitions(id,name,game,format,start_date,max_players,registration_fee,registration_currency) values
  ('b6000000-0000-0000-0000-0000000000c2','BRK2','efootball','single_elimination',now()+interval '1 day',2,0,'XOF');
insert into phases(id,competition_id,phase_order,type,status) values
  ('b6000000-0000-0000-0000-0000000000e2','b6000000-0000-0000-0000-0000000000c2',1,'knockout','ongoing');
-- finale2 a déjà un player2 (D) pour rester schedulable (évite un walkover).
insert into matches(id,competition_id,round,player2_id,status) values
  ('b6000000-0000-0000-0000-0000000000d5','b6000000-0000-0000-0000-0000000000c2',2,
   'b6000000-0000-0000-0000-0000000000a4','pending');
-- qf pointe directement final2 via next_match_id.
insert into matches(id,competition_id,round,player1_id,player2_id,status,next_match_id) values
  ('b6000000-0000-0000-0000-0000000000d4','b6000000-0000-0000-0000-0000000000c2',1,
   'b6000000-0000-0000-0000-0000000000a5','b6000000-0000-0000-0000-0000000000a6','scheduled',
   'b6000000-0000-0000-0000-0000000000d5');
-- next_position vient toujours de bracket_nodes ; next_node_id NULL ici.
insert into bracket_nodes(id,competition_id,phase_id,round_number,position_in_round,total_rounds,match_id,next_node_id,next_position) values
  ('b6000000-0000-0000-0000-0000000000f5','b6000000-0000-0000-0000-0000000000c2','b6000000-0000-0000-0000-0000000000e2',2,1,2,'b6000000-0000-0000-0000-0000000000d5',null,null),
  ('b6000000-0000-0000-0000-0000000000f4','b6000000-0000-0000-0000-0000000000c2','b6000000-0000-0000-0000-0000000000e2',1,1,2,'b6000000-0000-0000-0000-0000000000d4',null,'player1');

-- ─── qf : E gagne → final2.player1 = E (via next_match_id direct) ────
update matches set status='completed', score1=3, score2=1,
  winner_id='b6000000-0000-0000-0000-0000000000a5'
  where id='b6000000-0000-0000-0000-0000000000d4';

select is((select player1_id from matches where id='b6000000-0000-0000-0000-0000000000d5'),
  'b6000000-0000-0000-0000-0000000000a5'::uuid,
  'cascade (next_match_id direct) : le gagnant de qf occupe final2.player1');
select is((select player2_id from matches where id='b6000000-0000-0000-0000-0000000000d5'),
  'b6000000-0000-0000-0000-0000000000a4'::uuid,
  'ciblage : la cascade remplit player1 sans toucher au player2 préexistant');

select * from finish();
rollback;
