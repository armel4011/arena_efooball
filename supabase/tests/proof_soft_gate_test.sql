-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Anti-triche P1 #5 : soft-gate « preuve » de finalize_match_score
-- ════════════════════════════════════════════════════════════════════
-- Couvre la migration 20260709120000 :
--   * comp À PRIX + vainqueur AVEC commitment            → completed, pas de trace
--   * comp À PRIX + vainqueur SANS commit, enforced=OFF  → completed + proof_missing
--     (capture_status repris de la trace streams.unavailable)
--   * comp À PRIX + vainqueur SANS commit, enforced=ON   → disputed (revue admin)
--   * comp SANS prix + vainqueur sans commit             → completed, jamais gaté
--   * comp À PRIX + match NUL (winner null) sans commit  → completed, jamais gaté
--
-- Pattern (cf. admin_privilege_escalation_test) : on bascule en rôle
-- `authenticated` avec un JWT simulé (un des joueurs) pour appeler la RPC
-- SECURITY DEFINER `finalize_match_score`, on lit l'effet dans une table temp,
-- puis on `reset role` AVANT les assertions pgTAP.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(11);

-- Triggers de cascade/stats/planif/notif neutralisés : on teste le gate, pas
-- l'avancement du tournoi.
alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;
alter table public.matches disable trigger z_auto_schedule_next_round_on_match_complete;
alter table public.matches disable trigger trg_matches_auto_publish_final;
alter table public.matches disable trigger trg_notify_match_room_activated_upd;

-- ─── Fixtures (superuser : bypass RLS) ──────────────────────────────
insert into auth.users(id) values
  ('7f7f7f7f-0000-0000-0000-0000000000a1'),  -- player1 (vainqueur des matchs décidés)
  ('7f7f7f7f-0000-0000-0000-0000000000a2');  -- player2
insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban) values
  ('7f7f7f7f-0000-0000-0000-0000000000a1','pg_p1','pg1@ci.invalid','CI','PGP1','player',true,false),
  ('7f7f7f7f-0000-0000-0000-0000000000a2','pg_p2','pg2@ci.invalid','CI','PGP2','player',true,false);

-- comp à prix (ongoing) / comp sans prix (ongoing).
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,prize_pool_local) values
  ('7d7d7d7d-0000-0000-0000-000000000001','PGPRIZE','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF',50000),
  ('7d7d7d7d-0000-0000-0000-000000000002','PGFREE','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF',0);

-- Matchs prêts à finaliser (in_progress, les deux joueurs assis).
--  M1 prix + commit vainqueur / M2 prix sans commit (trace unavailable)
--  M3 prix sans commit (enforced) / M4 sans prix / M5 prix NUL.
insert into matches(id,competition_id,status,player1_id,player2_id) values
  ('7e7e7e7e-1000-0000-0000-000000000001','7d7d7d7d-0000-0000-0000-000000000001','in_progress',
   '7f7f7f7f-0000-0000-0000-0000000000a1','7f7f7f7f-0000-0000-0000-0000000000a2'),
  ('7e7e7e7e-1000-0000-0000-000000000002','7d7d7d7d-0000-0000-0000-000000000001','in_progress',
   '7f7f7f7f-0000-0000-0000-0000000000a1','7f7f7f7f-0000-0000-0000-0000000000a2'),
  ('7e7e7e7e-1000-0000-0000-000000000003','7d7d7d7d-0000-0000-0000-000000000001','in_progress',
   '7f7f7f7f-0000-0000-0000-0000000000a1','7f7f7f7f-0000-0000-0000-0000000000a2'),
  ('7e7e7e7e-1000-0000-0000-000000000004','7d7d7d7d-0000-0000-0000-000000000002','in_progress',
   '7f7f7f7f-0000-0000-0000-0000000000a1','7f7f7f7f-0000-0000-0000-0000000000a2'),
  ('7e7e7e7e-1000-0000-0000-000000000005','7d7d7d7d-0000-0000-0000-000000000001','in_progress',
   '7f7f7f7f-0000-0000-0000-0000000000a1','7f7f7f7f-0000-0000-0000-0000000000a2');

-- Soumissions concordantes des deux joueurs. M1..M4 = 3-1 (p1 gagne), M5 = 2-2 (nul).
insert into match_events(match_id,type,created_by,payload)
select m, 'score_submitted', p, jsonb_build_object('score1',s1,'score2',s2)
from (values
  ('7e7e7e7e-1000-0000-0000-000000000001'::uuid,3,1),
  ('7e7e7e7e-1000-0000-0000-000000000002'::uuid,3,1),
  ('7e7e7e7e-1000-0000-0000-000000000003'::uuid,3,1),
  ('7e7e7e7e-1000-0000-0000-000000000004'::uuid,3,1),
  ('7e7e7e7e-1000-0000-0000-000000000005'::uuid,2,2)
) as v(m,s1,s2)
cross join (values
  ('7f7f7f7f-0000-0000-0000-0000000000a1'::uuid),
  ('7f7f7f7f-0000-0000-0000-0000000000a2'::uuid)
) as pl(p);

-- Preuves : M1 → commitment du vainqueur (p1). M2 → trace « unavailable » (pas
-- de hash). M3/M4/M5 → aucune ligne streams.
insert into streams(match_id,player_id,provider,is_public,is_active,proof_sha256,proof_committed_at) values
  ('7e7e7e7e-1000-0000-0000-000000000001','7f7f7f7f-0000-0000-0000-0000000000a1','native_recorder',false,false,
   repeat('a',64), now());
insert into streams(match_id,player_id,provider,is_public,is_active,capture_status,capture_note) values
  ('7e7e7e7e-1000-0000-0000-000000000002','7f7f7f7f-0000-0000-0000-0000000000a1','native_recorder',false,false,
   'unavailable','permission_denied');

create temp table _r(test text primary key, result text) on commit drop;

-- ════════════════════════════════════════════════════════════════════
-- Acte 1 — enforced = OFF (défaut) : finalise M1, M2, M4, M5 comme joueur p1
-- ════════════════════════════════════════════════════════════════════
update public.app_config set value='false'::jsonb where key='proof_gate_enforced';

set local role authenticated;
set local request.jwt.claims = '{"sub":"7f7f7f7f-0000-0000-0000-0000000000a1"}';

select public.finalize_match_score('7e7e7e7e-1000-0000-0000-000000000001');
select public.finalize_match_score('7e7e7e7e-1000-0000-0000-000000000002');
select public.finalize_match_score('7e7e7e7e-1000-0000-0000-000000000004');
select public.finalize_match_score('7e7e7e7e-1000-0000-0000-000000000005');

reset role;

-- ════════════════════════════════════════════════════════════════════
-- Acte 2 — enforced = ON : finalise M3 (prix, sans commit) → doit router disputed
-- ════════════════════════════════════════════════════════════════════
update public.app_config set value='true'::jsonb where key='proof_gate_enforced';

set local role authenticated;
set local request.jwt.claims = '{"sub":"7f7f7f7f-0000-0000-0000-0000000000a1"}';

select public.finalize_match_score('7e7e7e7e-1000-0000-0000-000000000003');

reset role;

-- ─── Capture des états observés ─────────────────────────────────────
insert into _r values
  ('m1_status', (select status::text from matches where id='7e7e7e7e-1000-0000-0000-000000000001')),
  ('m1_proofmissing', (select count(*)::text from match_events where match_id='7e7e7e7e-1000-0000-0000-000000000001' and type='proof_missing')),
  ('m2_status', (select status::text from matches where id='7e7e7e7e-1000-0000-0000-000000000002')),
  ('m2_proofmissing', (select count(*)::text from match_events where match_id='7e7e7e7e-1000-0000-0000-000000000002' and type='proof_missing')),
  ('m2_capstatus', (select payload->>'capture_status' from match_events where match_id='7e7e7e7e-1000-0000-0000-000000000002' and type='proof_missing' limit 1)),
  ('m3_status', (select status::text from matches where id='7e7e7e7e-1000-0000-0000-000000000003')),
  ('m3_validated', (select count(*)::text from match_events where match_id='7e7e7e7e-1000-0000-0000-000000000003' and type='score_validated')),
  ('m4_status', (select status::text from matches where id='7e7e7e7e-1000-0000-0000-000000000004')),
  ('m4_proofmissing', (select count(*)::text from match_events where match_id='7e7e7e7e-1000-0000-0000-000000000004' and type='proof_missing')),
  ('m5_status', (select status::text from matches where id='7e7e7e7e-1000-0000-0000-000000000005')),
  ('m5_proofmissing', (select count(*)::text from match_events where match_id='7e7e7e7e-1000-0000-0000-000000000005' and type='proof_missing'));

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test='m1_status'), 'completed',
  'prix + vainqueur AVEC commitment → completed');
select is((select result from _r where test='m1_proofmissing'), '0',
  'prix + commit → aucun event proof_missing');
select is((select result from _r where test='m2_status'), 'completed',
  'prix + sans commit, enforced OFF → completed (trace seule)');
select is((select result from _r where test='m2_proofmissing'), '1',
  'prix + sans commit → un event proof_missing journalisé');
select is((select result from _r where test='m2_capstatus'), 'unavailable',
  'proof_missing reprend le capture_status de la trace streams');
select is((select result from _r where test='m3_status'), 'disputed',
  'prix + sans commit, enforced ON → routé vers disputed');
select is((select result from _r where test='m3_validated'), '0',
  'match routé disputed → PAS de score_validated (non complété)');
select is((select result from _r where test='m4_status'), 'completed',
  'comp SANS prix → jamais gaté, completed');
select is((select result from _r where test='m4_proofmissing'), '0',
  'comp SANS prix → aucun proof_missing');
select is((select result from _r where test='m5_status'), 'completed',
  'match NUL (winner null) → jamais gaté, completed');
select is((select result from _r where test='m5_proofmissing'), '0',
  'match NUL → aucun proof_missing');

select * from finish();
rollback;
