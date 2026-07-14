-- ════════════════════════════════════════════════════════════════════
-- pgTAP — admin_filter_users : cloisonnement pays (audit 2026-07-14)
-- ════════════════════════════════════════════════════════════════════
-- Couvre le fix P2 (20260714130000) : `admin_filter_users` renvoie SETOF
-- profiles (dont l'email). Un admin scopé {CM} ne doit voir QUE les profils de
-- ses pays autorisés — `p_country_code` était un simple filtre, pas une borne.
--
--   • admin scopé {CM}     → aucun profil SN, voit les profils CM ;
--   • admin scopé {CM}, p_country_code='SN' → 0 ligne (ne contourne pas le scope) ;
--   • admin global (scope NULL) → voit CM ET SN ;
--   • super-admin              → voit CM ET SN.
--
-- Le rôle/scope de l'appelant est piloté par profiles.admin_allowed_countries +
-- request.jwt.claims (auth.uid). Superuser, rollback final.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(5);

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('ce000000-0000-0000-0000-0000000000cd'),  -- admin scopé {CM}
  ('ce000000-0000-0000-0000-0000000000a6'),  -- admin global (scope NULL)
  ('ce000000-0000-0000-0000-0000000000ff'),  -- super-admin
  ('ce000000-0000-0000-0000-0000000000c1'),  -- joueur CM
  ('ce000000-0000-0000-0000-00000000005e');   -- joueur SN

insert into profiles(id,username,email,country_code,referral_code,role,is_active,admin_allowed_countries) values
  ('ce000000-0000-0000-0000-0000000000cd','ce_admin_cm','ceadcm@ci.invalid','CM','CEAD','admin',true, array['CM']),
  ('ce000000-0000-0000-0000-0000000000a6','ce_admin_gl','ceadgl@ci.invalid','CM','CEAG','admin',true, NULL),
  ('ce000000-0000-0000-0000-0000000000ff','ce_super','cesu@ci.invalid','CM','CESU','super_admin',true, NULL),
  ('ce000000-0000-0000-0000-0000000000c1','ce_user_cm','ceucm@ci.invalid','CM','CEUC','player',true, NULL),
  ('ce000000-0000-0000-0000-00000000005e','ce_user_sn','ceusn@ci.invalid','SN','CEUS','player',true, NULL);

-- ─── Admin scopé {CM} ───────────────────────────────────────────────
set local request.jwt.claims = '{"sub":"ce000000-0000-0000-0000-0000000000cd"}';

select is(
  (select count(*)::int from public.admin_filter_users() where country_code='SN'),
  0, 'admin {CM} : aucun profil SN dans la liste');
select isnt(
  (select count(*)::int from public.admin_filter_users() where country_code='CM'),
  0, 'admin {CM} : voit bien des profils CM');
select is(
  (select count(*)::int from public.admin_filter_users(p_country_code := 'SN')),
  0, 'admin {CM} : filtrer sur SN ne contourne pas le scope (0 ligne)');

-- ─── Admin global (scope NULL) ──────────────────────────────────────
set local request.jwt.claims = '{"sub":"ce000000-0000-0000-0000-0000000000a6"}';
select isnt(
  (select count(*)::int from public.admin_filter_users() where country_code='SN'),
  0, 'admin global : voit les profils SN');

-- ─── Super-admin ────────────────────────────────────────────────────
set local request.jwt.claims = '{"sub":"ce000000-0000-0000-0000-0000000000ff"}';
select isnt(
  (select count(*)::int from public.admin_filter_users() where country_code='SN'),
  0, 'super-admin : voit les profils SN');

select * from finish();
rollback;
