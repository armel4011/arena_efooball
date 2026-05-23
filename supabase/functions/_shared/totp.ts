// =============================================================================
// ARENA — TOTP helpers (RFC 6238 + RFC 4226) en pur Deno / Web Crypto.
// =============================================================================
// Pas de dépendance externe : on évite d'avoir à pin une lib qui parfois
// n'est pas compat Deno (`otplib` notamment importe `node:crypto`). L'algo
// est court et bien spécifié, donc on l'écrit ici.
//
// Surface :
//   * `generateSecretBase32()`  — 20 octets random → 32 chars base32
//   * `otpauthUri()`            — construit `otpauth://totp/...`
//   * `verifyTotp()`            — valide un code 6 chiffres (fenêtre ±1)
//   * `generateBackupCodes()`   — 10 codes alphanumériques 8 chars
// =============================================================================

const BASE32_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

// ─────────────────────────────────────────────────────────────────────────────
// Base32 (RFC 4648, no padding) — uniquement encode (decode interne).
// ─────────────────────────────────────────────────────────────────────────────
function bytesToBase32(bytes: Uint8Array): string {
  let bits = 0;
  let value = 0;
  let out = "";
  for (const b of bytes) {
    value = (value << 8) | b;
    bits += 8;
    while (bits >= 5) {
      out += BASE32_ALPHABET[(value >>> (bits - 5)) & 0x1f];
      bits -= 5;
    }
  }
  if (bits > 0) {
    out += BASE32_ALPHABET[(value << (5 - bits)) & 0x1f];
  }
  return out;
}

function base32ToBytes(input: string): Uint8Array {
  const clean = input.replace(/=+$/, "").toUpperCase().replace(/\s/g, "");
  const out: number[] = [];
  let bits = 0;
  let value = 0;
  for (const c of clean) {
    const idx = BASE32_ALPHABET.indexOf(c);
    if (idx < 0) {
      throw new Error(`invalid_base32_char:${c}`);
    }
    value = (value << 5) | idx;
    bits += 5;
    if (bits >= 8) {
      out.push((value >>> (bits - 8)) & 0xff);
      bits -= 8;
    }
  }
  return new Uint8Array(out);
}

// ─────────────────────────────────────────────────────────────────────────────
// Secret + otpauth URI
// ─────────────────────────────────────────────────────────────────────────────
export function generateSecretBase32(): string {
  // 20 octets = 160 bits — recommandé RFC 4226 §4.
  const buf = new Uint8Array(20);
  crypto.getRandomValues(buf);
  return bytesToBase32(buf);
}

export function otpauthUri(params: {
  issuer: string;
  accountName: string;
  secret: string;
}): string {
  const label = `${encodeURIComponent(params.issuer)}:${
    encodeURIComponent(params.accountName)
  }`;
  const qs = new URLSearchParams({
    secret: params.secret,
    issuer: params.issuer,
    algorithm: "SHA1",
    digits: "6",
    period: "30",
  });
  return `otpauth://totp/${label}?${qs.toString()}`;
}

// ─────────────────────────────────────────────────────────────────────────────
// HOTP / TOTP
// ─────────────────────────────────────────────────────────────────────────────
async function hotp(secretBytes: Uint8Array, counter: bigint): Promise<string> {
  // Counter en big-endian sur 8 octets.
  const counterBuf = new Uint8Array(8);
  let c = counter;
  for (let i = 7; i >= 0; i--) {
    counterBuf[i] = Number(c & 0xffn);
    c >>= 8n;
  }
  const key = await crypto.subtle.importKey(
    "raw",
    secretBytes,
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign("HMAC", key, counterBuf),
  );
  // Dynamic truncation (RFC 4226 §5.3).
  const offset = sig[sig.length - 1] & 0x0f;
  const binCode = ((sig[offset] & 0x7f) << 24) |
    ((sig[offset + 1] & 0xff) << 16) |
    ((sig[offset + 2] & 0xff) << 8) |
    (sig[offset + 3] & 0xff);
  const code = binCode % 1_000_000;
  return code.toString().padStart(6, "0");
}

/**
 * Vérifie un code TOTP 6 chiffres avec une fenêtre de ±1 step (30 s)
 * pour compenser un léger drift d'horloge.
 *
 * Retourne `true` si valide, sinon `false`. Ne *jette pas* — l'appelant
 * mappe une 401 / message UI.
 */
export async function verifyTotp(params: {
  secretBase32: string;
  code: string;
  windowSteps?: number;
}): Promise<boolean> {
  const window = params.windowSteps ?? 1;
  const cleanCode = params.code.trim();
  if (!/^\d{6}$/.test(cleanCode)) return false;
  let secretBytes: Uint8Array;
  try {
    secretBytes = base32ToBytes(params.secretBase32);
  } catch (_) {
    return false;
  }
  const step = BigInt(Math.floor(Date.now() / 1000 / 30));
  for (let offset = -window; offset <= window; offset++) {
    const candidate = await hotp(secretBytes, step + BigInt(offset));
    // Comparaison constant-time (codes 6 chars, mais on garde la
    // discipline pour éviter une éventuelle attaque par timing).
    if (timingSafeEqual(candidate, cleanCode)) return true;
  }
  return false;
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Backup codes
// ─────────────────────────────────────────────────────────────────────────────
// Les codes sont générés en clair (40 bits d'entropie / code), retournés à
// l'utilisateur UNE seule fois à la finalisation du setup, puis stockés en
// DB sous forme de hash HMAC-SHA256 dérivé d'une clé secrète (env var
// `TOTP_BACKUP_HMAC_KEY` côté EF). Cela rend le brute-force offline
// impraticable même si la DB est compromise — l'attaquant aurait besoin
// AUSSI de la clé HMAC pour reconstituer les hashes.
// ─────────────────────────────────────────────────────────────────────────────
const BACKUP_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // sans 0/O/1/I/L

export function generateBackupCodes(count = 10, length = 8): string[] {
  const codes: string[] = [];
  for (let i = 0; i < count; i++) {
    const buf = new Uint8Array(length);
    crypto.getRandomValues(buf);
    let code = "";
    for (let j = 0; j < length; j++) {
      code += BACKUP_ALPHABET[buf[j] % BACKUP_ALPHABET.length];
    }
    codes.push(`${code.slice(0, 4)}-${code.slice(4)}`);
  }
  return codes;
}

function hexFromBytes(bytes: Uint8Array): string {
  let out = "";
  for (const b of bytes) {
    out += b.toString(16).padStart(2, "0");
  }
  return out;
}

function hexToBytes(hex: string): Uint8Array {
  if (hex.length % 2 !== 0) {
    throw new Error("invalid_hex_length");
  }
  const out = new Uint8Array(hex.length / 2);
  for (let i = 0; i < out.length; i++) {
    out[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return out;
}

function normalizeBackupCode(raw: string): string {
  return raw.trim().toUpperCase();
}

/**
 * Calcule HMAC-SHA256(hmacKey, normalize(code)) → hex 64 chars.
 * `hmacKey` est attendu en hex (sortie de `openssl rand -hex 32`).
 */
export async function hashBackupCode(
  code: string,
  hmacKey: string,
): Promise<string> {
  const keyBytes = hexToBytes(hmacKey);
  const key = await crypto.subtle.importKey(
    "raw",
    keyBytes,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const msg = new TextEncoder().encode(normalizeBackupCode(code));
  const sig = new Uint8Array(await crypto.subtle.sign("HMAC", key, msg));
  return hexFromBytes(sig);
}

/**
 * Hash en parallèle une liste de codes (au moment du setup).
 */
export async function hashBackupCodes(
  codes: string[],
  hmacKey: string,
): Promise<string[]> {
  return await Promise.all(codes.map((c) => hashBackupCode(c, hmacKey)));
}

/**
 * Compare un code proposé à la liste de hashes stockés. Le code candidat
 * est hashé puis comparé en constant-time. Si trouvé, retourne la liste
 * *sans* ce hash (à re-écrire en DB pour single-use).
 */
export async function consumeBackupCodeHashed(
  storedHashes: string[],
  proposed: string,
  hmacKey: string,
): Promise<
  { matched: true; remaining: string[] } | { matched: false }
> {
  const candidate = await hashBackupCode(proposed, hmacKey);
  let matchIdx = -1;
  for (let i = 0; i < storedHashes.length; i++) {
    if (timingSafeEqual(storedHashes[i], candidate)) {
      matchIdx = i;
    }
  }
  if (matchIdx < 0) return { matched: false };
  const remaining = [...storedHashes];
  remaining.splice(matchIdx, 1);
  return { matched: true, remaining };
}
