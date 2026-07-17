-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Audit 2026-07-17 P3 hygiène round 2
-- ════════════════════════════════════════════════════════════════════
-- Verrouille le correctif de 20260717230000 : la recréation des policies de
-- `user_onboarding_seen` avec `(select auth.uid())` (initplan) laisse les deux
-- policies self-only en place ET préserve l'isolation par utilisateur.
-- L'initplan est une optimisation invisible au comportement ; ce test protège
-- la sémantique contre une régression lors de la recréation.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(5);

-- ─── Policies self-only présentes après recréation ──────────────────
select policies_are(
  'public', 'user_onboarding_seen',
  array['user_onboarding_seen_self_select', 'user_onboarding_seen_self_insert'],
  'user_onboarding_seen : les deux policies self-only présentes après recréation');

-- ─── Fixtures ───────────────────────────────────────────────────────
insert into auth.users(id) values
  ('0b000000-0000-0000-0000-0000000000a1'),
  ('0b000000-0000-0000-0000-0000000000a2');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('0b000000-0000-0000-0000-0000000000a1','ob_p1','obp1@ci.invalid','CI','OBP1','player',true),
  ('0b000000-0000-0000-0000-0000000000a2','ob_p2','obp2@ci.invalid','CI','OBP2','player',true);

-- user 1 marque un flag : TRUE la 1re fois, FALSE ensuite
set local role authenticated;
set local request.jwt.claims = '{"sub":"0b000000-0000-0000-0000-0000000000a1"}';
select is(
  public.onboarding_mark_seen_once('match_role_intro:home'), true,
  'onboarding_mark_seen_once : TRUE au 1er passage');
select is(
  public.onboarding_mark_seen_once('match_role_intro:home'), false,
  'onboarding_mark_seen_once : FALSE si déjà vu');
select is(
  (select count(*)::int from public.user_onboarding_seen), 1,
  'user 1 ne voit QUE sa propre ligne (RLS self-select)');

-- user 2 ne voit pas le flag de user 1
set local request.jwt.claims = '{"sub":"0b000000-0000-0000-0000-0000000000a2"}';
select is(
  (select count(*)::int from public.user_onboarding_seen), 0,
  'user 2 ne voit AUCUNE ligne de user 1 (isolation RLS)');

reset role;
select * from finish();
rollback;
