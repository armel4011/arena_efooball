// Tests des gardes d'auth pures partagées (_shared/auth_guards.ts).
// Lancer : deno test --allow-all  (depuis supabase/functions/)

import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1";
import {
  bearerToken,
  hasBearer,
  isAdminRole,
  isBackupCodeFormat,
  isSixDigitCode,
} from "./auth_guards.ts";

Deno.test("hasBearer", () => {
  assert(hasBearer("Bearer abc.def"));
  assertFalse(hasBearer("bearer abc")); // sensible à la casse
  assertFalse(hasBearer("Token abc"));
  assertFalse(hasBearer(""));
  assertFalse(hasBearer(null));
  assertFalse(hasBearer(undefined));
});

Deno.test("bearerToken extrait le token sans préfixe", () => {
  assertEquals(bearerToken("Bearer abc.def.ghi"), "abc.def.ghi");
  assertEquals(bearerToken("Bearer "), "");
  assertEquals(bearerToken("nope"), null);
  assertEquals(bearerToken(null), null);
});

Deno.test("isSixDigitCode : exactement 6 chiffres", () => {
  assert(isSixDigitCode("000000"));
  assert(isSixDigitCode("123456"));
  assertFalse(isSixDigitCode("12345")); // 5 chiffres
  assertFalse(isSixDigitCode("1234567")); // 7 chiffres
  assertFalse(isSixDigitCode("12 456")); // espace
  assertFalse(isSixDigitCode("12a456")); // lettre
  assertFalse(isSixDigitCode("ABCD-EFGH")); // backup code → pas un TOTP
  assertFalse(isSixDigitCode(""));
});

Deno.test("isBackupCodeFormat : XXXX-XXXX alphanumérique", () => {
  assert(isBackupCodeFormat("AB12-cd34"));
  assert(isBackupCodeFormat("0000-0000"));
  assertFalse(isBackupCodeFormat("123456")); // un TOTP, pas un backup
  assertFalse(isBackupCodeFormat("ABCD-EFGH-IJKL")); // 3 blocs
  assertFalse(isBackupCodeFormat("AB1-CD34")); // bloc trop court
  assertFalse(isBackupCodeFormat("AB1!-CD34")); // symbole
  assertFalse(isBackupCodeFormat(""));
});

Deno.test("isAdminRole : admin et super_admin uniquement", () => {
  assert(isAdminRole("admin"));
  assert(isAdminRole("super_admin"));
  assertFalse(isAdminRole("player"));
  assertFalse(isAdminRole("Admin")); // sensible à la casse
  assertFalse(isAdminRole(""));
  assertFalse(isAdminRole(null));
  assertFalse(isAdminRole(undefined));
});
