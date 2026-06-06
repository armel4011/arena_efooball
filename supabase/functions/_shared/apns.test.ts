// Tests de la lecture de config APNs (_shared/apns.ts) + classe d'erreur.
// readApnsConfig() doit renvoyer null tant que les secrets ne sont pas posés
// (déploiement sûr sans compte Apple Dev), sinon une config avec les défauts
// attendus. On manipule Deno.env → nécessite --allow-env (couvert par --allow-all).
//
// Lancer : deno test --allow-all  (depuis supabase/functions/)

import { assert, assertEquals } from "jsr:@std/assert@1";
import { ApnsTokenInvalidError, readApnsConfig } from "./apns.ts";

const APNS_VARS = [
  "APNS_KEY_P8",
  "APNS_KEY_ID",
  "APNS_TEAM_ID",
  "APNS_BUNDLE_ID",
  "APNS_ENV",
];

/** Nettoie toutes les variables APNs avant/après un test. */
function clearApnsEnv() {
  for (const v of APNS_VARS) Deno.env.delete(v);
}

Deno.test("readApnsConfig → null si un secret obligatoire manque", () => {
  clearApnsEnv();
  try {
    assertEquals(readApnsConfig(), null);
    // Même avec 2 des 3 secrets obligatoires → toujours null.
    Deno.env.set("APNS_KEY_P8", "pem");
    Deno.env.set("APNS_KEY_ID", "KID");
    assertEquals(readApnsConfig(), null);
  } finally {
    clearApnsEnv();
  }
});

Deno.test("readApnsConfig → défauts (bundle com.arena.app, host production)", () => {
  clearApnsEnv();
  try {
    Deno.env.set("APNS_KEY_P8", "pem");
    Deno.env.set("APNS_KEY_ID", "KID");
    Deno.env.set("APNS_TEAM_ID", "TEAM");
    const cfg = readApnsConfig();
    assert(cfg !== null);
    assertEquals(cfg?.bundleId, "com.arena.app");
    assertEquals(cfg?.host, "https://api.push.apple.com");
    assertEquals(cfg?.keyP8, "pem");
  } finally {
    clearApnsEnv();
  }
});

Deno.test("readApnsConfig → APNS_ENV=sandbox bascule le host", () => {
  clearApnsEnv();
  try {
    Deno.env.set("APNS_KEY_P8", "pem");
    Deno.env.set("APNS_KEY_ID", "KID");
    Deno.env.set("APNS_TEAM_ID", "TEAM");
    Deno.env.set("APNS_ENV", "sandbox");
    Deno.env.set("APNS_BUNDLE_ID", "com.arena.admin");
    const cfg = readApnsConfig();
    assertEquals(cfg?.host, "https://api.sandbox.push.apple.com");
    assertEquals(cfg?.bundleId, "com.arena.admin");
  } finally {
    clearApnsEnv();
  }
});

Deno.test("readApnsConfig → valeur APNS_ENV inconnue retombe sur production", () => {
  clearApnsEnv();
  try {
    Deno.env.set("APNS_KEY_P8", "pem");
    Deno.env.set("APNS_KEY_ID", "KID");
    Deno.env.set("APNS_TEAM_ID", "TEAM");
    Deno.env.set("APNS_ENV", "staging");
    assertEquals(readApnsConfig()?.host, "https://api.push.apple.com");
  } finally {
    clearApnsEnv();
  }
});

Deno.test("ApnsTokenInvalidError → expose reason, detail et message", () => {
  const err = new ApnsTokenInvalidError("BadDeviceToken", "410");
  assert(err instanceof Error);
  assertEquals(err.name, "ApnsTokenInvalidError");
  assertEquals(err.reason, "BadDeviceToken");
  assertEquals(err.detail, "410");
  assertEquals(err.message, "apns_token_invalid:BadDeviceToken:410");
});
