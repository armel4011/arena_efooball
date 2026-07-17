-- ════════════════════════════════════════════════════════════════════
-- pgTAP — le 3e strike (ban à vie) exige un super-admin GLOBAL
-- ════════════════════════════════════════════════════════════════════
-- Durcissement #2 (20260717240000). Un super-admin SCOPÉ pays peut poser un
-- verdict de culpabilité sous le seuil (arbitrage), mais NE peut pas déclencher
-- seul le ban à vie au 3e verdict — celui-ci exige un super-admin global
-- (admin_allowed_countries IS NULL).
--
--   T   (a1) : cible, déjà 2 strikes (litiges resolved+guilty)
--   SAc (c5) : super-admin scopé {'CM'}
--   SAg (c9) : super-admin global (scope NULL)
--   T2  (a2) : cible fraîche (0 strike) — le scopé doit poser SON strike 1
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(6);

-- cascade/stats/notifs de matches neutralisées : on teste le seul arbitrage.
alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;
alter table public.matches disable trigger z_auto_schedule_next_round_on_match_complete;
alter table public.matches disable trigger trg_notify_match_room_activated_upd;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('33000000-0000-0000-0000-0000000000a1'),  -- T
  ('33000000-0000-0000-0000-0000000000a2'),  -- T2
  ('33000000-0000-0000-0000-0000000000b1'),  -- adversaire de T
  ('33000000-0000-0000-0000-0000000000b2'),  -- adversaire de T2
  ('33000000-0000-0000-0000-0000000000c5'),  -- SAc (scopé CM)
  ('33000000-0000-0000-0000-0000000000c9');  -- SAg (global)
insert into profiles(id,username,email,country_code,referral_code,role,is_active,admin_allowed_countries) values
  ('33000000-0000-0000-0000-0000000000a1','ts_t1','t1@ci.invalid','CM','TST1','player',true,null),
  ('33000000-0000-0000-0000-0000000000a2','ts_t2','t2@ci.invalid','CM','TST2','player',true,null),
  ('33000000-0000-0000-0000-0000000000b1','ts_b1','b1@ci.invalid','CM','TSB1','player',true,null),
  ('33000000-0000-0000-0000-0000000000b2','ts_b2','b2@ci.invalid','CM','TSB2','player',true,null),
  ('33000000-0000-0000-0000-0000000000c5','ts_sac','sac@ci.invalid','CM','TSAC','super_admin',true,array['CM']),
  ('33000000-0000-0000-0000-0000000000c9','ts_sag','sag@ci.invalid','CM','TSAG','super_admin',true,null);

-- Compétition CM sans cagnotte (les deux acteurs sont super-admin de toute façon)
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code,prize_pool_local)
values ('33000000-0000-0000-0000-0000000000f1','3S','efootball','single_elimination','ongoing',
        '2026-08-01 10:00:00+00',8,0,'XOF','CM',0);

insert into matches(id,competition_id,status,scheduled_at,player1_id,player2_id) values
  ('33000000-0000-0000-0000-0000000000e1','33000000-0000-0000-0000-0000000000f1','ready','2026-08-01 10:00:00+00','33000000-0000-0000-0000-0000000000a1','33000000-0000-0000-0000-0000000000b1'),
  ('33000000-0000-0000-0000-0000000000e2','33000000-0000-0000-0000-0000000000f1','ready','2026-08-01 11:00:00+00','33000000-0000-0000-0000-0000000000a1','33000000-0000-0000-0000-0000000000b1'),
  ('33000000-0000-0000-0000-0000000000e3','33000000-0000-0000-0000-0000000000f1','ready','2026-08-01 12:00:00+00','33000000-0000-0000-0000-0000000000a1','33000000-0000-0000-0000-0000000000b1'),
  ('33000000-0000-0000-0000-0000000000e4','33000000-0000-0000-0000-0000000000f1','ready','2026-08-01 13:00:00+00','33000000-0000-0000-0000-0000000000a2','33000000-0000-0000-0000-0000000000b2');

-- T a déjà 2 strikes (litiges resolved+guilty, insérés en direct = rôle postgres)
insert into disputes(id,match_id,opened_by,status,resolved_by,resolved_at,resolution,guilty_party_id) values
  ('33000000-0000-0000-0000-0000000000d1','33000000-0000-0000-0000-0000000000e1','33000000-0000-0000-0000-0000000000b1','resolved','33000000-0000-0000-0000-0000000000c9',now(),'strike 1','33000000-0000-0000-0000-0000000000a1'),
  ('33000000-0000-0000-0000-0000000000d2','33000000-0000-0000-0000-0000000000e2','33000000-0000-0000-0000-0000000000b1','resolved','33000000-0000-0000-0000-0000000000c9',now(),'strike 2','33000000-0000-0000-0000-0000000000a1');
-- Litiges ouverts pour le 3e verdict (T) et le 1er verdict (T2)
insert into disputes(id,match_id,opened_by,status) values
  ('33000000-0000-0000-0000-0000000000d3','33000000-0000-0000-0000-0000000000e3','33000000-0000-0000-0000-0000000000b1','open'),
  ('33000000-0000-0000-0000-0000000000d4','33000000-0000-0000-0000-0000000000e4','33000000-0000-0000-0000-0000000000b2','open');

-- ─── 1. Sanity : 2 strikes ne bannissent pas ────────────────────────
select is(
  (select permanent_ban from profiles where id='33000000-0000-0000-0000-0000000000a1'),
  false, 'apres 2 strikes, T n''est pas banni');

-- ─── 2. Super-admin SCOPÉ au 3e verdict → REFUS 42501 ───────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"33000000-0000-0000-0000-0000000000c5"}';
select throws_ok(
  $$ select public.resolve_dispute(
       '33000000-0000-0000-0000-0000000000e3','33000000-0000-0000-0000-0000000000d3',
       '3e verdict', false, '33000000-0000-0000-0000-0000000000b1', null, null,
       '33000000-0000-0000-0000-0000000000a1') $$,
  '42501',
  'Le 3e verdict de culpabilite (ban a vie) exige un super-admin global, non restreint a un pays. Escalade a un super-admin non scope.',
  'super-admin scope pays : 3e strike refuse (42501)');

-- ─── 3. Après le refus, T toujours pas banni ────────────────────────
reset role;
select is(
  (select permanent_ban from profiles where id='33000000-0000-0000-0000-0000000000a1'),
  false, 'apres le refus, T n''est toujours pas banni');

-- ─── 4. Super-admin GLOBAL au 3e verdict → SUCCÈS ───────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"33000000-0000-0000-0000-0000000000c9"}';
select lives_ok(
  $$ select public.resolve_dispute(
       '33000000-0000-0000-0000-0000000000e3','33000000-0000-0000-0000-0000000000d3',
       '3e verdict', false, '33000000-0000-0000-0000-0000000000b1', null, null,
       '33000000-0000-0000-0000-0000000000a1') $$,
  'super-admin global : 3e strike accepte');

-- ─── 5. T est désormais banni à vie ─────────────────────────────────
reset role;
select is(
  (select permanent_ban from profiles where id='33000000-0000-0000-0000-0000000000a1'),
  true, 'apres le 3e strike par un super-admin global, T est banni a vie');

-- ─── 6. Le scopé peut poser un strike SOUS le seuil (T2, strike 1) ──
set local role authenticated;
set local request.jwt.claims = '{"sub":"33000000-0000-0000-0000-0000000000c5"}';
select lives_ok(
  $$ select public.resolve_dispute(
       '33000000-0000-0000-0000-0000000000e4','33000000-0000-0000-0000-0000000000d4',
       'strike 1 T2', false, '33000000-0000-0000-0000-0000000000b2', null, null,
       '33000000-0000-0000-0000-0000000000a2') $$,
  'super-admin scope pays : strike sous le seuil (1er verdict T2) autorise');

reset role;
select * from finish();
rollback;
