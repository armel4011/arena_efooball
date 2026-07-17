-- ════════════════════════════════════════════════════════════════════
-- pgTAP — reprogrammation en arrière : pas de collapse de rounds
-- ════════════════════════════════════════════════════════════════════
-- Régression 20260717180000. Avec l'ancien plancher par ligne
-- (`greatest(scheduled_at + delta, now()+5min)`), TOUS les rounds tombant dans
-- le passé après décalage étaient écrasés sur la MÊME valeur, now()+5min :
-- rounds 1 et 2 à la même heure, alors que le round 2 se joue entre les
-- vainqueurs du round 1. Le décalage uniforme préserve l'ordre et les écarts.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(4);

alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;
alter table public.matches disable trigger z_auto_schedule_next_round_on_match_complete;
alter table public.matches disable trigger trg_notify_match_room_activated_upd;

insert into auth.users(id) values
  ('c3000000-0000-0000-0000-0000000000a1'),
  ('c3000000-0000-0000-0000-0000000000a2');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('c3000000-0000-0000-0000-0000000000a1','sp_p1','spp1@ci.invalid','CI','SPP1','player',true),
  ('c3000000-0000-0000-0000-0000000000a2','sp_p2','spp2@ci.invalid','CI','SPP2','player',true);

-- start_date à +10 jours ; 3 rounds espacés d'un jour : J+10, J+11, J+12.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency)
values ('c3000000-0000-0000-0000-00000000c001','SPACING','efootball','single_elimination','ongoing',
        now() + interval '10 days',8,0,'XOF');

insert into matches(id,competition_id,round,status,scheduled_at,player1_id,player2_id) values
  ('c3000000-0000-0000-0000-000000000021','c3000000-0000-0000-0000-00000000c001',1,'scheduled',
   now() + interval '10 days','c3000000-0000-0000-0000-0000000000a1','c3000000-0000-0000-0000-0000000000a2'),
  ('c3000000-0000-0000-0000-000000000022','c3000000-0000-0000-0000-00000000c001',2,'pending',
   now() + interval '11 days',null,null),
  ('c3000000-0000-0000-0000-000000000023','c3000000-0000-0000-0000-00000000c001',3,'pending',
   now() + interval '12 days',null,null);

-- Reprogrammation VERS LE PASSÉ : delta = -11 jours. Sans le fix, les rounds 1
-- (→ now-1j) ET 2 (→ now, à la seconde près) tombent sous le plancher et se
-- retrouvent tous deux à now()+5min.
update public.competitions
   set start_date = now() - interval '1 day'
 where id = 'c3000000-0000-0000-0000-00000000c001';

select ok(
  (select scheduled_at from matches where id='c3000000-0000-0000-0000-000000000021')
    between now() + interval '4 minutes' and now() + interval '6 minutes',
  'round 1 (le plus précoce) est planché à ~maintenant+5min');

select ok(
  (select count(distinct scheduled_at) from matches
    where competition_id='c3000000-0000-0000-0000-00000000c001') = 3,
  'les 3 rounds gardent 3 horaires DISTINCTS (pas de collapse)');

select ok(
  (select scheduled_at from matches where id='c3000000-0000-0000-0000-000000000022')
   - (select scheduled_at from matches where id='c3000000-0000-0000-0000-000000000021')
    = interval '1 day',
  'écart round 1 → round 2 préservé (1 jour)');

select ok(
  (select scheduled_at from matches where id='c3000000-0000-0000-0000-000000000023')
   - (select scheduled_at from matches where id='c3000000-0000-0000-0000-000000000022')
    = interval '1 day',
  'écart round 2 → round 3 préservé (1 jour)');

select * from finish();
rollback;
