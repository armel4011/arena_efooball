-- ════════════════════════════════════════════════════════════════════
-- pgTAP — delete_competition_cascade : garde super-admin (audit 2026-06-24)
-- ════════════════════════════════════════════════════════════════════
-- La RPC SECURITY DEFINER hard-DELETE les pièces comptables (payouts,
-- platform_revenue, payments) d'une compétition. La garde a été durcie de
-- is_admin() → is_super_admin() (migration 20260624120000) : un admin SIMPLE
-- ne doit PAS pouvoir effacer la comptabilité, seul un super-admin le peut.
--
-- Le rôle de l'appelant est piloté par request.jwt.claims (auth.uid →
-- is_super_admin / is_admin).
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(5);

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('6c6c6c6c-0000-0000-0000-000000000001'),  -- super-admin
  ('6c6c6c6c-0000-0000-0000-000000000002'),  -- admin simple
  ('6c6c6c6c-0000-0000-0000-000000000003');  -- joueur
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('6c6c6c6c-0000-0000-0000-000000000001','del_sa','dsa@ci.invalid','CI','DSA','super_admin',true),
  ('6c6c6c6c-0000-0000-0000-000000000002','del_ad','dad@ci.invalid','CI','DAD','admin',true),
  ('6c6c6c6c-0000-0000-0000-000000000003','del_pl','dpl@ci.invalid','CI','DPL','player',true);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,prize_distribution) values
  ('6d6d6d6d-0000-0000-0000-000000000001','DELME','efootball','single_elimination','completed',now()-interval '1 day',4,1000,'XAF','[0,0,0,0]'::jsonb);

select has_function('public', 'delete_competition_cascade', array['uuid']);

-- ─── Un joueur ne peut PAS supprimer ────────────────────────────────
set local request.jwt.claims = '{"sub":"6c6c6c6c-0000-0000-0000-000000000003"}';
select throws_ok(
  $$ select public.delete_competition_cascade('6d6d6d6d-0000-0000-0000-000000000001') $$,
  'P0001', 'forbidden: super-admin only', 'un joueur ne peut pas supprimer une compétition');

-- ─── Un ADMIN SIMPLE ne peut PAS supprimer (cœur du durcissement) ────
set local request.jwt.claims = '{"sub":"6c6c6c6c-0000-0000-0000-000000000002"}';
select throws_ok(
  $$ select public.delete_competition_cascade('6d6d6d6d-0000-0000-0000-000000000001') $$,
  'P0001', 'forbidden: super-admin only', 'un admin simple ne peut PAS effacer la comptabilité');

-- la compétition existe toujours après les tentatives refusées
select is(
  (select count(*)::int from competitions where id='6d6d6d6d-0000-0000-0000-000000000001'),
  1, 'la compétition survit aux tentatives non-super-admin');

-- ─── Un super-admin peut supprimer ──────────────────────────────────
set local request.jwt.claims = '{"sub":"6c6c6c6c-0000-0000-0000-000000000001"}';
select lives_ok(
  $$ select public.delete_competition_cascade('6d6d6d6d-0000-0000-0000-000000000001') $$,
  'un super-admin peut supprimer la compétition');

select * from finish();
rollback;
