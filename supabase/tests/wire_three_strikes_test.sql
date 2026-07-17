-- ════════════════════════════════════════════════════════════════════
-- pgTAP — câblage « 3 strikes » : resolve_dispute désigne le coupable
-- ════════════════════════════════════════════════════════════════════
-- 20260717220000. La feature était dormante : le trigger de ban attendait une
-- écriture de `disputes.guilty_party_id` que RIEN n'effectuait. On vérifie que
-- le nouveau chemin serveur la remplit, et que ses gardes tiennent — dont
-- celle qui manquait côté RLS et qui a valu le P0 (un coupable hors du match).
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(7);

alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;

insert into auth.users(id) values
  ('a5000000-0000-0000-0000-0000000000a1'),
  ('a5000000-0000-0000-0000-0000000000a2'),
  ('a5000000-0000-0000-0000-0000000000a3'),
  ('a5000000-0000-0000-0000-0000000000a4'),
  ('a5000000-0000-0000-0000-0000000000a5');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('a5000000-0000-0000-0000-0000000000a1','w_j1','wj1@ci.invalid','CM','WJ11','player',true),
  ('a5000000-0000-0000-0000-0000000000a2','w_j2','wj2@ci.invalid','CM','WJ21','player',true),
  ('a5000000-0000-0000-0000-0000000000a3','w_sa','wsa@ci.invalid','CM','WSA1','super_admin',true),
  ('a5000000-0000-0000-0000-0000000000a4','w_ad','wad@ci.invalid','CM','WAD1','admin',true),
  ('a5000000-0000-0000-0000-0000000000a5','w_tiers','wti@ci.invalid','CM','WTI1','player',true);

-- Sans cagnotte : isole la garde « strike » de la garde « cagnotte ».
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code)
values ('a5000000-0000-0000-0000-00000000c001','WIRE','efootball','single_elimination','ongoing',
        now() - interval '1 day',4,0,'XOF','CM');

insert into matches(id,competition_id,round,status,player1_id,player2_id) values
  ('a5000000-0000-0000-0000-000000000011','a5000000-0000-0000-0000-00000000c001',1,'disputed',
   'a5000000-0000-0000-0000-0000000000a1','a5000000-0000-0000-0000-0000000000a2'),
  ('a5000000-0000-0000-0000-000000000012','a5000000-0000-0000-0000-00000000c001',1,'disputed',
   'a5000000-0000-0000-0000-0000000000a1','a5000000-0000-0000-0000-0000000000a2'),
  ('a5000000-0000-0000-0000-000000000013','a5000000-0000-0000-0000-00000000c001',1,'disputed',
   'a5000000-0000-0000-0000-0000000000a1','a5000000-0000-0000-0000-0000000000a2');
insert into disputes(id,match_id,opened_by,status,reason) values
  ('a5000000-0000-0000-0000-0000000000d1','a5000000-0000-0000-0000-000000000011','a5000000-0000-0000-0000-0000000000a1','open','r1'),
  ('a5000000-0000-0000-0000-0000000000d2','a5000000-0000-0000-0000-000000000012','a5000000-0000-0000-0000-0000000000a1','open','r2'),
  ('a5000000-0000-0000-0000-0000000000d3','a5000000-0000-0000-0000-000000000013','a5000000-0000-0000-0000-0000000000a1','open','r3');

set local role authenticated;

-- ─── Gardes ────────────────────────────────────────────────────────────────
-- Un admin SIMPLE ne peut pas armer un ban à vie.
set local request.jwt.claims = '{"sub":"a5000000-0000-0000-0000-0000000000a4","role":"authenticated"}';
select throws_ok(
  $$select public.resolve_dispute(
      'a5000000-0000-0000-0000-000000000011'::uuid,
      'a5000000-0000-0000-0000-0000000000d1'::uuid,
      'just', false, 'a5000000-0000-0000-0000-0000000000a1'::uuid, null, null,
      'a5000000-0000-0000-0000-0000000000a2'::uuid)$$,
  '42501',
  'Designer un coupable (strike) : reserve au super-admin',
  'un admin simple ne peut pas designer de coupable');

set local request.jwt.claims = '{"sub":"a5000000-0000-0000-0000-0000000000a3","role":"authenticated"}';

-- Le coupable doit être un joueur DE CE MATCH : c'est l'absence de ce lien qui
-- permettait, côté REST, de faire bannir un tiers arbitraire (P0).
select throws_ok(
  $$select public.resolve_dispute(
      'a5000000-0000-0000-0000-000000000011'::uuid,
      'a5000000-0000-0000-0000-0000000000d1'::uuid,
      'just', false, 'a5000000-0000-0000-0000-0000000000a1'::uuid, null, null,
      'a5000000-0000-0000-0000-0000000000a5'::uuid)$$,
  '22023',
  'Le coupable doit etre un des deux joueurs du match',
  'un tiers hors du match ne peut pas etre declare coupable');

-- ─── Le chemin nominal ─────────────────────────────────────────────────────
select lives_ok(
  $$select public.resolve_dispute(
      'a5000000-0000-0000-0000-000000000011'::uuid,
      'a5000000-0000-0000-0000-0000000000d1'::uuid,
      'triche 1', false, 'a5000000-0000-0000-0000-0000000000a1'::uuid, null, null,
      'a5000000-0000-0000-0000-0000000000a2'::uuid)$$,
  'un super-admin enregistre un verdict de culpabilite');

select is(
  (select guilty_party_id from disputes where id='a5000000-0000-0000-0000-0000000000d1'),
  'a5000000-0000-0000-0000-0000000000a2'::uuid,
  'le coupable est bien enregistre sur le litige');

-- COMPATIBILITÉ ASCENDANTE : les APK déjà installés appellent avec 7 params.
select lives_ok(
  $$select public.resolve_dispute(
      'a5000000-0000-0000-0000-000000000012'::uuid,
      'a5000000-0000-0000-0000-0000000000d2'::uuid,
      'ancien client', false, 'a5000000-0000-0000-0000-0000000000a1'::uuid, 3, 0)$$,
  'un appel a 7 parametres (APK en circulation) fonctionne toujours');

-- ─── Le 3e verdict bannit ──────────────────────────────────────────────────
-- d2 vient d'être résolu SANS coupable (appel legacy) → il ne compte pas.
-- On pose les 2 verdicts manquants pour atteindre le seuil.
reset role;
insert into disputes(match_id,opened_by,status,resolved_by,guilty_party_id,reason) values
  ('a5000000-0000-0000-0000-000000000012','a5000000-0000-0000-0000-0000000000a1','resolved',
   'a5000000-0000-0000-0000-0000000000a3','a5000000-0000-0000-0000-0000000000a2','verdict 2');

select ok(
  (select permanent_ban from profiles where id='a5000000-0000-0000-0000-0000000000a2') = false,
  '2 verdicts ne bannissent pas');

set local role authenticated;
set local request.jwt.claims = '{"sub":"a5000000-0000-0000-0000-0000000000a3","role":"authenticated"}';
select public.resolve_dispute(
  'a5000000-0000-0000-0000-000000000013'::uuid,
  'a5000000-0000-0000-0000-0000000000d3'::uuid,
  'triche 3', false, 'a5000000-0000-0000-0000-0000000000a1'::uuid, null, null,
  'a5000000-0000-0000-0000-0000000000a2'::uuid);

reset role;
select ok(
  (select permanent_ban from profiles where id='a5000000-0000-0000-0000-0000000000a2') = true,
  'le 3e verdict declenche le ban a vie (feature enfin operante)');

select * from finish();
rollback;
