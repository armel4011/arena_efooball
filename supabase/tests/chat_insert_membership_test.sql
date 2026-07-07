-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Audit 2026-07-07 (P1 #3) : INSERT chat_messages exige l'appartenance
-- ════════════════════════════════════════════════════════════════════
-- Couvre la migration 20260707130000 : un authentifié ne peut poster que
-- dans un canal dont il est membre (miroir de chat_messages_select) :
--   match=joueur, friend=amitié acceptée, admin_user=support_user ;
--   competition_broadcast/global = écriture admin-only ; admin = tout.
--
-- Pattern (cf. payments_payouts_rls_test) : rôle `authenticated` + JWT simulé
-- pour exercer la RLS, capture dans une table temp, puis `reset role` avant les
-- assertions pgTAP.
--
-- Correspondance des UUID (hex valides) :
--   users     a1=player1 a2=player2 b1=friend1 b2=friend2 c1=support d1=outsider e1=admin
--   canaux    ...01=match ...02=friend ...03=support(admin_user) ...04=broadcast
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(8);

-- Triggers de side-effect neutralisés : modération (appel HTTP Edge) + notif
-- support. On teste la RLS d'INSERT, pas les effets de bord.
alter table public.chat_messages disable trigger trg_chat_messages_moderate;
alter table public.chat_messages disable trigger trg_chat_messages_support_notify;

-- ─── Fixtures (superuser : bypass RLS) ──────────────────────────────
insert into auth.users(id) values
  ('8a8a8a8a-0000-0000-0000-0000000000a1'),
  ('8a8a8a8a-0000-0000-0000-0000000000a2'),
  ('8a8a8a8a-0000-0000-0000-0000000000b1'),
  ('8a8a8a8a-0000-0000-0000-0000000000b2'),
  ('8a8a8a8a-0000-0000-0000-0000000000c1'),
  ('8a8a8a8a-0000-0000-0000-0000000000d1'),
  ('8a8a8a8a-0000-0000-0000-0000000000e1');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('8a8a8a8a-0000-0000-0000-0000000000a1','ci_p1','cip1@ci.invalid','CI','CIP1','player',true),
  ('8a8a8a8a-0000-0000-0000-0000000000a2','ci_p2','cip2@ci.invalid','CI','CIP2','player',true),
  ('8a8a8a8a-0000-0000-0000-0000000000b1','ci_fr1','cifr1@ci.invalid','CI','CIFR1','player',true),
  ('8a8a8a8a-0000-0000-0000-0000000000b2','ci_fr2','cifr2@ci.invalid','CI','CIFR2','player',true),
  ('8a8a8a8a-0000-0000-0000-0000000000c1','ci_sup','cisup@ci.invalid','CI','CISUP','player',true),
  ('8a8a8a8a-0000-0000-0000-0000000000d1','ci_out','ciout@ci.invalid','CI','CIOUT','player',true),
  ('8a8a8a8a-0000-0000-0000-0000000000e1','ci_adm','ciadm@ci.invalid','CI','CIADM','admin',true);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency)
values ('8b8b8b8b-0000-0000-0000-000000000001','CHAT','efootball','single_elimination','ongoing',now()-interval '1 hour',4,0,'XAF');

insert into matches(id,competition_id,status,player1_id,player2_id) values
  ('8c8c8c8c-0000-0000-0000-000000000001','8b8b8b8b-0000-0000-0000-000000000001','in_progress',
   '8a8a8a8a-0000-0000-0000-0000000000a1','8a8a8a8a-0000-0000-0000-0000000000a2');

insert into friendships(id,requester_id,addressee_id,status) values
  ('8d8d8d8d-0000-0000-0000-000000000001','8a8a8a8a-0000-0000-0000-0000000000b1',
   '8a8a8a8a-0000-0000-0000-0000000000b2','accepted');

-- Canaux : match / friend / admin_user(support) / competition_broadcast.
insert into chat_channels(id,type,match_id) values
  ('8e8e8e8e-0000-0000-0000-000000000001','match','8c8c8c8c-0000-0000-0000-000000000001');
insert into chat_channels(id,type,friendship_id) values
  ('8e8e8e8e-0000-0000-0000-000000000002','friend','8d8d8d8d-0000-0000-0000-000000000001');
insert into chat_channels(id,type,support_user_id) values
  ('8e8e8e8e-0000-0000-0000-000000000003','admin_user','8a8a8a8a-0000-0000-0000-0000000000c1');
-- competition_broadcast exige competition_id (chat_channels_coherence_check).
insert into chat_channels(id,type,competition_id) values
  ('8e8e8e8e-0000-0000-0000-000000000004','competition_broadcast','8b8b8b8b-0000-0000-0000-000000000001');

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

set local role authenticated;

-- (1) OUT → canal MATCH dont il n'est pas joueur → BLOQUÉ.
set local request.jwt.claims = '{"sub":"8a8a8a8a-0000-0000-0000-0000000000d1"}';
do $$ begin
  insert into public.chat_messages(channel_id,sender_id,content)
  values ('8e8e8e8e-0000-0000-0000-000000000001','8a8a8a8a-0000-0000-0000-0000000000d1','intrusion');
  insert into _r values ('out_into_match','allowed');
exception when others then insert into _r values ('out_into_match','blocked'); end $$;

-- (2) P1 → son canal MATCH → AUTORISÉ.
set local request.jwt.claims = '{"sub":"8a8a8a8a-0000-0000-0000-0000000000a1"}';
do $$ begin
  insert into public.chat_messages(channel_id,sender_id,content)
  values ('8e8e8e8e-0000-0000-0000-000000000001','8a8a8a8a-0000-0000-0000-0000000000a1','gg');
  insert into _r values ('p1_into_match','allowed');
exception when others then insert into _r values ('p1_into_match','blocked'); end $$;

-- (3) OUT → canal FRIEND dont il n'est pas membre → BLOQUÉ.
set local request.jwt.claims = '{"sub":"8a8a8a8a-0000-0000-0000-0000000000d1"}';
do $$ begin
  insert into public.chat_messages(channel_id,sender_id,content)
  values ('8e8e8e8e-0000-0000-0000-000000000002','8a8a8a8a-0000-0000-0000-0000000000d1','intrusion');
  insert into _r values ('out_into_friend','allowed');
exception when others then insert into _r values ('out_into_friend','blocked'); end $$;

-- (4) FR1 → canal FRIEND (amitié acceptée) → AUTORISÉ.
set local request.jwt.claims = '{"sub":"8a8a8a8a-0000-0000-0000-0000000000b1"}';
do $$ begin
  insert into public.chat_messages(channel_id,sender_id,content)
  values ('8e8e8e8e-0000-0000-0000-000000000002','8a8a8a8a-0000-0000-0000-0000000000b1','salut');
  insert into _r values ('fr1_into_friend','allowed');
exception when others then insert into _r values ('fr1_into_friend','blocked'); end $$;

-- (5) OUT → canal BROADCAST → BLOQUÉ (écriture admin-only).
set local request.jwt.claims = '{"sub":"8a8a8a8a-0000-0000-0000-0000000000d1"}';
do $$ begin
  insert into public.chat_messages(channel_id,sender_id,content)
  values ('8e8e8e8e-0000-0000-0000-000000000004','8a8a8a8a-0000-0000-0000-0000000000d1','spam a tous');
  insert into _r values ('out_into_broadcast','allowed');
exception when others then insert into _r values ('out_into_broadcast','blocked'); end $$;

-- (6) OUT → canal SUPPORT d'autrui → BLOQUÉ.
do $$ begin
  insert into public.chat_messages(channel_id,sender_id,content)
  values ('8e8e8e8e-0000-0000-0000-000000000003','8a8a8a8a-0000-0000-0000-0000000000d1','intrusion');
  insert into _r values ('out_into_support','allowed');
exception when others then insert into _r values ('out_into_support','blocked'); end $$;

-- (7) SUP → SON canal SUPPORT → AUTORISÉ.
set local request.jwt.claims = '{"sub":"8a8a8a8a-0000-0000-0000-0000000000c1"}';
do $$ begin
  insert into public.chat_messages(channel_id,sender_id,content)
  values ('8e8e8e8e-0000-0000-0000-000000000003','8a8a8a8a-0000-0000-0000-0000000000c1','besoin daide');
  insert into _r values ('sup_into_support','allowed');
exception when others then insert into _r values ('sup_into_support','blocked'); end $$;

-- (8) ADMIN → canal BROADCAST → AUTORISÉ (is_admin).
set local request.jwt.claims = '{"sub":"8a8a8a8a-0000-0000-0000-0000000000e1"}';
do $$ begin
  insert into public.chat_messages(channel_id,sender_id,content)
  values ('8e8e8e8e-0000-0000-0000-000000000004','8a8a8a8a-0000-0000-0000-0000000000e1','annonce officielle');
  insert into _r values ('admin_into_broadcast','allowed');
exception when others then insert into _r values ('admin_into_broadcast','blocked'); end $$;

reset role;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test='out_into_match'),      'blocked',
  'un non-joueur ne peut PAS poster dans un canal match');
select is((select result from _r where test='p1_into_match'),       'allowed',
  'un joueur peut poster dans son canal match');
select is((select result from _r where test='out_into_friend'),     'blocked',
  'un non-membre ne peut PAS poster dans un canal friend');
select is((select result from _r where test='fr1_into_friend'),     'allowed',
  'un ami (amitié acceptée) peut poster dans le canal friend');
select is((select result from _r where test='out_into_broadcast'),  'blocked',
  'un user simple ne peut PAS poster dans un canal broadcast (admin-only)');
select is((select result from _r where test='out_into_support'),    'blocked',
  'un tiers ne peut PAS poster dans le canal support d''autrui');
select is((select result from _r where test='sup_into_support'),    'allowed',
  'le propriétaire du fil support peut y poster');
select is((select result from _r where test='admin_into_broadcast'),'allowed',
  'un admin peut poster dans un canal broadcast');

select * from finish();
rollback;
