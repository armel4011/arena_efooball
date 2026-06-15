-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Recalcul automatique du classement de groupe (group_memberships)
-- ════════════════════════════════════════════════════════════════════
-- Couvre la logique métier introduite par
-- 20260615120000_auto_recalculate_group_standings.sql :
--   * seed : un membership par joueur du groupe dès l'INSERT des matchs ;
--   * recalcul P/V/N/D/BP/BC/Pts au passage completed/forfeited ;
--   * convention forfait (défaite 0 but / victoire adverse) ;
--   * départage de position (points → diff → BP) ;
--   * generate_round_robin_bracket crée un groupe unique + group_id sur ses
--     matchs (le round-robin obtient un classement).
--
-- Exécuté en superuser (bypass RLS) ; tout est annulé par le rollback final.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(12);

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('11111111-0000-0000-0000-000000000001'),  -- A
  ('11111111-0000-0000-0000-000000000002'),  -- B
  ('11111111-0000-0000-0000-000000000003'),  -- C
  ('11111111-0000-0000-0000-000000000004');  -- D (round-robin)

insert into profiles(id, username, email, country_code, referral_code, role) values
  ('11111111-0000-0000-0000-000000000001','t_std_a','a@ci.invalid','CI','STDREFA','player'),
  ('11111111-0000-0000-0000-000000000002','t_std_b','b@ci.invalid','CI','STDREFB','player'),
  ('11111111-0000-0000-0000-000000000003','t_std_c','c@ci.invalid','CI','STDREFC','player'),
  ('11111111-0000-0000-0000-000000000004','t_std_d','d@ci.invalid','CI','STDREFD','player');

insert into competitions(id,name,game,format,start_date,max_players,registration_fee,registration_currency) values
  ('22222222-0000-0000-0000-000000000001','GS-grp','efootball','groups_then_knockout',now()+interval '1 day',4,0,'XOF'),
  ('22222222-0000-0000-0000-000000000002','GS-rr','efootball','round_robin',now()+interval '1 day',4,0,'XOF');

insert into phases(id,competition_id,phase_order,type,status) values
  ('33333333-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001',1,'groups','ongoing');

insert into groups(id,competition_id,phase_id,name,group_number) values
  ('44444444-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','33333333-0000-0000-0000-000000000001','Groupe A',1);

-- 3 matchs du groupe (round null → n'entraîne pas le scheduling KO).
-- L'AFTER INSERT trigger seed les memberships.
insert into matches(id,competition_id,group_id,player1_id,player2_id,status) values
  ('55555555-0000-0000-0000-0000000000ab','22222222-0000-0000-0000-000000000001','44444444-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000002','scheduled'),
  ('55555555-0000-0000-0000-0000000000ac','22222222-0000-0000-0000-000000000001','44444444-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000003','pending'),
  ('55555555-0000-0000-0000-0000000000bc','22222222-0000-0000-0000-000000000001','44444444-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000002','11111111-0000-0000-0000-000000000003','pending');

-- 1) Seed : 3 memberships créés à 0.
select is(
  (select count(*)::int from group_memberships where group_id='44444444-0000-0000-0000-000000000001'),
  3, 'seed: 3 memberships créés dès l''INSERT des matchs');

-- ─── A bat B 2-1 ────────────────────────────────────────────────────
update matches set status='completed', score1=2, score2=1,
  winner_id='11111111-0000-0000-0000-000000000001'
  where id='55555555-0000-0000-0000-0000000000ab';

select is((select points from group_memberships
  where group_id='44444444-0000-0000-0000-000000000001' and profile_id='11111111-0000-0000-0000-000000000001'),
  3, 'A : 3 pts après une victoire');
select is((select played from group_memberships
  where group_id='44444444-0000-0000-0000-000000000001' and profile_id='11111111-0000-0000-0000-000000000002'),
  1, 'B : 1 match joué');
select is((select points from group_memberships
  where group_id='44444444-0000-0000-0000-000000000001' and profile_id='11111111-0000-0000-0000-000000000002'),
  0, 'B : 0 pt après une défaite');

-- ─── A et C font 1-1 (nul) ──────────────────────────────────────────
update matches set status='completed', score1=1, score2=1, winner_id=null
  where id='55555555-0000-0000-0000-0000000000ac';

select is((select points from group_memberships
  where group_id='44444444-0000-0000-0000-000000000001' and profile_id='11111111-0000-0000-0000-000000000001'),
  4, 'A : 4 pts (victoire + nul)');
select is((select played from group_memberships
  where group_id='44444444-0000-0000-0000-000000000001' and profile_id='11111111-0000-0000-0000-000000000001'),
  2, 'A : 2 matchs joués');
select is((select points from group_memberships
  where group_id='44444444-0000-0000-0000-000000000001' and profile_id='11111111-0000-0000-0000-000000000003'),
  1, 'C : 1 pt après un nul');

-- ─── B déclare forfait contre C (victoire C, 0 but) ─────────────────
update matches set status='forfeited',
  winner_id='11111111-0000-0000-0000-000000000003'
  where id='55555555-0000-0000-0000-0000000000bc';

select is((select points from group_memberships
  where group_id='44444444-0000-0000-0000-000000000001' and profile_id='11111111-0000-0000-0000-000000000003'),
  4, 'C : 4 pts (nul + victoire par forfait)');
select is((select losses from group_memberships
  where group_id='44444444-0000-0000-0000-000000000001' and profile_id='11111111-0000-0000-0000-000000000002'),
  2, 'B : 2 défaites (dont forfait)');

-- ─── Positions : A(4,+1) > C(4,0) > B(0,-1) ─────────────────────────
select is((select position from group_memberships
  where group_id='44444444-0000-0000-0000-000000000001' and profile_id='11111111-0000-0000-0000-000000000001'),
  1, 'position 1 = A (départage diff de buts)');
select is((select position from group_memberships
  where group_id='44444444-0000-0000-0000-000000000001' and profile_id='11111111-0000-0000-0000-000000000003'),
  2, 'position 2 = C');

-- ─── Round-robin : génère un groupe unique + group_id sur les matchs ─
insert into competition_registrations(competition_id,player_id,status) values
  ('22222222-0000-0000-0000-000000000002','11111111-0000-0000-0000-000000000001','confirmed'),
  ('22222222-0000-0000-0000-000000000002','11111111-0000-0000-0000-000000000002','confirmed'),
  ('22222222-0000-0000-0000-000000000002','11111111-0000-0000-0000-000000000003','confirmed'),
  ('22222222-0000-0000-0000-000000000002','11111111-0000-0000-0000-000000000004','confirmed');

select public.generate_round_robin_bracket('22222222-0000-0000-0000-000000000002');

select is(
  (select count(*)::int from groups where competition_id='22222222-0000-0000-0000-000000000002'),
  1, 'round-robin : un groupe unique créé');
select is(
  (select count(*)::int from matches
     where competition_id='22222222-0000-0000-0000-000000000002' and group_id is null),
  0, 'round-robin : tous les matchs ont un group_id');

select * from finish();
rollback;
