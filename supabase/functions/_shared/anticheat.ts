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

import { crypto as stdCrypto } from "jsr:@std/crypto@1";

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

/** Levée par [limitBytes] quand le flux dépasse le plafond d'octets — l'appelant
 *  la distingue d'une vraie erreur de hash pour renvoyer 413 (trop volumineux). */
export class ByteCapExceededError extends Error {
  constructor() {
    super("byte_cap_exceeded");
    this.name = "ByteCapExceededError";
  }
}

/** Enveloppe un flux d'octets d'un plafond DUR : dès que le cumul dépasse
 *  `maxBytes`, le flux dérivé est mis en erreur ([ByteCapExceededError]). Sert
 *  de garde-fou CPU/abus même si le `Content-Length` est absent ou mensonger —
 *  la mémoire, elle, reste bornée par le hash en flux ci-dessous. */
export function limitBytes(
  source: ReadableStream<Uint8Array>,
  maxBytes: number,
): ReadableStream<Uint8Array> {
  let total = 0;
  return source.pipeThrough(
    new TransformStream<Uint8Array, Uint8Array>({
      transform(chunk, controller) {
        total += chunk.byteLength;
        if (total > maxBytes) {
          controller.error(new ByteCapExceededError());
          return;
        }
        controller.enqueue(chunk);
      },
    }),
  );
}

/** Itère un `ReadableStream` en `AsyncGenerator` de chunks. `@std/crypto`
 *  accepte un `AsyncIterable<BufferSource>` mais pas un `ReadableStream` brut
 *  (son type ne l'expose pas comme async-iterable) — d'où ce pont. La copie
 *  `new Uint8Array(value)` réadosse le chunk à un `ArrayBuffer` strict (et non
 *  `ArrayBufferLike`), seul type que `BufferSource` accepte sous TS 5.7+ ; coût
 *  négligeable (chunks ~64 Ko), la mémoire reste bornée à un chunk à la fois. */
async function* readChunks(
  stream: ReadableStream<Uint8Array>,
): AsyncGenerator<Uint8Array<ArrayBuffer>> {
  const reader = stream.getReader();
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      if (value) yield new Uint8Array(value);
    }
  } finally {
    reader.releaseLock();
  }
}

/** SHA-256 (hex minuscules) calculé EN FLUX sur un flux de chunks — mémoire
 *  CONSTANTE : ne bufferise JAMAIS tout le fichier, contrairement à
 *  `crypto.subtle.digest` de Web Crypto qui exige le buffer complet (2× la
 *  taille avec le `arrayBuffer()`). C'est ce qui permet de vérifier une preuve
 *  volumineuse (proxy 360p ou fallback 540p) sans faire OOM l'isolate. */
export async function sha256HexOfStream(
  stream: ReadableStream<Uint8Array>,
): Promise<string> {
  const digest = await stdCrypto.subtle.digest("SHA-256", readChunks(stream));
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** `true` si `userId` est un des deux joueurs assis du match. */
export function isPlayerOfMatch(
  match: { player1_id?: unknown; player2_id?: unknown } | null | undefined,
  userId: string,
): boolean {
  if (!match) return false;
  return match.player1_id === userId || match.player2_id === userId;
}
