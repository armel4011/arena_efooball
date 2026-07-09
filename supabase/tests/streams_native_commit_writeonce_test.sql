-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Ré-audit 2026-07-09 : write-once DB du commitment natif
-- ════════════════════════════════════════════════════════════════════
-- Index streams_one_native_commit_per_player (20260709200000) :
--   * au plus UNE ligne native COMMITTÉE par (match, joueur) → 2e commit refusé ;
--   * plusieurs lignes de session natives NON-committées restent autorisées
--     (openSession insère une ligne par session).
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(3);

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('c0ff0000-0000-0000-0000-0000000000b1'),('c0ff0000-0000-0000-0000-0000000000b2');
insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban) values
  ('c0ff0000-0000-0000-0000-0000000000b1','wo_p1','wop1@ci.invalid','CM','WOP1','player',true,false),
  ('c0ff0000-0000-0000-0000-0000000000b2','wo_p2','wop2@ci.invalid','CM','WOP2','player',true,false);
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code) values
  ('c0ff0000-0000-0000-0000-0000000000d1','WO_COMP','efootball','single_elimination','ongoing',now()-interval '1 hour',4,0,'XAF','CM');
insert into matches(id,competition_id,status,player1_id,player2_id) values
  ('c0ff0000-0000-0000-0000-0000000000e1','c0ff0000-0000-0000-0000-0000000000d1','in_progress',
   'c0ff0000-0000-0000-0000-0000000000b1','c0ff0000-0000-0000-0000-0000000000b2');

create temp table _r(test text primary key, result text) on commit drop;

-- (1) 1re ligne native COMMITTÉE → OK
do $$ begin
  insert into public.streams(match_id,player_id,provider,is_public,is_active,proof_sha256,proof_committed_at)
  values ('c0ff0000-0000-0000-0000-0000000000e1','c0ff0000-0000-0000-0000-0000000000b1',
          'native_recorder',false,false,repeat('a',64),now());
  insert into _r values ('first_commit','ok');
exception when others then insert into _r values ('first_commit','blocked'); end $$;

-- (2) 2e ligne native COMMITTÉE, même (match,joueur) → REFUSÉE (write-once)
do $$ begin
  insert into public.streams(match_id,player_id,provider,is_public,is_active,proof_sha256,proof_committed_at)
  values ('c0ff0000-0000-0000-0000-0000000000e1','c0ff0000-0000-0000-0000-0000000000b1',
          'native_recorder',false,false,repeat('b',64),now());
  insert into _r values ('second_commit','allowed');
exception when unique_violation then insert into _r values ('second_commit','blocked');
          when others then insert into _r values ('second_commit','other_error'); end $$;

-- (3) deux lignes de session natives NON-committées → AUTORISÉES (sessions multiples)
do $$ begin
  insert into public.streams(match_id,player_id,provider,is_public,is_active)
  values ('c0ff0000-0000-0000-0000-0000000000e1','c0ff0000-0000-0000-0000-0000000000b1','native_recorder',false,true);
  insert into public.streams(match_id,player_id,provider,is_public,is_active)
  values ('c0ff0000-0000-0000-0000-0000000000e1','c0ff0000-0000-0000-0000-0000000000b1','native_recorder',false,false);
  insert into _r values ('two_sessions','ok');
exception when others then insert into _r values ('two_sessions','blocked'); end $$;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test='first_commit'), 'ok',
  'write-once : 1re ligne native committée acceptée');
select is((select result from _r where test='second_commit'), 'blocked',
  'write-once : 2e commit natif du même (match,joueur) refusé (unique)');
select is((select result from _r where test='two_sessions'), 'ok',
  'write-once : plusieurs lignes de session natives NON-committées restent autorisées');

select * from finish();
rollback;
