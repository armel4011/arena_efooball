-- ════════════════════════════════════════════════════════════════════
-- pgTAP — RLS & gardes serveur sur l'argent (payments / payouts)
-- ════════════════════════════════════════════════════════════════════
-- Couvre les invariants P0 « argent » qui ne reposaient sur AUCUN test
-- automatisé (audit 2026-06-13) :
--   * guard_payments_amount  : un joueur ne peut PAS fixer le montant ;
--     le trigger l'écrase par le `registration_fee` de la compétition.
--   * payments_self_insert    : insert limité à soi + provider manuel +
--     status 'awaiting_admin' (pas de status 'validated'/'succeeded' forgé).
--   * payments_select         : isolation — un joueur ne voit que ses paiements.
--   * payments_admin_update   : seul un super_admin peut valider (UPDATE).
--   * payouts_select / payouts_admin_update : mêmes garanties côté gains.
--
-- Pattern : on bascule en rôle `authenticated` avec un JWT simulé pour
-- exercer la RLS, on capture les résultats dans une table temporaire, puis
-- on `reset role` AVANT d'appeler les fonctions pgTAP (qui tournent en
-- superuser). Logique validée en prod via transaction ROLLBACK le 2026-06-13.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(10);

-- ─── Fixtures (en superuser : bypass RLS) ───────────────────────────
insert into auth.users(id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'),  -- joueur
  ('aaaaaaaa-0000-0000-0000-000000000002'),  -- super_admin
  ('aaaaaaaa-0000-0000-0000-000000000003');  -- autre joueur

insert into profiles(id, username, email, country_code, referral_code, role) values
  ('aaaaaaaa-0000-0000-0000-000000000001','t_ci_user','u1@ci.invalid','CI','CIREF001','player'),
  ('aaaaaaaa-0000-0000-0000-000000000002','t_ci_sadmin','sa@ci.invalid','CI','CIREF002','super_admin'),
  ('aaaaaaaa-0000-0000-0000-000000000003','t_ci_other','o@ci.invalid','CI','CIREF003','player');

insert into competitions(id,name,game,format,start_date,max_players,registration_fee,registration_currency) values
  ('cccccccc-0000-0000-0000-000000000001','CI1','efootball','single_elimination',now()+interval '1 day',8,5000,'XOF'),
  ('cccccccc-0000-0000-0000-000000000002','CI2','efootball','single_elimination',now()+interval '1 day',8,7500,'XOF');

-- Paiements pré-existants (insérés ici en superuser).
insert into payments(id,user_id,competition_id,amount_local,currency,provider,status) values
  ('dddddddd-0000-0000-0000-000000000011','aaaaaaaa-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000001',5000,'XOF','mobile_money_manual','awaiting_admin'),
  ('dddddddd-0000-0000-0000-000000000099','aaaaaaaa-0000-0000-0000-000000000003','cccccccc-0000-0000-0000-000000000001',5000,'XOF','mobile_money_manual','awaiting_admin');

-- Payouts pré-existants (un par joueur).
insert into payouts(id,user_id,competition_id,amount_local,currency,status) values
  ('eeeeeeee-0000-0000-0000-000000000011','aaaaaaaa-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000001',3000,'XOF','pending_admin_validation'),
  ('eeeeeeee-0000-0000-0000-000000000099','aaaaaaaa-0000-0000-0000-000000000003','cccccccc-0000-0000-0000-000000000001',3000,'XOF','pending_admin_validation');

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

-- ─── Acte 1 : joueur authentifié (aaaa…001) ─────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}';

-- (1) GARDE MONTANT : un montant déclaré à 1 est écrasé par le fee (7500/XOF).
with ins as (
  insert into payments(user_id,competition_id,amount_local,currency,provider,status)
  values ('aaaaaaaa-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000002',1,'ZZZ','mobile_money_manual','awaiting_admin')
  returning amount_local, currency
)
insert into _r select 'guard_amount', amount_local::text || '/' || currency from ins;

-- (2) ISOLATION SELECT : le joueur ne voit que ses paiements (les 2 siens).
insert into _r select 'select_isolation', count(*)::text from payments;

-- (3) with_check refuse un status 'validated' forgé.
do $$ begin
  insert into payments(user_id,competition_id,amount_local,currency,provider,status)
  values ('aaaaaaaa-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000001',5000,'XOF','mobile_money_manual','validated');
  insert into _r values ('reject_forged_status','allowed');
exception when others then insert into _r values ('reject_forged_status','denied'); end $$;

-- (4) with_check refuse un user_id usurpé.
do $$ begin
  insert into payments(user_id,competition_id,amount_local,currency,provider,status)
  values ('aaaaaaaa-0000-0000-0000-000000000002','cccccccc-0000-0000-0000-000000000001',5000,'XOF','mobile_money_manual','awaiting_admin');
  insert into _r values ('reject_spoofed_user','allowed');
exception when others then insert into _r values ('reject_spoofed_user','denied'); end $$;

-- (5) Un joueur ne peut PAS valider un paiement (UPDATE réservé super_admin → 0 ligne).
with upd as (
  update payments set status='succeeded' where id='dddddddd-0000-0000-0000-000000000011' returning 1
)
insert into _r select 'user_cannot_validate', count(*)::text from upd;

-- (8) Payouts : isolation SELECT (le joueur ne voit que son gain).
insert into _r select 'payout_isolation', count(*)::text from payouts;

-- (9) Payouts : un joueur ne peut PAS valider (0 ligne).
with upd as (
  update payouts set status='paid' where id='eeeeeeee-0000-0000-0000-000000000011' returning 1
)
insert into _r select 'payout_user_cannot_update', count(*)::text from upd;

-- ─── Acte 2 : super_admin authentifié (aaaa…002) ────────────────────
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-000000000002"}';

-- (6) Le super_admin PEUT valider le paiement (1 ligne).
with upd as (
  update payments set status='succeeded' where id='dddddddd-0000-0000-0000-000000000011' returning 1
)
insert into _r select 'sadmin_can_validate', count(*)::text from upd;

-- (7) Le super_admin voit tous les paiements (≥ 3).
insert into _r select 'sadmin_sees_all', (count(*) >= 3)::text from payments;

-- (10) Payouts : le super_admin PEUT valider (1 ligne).
with upd as (
  update payouts set status='paid' where id='eeeeeeee-0000-0000-0000-000000000011' returning 1
)
insert into _r select 'payout_sadmin_can_update', count(*)::text from upd;

reset role;

-- ─── Assertions pgTAP (en superuser) ────────────────────────────────
select is((select result from _r where test='guard_amount'), '7500.00/XOF',
  'guard_payments_amount écrase le montant déclaré par le registration_fee');
select is((select result from _r where test='select_isolation'), '2',
  'payments_select : un joueur ne voit que ses propres paiements');
select is((select result from _r where test='reject_forged_status'), 'denied',
  'payments_self_insert refuse un status forgé (validated)');
select is((select result from _r where test='reject_spoofed_user'), 'denied',
  'payments_self_insert refuse un user_id usurpé');
select is((select result from _r where test='user_cannot_validate'), '0',
  'payments_admin_update : un joueur ne peut pas valider un paiement');
select is((select result from _r where test='sadmin_can_validate'), '1',
  'payments_admin_update : un super_admin peut valider un paiement');
select is((select result from _r where test='sadmin_sees_all'), 'true',
  'payments_select : un super_admin voit tous les paiements');
select is((select result from _r where test='payout_isolation'), '1',
  'payouts_select : un joueur ne voit que ses propres gains');
select is((select result from _r where test='payout_user_cannot_update'), '0',
  'payouts_admin_update : un joueur ne peut pas valider un gain');
select is((select result from _r where test='payout_sadmin_can_update'), '1',
  'payouts_admin_update : un super_admin peut valider un gain');

select finish();
rollback;
