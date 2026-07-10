-- ════════════════════════════════════════════════════════════════════
-- pgTAP — resolve_dispute (arbitrage litige / argent)
-- ════════════════════════════════════════════════════════════════════
-- P0 audit 2026-06-24 : la RPC écrivait `winner_id = p_winner_id` SANS
-- vérifier que ce joueur participe au match → un admin pouvait désigner un
-- complice (même non-inscrit) vainqueur d'une finale → versement détourné.
-- Couvre : gate is_admin(), justification obligatoire, validation du vainqueur
-- (∈ {player1, player2}), scores >= 0, le chemin nominal (verdict + litige
-- résolu dans la même transaction), et le durcissement 2026-06-25 (super-admin
-- requis pour arbitrer un match rattaché à une compétition AVEC PRIX).
--
-- Les triggers de cascade bracket/stats/standings sont neutralisés : on teste
-- la logique propre de resolve_dispute, pas l'avancement du tournoi.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(9);

alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;
alter table public.matches disable trigger z_auto_schedule_next_round_on_match_complete;
alter table public.matches disable trigger trg_notify_match_room_activated_upd;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('6d6d6d6d-0000-0000-0000-000000000001'),  -- admin
  ('6d6d6d6d-0000-0000-0000-000000000002'),  -- super-admin
  ('6d6d6d6d-0000-0000-0000-0000000000a1'),  -- joueur 1 (player1)
  ('6d6d6d6d-0000-0000-0000-0000000000a2'),  -- joueur 2 (player2)
  ('6d6d6d6d-0000-0000-0000-0000000000a9');  -- tiers NON joueur du match
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('6d6d6d6d-0000-0000-0000-000000000001','rd_adm','rda@ci.invalid','CI','RDA','admin',true),
  ('6d6d6d6d-0000-0000-0000-000000000002','rd_sa','rdsa@ci.invalid','CI','RDSA','super_admin',true),
  ('6d6d6d6d-0000-0000-0000-0000000000a1','rd_a','rd1@ci.invalid','CI','RD1','player',true),
  ('6d6d6d6d-0000-0000-0000-0000000000a2','rd_b','rd2@ci.invalid','CI','RD2','player',true),
  ('6d6d6d6d-0000-0000-0000-0000000000a9','rd_x','rd9@ci.invalid','CI','RD9','player',true);

-- c1 : compétition SANS prix (prize_pool_local défaut 0) → admin simple OK.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency)
values ('6e6e6e6e-0000-0000-0000-000000000001','RD','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF');
-- c2 : compétition AVEC prix (cagnotte 50000) → super-admin requis.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,prize_pool_local)
values ('6e6e6e6e-0000-0000-0000-000000000002','RDPRIZE','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF',50000);

insert into matches(id,competition_id,status,player1_id,player2_id) values
  ('6f6f6f6f-0000-0000-0000-000000000001','6e6e6e6e-0000-0000-0000-000000000001','disputed',
   '6d6d6d6d-0000-0000-0000-0000000000a1','6d6d6d6d-0000-0000-0000-0000000000a2'),
  ('6f6f6f6f-0000-0000-0000-000000000002','6e6e6e6e-0000-0000-0000-000000000002','disputed',
   '6d6d6d6d-0000-0000-0000-0000000000a1','6d6d6d6d-0000-0000-0000-0000000000a2');

insert into disputes(id,match_id,opened_by,status) values
  ('60606060-0000-0000-0000-000000000001','6f6f6f6f-0000-0000-0000-000000000001',
   '6d6d6d6d-0000-0000-0000-0000000000a1','open'),
  ('60606060-0000-0000-0000-000000000002','6f6f6f6f-0000-0000-0000-000000000002',
   '6d6d6d6d-0000-0000-0000-0000000000a1','open');

-- ─── Gate : un non-admin ne peut pas arbitrer ───────────────────────
set local request.jwt.claims = '{"sub":"6d6d6d6d-0000-0000-0000-0000000000a1"}';
select throws_ok(
  $$ select public.resolve_dispute('6f6f6f6f-0000-0000-0000-000000000001',
       '60606060-0000-0000-0000-000000000001','triche', false,
       '6d6d6d6d-0000-0000-0000-0000000000a1', 3, 1) $$,
  '42501', null, 'un non-admin ne peut pas résoudre un litige');

-- ─── En admin ───────────────────────────────────────────────────────
set local request.jwt.claims = '{"sub":"6d6d6d6d-0000-0000-0000-000000000001"}';

-- P0 : vainqueur hors des deux joueurs du match → rejet
select throws_ok(
  $$ select public.resolve_dispute('6f6f6f6f-0000-0000-0000-000000000001',
       '60606060-0000-0000-0000-000000000001','verdict', false,
       '6d6d6d6d-0000-0000-0000-0000000000a9', 3, 1) $$,
  '22023', null, 'P0 : un vainqueur qui ne joue pas le match est refusé');

-- P0 : score négatif → rejet
select throws_ok(
  $$ select public.resolve_dispute('6f6f6f6f-0000-0000-0000-000000000001',
       '60606060-0000-0000-0000-000000000001','verdict', false,
       '6d6d6d6d-0000-0000-0000-0000000000a1', -1, 1) $$,
  '22023', null, 'P0 : un score négatif est refusé');

-- ─── Chemin nominal : vainqueur valide ──────────────────────────────
select lives_ok(
  $$ select public.resolve_dispute('6f6f6f6f-0000-0000-0000-000000000001',
       '60606060-0000-0000-0000-000000000001','player1 gagne 3-1', false,
       '6d6d6d6d-0000-0000-0000-0000000000a1', 3, 1) $$,
  'verdict valide accepté (vainqueur = player1)');

select is(
  (select winner_id from matches where id='6f6f6f6f-0000-0000-0000-000000000001'),
  '6d6d6d6d-0000-0000-0000-0000000000a1'::uuid, 'le vainqueur enregistré est bien player1');
select is(
  (select status from matches where id='6f6f6f6f-0000-0000-0000-000000000001')::text,
  'completed', 'le match passe à completed');
select is(
  (select status from disputes where id='60606060-0000-0000-0000-000000000001'),
  'resolved', 'le litige passe à resolved (même transaction)');

-- ─── Durcissement 2026-06-25 : match à cagnotte → super-admin requis ──
-- (jwt encore en admin simple) refus sur le match de la compétition à prix
select throws_ok(
  $$ select public.resolve_dispute('6f6f6f6f-0000-0000-0000-000000000002',
       '60606060-0000-0000-0000-000000000002','verdict', false,
       '6d6d6d6d-0000-0000-0000-0000000000a1', 3, 1) $$,
  '42501', null, 'un admin simple ne peut pas arbitrer un match à cagnotte');

-- en super-admin, le même arbitrage est accepté
set local request.jwt.claims = '{"sub":"6d6d6d6d-0000-0000-0000-000000000002"}';
select lives_ok(
  $$ select public.resolve_dispute('6f6f6f6f-0000-0000-0000-000000000002',
       '60606060-0000-0000-0000-000000000002','verdict super-admin', false,
       '6d6d6d6d-0000-0000-0000-0000000000a1', 3, 1) $$,
  'un super-admin peut arbitrer un match à cagnotte');

select * from finish();
rollback;
