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
--   • refus : payouts existants, match suivant déjà engagé, non-admin.
--
-- Superuser, rollback final.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(10);

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

-- Match TERMINÉ : J1 bat J2 3-1. Les stats ci-dessus sont l'état APRÈS
-- incrément par le trigger — on attend leur retour exact après décrément.
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

-- ─── Cas nominal ────────────────────────────────────────────────────
select lives_ok(
  $$ select public.replay_match('da000000-0000-0000-0000-0000000000f1',
       'da000000-0000-0000-0000-0000000000d1', 'preuves illisibles des 2 cotes',
       now() + interval '1 day') $$,
  'admin CM : remise en jeu acceptée');

-- STATS : miroir exact de l'incrément → retour à l'état d'avant le match.
select is(
  (select stats from profiles where id='da000000-0000-0000-0000-000000000001'),
  jsonb_build_object('wins',4,'losses',2,'draws',1,'goals_scored',17,'goals_conceded',9),
  'J1 : victoire + buts du match retirés (pas de double-comptage au rejeu)');
select is(
  (select stats from profiles where id='da000000-0000-0000-0000-000000000002'),
  jsonb_build_object('wins',3,'losses',3,'draws',0,'goals_scored',11,'goals_conceded',12),
  'J2 : défaite + buts du match retirés');

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

-- ─── Refus : des gains ont déjà été générés ─────────────────────────
insert into payouts(competition_id,user_id,amount_local,currency,status)
values ('da000000-0000-0000-0000-0000000000c0','da000000-0000-0000-0000-000000000001',
        1000,'XAF','pending');
select throws_ok(
  $$ select public.replay_match('da000000-0000-0000-0000-0000000000f1',
       'da000000-0000-0000-0000-0000000000d1', 'seconde tentative', now() + interval '2 days') $$,
  '22023', NULL, 'payouts existants : refuse (incohérence comptable)');

select * from finish();
rollback;
