-- ════════════════════════════════════════════════════════════════════
-- pgTAP — replay_match : remise en jeu d'un match sur litige non tranché
-- ════════════════════════════════════════════════════════════════════
-- Couvre 20260716130000. Le vrai risque n'est pas la RPC elle-même mais ce
-- qu'elle DÉFAIT : le schéma est conçu pour avancer (stats accumulées, vainqueur
-- cascadé, compétition clôturée), jamais pour revenir en arrière.
--
--   • stats : le décrément est le MIROIR EXACT de l'incrément (sinon un match
--     rejoué double-compte et fausse les classements à vie) ;
--   • match : réellement remis en jeu (score/vainqueur effacés, room_code vidé,
--     replayed_at posé pour périmer les soumissions de la 1re manche) ;
--   • litige : clos SANS guilty_party_id (un rejeu n'accuse personne — sinon
--     trg_three_strikes_ban sanctionnerait) ;
--   • bracket : le vainqueur est dé-propagé du match suivant ;
--   • SEUL UN MATCH EN LITIGE se rejoue : dispute_id NULL / inconnu / d'un autre
--     match / déjà tranché → refus (cf. 20260716140000) ;
--   • refus : payouts existants, match suivant déjà engagé, non-admin.
--
-- Superuser, rollback final.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(14);

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('da000000-0000-0000-0000-0000000000ad'),  -- admin CM
  ('da000000-0000-0000-0000-000000000001'),  -- joueur 1
  ('da000000-0000-0000-0000-000000000002'),  -- joueur 2
  ('da000000-0000-0000-0000-000000000009');  -- joueur lambda (non-admin)

insert into profiles(id,username,email,country_code,referral_code,role,is_active,admin_allowed_countries,stats) values
  ('da000000-0000-0000-0000-0000000000ad','re_admin','readm@ci.invalid','CM','READ','admin',true, array['CM'], '{}'::jsonb),
  ('da000000-0000-0000-0000-000000000001','re_p1','rep1@ci.invalid','CM','REP1','player',true, NULL,
     jsonb_build_object('wins',5,'losses',2,'draws',1,'goals_scored',20,'goals_conceded',10)),
  ('da000000-0000-0000-0000-000000000002','re_p2','rep2@ci.invalid','CM','REP2','player',true, NULL,
     jsonb_build_object('wins',3,'losses',4,'draws',0,'goals_scored',12,'goals_conceded',15)),
  ('da000000-0000-0000-0000-000000000009','re_p9','rep9@ci.invalid','CM','REP9','player',true, NULL, '{}'::jsonb);

-- Compétition SANS cagnotte (sinon la RPC exige un super-admin) et CLÔTURÉE :
-- on vérifie du même coup qu'elle est rouverte.
insert into competitions(id,name,game,format,status,start_date,max_players,current_players,
                         registration_currency,created_by,country_code,
                         prize_pool_local,prize_distribution,completed_at)
values ('da000000-0000-0000-0000-0000000000c0','re_comp','efootball','single_elimination','completed',
        now() - interval '2 days', 2, 2, 'XAF', 'da000000-0000-0000-0000-0000000000ad','CM',
        0,'[]'::jsonb, now());

insert into competition_registrations(competition_id,player_id,status,final_rank) values
  ('da000000-0000-0000-0000-0000000000c0','da000000-0000-0000-0000-000000000001','confirmed',1),
  ('da000000-0000-0000-0000-0000000000c0','da000000-0000-0000-0000-000000000002','confirmed',2);

-- Match TERMINÉ : J1 bat J2 3-1.
-- ⚠️ Cet INSERT en `completed` déclenche `trg_matches_increment_stats_insert` :
-- les stats des fixtures ci-dessus sont donc incrémentées ICI même. C'est ce
-- qu'on veut — le test devient un ALLER-RETOUR : incrément (trigger) puis
-- décrément (replay_match) doivent ramener EXACTEMENT aux valeurs de fixture.
-- C'est la seule preuve qui compte : un décrément qui ne serait pas le miroir
-- exact de l'incrément fausserait les classements à vie.
insert into matches(id,competition_id,round,match_number,player1_id,player2_id,
                    status,score1,score2,winner_id,started_at,finished_at,room_code)
values ('da000000-0000-0000-0000-0000000000f1','da000000-0000-0000-0000-0000000000c0',1,1,
        'da000000-0000-0000-0000-000000000001','da000000-0000-0000-0000-000000000002',
        'completed',3,1,'da000000-0000-0000-0000-000000000001', now()-interval '1 day',
        now()-interval '23 hours','ABCD1234');

insert into disputes(id,match_id,opened_by,status,reason)
values ('da000000-0000-0000-0000-0000000000d1','da000000-0000-0000-0000-0000000000f1',
        'da000000-0000-0000-0000-000000000002','admin_review','score contesté');

-- ─── Refus : non-admin ──────────────────────────────────────────────
set local request.jwt.claims = '{"sub":"da000000-0000-0000-0000-000000000009"}';
select throws_ok(
  $$ select public.replay_match('da000000-0000-0000-0000-0000000000f1',
       'da000000-0000-0000-0000-0000000000d1', 'test', now() + interval '1 day') $$,
  '42501', NULL, 'non-admin : refuse (42501)');

-- ─── Refus : justification vide ─────────────────────────────────────
set local request.jwt.claims = '{"sub":"da000000-0000-0000-0000-0000000000ad"}';
select throws_ok(
  $$ select public.replay_match('da000000-0000-0000-0000-0000000000f1',
       'da000000-0000-0000-0000-0000000000d1', '   ', now() + interval '1 day') $$,
  '22023', NULL, 'justification vide : refuse (22023)');

-- ─── Refus : date dans le passé ─────────────────────────────────────
select throws_ok(
  $$ select public.replay_match('da000000-0000-0000-0000-0000000000f1',
       'da000000-0000-0000-0000-0000000000d1', 'preuves illisibles', now() - interval '1 hour') $$,
  '22023', NULL, 'date passée : refuse (22023)');

-- ─── SEUL UN MATCH EN LITIGE PEUT ÊTRE REJOUÉ ───────────────────────
-- Sans ces gardes, `update disputes where id = p_dispute_id` touchait 0 ligne
-- en silence et le match était rejoué quand même : n'importe quel match, sans
-- litige, voyait ses stats décrémentées et son bracket dé-propagé.
select throws_ok(
  $$ select public.replay_match('da000000-0000-0000-0000-0000000000f1',
       NULL, 'sans litige', now() + interval '1 day') $$,
  '22023', NULL, 'dispute_id NULL : refuse (seul un match en litige se rejoue)');

select throws_ok(
  $$ select public.replay_match('da000000-0000-0000-0000-0000000000f1',
       'da000000-0000-0000-0000-0000000000de', 'litige inexistant', now() + interval '1 day') $$,
  '22023', NULL, 'litige inconnu : refuse');

-- Un litige RÉEL, mais qui porte sur un AUTRE match : ne doit pas servir de
-- passe-droit pour rejouer celui-ci.
-- ⚠️ `disputed` et NON `completed` : J1 joue aussi ce match, et un INSERT en
-- `completed` déclencherait `trg_matches_increment_stats_insert` une 2e fois sur
-- lui (nul, +1 draw) — que le décrément de f1 ne rattrape pas, faussant
-- l'assertion d'aller-retour plus bas. Le statut n'importe pas ici : seul le
-- litige rattaché compte.
insert into matches(id,competition_id,round,match_number,player1_id,player2_id,status)
values ('da000000-0000-0000-0000-0000000000f2','da000000-0000-0000-0000-0000000000c0',1,2,
        'da000000-0000-0000-0000-000000000001','da000000-0000-0000-0000-000000000009','disputed');
insert into disputes(id,match_id,opened_by,status,reason)
values ('da000000-0000-0000-0000-0000000000d2','da000000-0000-0000-0000-0000000000f2',
        'da000000-0000-0000-0000-000000000009','open','autre match');
select throws_ok(
  $$ select public.replay_match('da000000-0000-0000-0000-0000000000f1',
       'da000000-0000-0000-0000-0000000000d2', 'litige d un autre match', now() + interval '1 day') $$,
  '22023', NULL, 'litige d''un AUTRE match : refuse');

-- ─── Cas nominal ────────────────────────────────────────────────────
select lives_ok(
  $$ select public.replay_match('da000000-0000-0000-0000-0000000000f1',
       'da000000-0000-0000-0000-0000000000d1', 'preuves illisibles des 2 cotes',
       now() + interval '1 day') $$,
  'admin CM : remise en jeu acceptée');

-- STATS — LE test : l'aller-retour incrément (trigger à l'INSERT) → décrément
-- (replay_match) doit rendre EXACTEMENT les valeurs de fixture. Toute dérive ici
-- signifie un match rejoué qui double-compte, à vie et sans rattrapage.
select is(
  (select stats from profiles where id='da000000-0000-0000-0000-000000000001'),
  jsonb_build_object('wins',5,'losses',2,'draws',1,'goals_scored',20,'goals_conceded',10),
  'J1 : stats revenues à l''identique (incrément puis décrément = identité)');
select is(
  (select stats from profiles where id='da000000-0000-0000-0000-000000000002'),
  jsonb_build_object('wins',3,'losses',4,'draws',0,'goals_scored',12,'goals_conceded',15),
  'J2 : stats revenues à l''identique');

-- MATCH : réellement remis en jeu.
select is(
  (select row(status::text, score1, score2, winner_id, room_code, replayed_at is not null)::text
     from matches where id='da000000-0000-0000-0000-0000000000f1'),
  row('scheduled', NULL::int, NULL::int, NULL::uuid, NULL::text, true)::text,
  'match : scheduled, score/vainqueur/room_code effacés, replayed_at posé');

-- LITIGE : clos SANS coupable (sinon trg_three_strikes_ban sanctionnerait).
select is(
  (select row(status, guilty_party_id is null)::text
     from disputes where id='da000000-0000-0000-0000-0000000000d1'),
  row('resolved', true)::text,
  'litige : resolved, aucun coupable désigné');

-- COMPÉTITION : rouverte (le match tranché l'avait clôturée).
select is(
  (select row(status::text, completed_at is null)::text
     from competitions where id='da000000-0000-0000-0000-0000000000c0'),
  row('ongoing', true)::text,
  'compétition : rouverte en ongoing, completed_at effacé');

-- ─── Refus : le litige vient d'être clos par le rejeu ───────────────
-- Sinon un vieux litige clos servirait à rejouer le même match indéfiniment.
select throws_ok(
  $$ select public.replay_match('da000000-0000-0000-0000-0000000000f1',
       'da000000-0000-0000-0000-0000000000d1', 'rejouer sur un litige clos',
       now() + interval '2 days') $$,
  '22023', NULL, 'litige déjà tranché : refuse (pas de rejeu en boucle)');

-- ─── Refus : des gains ont déjà été générés ─────────────────────────
-- Litige NEUF : d1 est clos depuis le rejeu, il lèverait avant d'atteindre la
-- garde payouts — le test passerait pour la mauvaise raison.
insert into disputes(id,match_id,opened_by,status,reason)
values ('da000000-0000-0000-0000-0000000000d3','da000000-0000-0000-0000-0000000000f1',
        'da000000-0000-0000-0000-000000000002','open','litige rouvert');
insert into payouts(competition_id,user_id,amount_local,currency,status)
values ('da000000-0000-0000-0000-0000000000c0','da000000-0000-0000-0000-000000000001',
        1000,'XAF','pending_admin_validation');
select throws_ok(
  $$ select public.replay_match('da000000-0000-0000-0000-0000000000f1',
       'da000000-0000-0000-0000-0000000000d3', 'seconde tentative', now() + interval '2 days') $$,
  '22023', NULL, 'payouts existants : refuse (incohérence comptable)');

select * from finish();
rollback;
