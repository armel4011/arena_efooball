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

/** IP de l'appelant derrière le proxy Supabase. `x-forwarded-for` a la forme
 *  "clientSpoofable, …, ipRéelle" : la gateway Supabase APPENDE l'IP réelle de
 *  la connexion à DROITE. Les entrées de gauche sont fournies par le client et
 *  donc falsifiables → on prend la DERNIÈRE entrée (non spoofable). */
export function clientIp(req: Request): string {
  const fwd = req.headers.get("x-forwarded-for") ?? "";
  const parts = fwd.split(",").map((p) => p.trim()).filter((p) => p.length > 0);
  const real = parts[parts.length - 1];
  return real && real.length > 0 ? real : "unknown";
}

/** Clé de rate-limit anti-énumération de codes. On privilégie l'EMAIL cible —
 *  dimension d'identité stable et non-spoofable : c'est un champ requis et
 *  validé, l'attaquant doit s'y engager — plutôt que l'IP seule (header XFF
 *  partiellement contrôlé par le client). Fallback IP réelle si email absent.
 *  La colonne `admin_register_attempts.ip` n'est qu'une clé texte : y stocker
 *  "email:…" / "ip:…" est transparent pour les RPC de lock. */
export function rateLimitKey(email: string, req: Request): string {
  const e = normalizeEmail(email);
  return e ? `email:${e}` : `ip:${clientIp(req)}`;
}

/** Clés de rate-limit anti-énumération de codes, verrouillées sur DEUX
 *  dimensions indépendantes (audit 2026-07-14) :
 *   • l'EMAIL cible — identité stable, mais que l'attaquant contrôle : en la
 *     faisant tourner il repart d'un compteur neuf à chaque probe, donc seule
 *     elle ne borne jamais le volume total de tentatives ;
 *   • l'IP réelle (dernière entrée XFF, non-spoofable) — borne le volume total
 *     quel que soit l'email présenté.
 *  On verrouille/enregistre sur les DEUX : une tentative est bloquée si l'une
 *  OU l'autre est en cooldown. Dédupliquées, entrées vides écartées. */
export function rateLimitKeys(email: string, req: Request): string[] {
  const keys: string[] = [];
  const e = normalizeEmail(email);
  if (e) keys.push(`email:${e}`);
  const ip = clientIp(req);
  if (ip && ip !== "unknown") keys.push(`ip:${ip}`);
  // Garde-fou : si ni email ni IP exploitables, retomber sur une clé IP unique
  // (jamais de tableau vide → le rate-limit n'est jamais court-circuité).
  if (keys.length === 0) keys.push(`ip:${ip}`);
  return [...new Set(keys)];
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
