-- ════════════════════════════════════════════════════════════════════
-- pgTAP — reprogrammation compétition → décalage des matchs programmés
-- ════════════════════════════════════════════════════════════════════
-- Quand `competitions.start_date` change, les matchs NON DÉMARRÉS
-- (pending/scheduled/ready) doivent se décaler du MÊME delta (espacement des
-- rounds préservé) ; les matchs déjà joués (completed…) ne bougent pas.
--
-- Triggers de cascade/notif neutralisés : on teste le seul décalage.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(5);

alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;
alter table public.matches disable trigger z_auto_schedule_next_round_on_match_complete;
alter table public.matches disable trigger trg_notify_match_room_activated_upd;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('c1000000-0000-0000-0000-0000000000a1'),
  ('c1000000-0000-0000-0000-0000000000a2');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('c1000000-0000-0000-0000-0000000000a1','sm_p1','smp1@ci.invalid','CI','SMP1','player',true),
  ('c1000000-0000-0000-0000-0000000000a2','sm_p2','smp2@ci.invalid','CI','SMP2','player',true);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency)
values ('c1000000-0000-0000-0000-00000000c001','SHIFT','efootball','single_elimination','ongoing',
        '2026-08-01 10:00:00+00',4,0,'XOF');

insert into matches(id,competition_id,status,scheduled_at,player1_id,player2_id) values
  -- round 1 programmé (doit se décaler)
  ('c1000000-0000-0000-0000-000000000011','c1000000-0000-0000-0000-00000000c001','scheduled',
   '2026-08-01 10:00:00+00','c1000000-0000-0000-0000-0000000000a1','c1000000-0000-0000-0000-0000000000a2'),
  -- round 2 placeholder pending (doit se décaler, espacement +2h préservé)
  ('c1000000-0000-0000-0000-000000000013','c1000000-0000-0000-0000-00000000c001','pending',
   '2026-08-01 12:00:00+00',null,null),
  -- match déjà joué (ne doit PAS bouger)
  ('c1000000-0000-0000-0000-000000000012','c1000000-0000-0000-0000-00000000c001','completed',
   '2026-08-01 10:00:00+00','c1000000-0000-0000-0000-0000000000a1','c1000000-0000-0000-0000-0000000000a2');

select has_function('public', 'shift_competition_matches_on_reschedule', array[]::text[]);

-- ─── Reprogrammation : +2 jours ─────────────────────────────────────
update public.competitions
   set start_date = '2026-08-03 10:00:00+00'
 where id = 'c1000000-0000-0000-0000-00000000c001';

select is(
  (select scheduled_at from matches where id='c1000000-0000-0000-0000-000000000011'),
  '2026-08-03 10:00:00+00'::timestamptz,
  'match scheduled décalé de +2 jours');
select is(
  (select scheduled_at from matches where id='c1000000-0000-0000-0000-000000000013'),
  '2026-08-03 12:00:00+00'::timestamptz,
  'match pending décalé de +2 jours (espacement +2h préservé)');
select is(
  (select scheduled_at from matches where id='c1000000-0000-0000-0000-000000000012'),
  '2026-08-01 10:00:00+00'::timestamptz,
  'match completed NON décalé');

-- ─── Modifier une autre colonne ne décale rien (trigger scoping) ────
update public.competitions
   set name = 'SHIFT2'
 where id = 'c1000000-0000-0000-0000-00000000c001';
select is(
  (select scheduled_at from matches where id='c1000000-0000-0000-0000-000000000011'),
  '2026-08-03 10:00:00+00'::timestamptz,
  'changer le nom ne re-décale pas les matchs');

select * from finish();
rollback;
