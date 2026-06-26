-- ════════════════════════════════════════════════════════════════════
-- pgTAP — generate_single_elim_bracket : propagation des vainqueurs de byes
-- ════════════════════════════════════════════════════════════════════
-- Couvre le fix audit 2026-06-26 (20260626120000) : sur un effectif non
-- puissance-de-2, le vainqueur d'un bye (round 1) doit être AVANCÉ dans le match
-- du round suivant dès la génération. Avant le fix, le Pass 4 faisait un UPDATE
-- no-op qui ne franchissait pas la garde de `cascade_match_winner` → le bye
-- winner n'avançait jamais :
--   * 3 joueurs → le 3e (bye) était éliminé sans jouer, mauvais champion ;
--   * 5 joueurs → un match du round 2 restait sans joueur → bracket figé.
--
-- Le shuffle des seeds est aléatoire : les assertions sont STRUCTURELLES
-- (indépendantes de quel joueur tire le bye). Superuser, rollback final.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(12);

-- La génération + la cascade insèrent des notifications ; on coupe le dispatch
-- FCM (pg_net) pour ce test transactionnel.
alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Joueurs ────────────────────────────────────────────────────────
insert into auth.users(id) values
  ('bb000000-0000-0000-0000-0000000000a1'),('bb000000-0000-0000-0000-0000000000a2'),
  ('bb000000-0000-0000-0000-0000000000a3'),('bb000000-0000-0000-0000-0000000000a4'),
  ('bb000000-0000-0000-0000-0000000000a5');
insert into profiles(id,username,email,country_code,referral_code,role) values
  ('bb000000-0000-0000-0000-0000000000a1','bye_a','bya@ci.invalid','CI','BYEA','player'),
  ('bb000000-0000-0000-0000-0000000000a2','bye_b','byb@ci.invalid','CI','BYEB','player'),
  ('bb000000-0000-0000-0000-0000000000a3','bye_c','byc@ci.invalid','CI','BYEC','player'),
  ('bb000000-0000-0000-0000-0000000000a4','bye_d','byd@ci.invalid','CI','BYED','player'),
  ('bb000000-0000-0000-0000-0000000000a5','bye_e','bye@ci.invalid','CI','BYEE','player');

-- ════════════════════════════════════════════════════════════════════
-- SCÉNARIO 1 — 3 joueurs (size=4, 1 bye) : « mauvais champion »
-- auto_generate_bracket=false → on appelle le générateur manuellement.
-- ════════════════════════════════════════════════════════════════════
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,auto_generate_bracket) values
  ('bb000000-0000-0000-0000-0000000000c1','BYE3','efootball','single_elimination','registration_closed',now()+interval '1 hour',4,0,'XOF',false);
insert into competition_registrations(competition_id,player_id,status) values
  ('bb000000-0000-0000-0000-0000000000c1','bb000000-0000-0000-0000-0000000000a1','confirmed'),
  ('bb000000-0000-0000-0000-0000000000c1','bb000000-0000-0000-0000-0000000000a2','confirmed'),
  ('bb000000-0000-0000-0000-0000000000c1','bb000000-0000-0000-0000-0000000000a3','confirmed');

select generate_single_elim_bracket('bb000000-0000-0000-0000-0000000000c1');

-- Structure attendue : 2 matchs round 1 (1 réel scheduled + 1 bye forfeited) + 1 finale.
select is(
  (select count(*)::int from matches where competition_id='bb000000-0000-0000-0000-0000000000c1'),
  3, '3 joueurs → 3 matchs générés (2 round1 + finale)');
select is(
  (select count(*)::int from matches where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=1 and status='forfeited'),
  1, 'round 1 : exactement 1 match bye (forfeited)');
select is(
  (select count(*)::int from matches where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=1 and status='scheduled'),
  1, 'round 1 : exactement 1 match réel (scheduled)');
select ok(
  (select winner_id from matches where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=1 and status='forfeited')
    in (select player_id from competition_registrations where competition_id='bb000000-0000-0000-0000-0000000000c1' and status='confirmed'),
  'le bye a un winner = un inscrit confirmé');

-- ★ Cœur du fix : juste après génération, la finale contient DÉJÀ le bye winner
--   (1 seul slot rempli, l'autre attend le match réel). Avant le fix → 0 slot.
select is(
  (select (case when player1_id is not null then 1 else 0 end)
        + (case when player2_id is not null then 1 else 0 end)
     from matches where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=2),
  1, '★ finale : le bye winner est avancé dès la génération (1 slot rempli)');
select is(
  (select coalesce(player1_id, player2_id) from matches where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=2),
  (select winner_id from matches where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=1 and status='forfeited'),
  '★ le joueur avancé en finale EST le vainqueur du bye');

-- Stash des valeurs avant de jouer le match réel.
create temp table se3 as
select
  (select winner_id  from matches where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=1 and status='forfeited') as bye_winner,
  (select player1_id from matches where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=1 and status='scheduled') as real_winner;

-- On joue le match réel (player1 gagne) → cascade + scheduling.
update matches
   set status='completed'::match_status, winner_id=player1_id, score1=1, score2=0, finished_at=now()
 where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=1 and status='scheduled';

select is(
  (select (case when player1_id is not null then 1 else 0 end)
        + (case when player2_id is not null then 1 else 0 end)
     from matches where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=2),
  2, 'finale : 2 joueurs présents une fois le match réel joué');
select is(
  (select status::text from matches where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=2),
  'scheduled', 'finale jouée normalement (scheduled), PAS un walkover qui aurait spolié le bye winner');
select ok(
  (select array[player1_id, player2_id] @> array[(select bye_winner from se3), (select real_winner from se3)]
     from matches where competition_id='bb000000-0000-0000-0000-0000000000c1' and round=2),
  'finale = bye winner vs vainqueur du match réel');

-- ════════════════════════════════════════════════════════════════════
-- SCÉNARIO 2 — 5 joueurs (size=8, 3 byes) : « anti-deadlock »
-- ════════════════════════════════════════════════════════════════════
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,auto_generate_bracket) values
  ('bb000000-0000-0000-0000-0000000000c2','BYE5','efootball','single_elimination','registration_closed',now()+interval '1 hour',8,0,'XOF',false);
insert into competition_registrations(competition_id,player_id,status) values
  ('bb000000-0000-0000-0000-0000000000c2','bb000000-0000-0000-0000-0000000000a1','confirmed'),
  ('bb000000-0000-0000-0000-0000000000c2','bb000000-0000-0000-0000-0000000000a2','confirmed'),
  ('bb000000-0000-0000-0000-0000000000c2','bb000000-0000-0000-0000-0000000000a3','confirmed'),
  ('bb000000-0000-0000-0000-0000000000c2','bb000000-0000-0000-0000-0000000000a4','confirmed'),
  ('bb000000-0000-0000-0000-0000000000c2','bb000000-0000-0000-0000-0000000000a5','confirmed');

select generate_single_elim_bracket('bb000000-0000-0000-0000-0000000000c2');

-- Il existe au moins un bye round-1 avec un vrai vainqueur (le 5e seed).
select ok(
  (select count(*)::int from matches
     where competition_id='bb000000-0000-0000-0000-0000000000c2' and round=1
       and status='forfeited' and winner_id is not null) >= 1,
  '5 joueurs : au moins 1 bye round-1 avec un vainqueur réel');

-- ★ Anti-deadlock : ce vainqueur de bye est présent dans un match du round 2
--   dès la génération (avant le fix : présent nulle part → match round-2 orphelin).
select ok(
  (select winner_id from matches
     where competition_id='bb000000-0000-0000-0000-0000000000c2' and round=1
       and status='forfeited' and winner_id is not null limit 1)
   in (
     select player1_id from matches where competition_id='bb000000-0000-0000-0000-0000000000c2' and round=2
     union all
     select player2_id from matches where competition_id='bb000000-0000-0000-0000-0000000000c2' and round=2
   ),
  '★ le bye winner est avancé dans un match du round 2 (pas d''orphelin)');

-- On joue les 2 matchs réels du round 1 → la chaîne (cascade + walkover) ne doit
-- laisser AUCUN match round-2 figé sans joueur.
update matches
   set status='completed'::match_status, winner_id=player1_id, score1=1, score2=0, finished_at=now()
 where competition_id='bb000000-0000-0000-0000-0000000000c2' and round=1 and status='scheduled';

select is(
  (select count(*)::int from matches
     where competition_id='bb000000-0000-0000-0000-0000000000c2' and round=2
       and status='pending' and player1_id is null and player2_id is null),
  0, '★ aucun match round-2 figé sans joueur après le round 1 (pas de deadlock)');

select * from finish();
rollback;
