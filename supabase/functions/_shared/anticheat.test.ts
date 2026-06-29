// Tests des décisions pures anti-triche (_shared/anticheat.ts).
// Lancer : deno test --allow-all  (depuis supabase/functions/)

import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1";
import {
  isPlayerOfMatch,
  isPositiveInt,
  isSha256Hex,
  normalizeSha256,
  objectPathBelongsTo,
  objectPrefixFor,
} from "./anticheat.ts";

const HASH = "a".repeat(64); // 64 hex valides
const MATCH = "11111111-1111-1111-1111-111111111111";
const PLAYER = "22222222-2222-2222-2222-222222222222";

Deno.test("isSha256Hex : exactement 64 [0-9a-f]", () => {
  assert(isSha256Hex(HASH));
  assert(isSha256Hex("0123456789abcdef".repeat(4)));
  assertFalse(isSha256Hex("A".repeat(64))); // majuscules
  assertFalse(isSha256Hex("a".repeat(63))); // trop court
  assertFalse(isSha256Hex("a".repeat(65))); // trop long
  assertFalse(isSha256Hex("g".repeat(64))); // hors hex
  assertFalse(isSha256Hex(""));
  assertFalse(isSha256Hex(null));
  assertFalse(isSha256Hex(123));
});

Deno.test("normalizeSha256 : trim + minuscules, sinon null", () => {
  assertEquals(normalizeSha256("  " + "AB".repeat(32) + " "), "ab".repeat(32));
  assertEquals(normalizeSha256(HASH), HASH);
  assertEquals(normalizeSha256("xyz"), null);
  assertEquals(normalizeSha256(null), null);
  assertEquals(normalizeSha256(42), null);
});

Deno.test("isPositiveInt : entier strictement positif", () => {
  assert(isPositiveInt(1));
  assert(isPositiveInt(123456));
  assertFalse(isPositiveInt(0));
  assertFalse(isPositiveInt(-5));
  assertFalse(isPositiveInt(1.5));
  assertFalse(isPositiveInt(Number.NaN));
  assertFalse(isPositiveInt(Number.POSITIVE_INFINITY));
  assertFalse(isPositiveInt("3"));
  assertFalse(isPositiveInt(null));
});

Deno.test("objectPrefixFor : {match}/{player}/", () => {
  assertEquals(objectPrefixFor(MATCH, PLAYER), `${MATCH}/${PLAYER}/`);
});

Deno.test("objectPathBelongsTo : seulement le dossier du (match, joueur)", () => {
  assert(objectPathBelongsTo(`${MATCH}/${PLAYER}/proof_1.mp4`, MATCH, PLAYER));
  // Dossier de l'adversaire → refusé.
  const opponent = "33333333-3333-3333-3333-333333333333";
  assertFalse(
    objectPathBelongsTo(`${MATCH}/${opponent}/proof_1.mp4`, MATCH, PLAYER),
  );
  // Traversée / chemins hostiles.
  assertFalse(objectPathBelongsTo(`${MATCH}/${PLAYER}/../x.mp4`, MATCH, PLAYER));
  assertFalse(objectPathBelongsTo(`/${MATCH}/${PLAYER}/x.mp4`, MATCH, PLAYER));
  assertFalse(
    objectPathBelongsTo(`https://evil/${MATCH}/${PLAYER}/x`, MATCH, PLAYER),
  );
  assertFalse(objectPathBelongsTo("", MATCH, PLAYER));
  assertFalse(objectPathBelongsTo(null, MATCH, PLAYER));
});

Deno.test("isPlayerOfMatch : p1 ou p2 uniquement", () => {
  const m = { player1_id: PLAYER, player2_id: "other" };
  assert(isPlayerOfMatch(m, PLAYER));
  assert(isPlayerOfMatch(m, "other"));
  assertFalse(isPlayerOfMatch(m, "intrus"));
  assertFalse(isPlayerOfMatch(null, PLAYER));
  assertFalse(isPlayerOfMatch(undefined, PLAYER));
});
