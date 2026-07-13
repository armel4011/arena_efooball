-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Audit 2026-07-09 F2 (v2 « trace seule ») : subvention déclarée + trace
-- ════════════════════════════════════════════════════════════════════
-- Migration 20260709180000 :
--   * generate_payouts NE BLOQUE PAS la subvention (pool > frais) — le cap au
--     pool déclaré (super-admin only via F3) reste la seule borne ;
--   * il ENRICHIT la trace audit payout_pool_subsidy (actual vs authorized) ;
--   * set_competition_subsidy déclare la subvention (super-admin only).
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(6);

alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('f2000000-0000-0000-0000-0000000000a0'),  -- super-admin
  ('f2000000-0000-0000-0000-0000000000c0'),  -- admin simple
  ('f2000000-0000-0000-0000-0000000000b1');  -- gagnant rang 1
insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban) values
  ('f2000000-0000-0000-0000-0000000000a0','f2_sa','f2sa@ci.invalid','CM','F2SA','super_admin',true,false),
  ('f2000000-0000-0000-0000-0000000000c0','f2_ad','f2ad@ci.invalid','CM','F2AD','admin',true,false),
  ('f2000000-0000-0000-0000-0000000000b1','f2_p1','f2p1@ci.invalid','CM','F2P1','player',true,false);

-- d1 : pool 5000, AUCUNE recette → subvention réelle 5000 (mais PAS bloquée).
-- d2 : pool 3000, recette 3000 → pas de subvention.
-- NB : registration_fee de d2 = 3000 pour rester cohérent avec le trigger
-- enforce_payment_amount (migration 20260713120000) qui recale amount_local
-- des paiements sur le fee de la compétition — un paiement ne peut plus
-- diverger du fee, la recette encaissée (ligne payments ci-dessous) DOIT donc
-- valoir le fee.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code,prize_pool_local,prize_distribution) values
  ('f2000000-0000-0000-0000-000000000d01','F2_NOFEE','efootball','single_elimination','completed',now()-interval '2 hour',4,1000,'XAF','CM',5000,'["5000"]'::jsonb),
  ('f2000000-0000-0000-0000-000000000d02','F2_FEEOK','efootball','single_elimination','completed',now()-interval '2 hour',4,3000,'XAF','CM',3000,'["3000"]'::jsonb);

insert into competition_registrations(competition_id,player_id,status,final_rank) values
  ('f2000000-0000-0000-0000-000000000d01','f2000000-0000-0000-0000-0000000000b1','confirmed',1),
  ('f2000000-0000-0000-0000-000000000d02','f2000000-0000-0000-0000-0000000000b1','confirmed',1);

-- Recette encaissée 3000 sur d2 (provider requis, NOT NULL).
insert into payments(user_id,competition_id,amount_local,currency,status,provider,payer_method) values
  ('f2000000-0000-0000-0000-0000000000b1','f2000000-0000-0000-0000-000000000d02',3000,'XAF','succeeded','mobile_money_manual','mtn_momo');

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

set local role authenticated;

-- (1) super-admin génère d1 (pool 5000 > frais 0) → RÉUSSIT (pas de blocage F2)
set local request.jwt.claims = '{"sub":"f2000000-0000-0000-0000-0000000000a0"}';
do $$ declare n int; begin
  n := public.generate_payouts('f2000000-0000-0000-0000-000000000d01');
  insert into _r values ('gen_nofee','ok:'||n);
exception when others then insert into _r values ('gen_nofee','blocked:'||sqlerrm); end $$;

-- (4) admin simple déclare une subvention → BLOQUÉ (super-admin only)
set local request.jwt.claims = '{"sub":"f2000000-0000-0000-0000-0000000000c0"}';
do $$ begin
  perform public.set_competition_subsidy('f2000000-0000-0000-0000-000000000d01', 5000);
  insert into _r values ('setsub_admin','allowed');
exception when others then insert into _r values ('setsub_admin','blocked'); end $$;

-- (5) super-admin déclare 5000 sur d1
set local request.jwt.claims = '{"sub":"f2000000-0000-0000-0000-0000000000a0"}';
do $$ begin
  perform public.set_competition_subsidy('f2000000-0000-0000-0000-000000000d01', 5000);
  insert into _r values ('setsub_sa','ok');
exception when others then insert into _r values ('setsub_sa','blocked'); end $$;

-- (6) d2 : recettes couvrent → réussit, PAS de trace subvention
do $$ declare n int; begin
  n := public.generate_payouts('f2000000-0000-0000-0000-000000000d02');
  insert into _r values ('gen_feeok','ok:'||n);
exception when others then insert into _r values ('gen_feeok','blocked'); end $$;

reset role;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test='gen_nofee'), 'ok:1',
  'F2 : génération réussit même si pool > frais (aucun blocage — trace seule)');
select is(
  (select after_state->>'actual_subsidy' from public.admin_audit_log
   where action='payout_pool_subsidy' and target_id='f2000000-0000-0000-0000-000000000d01' limit 1),
  '5000', 'F2 : la trace audit enregistre la subvention RÉELLE (paid - collected)');
select is((select result from _r where test='setsub_admin'), 'blocked',
  'F2 : un admin simple NE PEUT PAS déclarer de subvention (super-admin only)');
select is((select result from _r where test='setsub_sa'), 'ok',
  'F2 : super-admin peut déclarer la subvention');
select is(
  (select authorized_subsidy_local::text from public.competitions
   where id='f2000000-0000-0000-0000-000000000d01'),
  '5000', 'F2 : set_competition_subsidy a bien posé authorized_subsidy_local');
select is(
  (select count(*)::text from public.admin_audit_log
   where action='payout_pool_subsidy' and target_id='f2000000-0000-0000-0000-000000000d02'),
  '0', 'F2 : recettes couvrant les gains → PAS de trace subvention');

select * from finish();
rollback;
