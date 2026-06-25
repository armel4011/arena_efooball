// =============================================================================
// ARENA — export-user-data/logic.ts
// =============================================================================
// Logique PURE de l'export RGPD, extraite du handler (index.ts) pour être
// testable sans `Deno.serve` ni accès réseau/DB.
//
// Sécurité : `matchesOrFilter`/`disputesOrFilter` construisent les filtres
// PostgREST `or=` à partir du SEUL userId issu du JWT — c'est ce qui garantit
// qu'un user n'exporte que SA donnée. `stripSensitiveProfileFields` retire les
// secrets TOTP qui ne doivent jamais sortir, même à l'export.
// =============================================================================

/** `true` si l'en-tête Authorization porte bien un Bearer token. */
export function hasBearerToken(authHeader: string): boolean {
  return authHeader.startsWith("Bearer ");
}

/** Filtre PostgREST `or=` pour les matchs : le user peut être player1,
 *  player2, home ou winner. Toutes les branches portent le MÊME userId. */
export function matchesOrFilter(userId: string): string {
  return `player1_id.eq.${userId},player2_id.eq.${userId},home_player_id.eq.${userId},winner_id.eq.${userId}`;
}

/** Filtre PostgREST `or=` pour les litiges : ouvert par le user ou désigné
 *  partie fautive. */
export function disputesOrFilter(userId: string): string {
  return `opened_by.eq.${userId},guilty_party_id.eq.${userId}`;
}

/** Retire les champs sensibles du profil (secret TOTP + backup codes) AVANT
 *  de les inclure dans l'export. Mute et renvoie l'objet (comme le handler). */
export function stripSensitiveProfileFields<T extends Record<string, unknown>>(
  profile: T,
): T {
  delete (profile as Record<string, unknown>).totp_secret;
  delete (profile as Record<string, unknown>).backup_codes;
  return profile;
}

/** Nom de fichier de download : `arena-data-{userId}-{YYYY-MM-DD}.json`. */
export function exportFilename(userId: string, isoTimestamp: string): string {
  return `arena-data-${userId}-${isoTimestamp.slice(0, 10)}.json`;
}

export interface ExportParts {
  registrations?: unknown[] | null;
  matches?: unknown[] | null;
  payments?: unknown[] | null;
  payouts?: unknown[] | null;
  notifications?: unknown[] | null;
  disputes?: unknown[] | null;
  streams?: unknown[] | null;
  chatMessages?: unknown[] | null;
  antiCheatEvents?: unknown[] | null;
  reintegrationRequests?: unknown[] | null;
}

/** Assemble le bundle d'export final. Chaque collection retombe sur `[]` si
 *  la requête n'a rien renvoyé (data null) — jamais `null`/`undefined` dans
 *  le JSON exporté. */
export function buildExportBundle(
  userId: string,
  exportedAt: string,
  profile: unknown,
  parts: ExportParts,
): Record<string, unknown> {
  return {
    format: "1.0",
    exportedAt,
    userId,
    profile,
    competitionRegistrations: parts.registrations ?? [],
    matches: parts.matches ?? [],
    payments: parts.payments ?? [],
    payouts: parts.payouts ?? [],
    notifications: parts.notifications ?? [],
    disputes: parts.disputes ?? [],
    streams: parts.streams ?? [],
    chatMessages: parts.chatMessages ?? [],
    antiCheatEvents: parts.antiCheatEvents ?? [],
    reintegrationRequests: parts.reintegrationRequests ?? [],
  };
}
