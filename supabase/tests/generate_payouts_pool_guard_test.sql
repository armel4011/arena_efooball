-- ════════════════════════════════════════════════════════════════════
-- pgTAP — generate_payouts : gardes budget (P1 audit 2026-06-24)
-- ════════════════════════════════════════════════════════════════════
-- La cagnotte ARENA est DÉCIDÉE par l'admin et PEUT légitimement dépasser les
-- frais encaissés (tournois promo / sponsorisés). Deux gardes :
--   1. Cap dur d'intégrité : SUM(payouts) <= prize_pool_local DÉCLARÉ → rejet
--      23514 si une prize_distribution corrompue dépasse le budget annoncé.
--   2. Alerte non-bloquante : si versements > frais encaissés (subvention
--      plateforme), trace une entrée admin_audit_log `payout_pool_subsidy`.
--   3. Durcissement 2026-06-25 : refus si des prix existent dans
--      prize_distribution mais aucune cagnotte n'est déclarée (pool <= 0).
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(6);

alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('72727272-0000-0000-0000-000000000001'),  -- super-admin
  ('72727272-0000-0000-0000-0000000000a1'),('72727272-0000-0000-0000-0000000000a2');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('72727272-0000-0000-0000-000000000001','pg_sa','pgsa@ci.invalid','CI','PGSA','super_admin',true),
  ('72727272-0000-0000-0000-0000000000a1','pg_a','pga@ci.invalid','CI','PGA1','player',true),
  ('72727272-0000-0000-0000-0000000000a2','pg_b','pgb@ci.invalid','CI','PGA2','player',true);

-- cPromo : pool déclaré 70000, frais encaissés 2000 → subvention légitime
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,prize_pool_local,prize_distribution)
values ('73737373-0000-0000-0000-0000000000A1','PROMO','efootball','single_elimination','completed',now()-interval '1 day',4,1000,'XAF',70000,'[50000, 20000]'::jsonb),
  -- cCorrupt : distribution (90000) > pool déclaré (70000) → doit être rejetée
       ('73737373-0000-0000-0000-0000000000B1','CORRUPT','efootball','single_elimination','completed',now()-interval '1 day',4,1000,'XAF',70000,'[60000, 30000]'::jsonb),
  -- cZero : des prix dans la distribution mais AUCUNE cagnotte déclarée (pool 0)
       ('73737373-0000-0000-0000-0000000000C1','ZEROPOOL','efootball','single_elimination','completed',now()-interval '1 day',4,1000,'XAF',0,'[30000, 0]'::jsonb);
insert into competition_registrations(competition_id,player_id,status,final_rank) values
  ('73737373-0000-0000-0000-0000000000A1','72727272-0000-0000-0000-0000000000a1','confirmed',1),
  ('73737373-0000-0000-0000-0000000000A1','72727272-0000-0000-0000-0000000000a2','confirmed',2),
  ('73737373-0000-0000-0000-0000000000B1','72727272-0000-0000-0000-0000000000a1','confirmed',1),
  ('73737373-0000-0000-0000-0000000000B1','72727272-0000-0000-0000-0000000000a2','confirmed',2),
  ('73737373-0000-0000-0000-0000000000C1','72727272-0000-0000-0000-0000000000a1','confirmed',1);
insert into payments(user_id,competition_id,amount_local,currency,status,provider) values
  ('72727272-0000-0000-0000-0000000000a1','73737373-0000-0000-0000-0000000000A1',1000,'XAF','succeeded','mobile_money_manual'),
  ('72727272-0000-0000-0000-0000000000a2','73737373-0000-0000-0000-0000000000A1',1000,'XAF','succeeded','mobile_money_manual');

set local request.jwt.claims = '{"sub":"72727272-0000-0000-0000-000000000001"}';

-- ─── P1.1 : distribution > pool déclaré → rejet 23514 ───────────────
select throws_ok(
  $$ select public.generate_payouts('73737373-0000-0000-0000-0000000000B1') $$,
  '23514', null, 'P1 : une distribution supérieure à la cagnotte déclarée est rejetée');
select is(
  (select count(*)::int from payouts where competition_id='73737373-0000-0000-0000-0000000000B1'),
  0, 'aucun payout généré quand la garde rejette (rollback)');

-- ─── P1.2 : promo légitime → versements + alerte subvention tracée ───
select is(
  public.generate_payouts('73737373-0000-0000-0000-0000000000A1'),
  2, 'tournoi promo : 2 versements générés (cagnotte > frais, autorisé)');
select is(
  (select count(*)::int from payouts where competition_id='73737373-0000-0000-0000-0000000000A1'),
  2, 'les 2 payouts promo sont bien en base');
select is(
  (select (after_state->>'paid_total')::numeric
     from admin_audit_log
     where action='payout_pool_subsidy' and target_id='73737373-0000-0000-0000-0000000000A1'),
  70000::numeric, 'subvention plateforme tracée dans admin_audit_log (paid_total=70000)');

-- ─── Durcissement : prix déclarés mais cagnotte non renseignée → rejet ──
select throws_ok(
  $$ select public.generate_payouts('73737373-0000-0000-0000-0000000000C1') $$,
  '23514', null, 'des prix sans cagnotte déclarée (pool=0) sont refusés');

select * from finish();
rollback;
