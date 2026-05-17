-- Drop d'un index débris confirmé par l'audit du 2026-05-17.
--
-- `idx_invitation_codes_unused` (créé par 20260505100005_audit_rls_indexes.sql)
-- indexait `(code) WHERE used_at IS NULL`. La migration Phase 12.5
-- (20260516100001_invitation_codes_target_and_uses.sql) a refactoré la
-- sémantique vers `uses_count`/`max_uses` et créé
-- `invitation_codes_code_active_idx WHERE uses_count = 0`. Depuis,
-- `used_at` est uniquement écrit comme audit trail dans l'EF
-- register-admin — jamais relu comme filtre. L'index est donc inutilisé
-- et obsolète.

DROP INDEX IF EXISTS public.idx_invitation_codes_unused;
