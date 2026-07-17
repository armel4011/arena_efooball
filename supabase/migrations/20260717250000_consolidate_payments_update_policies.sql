-- =============================================================================
-- ARENA — Audit 2026-07-17 (#4) : consolider les 2 policies UPDATE de `payments`
-- =============================================================================
-- `payments` porte deux policies PERMISSIVES pour UPDATE qui couvrent toutes deux
-- le rôle `authenticated` (advisor `multiple_permissive_policies` / 0006) :
--   • payments_admin_update (to public)      : super-admin valide un paiement
--       en attente (awaiting_admin -> succeeded/rejected), cloisonné pays.
--   • payments_self_cancel  (to authenticated): l'utilisateur annule son propre
--       paiement en attente (awaiting_admin -> failed).
-- Chaque UPDATE ré-évalue les DEUX policies. On les fusionne en une seule dont
-- le USING/WITH CHECK est le OR des deux — STRICTEMENT équivalent : avec
-- plusieurs policies permissives, Postgres autorise déjà « USING d'au moins une
-- ET WITH CHECK d'au moins une », soit exactement (A or B) des deux côtés.
--
-- Aucune ouverture : les branches restent indépendantes. Un utilisateur (branche
-- self) ne satisfait jamais le CHECK admin (exige is_super_admin) ; un
-- super-admin (branche admin) ne satisfait le CHECK self que s'il est lui-même
-- le payeur — cas déjà permis avant. La policy passe `to authenticated` : un
-- `anon` ne peut être ni super-admin ni propriétaire, il n'avait aucun UPDATE
-- légitime (resserrement inoffensif).
-- =============================================================================
-- Depends on: 20260717210000 (payments_admin_update, dernière def, scope pays),
--   20260714131051 (payments_self_cancel).
-- =============================================================================

drop policy if exists payments_admin_update on public.payments;
drop policy if exists payments_self_cancel on public.payments;

create policy payments_update on public.payments
  for update to authenticated
  using (
    -- super-admin : valide un paiement en attente de son périmètre pays
    (
      public.is_super_admin()
      and status = 'awaiting_admin'
      and public.admin_can_country((select auth.uid()), country_code)
    )
    or
    -- propriétaire : annule son propre paiement en attente
    (
      (select auth.uid()) = user_id
      and status = 'awaiting_admin'
    )
  )
  with check (
    (
      public.is_super_admin()
      and status = any (array['succeeded', 'rejected'])
      and public.admin_can_country((select auth.uid()), country_code)
    )
    or
    (
      (select auth.uid()) = user_id
      and status = 'failed'
    )
  );

comment on policy payments_update on public.payments is
  'Fusion de payments_admin_update + payments_self_cancel (audit 2026-07-17 #4). '
  'Branche super-admin : awaiting_admin -> succeeded/rejected, cloisonnee pays. '
  'Branche proprietaire : awaiting_admin -> failed (annulation). Une seule policy '
  'permissive au lieu de deux (advisor 0006), semantique identique.';
