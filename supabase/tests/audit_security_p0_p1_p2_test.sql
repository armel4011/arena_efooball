-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Audit 2026-07-09 : correctifs sécurité P0 / P1 / P2
-- ════════════════════════════════════════════════════════════════════
-- P0 : escalade role/scope admin fermée (super-admin only), tier admin préservé.
-- P1 : forge des colonnes proof_* de streams bloquée côté joueur.
-- P2a : ACL generate_single_elim_bracket re-verrouillée (pas authenticated).
-- P2b : set_competition_payment_options cloisonné par pays.
--
-- Pattern : rôle `authenticated` + JWT simulé, capture dans temp table, reset
-- role AVANT les assertions.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(9);

-- ─── Fixtures (superuser). UUIDs hex. ───────────────────────────────
insert into auth.users(id) values
  ('5ec00000-0000-0000-0000-0000000000a0'),  -- super-admin
  ('5ec00000-0000-0000-0000-0000000000c0'),  -- admin restreint CM
  ('5ec00000-0000-0000-0000-0000000000b1'),  -- player1 (sujet du test forge P1)
  ('5ec00000-0000-0000-0000-0000000000b2'),  -- player2
  ('5ec00000-0000-0000-0000-0000000000b3');  -- cible dédiée du test « super-admin change un role »
insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban,admin_allowed_countries) values
  ('5ec00000-0000-0000-0000-0000000000a0','se_sa','sesa@ci.invalid','CM','SESA','super_admin',true,false,null),
  ('5ec00000-0000-0000-0000-0000000000c0','se_cm','secm@ci.invalid','CM','SECM','admin',true,false,array['CM']),
  ('5ec00000-0000-0000-0000-0000000000b1','se_p1','sep1@ci.invalid','CM','SEP1','player',true,false,null),
  ('5ec00000-0000-0000-0000-0000000000b2','se_p2','sep2@ci.invalid','CM','SEP2','player',true,false,null),
  ('5ec00000-0000-0000-0000-0000000000b3','se_p3','sep3@ci.invalid','CM','SEP3','player',true,false,null);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code) values
  ('5ec00000-0000-0000-0000-0000000000d1','SECOMP_CM','efootball','single_elimination','ongoing',now()-interval '1 hour',4,0,'XAF','CM'),
  ('5ec00000-0000-0000-0000-0000000000d2','SECOMP_SN','efootball','single_elimination','ongoing',now()-interval '1 hour',4,0,'XAF','SN');

insert into matches(id,competition_id,status,player1_id,player2_id) values
  ('5ec00000-0000-0000-0000-0000000000e1','5ec00000-0000-0000-0000-0000000000d1','scheduled',
   '5ec00000-0000-0000-0000-0000000000b1','5ec00000-0000-0000-0000-0000000000b2');

insert into streams(id,match_id,player_id,provider,is_public,is_active,proof_sha256,proof_committed_at) values
  ('5ec00000-0000-0000-0000-0000000000f1','5ec00000-0000-0000-0000-0000000000e1',
   '5ec00000-0000-0000-0000-0000000000b1','native_recorder',false,false,null,null);

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

-- ════════════════════════════════════════════════════════════════════
-- P0 — profiles : escalade fermée, tier admin préservé
-- ════════════════════════════════════════════════════════════════════
set local role authenticated;

-- (1) admin simple s'auto-promeut super-admin → BLOQUÉ
set local request.jwt.claims = '{"sub":"5ec00000-0000-0000-0000-0000000000c0"}';
do $$ begin
  update public.profiles set role='super_admin' where id='5ec00000-0000-0000-0000-0000000000c0';
  insert into _r values ('p0_self_promote','allowed');
exception when others then insert into _r values ('p0_self_promote','blocked'); end $$;

-- (2) admin simple élargit son scope (admin_allowed_countries → null) → BLOQUÉ
do $$ begin
  update public.profiles set admin_allowed_countries=null where id='5ec00000-0000-0000-0000-0000000000c0';
  insert into _r values ('p0_widen_scope','allowed');
exception when others then insert into _r values ('p0_widen_scope','blocked'); end $$;

-- (4) admin simple bannit un joueur (is_active=false) → AUTORISÉ (tier admin préservé)
do $$ begin
  update public.profiles set is_active=false where id='5ec00000-0000-0000-0000-0000000000b2';
  insert into _r values ('p0_admin_ban','allowed');
exception when others then insert into _r values ('p0_admin_ban','blocked'); end $$;

-- (3) super-admin change un role → AUTORISÉ. Cible b3 (dédiée) pour ne pas
-- promouvoir p1, qui doit rester NON-admin pour le test de forge P1 (un admin
-- est légitimement exempté du guard streams).
set local request.jwt.claims = '{"sub":"5ec00000-0000-0000-0000-0000000000a0"}';
do $$ begin
  update public.profiles set role='admin' where id='5ec00000-0000-0000-0000-0000000000b3';
  insert into _r values ('p0_superadmin_role','allowed');
exception when others then insert into _r values ('p0_superadmin_role','blocked'); end $$;

-- ════════════════════════════════════════════════════════════════════
-- P1 — streams : forge de preuve bloquée
-- ════════════════════════════════════════════════════════════════════
set local request.jwt.claims = '{"sub":"5ec00000-0000-0000-0000-0000000000b1"}';

-- (5) joueur forge commitment + verdict → BLOQUÉ
do $$ begin
  update public.streams set proof_committed_at=now(), proof_sha256=repeat('a',64), proof_hash_verified=true, capture_status='committed'
   where id='5ec00000-0000-0000-0000-0000000000f1';
  insert into _r values ('p1_forge_proof','allowed');
exception when others then insert into _r values ('p1_forge_proof','blocked'); end $$;

-- (6) joueur bascule is_public (non figé) → AUTORISÉ
do $$ begin
  update public.streams set is_public=true where id='5ec00000-0000-0000-0000-0000000000f1';
  insert into _r values ('p1_benign_update','allowed');
exception when others then insert into _r values ('p1_benign_update','blocked'); end $$;

reset role;

-- ════════════════════════════════════════════════════════════════════
-- P2b — set_competition_payment_options cloisonné pays
-- ════════════════════════════════════════════════════════════════════
set local role authenticated;

-- (8) admin restreint CM → compétition SN → BLOQUÉ
set local request.jwt.claims = '{"sub":"5ec00000-0000-0000-0000-0000000000c0"}';
do $$ begin
  perform public.set_competition_payment_options('5ec00000-0000-0000-0000-0000000000d2', '[]'::jsonb);
  insert into _r values ('p2b_cm_on_sn','allowed');
exception when others then insert into _r values ('p2b_cm_on_sn','blocked'); end $$;

-- (9) super-admin → compétition SN → AUTORISÉ
set local request.jwt.claims = '{"sub":"5ec00000-0000-0000-0000-0000000000a0"}';
do $$ begin
  perform public.set_competition_payment_options('5ec00000-0000-0000-0000-0000000000d2', '[]'::jsonb);
  insert into _r values ('p2b_sa_on_sn','allowed');
exception when others then insert into _r values ('p2b_sa_on_sn','blocked'); end $$;

reset role;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test='p0_self_promote'), 'blocked',
  'P0 : admin simple NE PEUT PAS se promouvoir super-admin');
select is((select result from _r where test='p0_widen_scope'), 'blocked',
  'P0 : admin simple NE PEUT PAS élargir son scope pays');
select is((select result from _r where test='p0_superadmin_role'), 'allowed',
  'P0 : super-admin peut changer un role');
select is((select result from _r where test='p0_admin_ban'), 'allowed',
  'P0 : admin simple peut toujours bannir (is_active) — tier admin préservé');
select is((select result from _r where test='p1_forge_proof'), 'blocked',
  'P1 : joueur NE PEUT PAS forger proof_committed_at/sha256/hash_verified');
select is((select result from _r where test='p1_benign_update'), 'allowed',
  'P1 : joueur peut toujours modifier is_public (non figé)');
select is(
  (select has_function_privilege('authenticated','public.generate_single_elim_bracket(uuid)','execute')::text),
  'false', 'P2a : generate_single_elim_bracket non exécutable par authenticated');
select is((select result from _r where test='p2b_cm_on_sn'), 'blocked',
  'P2b : admin CM NE PEUT PAS réécrire les codes de paiement d''une comp SN');
select is((select result from _r where test='p2b_sa_on_sn'), 'allowed',
  'P2b : super-admin peut réécrire les codes de paiement (scope NULL)');

select * from finish();
rollback;
