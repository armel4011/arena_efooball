-- ════════════════════════════════════════════════════════════════════
-- pgTAP — attach_payment_proof : le joueur joint sa capture d'inscription
-- ════════════════════════════════════════════════════════════════════
-- Couvre la RPC SECURITY DEFINER public.attach_payment_proof(payment, path) :
--   - un joueur ne peut joindre une preuve QUE sur SON paiement en
--     `awaiting_admin` (WHERE user_id = auth.uid() AND status='awaiting_admin') ;
--   - viser le paiement d'un AUTRE joueur → introuvable (P0002), aucune écriture ;
--   - viser son propre paiement mais PAS awaiting_admin (déjà succeeded) → P0002.
--
-- Pattern : rôle `authenticated` + JWT simulé, capture des exceptions dans
-- une table temp, assertions après `reset role`.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(4);

-- ─── Fixtures (superuser : bypass RLS) ──────────────────────────────
insert into auth.users(id) values
  ('a5000000-0000-0000-0000-0000000000a1'),  -- propriétaire (awaiting)
  ('a5000000-0000-0000-0000-0000000000a2');  -- autre joueur (succeeded)
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('a5000000-0000-0000-0000-0000000000a1','ap_o','apo@ci.invalid','CM','APOO','player',true),
  ('a5000000-0000-0000-0000-0000000000a2','ap_x','apx@ci.invalid','CM','APXX','player',true);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency)
values ('a5000000-0000-0000-0000-0000000000c1','ATTACH','efootball','single_elimination','ongoing',now(),4,1000,'XAF');

insert into payments(id,user_id,competition_id,amount_local,currency,provider,status) values
  ('a5000000-0000-0000-0000-0000000000e1','a5000000-0000-0000-0000-0000000000a1','a5000000-0000-0000-0000-0000000000c1',1000,'XAF','mobile_money_manual','awaiting_admin'),
  ('a5000000-0000-0000-0000-0000000000e2','a5000000-0000-0000-0000-0000000000a2','a5000000-0000-0000-0000-0000000000c1',1000,'XAF','mobile_money_manual','succeeded');

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

set local role authenticated;

-- (1) L'autre joueur tente de joindre une preuve sur le paiement du proprio → P0002.
set local request.jwt.claims = '{"sub":"a5000000-0000-0000-0000-0000000000a2"}';
do $$ begin
  perform public.attach_payment_proof('a5000000-0000-0000-0000-0000000000e1', 'proofs/hack.jpg');
  insert into _r values ('nonowner','allowed');
exception when others then insert into _r values ('nonowner','blocked:'||sqlstate); end $$;

-- (2) Le propriétaire joint la preuve sur son paiement awaiting_admin → OK.
set local request.jwt.claims = '{"sub":"a5000000-0000-0000-0000-0000000000a1"}';
select public.attach_payment_proof('a5000000-0000-0000-0000-0000000000e1', 'proofs/legit.jpg');

-- (3) L'autre joueur joint sur SON paiement mais PAS awaiting_admin (succeeded) → P0002.
set local request.jwt.claims = '{"sub":"a5000000-0000-0000-0000-0000000000a2"}';
do $$ begin
  perform public.attach_payment_proof('a5000000-0000-0000-0000-0000000000e2', 'proofs/late.jpg');
  insert into _r values ('wrongstate','allowed');
exception when others then insert into _r values ('wrongstate','blocked:'||sqlstate); end $$;

reset role;

-- ─── Assertions (superuser) ─────────────────────────────────────────
select is((select result from _r where test='nonowner'), 'blocked:P0002',
  'un joueur ne peut pas joindre de preuve sur le paiement d''un autre (P0002)');
select is((select proof_path from payments where id='a5000000-0000-0000-0000-0000000000e1'),
  'proofs/legit.jpg', 'le proprietaire attache bien la preuve sur son paiement awaiting_admin');
select is((select proof_path from payments where id='a5000000-0000-0000-0000-0000000000e2'),
  null, 'le paiement de l''autre joueur (cible non-proprio) reste sans preuve');
select is((select result from _r where test='wrongstate'), 'blocked:P0002',
  'joindre une preuve sur un paiement PAS awaiting_admin est refuse (P0002)');

select * from finish();
rollback;
