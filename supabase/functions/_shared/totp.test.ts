// Tests du module TOTP (_shared/totp.ts) — logique de sécurité critique
// (2FA admin). On valide contre les vecteurs officiels RFC 6238 (Appendix B,
// SHA1, secret ASCII "12345678901234567890") + les invariants des backup codes.
//
// Lancer : deno test --allow-all  (depuis supabase/functions/)

import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1";
import {
  consumeBackupCodeHashed,
  generateBackupCodes,
  generateSecretBase32,
  hashBackupCode,
  hashBackupCodes,
  otpauthUri,
  verifyTotp,
} from "./totp.ts";

// Secret RFC 6238 "12345678901234567890" (20 octets ASCII) en base32.
const RFC_SECRET = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
// hmacKey hex 32 octets pour les tests de backup codes (valeur arbitraire).
const HMAC_KEY =
  "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

/** Exécute `fn` avec `Date.now()` figé à `seconds`, puis restaure. */
async function withFrozenTime(seconds: number, fn: () => Promise<void>) {
  const original = Date.now;
  Date.now = () => seconds * 1000;
  try {
    await fn();
  } finally {
    Date.now = original;
  }
}

Deno.test("generateSecretBase32 → 32 chars de l'alphabet base32", () => {
  const secret = generateSecretBase32();
  assertEquals(secret.length, 32);
  assert(/^[A-Z2-7]+$/.test(secret), `alphabet invalide: ${secret}`);
  // Deux appels → secrets différents (random).
  assert(generateSecretBase32() !== generateSecretBase32());
});

Deno.test("otpauthUri → URI otpauth valide et paramétrée", () => {
  const uri = otpauthUri({
    issuer: "Arena",
    accountName: "user@example.com",
    secret: RFC_SECRET,
  });
  assert(uri.startsWith("otpauth://totp/Arena:user%40example.com?"));
  assert(uri.includes(`secret=${RFC_SECRET}`));
  assert(uri.includes("issuer=Arena"));
  assert(uri.includes("algorithm=SHA1"));
  assert(uri.includes("digits=6"));
  assert(uri.includes("period=30"));
});

Deno.test("verifyTotp → accepte le code RFC 6238 (t=59s, step 1)", async () => {
  await withFrozenTime(59, async () => {
    assert(await verifyTotp({ secretBase32: RFC_SECRET, code: "287082" }));
  });
});

Deno.test("verifyTotp → rejette un mauvais code", async () => {
  await withFrozenTime(59, async () => {
    assertFalse(await verifyTotp({ secretBase32: RFC_SECRET, code: "000000" }));
  });
});

Deno.test("verifyTotp → rejette un format invalide (pas 6 chiffres)", async () => {
  await withFrozenTime(59, async () => {
    assertFalse(await verifyTotp({ secretBase32: RFC_SECRET, code: "12345" }));
    assertFalse(await verifyTotp({ secretBase32: RFC_SECRET, code: "1234567" }));
    assertFalse(await verifyTotp({ secretBase32: RFC_SECRET, code: "abcdef" }));
    assertFalse(await verifyTotp({ secretBase32: RFC_SECRET, code: "" }));
  });
});

Deno.test("verifyTotp → secret base32 invalide retourne false sans jeter", async () => {
  await withFrozenTime(59, async () => {
    assertFalse(await verifyTotp({ secretBase32: "0189!@#", code: "287082" }));
  });
});

Deno.test("verifyTotp → fenêtre ±1 step (drift d'horloge)", async () => {
  // Code "287082" appartient au step 1 (t=59s).
  // t=89s → step 2, fenêtre [1..3] inclut step 1 → accepté.
  await withFrozenTime(89, async () => {
    assert(await verifyTotp({ secretBase32: RFC_SECRET, code: "287082" }));
  });
  // t=120s → step 4, fenêtre [3..5] exclut step 1 → rejeté.
  await withFrozenTime(120, async () => {
    assertFalse(await verifyTotp({ secretBase32: RFC_SECRET, code: "287082" }));
  });
});

Deno.test("verifyTotp → fenêtre élargie via windowSteps", async () => {
  // t=120s → step 4 ; avec windowSteps=3 la fenêtre [1..7] inclut step 1.
  await withFrozenTime(120, async () => {
    assert(
      await verifyTotp({
        secretBase32: RFC_SECRET,
        code: "287082",
        windowSteps: 3,
      }),
    );
  });
});

Deno.test("generateBackupCodes → format, count et alphabet sûr", () => {
  const codes = generateBackupCodes();
  assertEquals(codes.length, 10);
  for (const code of codes) {
    assert(/^[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$/.test(code), `format: ${code}`);
    // Alphabet réel = sans 0/1/I/O (L est conservé, cf. BACKUP_ALPHABET).
    assertFalse(/[01IO]/.test(code.replace("-", "")));
  }
  // count personnalisé respecté.
  assertEquals(generateBackupCodes(5).length, 5);
});

Deno.test("hashBackupCode → déterministe, hex 64 chars, insensible à la casse", async () => {
  const h1 = await hashBackupCode("ABCD-2345", HMAC_KEY);
  const h2 = await hashBackupCode("ABCD-2345", HMAC_KEY);
  assertEquals(h1, h2);
  assertEquals(h1.length, 64);
  assert(/^[0-9a-f]{64}$/.test(h1));
  // normalize() met en majuscules + trim → même hash.
  assertEquals(await hashBackupCode("  abcd-2345  ", HMAC_KEY), h1);
});

Deno.test("hashBackupCode → clé HMAC différente → hash différent", async () => {
  const otherKey =
    "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  const h1 = await hashBackupCode("ABCD-2345", HMAC_KEY);
  const h2 = await hashBackupCode("ABCD-2345", otherKey);
  assert(h1 !== h2);
});

Deno.test("hashBackupCodes → équivalent au mapping de hashBackupCode", async () => {
  const codes = ["ABCD-2345", "EFGH-6789"];
  const batch = await hashBackupCodes(codes, HMAC_KEY);
  assertEquals(batch[0], await hashBackupCode("ABCD-2345", HMAC_KEY));
  assertEquals(batch[1], await hashBackupCode("EFGH-6789", HMAC_KEY));
});

Deno.test("consumeBackupCodeHashed → match single-use + normalisation", async () => {
  const stored = await hashBackupCodes(["AAAA-2345", "BBBB-6789"], HMAC_KEY);
  // Proposé en minuscules → doit matcher (normalisation interne).
  const res = await consumeBackupCodeHashed(stored, "aaaa-2345", HMAC_KEY);
  assert(res.matched);
  if (res.matched) {
    assertEquals(res.remaining.length, 1);
    // Le hash consommé est retiré ; il reste celui de BBBB-6789.
    assertEquals(res.remaining[0], await hashBackupCode("BBBB-6789", HMAC_KEY));
  }
});

Deno.test("consumeBackupCodeHashed → aucun match → matched:false", async () => {
  const stored = await hashBackupCodes(["AAAA-2345"], HMAC_KEY);
  const res = await consumeBackupCodeHashed(stored, "ZZZZ-9999", HMAC_KEY);
  assertFalse(res.matched);
});
