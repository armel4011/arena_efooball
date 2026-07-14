-- ════════════════════════════════════════════════════════════════════
-- pgTAP — cohérence cloisonnement pays P3 (audit 2026-07-14)
-- ════════════════════════════════════════════════════════════════════
-- Couvre le fix P3 (20260714140000) : reprogram_competition,
-- start_competition_now, admin_recompute_final_ranks et resolve_dispute
-- gataient sur is_admin() sans admin_can_country. Un admin scopé {CM} pouvait
-- agir sur une compétition/match d'un autre pays (SN).
--
-- Pour chaque RPC : un admin scopé {CM} qui vise une entité SN est refusé
-- (42501). Un admin global (scope NULL) franchit la garde pays — on vérifie
-- qu'il n'obtient PAS l'erreur « ce pays » (il peut tomber sur une autre garde
-- métier, ex. « < 2 joueurs », ce qui prouve que la garde pays a été passée).
--
-- request.jwt.claims pilote auth.uid ; superuser, rollback final.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(8);

alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('cf000000-0000-0000-0000-0000000000cd'),  -- admin scopé {CM}
  ('cf000000-0000-0000-0000-0000000000a6'),  -- admin global (scope NULL)
  ('cf000000-0000-0000-0000-0000000000f1'),
  ('cf000000-0000-0000-0000-0000000000f2');

insert into profiles(id,username,email,country_code,referral_code,role,is_active,admin_allowed_countries) values
  ('cf000000-0000-0000-0000-0000000000cd','cf_adm_cm','cfad@ci.invalid','CM','CFAD','admin',true, array['CM']),
  ('cf000000-0000-0000-0000-0000000000a6','cf_adm_gl','cfag@ci.invalid','CM','CFAG','admin',true, NULL),
  ('cf000000-0000-0000-0000-0000000000f1','cf_p1','cfp1@ci.invalid','SN','CFP1','player',true, NULL),
  ('cf000000-0000-0000-0000-0000000000f2','cf_p2','cfp2@ci.invalid','SN','CFP2','player',true, NULL);

-- Compétition SN (hors périmètre {CM}) + un match en litige.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code) values
  ('cf000000-0000-0000-0000-00000000c051','SN','efootball','single_elimination','registration_open',now()+interval '5 day',4,0,'XAF','SN');
insert into matches(id,competition_id,player1_id,player2_id,status) values
  ('cf000000-0000-0000-0000-00000000aa51','cf000000-0000-0000-0000-00000000c051',
   'cf000000-0000-0000-0000-0000000000f1','cf000000-0000-0000-0000-0000000000f2','disputed');

-- ═══ Admin scopé {CM} → refus sur une entité SN (les 4 RPC) ═══
set local request.jwt.claims = '{"sub":"cf000000-0000-0000-0000-0000000000cd"}';

select throws_ok(
  $$ select public.reprogram_competition('cf000000-0000-0000-0000-00000000c051', now()+interval '9 day') $$,
  '42501', 'Compte non autorise sur ce pays',
  'reprogram_competition : admin {CM} refusé sur compétition SN');

select throws_ok(
  $$ select public.start_competition_now('cf000000-0000-0000-0000-00000000c051') $$,
  '42501', 'Compte non autorise sur ce pays',
  'start_competition_now : admin {CM} refusé sur compétition SN');

select throws_ok(
  $$ select public.admin_recompute_final_ranks('cf000000-0000-0000-0000-00000000c051') $$,
  '42501', 'Compte non autorise sur ce pays',
  'admin_recompute_final_ranks : admin {CM} refusé sur compétition SN');

select throws_ok(
  $$ select public.resolve_dispute('cf000000-0000-0000-0000-00000000aa51', null, 'motif', false, 'cf000000-0000-0000-0000-0000000000f1') $$,
  '42501', 'Compte non autorise sur ce pays',
  'resolve_dispute : admin {CM} refusé sur match d''une compétition SN');

-- ═══ Admin global (scope NULL) → franchit la garde pays ═══
set local request.jwt.claims = '{"sub":"cf000000-0000-0000-0000-0000000000a6"}';

-- reprogram : réussit (registration_open est reprogrammable).
select lives_ok(
  $$ select public.reprogram_competition('cf000000-0000-0000-0000-00000000c051', now()+interval '9 day') $$,
  'reprogram_competition : admin global autorisé sur compétition SN');

-- start : tombe sur « < 2 joueurs » (pas « ce pays ») → garde pays franchie.
select throws_like(
  $$ select public.start_competition_now('cf000000-0000-0000-0000-00000000c051') $$,
  '%joueurs%',
  'start_competition_now : admin global franchit la garde pays (échoue plus loin sur le quota joueurs)');

-- recompute : réussit (garde pays franchie, recalcul déterministe).
select lives_ok(
  $$ select public.admin_recompute_final_ranks('cf000000-0000-0000-0000-00000000c051') $$,
  'admin_recompute_final_ranks : admin global autorisé sur compétition SN');

-- resolve_dispute : réussit (match sans cagnotte, garde pays franchie).
select lives_ok(
  $$ select public.resolve_dispute('cf000000-0000-0000-0000-00000000aa51', null, 'motif', false, 'cf000000-0000-0000-0000-0000000000f1') $$,
  'resolve_dispute : admin global autorisé sur match d''une compétition SN');

select * from finish();
rollback;
