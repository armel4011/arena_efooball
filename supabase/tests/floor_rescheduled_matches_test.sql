-- ════════════════════════════════════════════════════════════════════
-- pgTAP — reprogrammation vers le PASSÉ : plancher à maintenant+5min
-- ════════════════════════════════════════════════════════════════════
-- Reprogrammer une compétition à une date antérieure décale les matchs du
-- delta MAIS jamais dans le passé : le match le plus précoce est planché à
-- now()+5min. Depuis 20260717180000 le plancher est un décalage UNIFORME (et
-- non plus un `greatest` par ligne) : toute la grille est relevée du même
-- complément, donc l'espacement entre rounds est préservé.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(2);

alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;
alter table public.matches disable trigger z_auto_schedule_next_round_on_match_complete;
alter table public.matches disable trigger trg_notify_match_room_activated_upd;

insert into auth.users(id) values
  ('c2000000-0000-0000-0000-0000000000a1'),
  ('c2000000-0000-0000-0000-0000000000a2');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('c2000000-0000-0000-0000-0000000000a1','fl_p1','flp1@ci.invalid','CI','FLP1','player',true),
  ('c2000000-0000-0000-0000-0000000000a2','fl_p2','flp2@ci.invalid','CI','FLP2','player',true);

-- start_date à +10 jours ; matchs dans 10 j (round 1) et 20 j (round 2).
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency)
values ('c2000000-0000-0000-0000-00000000c001','FLOOR','efootball','single_elimination','ongoing',
        now() + interval '10 days',4,0,'XOF');

insert into matches(id,competition_id,status,scheduled_at,player1_id,player2_id) values
  ('c2000000-0000-0000-0000-000000000011','c2000000-0000-0000-0000-00000000c001','scheduled',
   now() + interval '10 days','c2000000-0000-0000-0000-0000000000a1','c2000000-0000-0000-0000-0000000000a2'),
  ('c2000000-0000-0000-0000-000000000013','c2000000-0000-0000-0000-00000000c001','pending',
   now() + interval '20 days',null,null);

-- Reprogrammation VERS LE PASSÉ : start_date à -1 jour (delta = -11 jours).
update public.competitions
   set start_date = now() - interval '1 day'
 where id = 'c2000000-0000-0000-0000-00000000c001';

-- round 1 (le plus précoce) : (now+10j) - 11j = now-1j → sous le plancher →
-- relevé à ~now()+5min, ce qui fixe le complément de toute la grille.
select ok(
  (select scheduled_at from matches where id='c2000000-0000-0000-0000-000000000011')
    between now() + interval '4 minutes' and now() + interval '6 minutes',
  'match le plus précoce est planché à ~maintenant+5min');

-- round 2 : suit le MÊME complément que le round 1 → l'écart de 10 jours qui
-- séparait les deux rounds est intact.
select ok(
  (select scheduled_at from matches where id='c2000000-0000-0000-0000-000000000013')
   - (select scheduled_at from matches where id='c2000000-0000-0000-0000-000000000011')
    = interval '10 days',
  'l''espacement entre les rounds est préservé exactement');

select * from finish();
rollback;
