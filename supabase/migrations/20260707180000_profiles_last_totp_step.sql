-- =============================================================================
-- ARENA — Audit 2026-07-07 (P2) : anti-rejeu TOTP (dernier step consommé)
-- =============================================================================
-- verifyTotp acceptait un code dans une fenêtre ±1 (30 s) SANS tracer le step
-- consommé → un code 6 chiffres capté pouvait être rejoué ~30-90 s. On persiste
-- le dernier step TOTP accepté par admin ; les EF admin-verify-totp /
-- admin-stepup-totp refusent désormais tout step ≤ ce dernier.
--
-- Colonne écrite UNIQUEMENT côté serveur (EF service_role) — jamais lue/écrite
-- par le client, donc pas de grant client ni d'exposition dans public_profiles.
-- =============================================================================

alter table public.profiles
  add column if not exists last_totp_step bigint;

comment on column public.profiles.last_totp_step is
  'Dernier step HOTP (floor(epoch/30)) accepté via TOTP. Anti-rejeu : les EF '
  'refusent un step <= celui-ci. Écrit uniquement par les Edge Functions '
  '(service_role) — audit 2026-07-07.';
