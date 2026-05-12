-- =============================================================================
-- ARENA — Phase 11 — Admin write policies
-- =============================================================================
-- Plugs the two RLS gaps that block the admin console from writing without an
-- Edge Function:
--   1. payouts : the original phase-0 RLS only allowed admins to SELECT.
--      Validation goes through `validate_payout` Edge Function in PHASE 12.5,
--      but until then the AdminPayoutsPage needs to flip status / stamp the
--      validating admin / write a justification client-side under RLS.
--   2. admin_audit_log : admin had SELECT-only, so the console couldn't append
--      its own trail. The trail is consequential for compliance — RLS-only
--      writes are acceptable for V1.0 because RLS keeps admin_id = auth.uid().
--
-- The Edge Functions that should eventually own these writes
-- (validate_payout, log_admin_action) are tracked in the PHASE 12.5 punch-list.
-- =============================================================================
-- Depends on: 20260505100005_audit_rls_indexes.sql
-- =============================================================================

-- ---------- payouts ----------------------------------------------------------
-- Admin can UPDATE a payout row (validation flow). The RLS keeps the
-- caller's role check; the column-level guarantees (e.g. only the
-- `validated_by_admin_id` / `status` columns get flipped) are enforced
-- application-side until the dedicated Edge Function lands.
create policy "payouts_admin_update"
  on public.payouts for update
  using (public.is_admin())
  with check (public.is_admin());

-- ---------- admin_audit_log --------------------------------------------------
-- Admin can append a row, but only attributed to themselves — the
-- `admin_id = auth.uid()` clause makes the trail tamper-resistant
-- (one admin can't backdate an action under another admin's name).
create policy "admin_audit_log_admin_insert"
  on public.admin_audit_log for insert
  with check (
    public.is_admin()
    and admin_id = auth.uid()
  );

-- The trail is append-only by design — no UPDATE / DELETE policies.

-- ---------- disputes: admin sees all + writes already covered ----------------
-- `disputes_admin_all` from migration 5 already grants admin full CRUD.

-- ---------- invitation_codes: super-admin already covered --------------------
-- `invitation_codes_super_admin` already grants super-admin full CRUD.
