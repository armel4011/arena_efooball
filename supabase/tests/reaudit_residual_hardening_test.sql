-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Ré-audit 2026-07-09 : durcissements résiduels
-- ════════════════════════════════════════════════════════════════════
-- Migration 20260709190000 :
--   P1 competition_payment_options : writes directs révoqués (RPC = seule voie).
--   P1 matches : 1re saisie d'un résultat à prix bloquée pour un admin simple
--      (super-admin only) ; libre pour super-admin ; libre sur comp SANS prix.
--   P2 app_release_config : write réservé au super-admin.
--   P2 anti-rejeu 'disputed' (finalize_match_score).
--   P3 guard streams : proof_* figées pour un admin aussi.
--   P3 registration_fee dans le guard financier.
--   P3 unicité (competition_id, rank) sur payouts.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(9);

alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;
alter table public.matches disable trigger z_auto_schedule_next_round_on_match_complete;
alter table public.matches disable trigger trg_matches_auto_publish_final;
alter table public.matches disable trigger trg_notify_match_room_activated_upd;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('aa000000-0000-0000-0000-0000000000a0'),  -- super-admin
  ('aa000000-0000-0000-0000-0000000000c0'),  -- admin simple (non restreint)
  ('aa000000-0000-0000-0000-0000000000b1'),
  ('aa000000-0000-0000-0000-0000000000b2');
insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban,admin_allowed_countries) values
  ('aa000000-0000-0000-0000-0000000000a0','ra_sa','rasa@ci.invalid','CM','RASA','super_admin',true,false,null),
  ('aa000000-0000-0000-0000-0000000000c0','ra_ad','raad@ci.invalid','CM','RAAD','admin',true,false,null),
  ('aa000000-0000-0000-0000-0000000000b1','ra_p1','rap1@ci.invalid','CM','RAP1','player',true,false,null),
  ('aa000000-0000-0000-0000-0000000000b2','ra_p2','rap2@ci.invalid','CM','RAP2','player',true,false,null);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code,prize_pool_local) values
  ('aa000000-0000-0000-0000-000000000d01','RA_PRIZE','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF','CM',50000),
  ('aa000000-0000-0000-0000-000000000d02','RA_FREE','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF','CM',0);

insert into matches(id,competition_id,status,player1_id,player2_id) values
  ('aa000000-0000-0000-0000-0000000000e1','aa000000-0000-0000-0000-000000000d01','in_progress','aa000000-0000-0000-0000-0000000000b1','aa000000-0000-0000-0000-0000000000b2'),
  ('aa000000-0000-0000-0000-0000000000e2','aa000000-0000-0000-0000-000000000d02','in_progress','aa000000-0000-0000-0000-0000000000b1','aa000000-0000-0000-0000-0000000000b2');

insert into streams(id,match_id,player_id,provider,is_public,is_active) values
  ('aa000000-0000-0000-0000-0000000000f1','aa000000-0000-0000-0000-0000000000e1','aa000000-0000-0000-0000-0000000000b1','native_recorder',false,false);

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

set local role authenticated;

-- (2) admin simple pose le résultat d'un match À PRIX → BLOQUÉ
set local request.jwt.claims = '{"sub":"aa000000-0000-0000-0000-0000000000c0"}';
do $$ begin
  update public.matches set winner_id='aa000000-0000-0000-0000-0000000000b1', score1=2, score2=0, status='completed'
   where id='aa000000-0000-0000-0000-0000000000e1';
  insert into _r values ('m_prize_admin','allowed');
exception when others then insert into _r values ('m_prize_admin','blocked'); end $$;

-- (4) admin simple pose le résultat d'un match SANS prix → AUTORISÉ (inchangé)
do $$ begin
  update public.matches set winner_id='aa000000-0000-0000-0000-0000000000b1', score1=2, score2=0, status='completed'
   where id='aa000000-0000-0000-0000-0000000000e2';
  insert into _r values ('m_free_admin','allowed');
exception when others then insert into _r values ('m_free_admin','blocked'); end $$;

-- (5) admin simple forge proof_hash_verified sur streams → BLOQUÉ (guard élargi)
do $$ begin
  update public.streams set proof_hash_verified=true, proof_sha256=repeat('a',64)
   where id='aa000000-0000-0000-0000-0000000000f1';
  insert into _r values ('streams_admin_proof','allowed');
exception when others then insert into _r values ('streams_admin_proof','blocked'); end $$;

-- (6) admin simple change registration_fee → BLOQUÉ (guard financier)
do $$ begin
  update public.competitions set registration_fee=999 where id='aa000000-0000-0000-0000-000000000d01';
  insert into _r values ('regfee_admin','allowed');
exception when others then insert into _r values ('regfee_admin','blocked'); end $$;

-- (3) super-admin pose le résultat d'un match à prix → AUTORISÉ
set local request.jwt.claims = '{"sub":"aa000000-0000-0000-0000-0000000000a0"}';
do $$ begin
  update public.matches set winner_id='aa000000-0000-0000-0000-0000000000b1', score1=3, score2=1, status='completed'
   where id='aa000000-0000-0000-0000-0000000000e1';
  insert into _r values ('m_prize_sa','allowed');
exception when others then insert into _r values ('m_prize_sa','blocked'); end $$;

reset role;

-- ─── Assertions ─────────────────────────────────────────────────────
select is(
  (select has_table_privilege('authenticated','public.competition_payment_options','UPDATE')::text),
  'false', 'P1 : writes directs révoqués sur competition_payment_options');
select is((select result from _r where test='m_prize_admin'), 'blocked',
  'P1 : admin simple NE PEUT PAS poser le résultat d''un match à prix');
select is((select result from _r where test='m_prize_sa'), 'allowed',
  'P1 : super-admin peut poser le résultat d''un match à prix');
select is((select result from _r where test='m_free_admin'), 'allowed',
  'P1 : admin simple peut poser le résultat d''un match SANS prix (inchangé)');
select is((select result from _r where test='streams_admin_proof'), 'blocked',
  'P3 : admin simple NE PEUT PAS forger proof_hash_verified sur streams');
select is((select result from _r where test='regfee_admin'), 'blocked',
  'P3 : admin simple NE PEUT PAS changer registration_fee');
select is(
  (select (pg_get_expr(polqual, polrelid) ilike '%is_super_admin%'
           and pg_get_expr(polqual, polrelid) not ilike '%is_admin()%')::text
   from pg_policy pol join pg_class c on c.oid=pol.polrelid
   where c.relname='app_release_config' and pol.polname='app_release_config_write_admin'),
  'true', 'P2 : app_release_config écriture réservée au super-admin (plus is_admin)');
select is(
  (select count(*)::text from pg_indexes where schemaname='public'
   and indexname='uniq_payouts_competition_rank'), '1',
  'P3 : index unique (competition_id, rank) présent sur payouts');
-- anti-rejeu 'disputed' : la liste anti-rejeu de finalize_match_score doit
-- contenir la séquence complète (…forfeited', 'disputed) — spécifique au fix,
-- pas au simple routage vers disputed.
select is(
  (select (pg_get_functiondef(oid) ilike '%''forfeited'', ''disputed''%')::text from pg_proc
   where proname='finalize_match_score' and pronamespace='public'::regnamespace),
  'true', 'P2 : finalize_match_score inclut disputed dans l''anti-rejeu');

select * from finish();
rollback;
