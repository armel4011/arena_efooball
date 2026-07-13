-- ════════════════════════════════════════════════════════════════════
-- pgTAP — mark_payment_refunded : clôture d'un remboursement (super-admin)
-- ════════════════════════════════════════════════════════════════════
-- Couvre la RPC SECURITY DEFINER public.mark_payment_refunded(payment) :
--   - RÉSERVÉE au super-admin (un admin simple / joueur → 42501) ;
--   - ne s'applique qu'à un paiement `refund_pending` → status 'refunded' ;
--   - un paiement PAS en attente de remboursement → 42501 (pas de
--     remboursement d'un paiement succeeded/awaiting).
--
-- Pattern : rôle `authenticated` + JWT simulé, capture des exceptions dans
-- une table temp, assertions après `reset role`.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(3);

-- Notif (pg_net) neutralisée : mark_payment_refunded insère une notification.
alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Fixtures (superuser : bypass RLS) ──────────────────────────────
insert into auth.users(id) values
  ('af000000-0000-0000-0000-00000000005a'),  -- super-admin
  ('af000000-0000-0000-0000-0000000000a1'),  -- joueur (refund_pending)
  ('af000000-0000-0000-0000-0000000000a2');  -- joueur (succeeded)
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('af000000-0000-0000-0000-00000000005a','rf_sa','rfsa@ci.invalid','CM','RFSA','super_admin',true),
  ('af000000-0000-0000-0000-0000000000a1','rf_p1','rfp1@ci.invalid','CM','RFP1','player',true),
  ('af000000-0000-0000-0000-0000000000a2','rf_p2','rfp2@ci.invalid','CM','RFP2','player',true);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency)
values ('af000000-0000-0000-0000-0000000000c1','REFUND','efootball','single_elimination','ongoing',now(),4,1000,'XAF');

insert into payments(id,user_id,competition_id,amount_local,currency,provider,status) values
  ('af000000-0000-0000-0000-0000000000e1','af000000-0000-0000-0000-0000000000a1','af000000-0000-0000-0000-0000000000c1',1000,'XAF','mobile_money_manual','refund_pending'),
  ('af000000-0000-0000-0000-0000000000e2','af000000-0000-0000-0000-0000000000a2','af000000-0000-0000-0000-0000000000c1',1000,'XAF','mobile_money_manual','succeeded');

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

set local role authenticated;

-- (1) Un JOUEUR (non super-admin) ne peut pas rembourser → 42501.
set local request.jwt.claims = '{"sub":"af000000-0000-0000-0000-0000000000a1"}';
do $$ begin
  perform public.mark_payment_refunded('af000000-0000-0000-0000-0000000000e1');
  insert into _r values ('nonsuper','allowed');
exception when others then insert into _r values ('nonsuper','blocked:'||sqlstate); end $$;

-- (2) Le super-admin rembourse un paiement refund_pending → 'refunded'.
set local request.jwt.claims = '{"sub":"af000000-0000-0000-0000-00000000005a"}';
select public.mark_payment_refunded('af000000-0000-0000-0000-0000000000e1');

-- (3) Le super-admin sur un paiement PAS en refund_pending (succeeded) → 42501.
do $$ begin
  perform public.mark_payment_refunded('af000000-0000-0000-0000-0000000000e2');
  insert into _r values ('wrongstate','allowed');
exception when others then insert into _r values ('wrongstate','blocked:'||sqlstate); end $$;

reset role;

-- ─── Assertions (superuser) ─────────────────────────────────────────
select is((select result from _r where test='nonsuper'), 'blocked:42501',
  'un joueur / admin non-super ne peut pas rembourser (42501)');
select is((select status from payments where id='af000000-0000-0000-0000-0000000000e1'),
  'refunded', 'le super-admin rembourse un paiement refund_pending → refunded');
select is((select result from _r where test='wrongstate'), 'blocked:42501',
  'un paiement PAS en refund_pending ne peut pas etre rembourse (42501)');

select * from finish();
rollback;
