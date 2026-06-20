-- ════════════════════════════════════════════════════════════════════
-- pgTAP — profiles.stats : compteur de carrière + rebuild
-- ════════════════════════════════════════════════════════════════════
-- Couvre la logique « compteur de carrière permanent » (migrations
-- 20260516150001 → 20260615220000) qui alimente leaderboards & profils :
--   * INCRÉMENT au passage d'un match à `completed` (UPDATE et INSERT),
--     pour les 2 joueurs, avec buts marqués/encaissés selon le côté ;
--   * victoire / défaite / NUL (winner_id null) ;
--   * BYE : player2 null → un seul incrément, pas de crash ;
--   * accumulation sur plusieurs matchs (jamais recalculé depuis zéro) ;
--   * career model : SUPPRIMER un match completed ne décrémente PAS ;
--   * `recalculate_player_stats` = REBUILD destructif (somme des matchs
--     actuels) — outil manuel, diverge volontairement du compteur.
--
-- Exécuté en superuser (bypass RLS / guards) ; rollback final.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(16);

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('a5000000-0000-0000-0000-0000000000a1'),  -- A
  ('a5000000-0000-0000-0000-0000000000a2'),  -- B
  ('a5000000-0000-0000-0000-0000000000a3'),  -- C
  ('a5000000-0000-0000-0000-0000000000a4');  -- D
insert into profiles(id,username,email,country_code,referral_code,role) values
  ('a5000000-0000-0000-0000-0000000000a1','st_a','sta@ci.invalid','CI','STATA','player'),
  ('a5000000-0000-0000-0000-0000000000a2','st_b','stb@ci.invalid','CI','STATB','player'),
  ('a5000000-0000-0000-0000-0000000000a3','st_c','stc@ci.invalid','CI','STATC','player'),
  ('a5000000-0000-0000-0000-0000000000a4','st_d','std@ci.invalid','CI','STATD','player');
insert into competitions(id,name,game,format,start_date,max_players,registration_fee,registration_currency) values
  ('a5000000-0000-0000-0000-0000000000c1','STATS','efootball','single_elimination',now()+interval '1 day',4,0,'XOF');

-- Matchs hors-bracket (round null → pas de scheduling, group_id null → pas de
-- classement de groupe) pour isoler le trigger de stats.
-- m1 : A vs B (passera completed via UPDATE).
insert into matches(id,competition_id,player1_id,player2_id,status) values
  ('a5000000-0000-0000-0000-0000000000d1','a5000000-0000-0000-0000-0000000000c1',
   'a5000000-0000-0000-0000-0000000000a1','a5000000-0000-0000-0000-0000000000a2','scheduled');

-- État initial : aucun match completed → pas d'incrément encore.
select ok(
  coalesce((select (stats->>'wins')::int from profiles where id='a5000000-0000-0000-0000-0000000000a1'),0) = 0,
  'A : 0 victoire avant tout match terminé');

-- ─── A bat B 3-1 (UPDATE → completed) ───────────────────────────────
update matches set status='completed', score1=3, score2=1,
  winner_id='a5000000-0000-0000-0000-0000000000a1'
  where id='a5000000-0000-0000-0000-0000000000d1';

select is((select (stats->>'wins')::int from profiles where id='a5000000-0000-0000-0000-0000000000a1'),
  1, 'A : +1 victoire');
select is((select (stats->>'goals_scored')::int from profiles where id='a5000000-0000-0000-0000-0000000000a1'),
  3, 'A : +3 buts marqués (score de son côté player1)');
select is((select (stats->>'goals_conceded')::int from profiles where id='a5000000-0000-0000-0000-0000000000a1'),
  1, 'A : +1 but encaissé');
select is((select (stats->>'losses')::int from profiles where id='a5000000-0000-0000-0000-0000000000a2'),
  1, 'B : +1 défaite');
select is((select (stats->>'goals_scored')::int from profiles where id='a5000000-0000-0000-0000-0000000000a2'),
  1, 'B : buts marqués = score2 (côté player2)');

-- ─── Pas de double-comptage : re-UPDATE d'un match déjà completed ────
update matches set score1=9
  where id='a5000000-0000-0000-0000-0000000000d1';
select is((select (stats->>'wins')::int from profiles where id='a5000000-0000-0000-0000-0000000000a1'),
  1, 'A : toujours 1 victoire (pas de re-incrément sur un match déjà completed)');

-- ─── A vs C : nul 2-2 (winner_id null) ──────────────────────────────
insert into matches(id,competition_id,player1_id,player2_id,status,score1,score2,winner_id) values
  ('a5000000-0000-0000-0000-0000000000d2','a5000000-0000-0000-0000-0000000000c1',
   'a5000000-0000-0000-0000-0000000000a1','a5000000-0000-0000-0000-0000000000a3','completed',2,2,null);

select is((select (stats->>'draws')::int from profiles where id='a5000000-0000-0000-0000-0000000000a1'),
  1, 'A : +1 nul');
select is((select (stats->>'wins')::int from profiles where id='a5000000-0000-0000-0000-0000000000a1'),
  1, 'A : un nul n''ajoute pas de victoire');
select is((select (stats->>'goals_scored')::int from profiles where id='a5000000-0000-0000-0000-0000000000a1'),
  5, 'A : buts marqués cumulés (3 + 2)');
select is((select (stats->>'draws')::int from profiles where id='a5000000-0000-0000-0000-0000000000a3'),
  1, 'C : +1 nul');

-- ─── INSERT direct d'un match completed : D bat C 5-0 ───────────────
insert into matches(id,competition_id,player1_id,player2_id,status,score1,score2,winner_id) values
  ('a5000000-0000-0000-0000-0000000000d3','a5000000-0000-0000-0000-0000000000c1',
   'a5000000-0000-0000-0000-0000000000a4','a5000000-0000-0000-0000-0000000000a3','completed',5,0,
   'a5000000-0000-0000-0000-0000000000a4');

select is((select (stats->>'wins')::int from profiles where id='a5000000-0000-0000-0000-0000000000a4'),
  1, 'D : +1 victoire via INSERT completed direct');
select is((select (stats->>'goals_conceded')::int from profiles where id='a5000000-0000-0000-0000-0000000000a3'),
  7, 'C : buts encaissés cumulés (2 du nul + 5)');

-- ─── BYE : player2 null → un seul incrément, pas de crash ───────────
insert into matches(id,competition_id,player1_id,player2_id,status,score1,score2,winner_id) values
  ('a5000000-0000-0000-0000-0000000000d4','a5000000-0000-0000-0000-0000000000c1',
   'a5000000-0000-0000-0000-0000000000a2',null,'completed',1,0,
   'a5000000-0000-0000-0000-0000000000a2');
select is((select (stats->>'wins')::int from profiles where id='a5000000-0000-0000-0000-0000000000a2'),
  1, 'B : +1 victoire sur BYE (player2 null, pas d''erreur)');

-- ─── Career model : SUPPRIMER un match completed ne décrémente PAS ───
delete from matches where id='a5000000-0000-0000-0000-0000000000d1';  -- A vs B
select is((select (stats->>'wins')::int from profiles where id='a5000000-0000-0000-0000-0000000000a1'),
  1, 'A : victoire conservée après suppression du match (compteur permanent)');

-- ─── recalculate_player_stats = REBUILD destructif (somme des matchs
--     completed ACTUELS). A n'a plus que le nul A-vs-C → wins 0. ──────
select is(
  (public.recalculate_player_stats('a5000000-0000-0000-0000-0000000000a1')->>'wins')::int,
  0, 'rebuild : A redescend à 0 victoire (seul le nul subsiste) — rebuild destructif');

select * from finish();
rollback;
