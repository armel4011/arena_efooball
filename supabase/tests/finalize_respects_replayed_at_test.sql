-- ════════════════════════════════════════════════════════════════════
-- pgTAP — un match rejoué ne se re-finalise pas sur l'ancienne manche
-- ════════════════════════════════════════════════════════════════════
-- Régression 20260717200000. AVANT, `finalize_match_score` relisait la dernière
-- soumission de chaque joueur SANS borner à `replayed_at` : juste après un
-- `replay_match`, le joueur favorisé rappelait la RPC et les soumissions
-- périmées (concordantes, puisque le match avait été finalisé avec) le
-- re-déclaraient vainqueur. La décision de rejeu de l'admin était annulée.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(3);

alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;
alter table public.matches disable trigger z_auto_schedule_next_round_on_match_complete;
alter table public.matches disable trigger trg_notify_match_room_activated_upd;

insert into auth.users(id) values
  ('e1000000-0000-0000-0000-0000000000a1'),
  ('e1000000-0000-0000-0000-0000000000a2');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('e1000000-0000-0000-0000-0000000000a1','rp_a','rpa@ci.invalid','CM','RPA1','player',true),
  ('e1000000-0000-0000-0000-0000000000a2','rp_b','rpb@ci.invalid','CM','RPB1','player',true);

-- Compétition SANS cagnotte : isole le contrat `replayed_at` du soft-gate de
-- preuve (competition_has_prize=false → la branche preuve n'est pas prise).
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code)
values ('e1000000-0000-0000-0000-00000000c001','REPLAY','efootball','single_elimination','ongoing',
        now() - interval '1 day',4,0,'XOF','CM');

-- Le match a été REJOUÉ il y a une minute (ce que fait `replay_match`).
insert into matches(id,competition_id,round,status,player1_id,player2_id,scheduled_at,replayed_at) values
  ('e1000000-0000-0000-0000-000000000011','e1000000-0000-0000-0000-00000000c001',1,'scheduled',
   'e1000000-0000-0000-0000-0000000000a1','e1000000-0000-0000-0000-0000000000a2',
   now() - interval '2 minutes', now() - interval '1 minute');

-- Les soumissions 3-0 de la manche PÉRIMÉE (antérieures au rejeu).
insert into match_events(match_id, type, created_by, payload, created_at) values
  ('e1000000-0000-0000-0000-000000000011','score_submitted','e1000000-0000-0000-0000-0000000000a1',
   '{"score1":3,"score2":0}'::jsonb, now() - interval '10 minutes'),
  ('e1000000-0000-0000-0000-000000000011','score_submitted','e1000000-0000-0000-0000-0000000000a2',
   '{"score1":3,"score2":0}'::jsonb, now() - interval '9 minutes');

set local role authenticated;
set local request.jwt.claims = '{"sub":"e1000000-0000-0000-0000-0000000000a1","role":"authenticated"}';

-- L'ATTAQUE : le joueur favorisé re-finalise l'ancien score juste après le rejeu.
select throws_ok(
  $$select public.finalize_match_score('e1000000-0000-0000-0000-000000000011'::uuid)$$,
  '22023',
  'Finalisation impossible : les deux joueurs doivent avoir soumis un score',
  'les soumissions anterieures au rejeu sont ignorees');

select is(
  (select status::text from matches where id='e1000000-0000-0000-0000-000000000011'),
  'scheduled',
  'le match rejoue reste a rejouer (non re-finalise)');

-- CONTRE-ÉPREUVE : de NOUVELLES soumissions (postérieures au rejeu) finalisent
-- normalement — le filtre ne casse pas le rejeu lui-même.
reset role;
insert into match_events(match_id, type, created_by, payload, created_at) values
  ('e1000000-0000-0000-0000-000000000011','score_submitted','e1000000-0000-0000-0000-0000000000a1',
   '{"score1":1,"score2":2}'::jsonb, now()),
  ('e1000000-0000-0000-0000-000000000011','score_submitted','e1000000-0000-0000-0000-0000000000a2',
   '{"score1":1,"score2":2}'::jsonb, now());

set local role authenticated;
set local request.jwt.claims = '{"sub":"e1000000-0000-0000-0000-0000000000a1","role":"authenticated"}';

select lives_ok(
  $$select public.finalize_match_score('e1000000-0000-0000-0000-000000000011'::uuid)$$,
  'la manche REJOUEE se finalise normalement sur ses propres soumissions');

select * from finish();
rollback;
