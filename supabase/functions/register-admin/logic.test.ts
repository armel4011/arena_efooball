// Tests de la logique pure d'inscription admin (register-admin/logic.ts).
// Lancer : deno test --allow-all  (depuis supabase/functions/)

import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  clientIp,
  isInvitationExpired,
  isValidCodeFormat,
  normalizeCode,
  normalizeEmail,
  validateAdminPassword,
  validateRegisterFields,
} from "./logic.ts";

Deno.test("validateAdminPassword : conforme → null", () => {
  assertEquals(validateAdminPassword("Abcdef12!xyz"), null);
  assertEquals(validateAdminPassword("StrongPass1_OK"), null);
});

Deno.test("validateAdminPassword : chaque règle manquante", () => {
  assertEquals(validateAdminPassword("Ab1!aaa"), "password_too_short"); // <12
  assertEquals(validateAdminPassword("abcdef12!xyz"), "password_no_uppercase");
  assertEquals(validateAdminPassword("ABCDEF12!XYZ"), "password_no_lowercase");
  assertEquals(validateAdminPassword("Abcdefgh!xyz"), "password_no_digit");
  assertEquals(validateAdminPassword("Abcdef12xyzz"), "password_no_symbol");
});

Deno.test("validateAdminPassword : symboles acceptés variés", () => {
  for (const sym of ["!", "@", "#", "$", "%", "^", "&", "*", "_", "-", "?"]) {
    assertEquals(
      validateAdminPassword(`Abcdef12xyz${sym}`),
      null,
      `symbole ${sym} doit être accepté`,
    );
  }
});

Deno.test("normalizeCode : strip ARENA-, espaces, uppercase", () => {
  assertEquals(normalizeCode("ARENA-ab12-cd34-ef56"), "AB12-CD34-EF56");
  assertEquals(normalizeCode("  arena-ab12-cd34-ef56  "), "AB12-CD34-EF56");
  assertEquals(normalizeCode("AB12-CD34-EF56"), "AB12-CD34-EF56");
  assertEquals(normalizeCode("ab 12-cd 34-ef 56"), "AB12-CD34-EF56");
});

Deno.test("isValidCodeFormat", () => {
  assert(isValidCodeFormat("AB12-CD34-EF56"));
  assert(isValidCodeFormat("0000-0000-0000"));
  assert(!isValidCodeFormat("AB12-CD34")); // 2 blocs
  assert(!isValidCodeFormat("AB12-CD34-EF56-GH78")); // 4 blocs
  assert(!isValidCodeFormat("ab12-cd34-ef56")); // minuscules (déjà normalisé attendu)
  assert(!isValidCodeFormat("AB1!-CD34-EF56")); // symbole interdit
  assert(!isValidCodeFormat("ARENA-AB12-CD34-EF56")); // préfixe non strippé
});

Deno.test("normalizeEmail", () => {
  assertEquals(normalizeEmail("  Foo@Bar.COM "), "foo@bar.com");
  assertEquals(normalizeEmail("a@b.co"), "a@b.co");
  assertEquals(normalizeEmail(123), "");
  assertEquals(normalizeEmail(undefined), "");
});

Deno.test("clientIp : première entrée de x-forwarded-for", () => {
  const mk = (xff: string | null) =>
    new Request("https://x.invalid", {
      headers: xff === null ? {} : { "x-forwarded-for": xff },
    });
  assertEquals(clientIp(mk("1.2.3.4, 10.0.0.1, 10.0.0.2")), "1.2.3.4");
  assertEquals(clientIp(mk("  5.6.7.8  ")), "5.6.7.8");
  assertEquals(clientIp(mk("")), "unknown");
  assertEquals(clientIp(mk(null)), "unknown");
});

Deno.test("validateRegisterFields : valide → null", () => {
  assertEquals(
    validateRegisterFields({
      rawCode: "ARENA-AB12-CD34-EF56",
      email: "admin@arena.gg",
      password: "Abcdef12!xyz",
      username: "newadmin",
    }),
    null,
  );
});

Deno.test("validateRegisterFields : ordre des erreurs", () => {
  const base = {
    rawCode: "ARENA-AB12-CD34-EF56",
    email: "admin@arena.gg",
    password: "Abcdef12!xyz",
    username: "newadmin",
  };
  assertEquals(
    validateRegisterFields({ ...base, password: "" }),
    "missing_fields",
  );
  assertEquals(
    validateRegisterFields({ ...base, rawCode: "ARENA-BAD" }),
    "bad_code_format",
  );
  assertEquals(
    validateRegisterFields({ ...base, email: "no-at-sign" }),
    "bad_email",
  );
  assertEquals(
    validateRegisterFields({ ...base, username: "ab" }),
    "bad_username",
  );
  assertEquals(
    validateRegisterFields({ ...base, username: "x".repeat(21) }),
    "bad_username",
  );
  assertEquals(
    validateRegisterFields({ ...base, password: "weak" }),
    "password_too_short",
  );
});

Deno.test("isInvitationExpired", () => {
  const now = Date.parse("2026-06-20T12:00:00Z");
  assert(isInvitationExpired("2026-06-20T11:59:59Z", now)); // passé
  assert(!isInvitationExpired("2026-06-20T12:00:01Z", now)); // futur
  assert(!isInvitationExpired(null, now)); // pas d'expiration
  assert(!isInvitationExpired("", now));
  assert(!isInvitationExpired("pas-une-date", now)); // invalide → non expiré
});
