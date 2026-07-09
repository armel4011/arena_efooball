-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Audit 2026-07-09 F4 : soft-gate enforced crée une ligne disputes
-- ════════════════════════════════════════════════════════════════════
-- Migration 20260709160000 : quand proof_gate_enforced=true et qu'un match à
-- prix est routé vers `disputed` faute de commitment, une ligne `disputes`
-- (admin_review / proof_missing / escalation 3) doit être créée (sinon le match
-- est invisible dans la file admin). Idempotent : une seule dispute par match.
--
-- Pattern : on appelle finalize_match_score en rôle authenticated (joueur) ;
-- triggers matches de cascade/stats/planif neutralisés.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(6);

alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;
alter table public.matches disable trigger z_auto_schedule_next_round_on_match_complete;
alter table public.matches disable trigger trg_matches_auto_publish_final;
alter table public.matches disable trigger trg_notify_match_room_activated_upd;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('f4000000-0000-0000-0000-0000000000b1'),
  ('f4000000-0000-0000-0000-0000000000b2');
insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban) values
  ('f4000000-0000-0000-0000-0000000000b1','f4_p1','f4p1@ci.invalid','CM','F4P1','player',true,false),
  ('f4000000-0000-0000-0000-0000000000b2','f4_p2','f4p2@ci.invalid','CM','F4P2','player',true,false);

-- Compétition À PRIX.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,prize_pool_local) values
  ('f4000000-0000-0000-0000-0000000000d1','F4COMP','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF',50000);

-- Match prêt à finaliser, vainqueur p1 sans commitment.
insert into matches(id,competition_id,status,player1_id,player2_id) values
  ('f4000000-0000-0000-0000-0000000000e1','f4000000-0000-0000-0000-0000000000d1','in_progress',
   'f4000000-0000-0000-0000-0000000000b1','f4000000-0000-0000-0000-0000000000b2');

-- Soumissions concordantes 3-1 (p1 gagne).
insert into match_events(match_id,type,created_by,payload)
select 'f4000000-0000-0000-0000-0000000000e1','score_submitted', p, jsonb_build_object('score1',3,'score2',1)
from (values ('f4000000-0000-0000-0000-0000000000b1'::uuid),('f4000000-0000-0000-0000-0000000000b2'::uuid)) as pl(p);

-- Enforcement ON.
update public.app_config set value='true'::jsonb where key='proof_gate_enforced';

-- ─── Finalisation (joueur p1) ──────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"f4000000-0000-0000-0000-0000000000b1"}';
select public.finalize_match_score('f4000000-0000-0000-0000-0000000000e1');
-- 2e appel : idempotence (le match est disputed, non bloqué par l'anti-rejeu).
select public.finalize_match_score('f4000000-0000-0000-0000-0000000000e1');
reset role;

-- Reset flag pour ne pas laisser l'enforcement ON dans la transaction.
update public.app_config set value='false'::jsonb where key='proof_gate_enforced';

-- ─── Assertions ─────────────────────────────────────────────────────
select is(
  (select status::text from matches where id='f4000000-0000-0000-0000-0000000000e1'),
  'disputed', 'F4 : match routé vers disputed (enforced)');

select is(
  (select count(*)::text from disputes
   where match_id='f4000000-0000-0000-0000-0000000000e1'
     and status in ('open','bot_review','admin_review')),
  '1', 'F4 : exactement UNE dispute ouverte (idempotent malgré 2 finalize)');

select is(
  (select reason from disputes where match_id='f4000000-0000-0000-0000-0000000000e1' limit 1),
  'proof_missing', 'F4 : la dispute a pour raison proof_missing');

select is(
  (select status from disputes where match_id='f4000000-0000-0000-0000-0000000000e1' limit 1),
  'admin_review', 'F4 : la dispute entre en admin_review');

select is(
  (select escalation_level::text from disputes where match_id='f4000000-0000-0000-0000-0000000000e1' limit 1),
  '3', 'F4 : escalation_level 3 (super-admin, aligné sur le gate matchs à prix)');

select is(
  (select (evidence->>'capture_status') from disputes where match_id='f4000000-0000-0000-0000-0000000000e1' limit 1),
  'missing', 'F4 : evidence porte capture_status=missing (aucune trace)');

select * from finish();
rollback;
