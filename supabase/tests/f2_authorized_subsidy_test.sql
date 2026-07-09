-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Audit 2026-07-09 F2 : subvention plateforme bornée
-- ════════════════════════════════════════════════════════════════════
-- Migration 20260709180000 :
--   * generate_payouts BLOQUE si versements > frais_encaissés + subvention_autorisée ;
--   * set_competition_subsidy pose la subvention (super-admin only) ;
--   * une fois la subvention autorisée, la génération passe + trace audit ;
--   * si les frais couvrent les gains, pas besoin de subvention.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(6);

-- Dispatch FCM neutralisé : generate_payouts insère des notifications.
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

-- d1 : comp à prix, AUCUNE recette (subvention nécessaire). d2 : recettes couvrent.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code,prize_pool_local,prize_distribution) values
  ('f2000000-0000-0000-0000-000000000d01','F2_NOFEE','efootball','single_elimination','completed',now()-interval '2 hour',4,1000,'XAF','CM',5000,'["5000"]'::jsonb),
  ('f2000000-0000-0000-0000-000000000d02','F2_FEEOK','efootball','single_elimination','completed',now()-interval '2 hour',4,1000,'XAF','CM',3000,'["3000"]'::jsonb);

insert into competition_registrations(competition_id,player_id,status,final_rank) values
  ('f2000000-0000-0000-0000-000000000d01','f2000000-0000-0000-0000-0000000000b1','confirmed',1),
  ('f2000000-0000-0000-0000-000000000d02','f2000000-0000-0000-0000-0000000000b1','confirmed',1);

-- Recette encaissée de 3000 sur d2 (couvre les gains) ; rien sur d1.
insert into payments(user_id,competition_id,amount_local,currency,status,payer_method) values
  ('f2000000-0000-0000-0000-0000000000b1','f2000000-0000-0000-0000-000000000d02',3000,'XAF','succeeded','mtn_momo');

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

set local role authenticated;

-- (1) d1 : gains 5000 > frais 0 + subvention 0 → BLOQUÉ
set local request.jwt.claims = '{"sub":"f2000000-0000-0000-0000-0000000000a0"}';
do $$ declare n int; begin
  n := public.generate_payouts('f2000000-0000-0000-0000-000000000d01');
  insert into _r values ('gen_nofee','ok');
exception when others then insert into _r values ('gen_nofee','blocked'); end $$;

-- (2) admin simple pose une subvention → BLOQUÉ (super-admin only)
set local request.jwt.claims = '{"sub":"f2000000-0000-0000-0000-0000000000c0"}';
do $$ begin
  perform public.set_competition_subsidy('f2000000-0000-0000-0000-000000000d01', 5000);
  insert into _r values ('setsub_admin','allowed');
exception when others then insert into _r values ('setsub_admin','blocked'); end $$;

-- (3) super-admin autorise 5000 de subvention, puis génère → OK (1 payout)
set local request.jwt.claims = '{"sub":"f2000000-0000-0000-0000-0000000000a0"}';
do $$ declare n int; begin
  perform public.set_competition_subsidy('f2000000-0000-0000-0000-000000000d01', 5000);
  n := public.generate_payouts('f2000000-0000-0000-0000-000000000d01');
  insert into _r values ('gen_subsidized','ok:'||n);
exception when others then insert into _r values ('gen_subsidized','blocked'); end $$;

-- (5) d2 : recettes 3000 couvrent les gains 3000, subvention 0 → OK
do $$ declare n int; begin
  n := public.generate_payouts('f2000000-0000-0000-0000-000000000d02');
  insert into _r values ('gen_feeok','ok:'||n);
exception when others then insert into _r values ('gen_feeok','blocked'); end $$;

reset role;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test='gen_nofee'), 'blocked',
  'F2 : gains > frais + subvention(0) → génération refusée');
select is((select result from _r where test='setsub_admin'), 'blocked',
  'F2 : un admin simple NE PEUT PAS poser de subvention (super-admin only)');
select is((select result from _r where test='gen_subsidized'), 'ok:1',
  'F2 : subvention autorisée → génération passe (1 payout)');
select is((select result from _r where test='gen_feeok'), 'ok:1',
  'F2 : recettes couvrant les gains → génération passe sans subvention');
select isnt(
  (select after_state->>'authorized_subsidy' from public.admin_audit_log
   where action='payout_pool_subsidy' and target_id='f2000000-0000-0000-0000-000000000d01' limit 1),
  null, 'F2 : la subvention consommée est tracée en audit (payout_pool_subsidy)');
select is(
  (select authorized_subsidy_local::text from public.competitions
   where id='f2000000-0000-0000-0000-000000000d01'),
  '5000', 'F2 : set_competition_subsidy a bien posé authorized_subsidy_local');

select * from finish();
rollback;
