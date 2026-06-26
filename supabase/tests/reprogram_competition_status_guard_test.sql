-- ════════════════════════════════════════════════════════════════════
-- pgTAP — reprogram_competition : garde de statut (audit 2026-06-26)
-- ════════════════════════════════════════════════════════════════════
-- `reprogram_competition` rouvre les inscriptions (status → registration_open).
-- Ne doit l'autoriser QUE depuis un état pré-démarrage (draft / registration_* /
-- to_reprogram), jamais sur une compétition ongoing / completed / cancelled
-- (sinon réouverture d'inscriptions sur un tournoi déjà lancé ou clos).
--
-- Rôle appelant piloté par request.jwt.claims (auth.uid → is_admin). Rollback.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(7);

alter table public.notifications disable trigger trg_notifications_dispatch;

insert into auth.users(id) values
  ('dd000000-0000-0000-0000-0000000000ad'),
  ('dd000000-0000-0000-0000-0000000000f1');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('dd000000-0000-0000-0000-0000000000ad','rp_admin','rpad@ci.invalid','CI','RPAD','admin',true),
  ('dd000000-0000-0000-0000-0000000000f1','rp_p1','rpp1@ci.invalid','CI','RPP1','player',true);

-- à reprogrammer (cas nominal)
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency) values
  ('dd000000-0000-0000-0000-00000000c0a1','RTOREP','efootball','single_elimination','to_reprogram',now()-interval '1 day',8,0,'XOF'),
  ('dd000000-0000-0000-0000-00000000c0a2','RONGO','efootball','single_elimination','ongoing',now()-interval '1 day',8,0,'XOF'),
  ('dd000000-0000-0000-0000-00000000c0a3','RDONE','efootball','single_elimination','completed',now()-interval '1 day',8,0,'XOF');
-- un inscrit confirmé sur la compétition à reprogrammer (pour la notif)
insert into competition_registrations(competition_id,player_id,status) values
  ('dd000000-0000-0000-0000-00000000c0a1','dd000000-0000-0000-0000-0000000000f1','confirmed');

select has_function('public', 'reprogram_competition', array['uuid','timestamptz']);

set local request.jwt.claims = '{"sub":"dd000000-0000-0000-0000-0000000000ad"}';

-- ─── OK : depuis to_reprogram ───────────────────────────────────────
select lives_ok(
  $$ select public.reprogram_competition('dd000000-0000-0000-0000-00000000c0a1', now()+interval '3 days') $$,
  'reprogrammation autorisée depuis to_reprogram');
select is(
  (select status::text from competitions where id='dd000000-0000-0000-0000-00000000c0a1'),
  'registration_open', 'la compétition repasse en registration_open');

-- ─── Refus : ongoing ────────────────────────────────────────────────
select throws_ok(
  $$ select public.reprogram_competition('dd000000-0000-0000-0000-00000000c0a2', now()+interval '3 days') $$,
  '42501', NULL, 'reprogrammation refusée sur une compétition ongoing');
select is(
  (select status::text from competitions where id='dd000000-0000-0000-0000-00000000c0a2'),
  'ongoing', 'la compétition ongoing reste ongoing');

-- ─── Refus : completed ──────────────────────────────────────────────
select throws_ok(
  $$ select public.reprogram_competition('dd000000-0000-0000-0000-00000000c0a3', now()+interval '3 days') $$,
  '42501', NULL, 'reprogrammation refusée sur une compétition completed');

-- ─── Refus : date dans le passé (RAISE sans errcode → P0001) ────────
select throws_ok(
  $$ select public.reprogram_competition('dd000000-0000-0000-0000-00000000c0a1', now()-interval '1 hour') $$,
  'P0001', NULL, 'reprogrammation refusée avec une date passée');

select * from finish();
rollback;
