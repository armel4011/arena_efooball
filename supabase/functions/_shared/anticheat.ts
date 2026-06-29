// =============================================================================
// ARENA — _shared/anticheat.ts
// =============================================================================
// Décisions PURES (testables sans serveur) du système anti-triche « commitment
// hash » (Phase 3, cf. plan réduction coût anti-triche).
//
// Flux : le client transcode un proxy 360p à la fin du match, en calcule le
// SHA-256 et l'engage (« commit ») via l'EF `anticheat-commit`. Sur litige,
// l'admin réclame la vidéo ; le client uploade le proxy ; l'EF `proof-verify`
// re-hashe l'objet stocké et compare au commitment. Match = preuve engageante ;
// mismatch / non-livré = charge contre le joueur.
//
// On factorise ici la validation de format + l'appartenance des objets pour
// les couvrir par anticheat.test.ts (les handlers `Deno.serve` ne sont pas
// testables unitairement).
// =============================================================================

/** `true` si `s` est un digest SHA-256 hexadécimal canonique : 64 [0-9a-f]. */
export function isSha256Hex(s: unknown): s is string {
  return typeof s === "string" && /^[0-9a-f]{64}$/.test(s);
}

/** Normalise un hash hex : trim + minuscules. Renvoie `null` si invalide après
 *  normalisation (on accepte donc une casse mixte en entrée, mais on STOCKE en
 *  minuscules pour que la contrainte SQL `^[0-9a-f]{64}$` passe et que la
 *  comparaison à la vérification soit insensible à la casse). */
export function normalizeSha256(s: unknown): string | null {
  if (typeof s !== "string") return null;
  const v = s.trim().toLowerCase();
  return isSha256Hex(v) ? v : null;
}

/** `true` si `n` est un entier strictement positif et fini (octets, durée…). */
export function isPositiveInt(n: unknown): n is number {
  return typeof n === "number" && Number.isInteger(n) && n > 0;
}

/** Préfixe canonique des objets d'un (match, joueur) dans le bucket
 *  `match-recordings` : `{matchId}/{playerId}/`. Aligné sur la convention déjà
 *  purgée par cleanup-streams et écrite par le recorder natif / Track Egress. */
export function objectPrefixFor(matchId: string, playerId: string): string {
  return `${matchId}/${playerId}/`;
}

/** `true` si `path` appartient bien au dossier du (match, joueur) — garde
 *  anti-traversée : un joueur ne peut faire vérifier qu'un objet de SON dossier,
 *  jamais celui de l'adversaire ni un chemin arbitraire (`..`, absolu, autre
 *  match). */
export function objectPathBelongsTo(
  path: unknown,
  matchId: string,
  playerId: string,
): path is string {
  if (typeof path !== "string" || path.length === 0) return false;
  if (path.includes("..") || path.includes("://") || path.startsWith("/")) {
    return false;
  }
  return path.startsWith(objectPrefixFor(matchId, playerId));
}

/** `true` si `userId` est un des deux joueurs assis du match. */
export function isPlayerOfMatch(
  match: { player1_id?: unknown; player2_id?: unknown } | null | undefined,
  userId: string,
): boolean {
  if (!match) return false;
  return match.player1_id === userId || match.player2_id === userId;
}
