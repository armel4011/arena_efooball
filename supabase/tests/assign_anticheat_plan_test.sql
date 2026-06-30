-- ════════════════════════════════════════════════════════════════════
-- pgTAP — assign_anticheat_plan (tiering anti-triche P0) : structure + ACL
-- ════════════════════════════════════════════════════════════════════
-- Le RPC (20260630120000) décide, par match et de façon idempotente, si on
-- egress LiveKit (tier `livekit`, 1 joueur tiré au hasard) ou pas (`native_only`).
-- Il est INTERNE : appelé uniquement par l'EF `livekit-token` en service-role.
-- On vérifie donc surtout l'ACL (jamais exposé au client) + la structure de la
-- table de plans. La logique de décision dépend de `random()` (échantillon),
-- donc non testée ici (vérifiée manuellement + E2E) pour rester déterministe.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(9);

-- Le RPC existe avec la bonne signature.
select has_function('public', 'assign_anticheat_plan', array['uuid']);

-- ACL : interne. service_role OUI ; anon et authenticated NON (revoke explicite).
select ok(
  has_function_privilege('service_role', 'public.assign_anticheat_plan(uuid)', 'execute'),
  'service_role peut exécuter le RPC (appelé par l''EF livekit-token)');
select ok(
  not has_function_privilege('anon', 'public.assign_anticheat_plan(uuid)', 'execute'),
  'anon ne peut PAS exécuter le RPC');
select ok(
  not has_function_privilege('authenticated', 'public.assign_anticheat_plan(uuid)', 'execute'),
  'authenticated ne peut PAS exécuter le RPC (interne, pas exposé au client)');

-- Table de plans + colonnes clés.
select has_table('public', 'match_anticheat_plans', 'la table de plans existe');
select has_column('public', 'match_anticheat_plans', 'mode', 'colonne mode');
select has_column('public', 'match_anticheat_plans', 'recorded_player_id', 'colonne recorded_player_id');
select has_column('public', 'match_anticheat_plans', 'reason', 'colonne reason');

-- RLS activée (écritures réservées service-role / RPC SECURITY DEFINER ;
-- lecture admin seule via policy).
select ok(
  (select relrowsecurity from pg_class where oid = 'public.match_anticheat_plans'::regclass),
  'RLS activée sur match_anticheat_plans');

select * from finish();
rollback;
