-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Audit 2026-07-07 (P2) : chat_channels_select restreint à l'appartenance
-- ════════════════════════════════════════════════════════════════════
-- Couvre la migration 20260707160000 : un authentifié ne voit que les canaux
-- dont il est membre (+ broadcast/global publics ; admin voit tout).
--
-- UUID (hex) : a1/a2 joueurs match · b1/b2 amis · c1 support · d1 outsider · e1 admin
-- canaux ...01 match · ...02 friend · ...03 admin_user(support) · ...04 broadcast
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(8);

-- ─── Fixtures (superuser) ───────────────────────────────────────────
insert into auth.users(id) values
  ('9c9c9c9c-0000-0000-0000-0000000000a1'),
  ('9c9c9c9c-0000-0000-0000-0000000000a2'),
  ('9c9c9c9c-0000-0000-0000-0000000000b1'),
  ('9c9c9c9c-0000-0000-0000-0000000000b2'),
  ('9c9c9c9c-0000-0000-0000-0000000000c1'),
  ('9c9c9c9c-0000-0000-0000-0000000000d1'),
  ('9c9c9c9c-0000-0000-0000-0000000000e1');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('9c9c9c9c-0000-0000-0000-0000000000a1','cc_p1','ccp1@ci.invalid','CI','CCP1','player',true),
  ('9c9c9c9c-0000-0000-0000-0000000000a2','cc_p2','ccp2@ci.invalid','CI','CCP2','player',true),
  ('9c9c9c9c-0000-0000-0000-0000000000b1','cc_fr1','ccfr1@ci.invalid','CI','CCFR1','player',true),
  ('9c9c9c9c-0000-0000-0000-0000000000b2','cc_fr2','ccfr2@ci.invalid','CI','CCFR2','player',true),
  ('9c9c9c9c-0000-0000-0000-0000000000c1','cc_sup','ccsup@ci.invalid','CI','CCSUP','player',true),
  ('9c9c9c9c-0000-0000-0000-0000000000d1','cc_out','ccout@ci.invalid','CI','CCOUT','player',true),
  ('9c9c9c9c-0000-0000-0000-0000000000e1','cc_adm','ccadm@ci.invalid','CI','CCADM','admin',true);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency)
values ('9d9d9d9d-0000-0000-0000-000000000001','CCH','efootball','single_elimination','ongoing',now()-interval '1 hour',4,0,'XAF');

insert into matches(id,competition_id,status,player1_id,player2_id) values
  ('9e9e9e9e-0000-0000-0000-000000000001','9d9d9d9d-0000-0000-0000-000000000001','in_progress',
   '9c9c9c9c-0000-0000-0000-0000000000a1','9c9c9c9c-0000-0000-0000-0000000000a2');

insert into friendships(id,requester_id,addressee_id,status) values
  ('9f9f9f9f-0000-0000-0000-000000000001','9c9c9c9c-0000-0000-0000-0000000000b1',
   '9c9c9c9c-0000-0000-0000-0000000000b2','accepted');

insert into chat_channels(id,type,match_id) values
  ('90909090-0000-0000-0000-000000000001','match','9e9e9e9e-0000-0000-0000-000000000001');
insert into chat_channels(id,type,friendship_id) values
  ('90909090-0000-0000-0000-000000000002','friend','9f9f9f9f-0000-0000-0000-000000000001');
insert into chat_channels(id,type,support_user_id) values
  ('90909090-0000-0000-0000-000000000003','admin_user','9c9c9c9c-0000-0000-0000-0000000000c1');
insert into chat_channels(id,type,competition_id) values
  ('90909090-0000-0000-0000-000000000004','competition_broadcast','9d9d9d9d-0000-0000-0000-000000000001');

create temp table _r(test text primary key, result int) on commit drop;

set local role authenticated;

-- ─── Outsider (d1) : ne voit QUE le broadcast ───────────────────────
set local request.jwt.claims = '{"sub":"9c9c9c9c-0000-0000-0000-0000000000d1"}';
insert into _r select 'out_sees_broadcast',
  (select count(*)::int from chat_channels where id='90909090-0000-0000-0000-000000000004');
insert into _r select 'out_sees_match',
  (select count(*)::int from chat_channels where id='90909090-0000-0000-0000-000000000001');
insert into _r select 'out_sees_friend',
  (select count(*)::int from chat_channels where id='90909090-0000-0000-0000-000000000002');
insert into _r select 'out_sees_support',
  (select count(*)::int from chat_channels where id='90909090-0000-0000-0000-000000000003');

-- ─── Membres : voient LEUR canal ────────────────────────────────────
set local request.jwt.claims = '{"sub":"9c9c9c9c-0000-0000-0000-0000000000a1"}';
insert into _r select 'p1_sees_match',
  (select count(*)::int from chat_channels where id='90909090-0000-0000-0000-000000000001');

set local request.jwt.claims = '{"sub":"9c9c9c9c-0000-0000-0000-0000000000b1"}';
insert into _r select 'fr1_sees_friend',
  (select count(*)::int from chat_channels where id='90909090-0000-0000-0000-000000000002');

set local request.jwt.claims = '{"sub":"9c9c9c9c-0000-0000-0000-0000000000c1"}';
insert into _r select 'sup_sees_support',
  (select count(*)::int from chat_channels where id='90909090-0000-0000-0000-000000000003');

-- ─── Admin : voit les 4 ─────────────────────────────────────────────
set local request.jwt.claims = '{"sub":"9c9c9c9c-0000-0000-0000-0000000000e1"}';
insert into _r select 'admin_sees_all',
  (select count(*)::int from chat_channels
     where id in ('90909090-0000-0000-0000-000000000001','90909090-0000-0000-0000-000000000002',
                  '90909090-0000-0000-0000-000000000003','90909090-0000-0000-0000-000000000004'));

reset role;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test='out_sees_broadcast'), 1,
  'un authentifié voit les canaux broadcast (publics)');
select is((select result from _r where test='out_sees_match'), 0,
  'un non-joueur ne voit PAS un canal match');
select is((select result from _r where test='out_sees_friend'), 0,
  'un non-membre ne voit PAS un canal friend');
select is((select result from _r where test='out_sees_support'), 0,
  'un tiers ne voit PAS le canal support d''autrui');
select is((select result from _r where test='p1_sees_match'), 1,
  'un joueur voit son canal match');
select is((select result from _r where test='fr1_sees_friend'), 1,
  'un ami voit son canal friend');
select is((select result from _r where test='sup_sees_support'), 1,
  'le propriétaire voit son canal support');
select is((select result from _r where test='admin_sees_all'), 4,
  'un admin voit tous les canaux');

select * from finish();
rollback;
