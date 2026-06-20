// =============================================================================
// ARENA — _shared/auth_guards.ts
// =============================================================================
// Gardes d'authentification PURES, partagées par les Edge Functions admin
// (setup-totp, verify-totp-setup, admin-stepup-totp, admin-verify-totp).
//
// Avant : chaque handler répliquait inline les mêmes contrôles
// (`authHeader.startsWith("Bearer ")`, `/^\d{6}$/`, `role !== "admin" && …`).
// Aucun n'était testable sans démarrer le serveur (`Deno.serve` top-level).
// On factorise ici les décisions pures → couvertes par auth_guards.test.ts.
// =============================================================================

/** `true` si l'en-tête Authorization porte un token Bearer. */
export function hasBearer(authHeader: string | null | undefined): boolean {
  return typeof authHeader === "string" && authHeader.startsWith("Bearer ");
}

/** Extrait le token Bearer (sans le préfixe), ou `null` s'il est absent. */
export function bearerToken(
  authHeader: string | null | undefined,
): string | null {
  if (!hasBearer(authHeader)) return null;
  return (authHeader as string).slice("Bearer ".length);
}

/** `true` si `code` est strictement 6 chiffres (un code TOTP, par opposition
 *  à un backup code au format XXXX-XXXX). */
export function isSixDigitCode(code: string): boolean {
  return /^\d{6}$/.test(code);
}

/** `true` si `code` a le format d'un backup code : XXXX-XXXX (alphanumérique). */
export function isBackupCodeFormat(code: string): boolean {
  return /^[A-Za-z0-9]{4}-[A-Za-z0-9]{4}$/.test(code);
}

/** `true` si le rôle donne accès aux fonctions admin (admin OU super_admin). */
export function isAdminRole(role: string | null | undefined): boolean {
  return role === "admin" || role === "super_admin";
}
