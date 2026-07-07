-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Audit 2026-07-07 (P2 #7) : validation de paiement idempotente
-- ════════════════════════════════════════════════════════════════════
-- Couvre la migration 20260707140000 : la policy payments_admin_update ne rend
-- modifiables QUE les paiements encore `awaiting_admin` (USING) et uniquement
-- vers succeeded/rejected (WITH CHECK).
--   - validation légitime d'un paiement en attente → OK ;
--   - tentative (liste périmée) sur un paiement `rejected` → NO-OP (RLS USING) ;
--   - idem sur `refund_pending` → NO-OP (pas de résurrection, pas de double
--     comptage revenu ni d'évasion de la file de remboursement) ;
--   - cible de statut illégale (ex. refund_pending posé en direct) → BLOQUÉ
--     par le WITH CHECK.
--
-- Pattern (cf. payments_payouts_rls_test) : rôle `authenticated` + JWT simulé,
-- capture dans une table temp, `reset role` avant les assertions.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(5);

-- Le trigger de validation insère une registration : neutralisé pour isoler la
-- RLS (on teste l'idempotence de l'UPDATE, pas l'inscription en aval).
alter table public.payments disable trigger trg_payment_validated_insert_registration;

-- ─── Fixtures (superuser : bypass RLS) ──────────────────────────────
insert into auth.users(id) values
  ('9a9a9a9a-0000-0000-0000-000000000001'),  -- super_admin
  ('9a9a9a9a-0000-0000-0000-0000000000a1'),  -- joueur (await)
  ('9a9a9a9a-0000-0000-0000-0000000000a2'),  -- joueur (await2)
  ('9a9a9a9a-0000-0000-0000-0000000000a3'),  -- joueur (rejected)
  ('9a9a9a9a-0000-0000-0000-0000000000a4');  -- joueur (refund_pending)
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('9a9a9a9a-0000-0000-0000-000000000001','pi_sa','pisa@ci.invalid','CI','PISA','super_admin',true),
  ('9a9a9a9a-0000-0000-0000-0000000000a1','pi_u1','piu1@ci.invalid','CI','PIU1','player',true),
  ('9a9a9a9a-0000-0000-0000-0000000000a2','pi_u2','piu2@ci.invalid','CI','PIU2','player',true),
  ('9a9a9a9a-0000-0000-0000-0000000000a3','pi_u3','piu3@ci.invalid','CI','PIU3','player',true),
  ('9a9a9a9a-0000-0000-0000-0000000000a4','pi_u4','piu4@ci.invalid','CI','PIU4','player',true);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency)
values ('9b9b9b9b-0000-0000-0000-000000000001','PAYIDEM','efootball','single_elimination','ongoing',now()+interval '1 day',8,5000,'XAF');

-- 4 paiements de 4 joueurs distincts (évite l'index unique paiement actif/comp).
insert into payments(id,user_id,competition_id,amount_local,currency,provider,status) values
  ('9c9c9c9c-0000-0000-0000-000000000001','9a9a9a9a-0000-0000-0000-0000000000a1','9b9b9b9b-0000-0000-0000-000000000001',5000,'XAF','mobile_money_manual','awaiting_admin'),
  ('9c9c9c9c-0000-0000-0000-000000000002','9a9a9a9a-0000-0000-0000-0000000000a2','9b9b9b9b-0000-0000-0000-000000000001',5000,'XAF','mobile_money_manual','awaiting_admin'),
  ('9c9c9c9c-0000-0000-0000-000000000003','9a9a9a9a-0000-0000-0000-0000000000a3','9b9b9b9b-0000-0000-0000-000000000001',5000,'XAF','mobile_money_manual','rejected'),
  ('9c9c9c9c-0000-0000-0000-000000000004','9a9a9a9a-0000-0000-0000-0000000000a4','9b9b9b9b-0000-0000-0000-000000000001',5000,'XAF','mobile_money_manual','refund_pending');

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

set local role authenticated;
set local request.jwt.claims = '{"sub":"9a9a9a9a-0000-0000-0000-000000000001"}';

-- (1) Validation LÉGITIME d'un paiement en attente → doit passer à succeeded.
update public.payments set status='succeeded',
       validated_by_admin_id='9a9a9a9a-0000-0000-0000-000000000001', validated_at=now()
 where id='9c9c9c9c-0000-0000-0000-000000000001';

-- (2) Tentative (liste périmée) de valider un paiement DÉJÀ rejeté → NO-OP RLS.
update public.payments set status='succeeded',
       validated_by_admin_id='9a9a9a9a-0000-0000-0000-000000000001', validated_at=now()
 where id='9c9c9c9c-0000-0000-0000-000000000003';

-- (3) Tentative de valider un paiement en remboursement → NO-OP RLS.
update public.payments set status='succeeded',
       validated_by_admin_id='9a9a9a9a-0000-0000-0000-000000000001', validated_at=now()
 where id='9c9c9c9c-0000-0000-0000-000000000004';

-- (4) Cible de statut ILLÉGALE (refund_pending posé en direct sur un paiement
--     en attente) → BLOQUÉ par le WITH CHECK.
do $$ begin
  update public.payments set status='refund_pending'
   where id='9c9c9c9c-0000-0000-0000-000000000002';
  insert into _r values ('illegal_target','allowed');
exception when others then insert into _r values ('illegal_target','blocked'); end $$;

reset role;

-- ─── Assertions (superuser) ─────────────────────────────────────────
select is((select status from payments where id='9c9c9c9c-0000-0000-0000-000000000001'),
  'succeeded', 'un paiement awaiting_admin est validé (succeeded)');
select is((select status from payments where id='9c9c9c9c-0000-0000-0000-000000000003'),
  'rejected', 'un paiement DÉJÀ rejeté ne peut PAS être ressuscité en succeeded (no-op RLS)');
select is((select status from payments where id='9c9c9c9c-0000-0000-0000-000000000004'),
  'refund_pending', 'un paiement en remboursement ne peut PAS être basculé en succeeded');
select is((select result from _r where test='illegal_target'),
  'blocked', 'poser un statut cible illégal (refund_pending) est bloqué par le WITH CHECK');
select is((select status from payments where id='9c9c9c9c-0000-0000-0000-000000000002'),
  'awaiting_admin', 'le paiement visé par la cible illégale reste awaiting_admin');

select * from finish();
rollback;
