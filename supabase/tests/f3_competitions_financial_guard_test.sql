-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Audit 2026-07-09 F3 : gardes financières competitions + scoping pays
-- ════════════════════════════════════════════════════════════════════
-- Migration 20260709170000 :
--   * guard : prize_pool_local/commission_xaf/commission_pct/prize_distribution
--     figés en UPDATE sauf super-admin (exception 42501) ;
--   * competitions_update_admin cloisonné pays (admin_can_country) → un admin
--     restreint hors pays ne modifie AUCUNE ligne (RLS, 0 ligne, pas d'exception).
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(5);

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('f3000000-0000-0000-0000-0000000000a0'),  -- super-admin
  ('f3000000-0000-0000-0000-0000000000c0');  -- admin restreint CM
insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban,admin_allowed_countries) values
  ('f3000000-0000-0000-0000-0000000000a0','f3_sa','f3sa@ci.invalid','CM','F3SA','super_admin',true,false,null),
  ('f3000000-0000-0000-0000-0000000000c0','f3_cm','f3cm@ci.invalid','CM','F3CM','admin',true,false,array['CM']);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code,prize_pool_local,commission_xaf) values
  ('f3000000-0000-0000-0000-0000000000d1','F3_CM','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF','CM',50000,500),
  ('f3000000-0000-0000-0000-0000000000d2','F3_SN','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF','SN',50000,500);

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

set local role authenticated;

-- ─── Guard financier (sur comp CM d1, pour isoler du scoping pays) ──────────
-- (1) admin simple CM gonfle prize_pool_local → BLOQUÉ (guard)
set local request.jwt.claims = '{"sub":"f3000000-0000-0000-0000-0000000000c0"}';
do $$ begin
  update public.competitions set prize_pool_local=999999 where id='f3000000-0000-0000-0000-0000000000d1';
  insert into _r values ('guard_admin_pool','allowed');
exception when others then insert into _r values ('guard_admin_pool','blocked'); end $$;

-- (2) super-admin change prize_pool_local → AUTORISÉ
set local request.jwt.claims = '{"sub":"f3000000-0000-0000-0000-0000000000a0"}';
do $$ begin
  update public.competitions set prize_pool_local=60000 where id='f3000000-0000-0000-0000-0000000000d1';
  insert into _r values ('guard_superadmin_pool','allowed');
exception when others then insert into _r values ('guard_superadmin_pool','blocked'); end $$;

-- ─── Scoping pays (édition d'un champ non-financier : nom) ──────────────────
-- (3) admin CM édite le nom de SA compétition (CM) → APPLIQUÉ
set local request.jwt.claims = '{"sub":"f3000000-0000-0000-0000-0000000000c0"}';
update public.competitions set name='F3_CM_EDIT' where id='f3000000-0000-0000-0000-0000000000d1';
insert into _r select 'scope_cm_on_cm',
  case when (select name from public.competitions where id='f3000000-0000-0000-0000-0000000000d1')='F3_CM_EDIT'
       then 'changed' else 'unchanged' end;

-- (4) admin CM tente d'éditer une compétition SN → NON APPLIQUÉ (RLS, 0 ligne)
update public.competitions set name='F3_SN_HACK' where id='f3000000-0000-0000-0000-0000000000d2';
insert into _r select 'scope_cm_on_sn',
  case when (select name from public.competitions where id='f3000000-0000-0000-0000-0000000000d2')='F3_SN_HACK'
       then 'changed' else 'unchanged' end;

-- (5) super-admin édite la compétition SN → APPLIQUÉ
set local request.jwt.claims = '{"sub":"f3000000-0000-0000-0000-0000000000a0"}';
update public.competitions set name='F3_SN_OK' where id='f3000000-0000-0000-0000-0000000000d2';
insert into _r select 'scope_sa_on_sn',
  case when (select name from public.competitions where id='f3000000-0000-0000-0000-0000000000d2')='F3_SN_OK'
       then 'changed' else 'unchanged' end;

reset role;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test='guard_admin_pool'), 'blocked',
  'F3 : admin simple NE PEUT PAS gonfler prize_pool_local');
select is((select result from _r where test='guard_superadmin_pool'), 'allowed',
  'F3 : super-admin peut changer prize_pool_local');
select is((select result from _r where test='scope_cm_on_cm'), 'changed',
  'F3 : admin CM édite sa compétition CM (champ non-financier)');
select is((select result from _r where test='scope_cm_on_sn'), 'unchanged',
  'F3 : admin CM NE PEUT PAS éditer une compétition SN (scoping pays)');
select is((select result from _r where test='scope_sa_on_sn'), 'changed',
  'F3 : super-admin édite une compétition SN (scope NULL)');

select * from finish();
rollback;
