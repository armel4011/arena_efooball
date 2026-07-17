-- =============================================================================
-- ARENA — Audit 2026-07-17 : P3 d'hygiène (round 2)
-- =============================================================================
-- Le round 1 (20260717210000_audit_p3_hygiene) a ratissé payments,
-- purge_match_reminders_on_reschedule et onboarding, mais a manqué l'initplan
-- des policies de `user_onboarding_seen` (créées le même jour, 20260717160000).
-- Un unique correctif ici.
--
-- NB : l'autre P3 pressenti (revoke EXECUTE sur le trigger
-- `shift_competition_matches_on_reschedule`) s'est révélé un FAUX POSITIF à la
-- vérification — son ACL est déjà `{postgres, service_role}` (revoke hérité
-- d'une version antérieure, préservé par `create or replace`). Rien à faire.
-- =============================================================================

-- ─── `user_onboarding_seen` : `auth.uid()` nu dans les policies ──────────────
-- Les deux policies (20260717160000) filtrent sur `auth.uid()` non enveloppé :
-- Postgres le ré-évalue PAR LIGNE au lieu d'une fois par requête (advisor
-- `auth_rls_initplan` / 0003). La convention établie du repo est
-- `(select auth.uid())` — déjà appliquée à `tutorial_video_views`
-- (20260612000126), dont cette table est le miroir. Impact : perf seule, aucune
-- fuite (la table est petite par utilisateur), mais l'advisor le remonte.
drop policy if exists user_onboarding_seen_self_select on public.user_onboarding_seen;
create policy user_onboarding_seen_self_select
  on public.user_onboarding_seen for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists user_onboarding_seen_self_insert on public.user_onboarding_seen;
create policy user_onboarding_seen_self_insert
  on public.user_onboarding_seen for insert
  to authenticated
  with check (user_id = (select auth.uid()));
