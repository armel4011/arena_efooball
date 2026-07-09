-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Cloisonnement pays des enregistrements anti-triche
-- ════════════════════════════════════════════════════════════════════
-- Couvre la migration 20260709130000 :
--   * admin_list_recordings : super-admin voit tout ; admin restreint ne voit
--     que ses pays ; colonne country_code exposée.
--   * admin_claim_proof : admin restreint refusé hors de ses pays, autorisé
--     dans ses pays ; super-admin autorisé partout.
-- (La policy storage match_recordings_admin_read réutilise le même helper
--  admin_can_country — non exerçable simplement en pgTAP sur storage.objects.)
--
-- Pattern (cf. admin_privilege_escalation_test) : rôle `authenticated` + JWT
-- simulé pour exercer is_admin()/admin_can_country, capture dans une temp table,
-- puis reset role AVANT les assertions.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(8);

-- Dispatch FCM neutralisé : admin_claim_proof insère une notification.
alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Fixtures (superuser : bypass RLS). UUIDs 100% hexadécimaux. ─────
--   a0 = super-admin (scope NULL) / c0 = admin CM / e0 = admin SN
--   b1,b2 = joueurs
insert into auth.users(id) values
  ('aaaaaaaa-0000-0000-0000-0000000000a0'),
  ('aaaaaaaa-0000-0000-0000-0000000000c0'),
  ('aaaaaaaa-0000-0000-0000-0000000000e0'),
  ('aaaaaaaa-0000-0000-0000-0000000000b1'),
  ('aaaaaaaa-0000-0000-0000-0000000000b2')
on conflict do nothing;

insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban,admin_allowed_countries) values
  ('aaaaaaaa-0000-0000-0000-0000000000a0','rc_sa','rcsa@ci.invalid','CM','RCSA','super_admin',true,false,null),
  ('aaaaaaaa-0000-0000-0000-0000000000c0','rc_cm','rccm@ci.invalid','CM','RCCM','admin',true,false,array['CM']),
  ('aaaaaaaa-0000-0000-0000-0000000000e0','rc_sn','rcsn@ci.invalid','SN','RCSN','admin',true,false,array['SN']),
  ('aaaaaaaa-0000-0000-0000-0000000000b1','rc_p1','rcp1@ci.invalid','CM','RCP1','player',true,false,null),
  ('aaaaaaaa-0000-0000-0000-0000000000b2','rc_p2','rcp2@ci.invalid','CM','RCP2','player',true,false,null);

-- Compétitions : une CM, une SN.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code) values
  ('cccccccc-0000-0000-0000-0000000000c1','RCCOMP_CM','efootball','single_elimination','ongoing',now()-interval '1 hour',4,0,'XAF','CM'),
  ('cccccccc-0000-0000-0000-0000000000c2','RCCOMP_SN','efootball','single_elimination','ongoing',now()-interval '1 hour',4,0,'XAF','SN');

-- Matchs (scheduled : aucun trigger de complétion).
insert into matches(id,competition_id,status,player1_id,player2_id) values
  ('dddddddd-0000-0000-0000-0000000000d1','cccccccc-0000-0000-0000-0000000000c1','scheduled',
   'aaaaaaaa-0000-0000-0000-0000000000b1','aaaaaaaa-0000-0000-0000-0000000000b2'),
  ('dddddddd-0000-0000-0000-0000000000d2','cccccccc-0000-0000-0000-0000000000c2','scheduled',
   'aaaaaaaa-0000-0000-0000-0000000000b1','aaaaaaaa-0000-0000-0000-0000000000b2');

-- Enregistrements : un par pays. proof_sha256 posé → réclamables ;
-- storage_path posé → listés (is_public=false).
insert into streams(id,match_id,player_id,provider,is_public,is_active,storage_path,proof_sha256,proof_committed_at) values
  ('eeeeeeee-0000-0000-0000-0000000000e1','dddddddd-0000-0000-0000-0000000000d1',
   'aaaaaaaa-0000-0000-0000-0000000000b1','native_recorder',false,false,
   'dddddddd-0000-0000-0000-0000000000d1/aaaaaaaa-0000-0000-0000-0000000000b1/v.mp4',repeat('a',64),now()),
  ('eeeeeeee-0000-0000-0000-0000000000e2','dddddddd-0000-0000-0000-0000000000d2',
   'aaaaaaaa-0000-0000-0000-0000000000b1','native_recorder',false,false,
   'dddddddd-0000-0000-0000-0000000000d2/aaaaaaaa-0000-0000-0000-0000000000b1/v.mp4',repeat('b',64),now());

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

-- ════════════════════════════════════════════════════════════════════
-- admin_list_recordings — comptage par admin
-- ════════════════════════════════════════════════════════════════════
set local role authenticated;

set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-0000000000a0"}';
insert into _r values ('list_superadmin',
  (select count(*)::text from public.admin_list_recordings(100)));

set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-0000000000c0"}';
insert into _r values ('list_admin_cm',
  (select count(*)::text from public.admin_list_recordings(100)));
insert into _r values ('list_admin_cm_country',
  (select string_agg(country_code, ',') from public.admin_list_recordings(100)));

set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-0000000000e0"}';
insert into _r values ('list_admin_sn',
  (select count(*)::text from public.admin_list_recordings(100)));

-- ════════════════════════════════════════════════════════════════════
-- admin_claim_proof — garde pays
-- ════════════════════════════════════════════════════════════════════
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-0000000000c0"}';

-- CM réclame l'enreg CM → autorisé.
do $$ begin
  perform public.admin_claim_proof('eeeeeeee-0000-0000-0000-0000000000e1');
  insert into _r values ('claim_cm_on_cm','ok');
exception when others then
  insert into _r values ('claim_cm_on_cm','raised');
end $$;

-- CM réclame l'enreg SN → refusé (hors périmètre pays).
do $$ begin
  perform public.admin_claim_proof('eeeeeeee-0000-0000-0000-0000000000e2');
  insert into _r values ('claim_cm_on_sn','ok');
exception when others then
  insert into _r values ('claim_cm_on_sn','raised');
end $$;

-- Super-admin réclame l'enreg SN → autorisé (scope NULL).
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-0000000000a0"}';
do $$ begin
  perform public.admin_claim_proof('eeeeeeee-0000-0000-0000-0000000000e2');
  insert into _r values ('claim_sa_on_sn','ok');
exception when others then
  insert into _r values ('claim_sa_on_sn','raised');
end $$;

reset role;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test='list_superadmin'), '2',
  'super-admin voit TOUS les enregistrements (tous pays)');
select is((select result from _r where test='list_admin_cm'), '1',
  'admin restreint CM ne voit qu''un enregistrement');
select is((select result from _r where test='list_admin_cm_country'), 'CM',
  'l''enregistrement vu par l''admin CM est bien du pays CM');
select is((select result from _r where test='list_admin_sn'), '1',
  'admin restreint SN ne voit que son enregistrement (SN)');
select is((select result from _r where test='claim_cm_on_cm'), 'ok',
  'admin CM peut réclamer un enregistrement CM');
select is((select result from _r where test='claim_cm_on_sn'), 'raised',
  'admin CM NE PEUT PAS réclamer un enregistrement SN (hors périmètre)');
select is((select result from _r where test='claim_sa_on_sn'), 'ok',
  'super-admin peut réclamer un enregistrement SN (scope NULL)');

-- Effet vérifié : la réclamation CM a bien estampillé proof_claimed_at.
select isnt((select proof_claimed_at from public.streams
             where id='eeeeeeee-0000-0000-0000-0000000000e1'), null,
  'admin_claim_proof a estampillé proof_claimed_at sur l''enreg CM');

select * from finish();
rollback;
