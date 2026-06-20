// =============================================================================
// ARENA — register-admin/logic.ts
// =============================================================================
// Logique PURE de validation de l'inscription admin, extraite du handler
// (index.ts) pour être testable sans démarrer `Deno.serve` ni toucher au
// réseau (l'import esm.sh de supabase-js reste dans index.ts).
//
// Sécurité : ces contrôles RÉPLIQUENT côté serveur ceux du formulaire Flutter
// — un client modifié pourrait soumettre un mot de passe faible, un username
// hors bornes ou un code mal formé. C'est la passe autoritaire.
// =============================================================================

/** Politique de mot de passe admin (PHASE 2bis) : 12+ chars, maj, min,
 *  chiffre, symbole. Renvoie le code d'erreur, ou `null` si conforme. */
export function validateAdminPassword(pw: string): string | null {
  if (pw.length < 12) return "password_too_short";
  if (!/[A-Z]/.test(pw)) return "password_no_uppercase";
  if (!/[a-z]/.test(pw)) return "password_no_lowercase";
  if (!/\d/.test(pw)) return "password_no_digit";
  if (!/[!@#$%^&*(),.?":{}|<>_\-]/.test(pw)) return "password_no_symbol";
  return null;
}

/** Le client envoie "ARENA-XXXX-XXXX-XXXX" mais la colonne `code` stocke
 *  "XXXX-XXXX-XXXX". Strip le préfixe + espaces + uppercase pour matcher. */
export function normalizeCode(input: string): string {
  let v = input.trim().toUpperCase().replace(/\s+/g, "");
  if (v.startsWith("ARENA-")) v = v.slice("ARENA-".length);
  return v;
}

/** `true` si le code normalisé respecte le format DB XXXX-XXXX-XXXX. */
export function isValidCodeFormat(code: string): boolean {
  return /^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(code);
}

/** Email normalisé (trim + lowercase), ou "" si l'entrée n'est pas une string. */
export function normalizeEmail(input: unknown): string {
  return typeof input === "string" ? input.trim().toLowerCase() : "";
}

/** IP de l'appelant derrière le proxy Supabase. `x-forwarded-for` peut
 *  contenir "client, proxy1, proxy2" — on garde la première entrée. */
export function clientIp(req: Request): string {
  const fwd = req.headers.get("x-forwarded-for") ?? "";
  const first = fwd.split(",")[0]?.trim();
  return first && first.length > 0 ? first : "unknown";
}

export interface RegisterFields {
  rawCode: string;
  email: string; // déjà normalisé (lowercase/trim) par le handler
  password: string;
  username: string; // déjà trim par le handler
}

/** Reproduit la séquence de validation 400 du handler dans l'ordre exact :
 *  champs requis → format du code → email → bornes username → mot de passe.
 *  Renvoie le code d'erreur (missing_fields / bad_code_format / bad_email /
 *  bad_username / password_*) ou `null` si tout est valide. */
export function validateRegisterFields(f: RegisterFields): string | null {
  if (!f.rawCode || !f.email || !f.password || !f.username) {
    return "missing_fields";
  }
  if (!isValidCodeFormat(normalizeCode(f.rawCode))) return "bad_code_format";
  if (!f.email.includes("@")) return "bad_email";
  if (f.username.length < 3 || f.username.length > 20) return "bad_username";
  return validateAdminPassword(f.password);
}

/** `true` si l'invitation a expiré (epoch ms strictement passé). Tolère un
 *  timestamp absent/invalide → non expiré (le handler gère le NULL en amont). */
export function isInvitationExpired(
  expiresAt: string | null | undefined,
  nowMs: number,
): boolean {
  if (!expiresAt) return false;
  const exp = new Date(expiresAt).getTime();
  return Number.isFinite(exp) && exp < nowMs;
}
