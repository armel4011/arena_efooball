-- ════════════════════════════════════════════════════════════════════
-- pgTAP — RLS competitions : masquage des compétitions pleines + à venir
-- ════════════════════════════════════════════════════════════════════
-- Invariant (policy `competitions_select`, migration
-- 20260620120000_competitions_hide_full_upcoming) : une compétition PLEINE
-- (current_players >= max_players) ET encore « à venir » (draft /
-- registration_open / registration_closed) est MASQUÉE aux non-inscrits,
-- mais VISIBLE aux inscrits (confirmés) et aux admins. Dès qu'elle est en
-- cours / terminée, elle redevient visible à tous. Une compétition non
-- pleine reste visible à tous.
--
-- NB : `current_players` est normalement maintenu par un trigger depuis le
-- compte d'inscriptions, et une inscription déclenche aussi quota parrainage
-- + génération de bracket. On insère donc les fixtures triggers DÉSACTIVÉS
-- (`session_replication_role = replica`) pour fixer `current_players` et le
-- statut de façon déterministe, puis on réactive avant les contrôles RLS.
-- Logique validée en prod via transaction ROLLBACK le 2026-06-20.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(5);

-- ─── Fixtures (superuser, triggers off) ─────────────────────────────
set local session_replication_role = replica;

insert into auth.users(id) values
  ('dddddddd-0000-0000-0000-000000000001'),  -- inscrit
  ('dddddddd-0000-0000-0000-000000000002'),  -- non inscrit
  ('dddddddd-0000-0000-0000-000000000003');  -- admin

insert into profiles(id, username, email, country_code, referral_code, role, is_active) values
  ('dddddddd-0000-0000-0000-000000000001','t_reg','reg@ci.invalid','CI','CIREG001','player', true),
  ('dddddddd-0000-0000-0000-000000000002','t_non','non@ci.invalid','CI','CINON002','player', true),
  ('dddddddd-0000-0000-0000-000000000003','t_adm','adm@ci.invalid','CI','CIADM003','admin',  true);

-- c_full_up : pleine (2/2) + à venir (registration_closed) → masquée aux non-inscrits
-- c_full_on : pleine (2/2) + EN COURS → visible à tous (contrôle)
-- c_open    : non pleine (1/8) + inscriptions ouvertes → visible à tous (contrôle)
insert into competitions(id,name,game,format,start_date,max_players,current_players,status,registration_currency) values
  ('eeeeeeee-0000-0000-0000-000000000001','full-up','efootball','single_elimination',now()+interval '1 day',2,2,'registration_closed','XOF'),
  ('eeeeeeee-0000-0000-0000-000000000002','full-on','efootball','single_elimination',now()+interval '1 day',2,2,'ongoing','XOF'),
  ('eeeeeeee-0000-0000-0000-000000000003','open',   'efootball','single_elimination',now()+interval '1 day',8,1,'registration_open','XOF');

-- L'inscrit confirmé sur c_full_up.
insert into competition_registrations(competition_id, player_id, status) values
  ('eeeeeeee-0000-0000-0000-000000000001','dddddddd-0000-0000-0000-000000000001','confirmed');

set local session_replication_role = default;

create temp table _v(test text primary key, n int) on commit drop;
grant all on _v to authenticated;

-- ─── Visibilité de c_full_up selon le rôle ──────────────────────────
-- Non inscrit → c_full_up masquée ; c_full_on (en cours) et c_open (non pleine) visibles.
set local role authenticated;
set local request.jwt.claims = '{"sub":"dddddddd-0000-0000-0000-000000000002"}';
insert into _v select 'nonreg_full_up',
  count(*)::int from competitions where id='eeeeeeee-0000-0000-0000-000000000001';
insert into _v select 'nonreg_full_on',
  count(*)::int from competitions where id='eeeeeeee-0000-0000-0000-000000000002';
insert into _v select 'nonreg_open',
  count(*)::int from competitions where id='eeeeeeee-0000-0000-0000-000000000003';

-- Inscrit confirmé → c_full_up visible.
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"dddddddd-0000-0000-0000-000000000001"}';
insert into _v select 'reg_full_up',
  count(*)::int from competitions where id='eeeeeeee-0000-0000-0000-000000000001';

-- Admin → c_full_up visible.
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"dddddddd-0000-0000-0000-000000000003"}';
insert into _v select 'admin_full_up',
  count(*)::int from competitions where id='eeeeeeee-0000-0000-0000-000000000001';

reset role;

-- ─── Assertions pgTAP ───────────────────────────────────────────────
select is((select n from _v where test='nonreg_full_up'), 0,
  'non-inscrit : compétition pleine + à venir MASQUÉE');
select is((select n from _v where test='reg_full_up'), 1,
  'inscrit confirmé : compétition pleine + à venir VISIBLE');
select is((select n from _v where test='admin_full_up'), 1,
  'admin : compétition pleine + à venir VISIBLE');
select is((select n from _v where test='nonreg_full_on'), 1,
  'non-inscrit : compétition pleine mais EN COURS reste visible');
select is((select n from _v where test='nonreg_open'), 1,
  'non-inscrit : compétition non pleine reste visible');

select finish();
rollback;
