// Tests de la logique pure de l'export RGPD (export-user-data/logic.ts).
// Lancer : deno test --allow-all  (depuis supabase/functions/)

import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  buildExportBundle,
  disputesOrFilter,
  exportFilename,
  hasBearerToken,
  matchesOrFilter,
  stripSensitiveProfileFields,
} from "./logic.ts";

Deno.test("hasBearerToken : exige le préfixe 'Bearer ' (sensible à la casse)", () => {
  assert(hasBearerToken("Bearer abc.def.ghi"));
  assert(!hasBearerToken("abc.def.ghi"));
  assert(!hasBearerToken(""));
  assert(!hasBearerToken("bearer abc")); // casse incorrecte
});

Deno.test("matchesOrFilter : 4 branches, toutes sur le MÊME userId", () => {
  const f = matchesOrFilter("U1");
  assertEquals(
    f,
    "player1_id.eq.U1,player2_id.eq.U1,home_player_id.eq.U1,winner_id.eq.U1",
  );
  // Sécurité : exactement 4 occurrences de l'userId, aucune autre valeur.
  assertEquals(f.split("eq.U1").length - 1, 4);
});

Deno.test("disputesOrFilter : ouvert-par + partie-fautive sur le userId", () => {
  assertEquals(
    disputesOrFilter("U7"),
    "opened_by.eq.U7,guilty_party_id.eq.U7",
  );
});

Deno.test("stripSensitiveProfileFields : retire totp_secret + backup_codes", () => {
  const p: Record<string, unknown> = {
    id: "u1",
    username: "neo",
    totp_secret: "SECRET",
    backup_codes: ["AAAA-BBBB"],
    email: "a@b.c",
  };
  const out = stripSensitiveProfileFields(p);
  assertEquals(out.totp_secret, undefined);
  assertEquals(out.backup_codes, undefined);
  // Les autres champs de conformité RGPD restent.
  assertEquals(out.username, "neo");
  assertEquals(out.email, "a@b.c");
  assert(!("totp_secret" in out));
});

Deno.test("exportFilename : arena-data-{userId}-{YYYY-MM-DD}.json", () => {
  assertEquals(
    exportFilename("u1", "2026-06-24T12:34:56.000Z"),
    "arena-data-u1-2026-06-24.json",
  );
});

Deno.test("buildExportBundle : collections nulles → tableaux vides", () => {
  const b = buildExportBundle("u1", "2026-06-24T00:00:00.000Z", { id: "u1" }, {
    registrations: null,
    matches: undefined,
  });
  assertEquals(b.format, "1.0");
  assertEquals(b.userId, "u1");
  assertEquals(b.exportedAt, "2026-06-24T00:00:00.000Z");
  assertEquals(b.profile, { id: "u1" });
  // Toutes les collections présentes et jamais null/undefined.
  for (
    const k of [
      "competitionRegistrations",
      "matches",
      "payments",
      "payouts",
      "notifications",
      "disputes",
      "streams",
      "chatMessages",
      "antiCheatEvents",
      "reintegrationRequests",
    ]
  ) {
    assertEquals(b[k], [], `${k} doit retomber sur []`);
  }
});

Deno.test("buildExportBundle : conserve les données fournies", () => {
  const b = buildExportBundle("u1", "2026-06-24T00:00:00.000Z", { id: "u1" }, {
    matches: [{ id: "m1" }],
    payments: [{ id: "p1" }, { id: "p2" }],
  });
  assertEquals(b.matches, [{ id: "m1" }]);
  assertEquals(b.payments, [{ id: "p1" }, { id: "p2" }]);
  assertEquals(b.notifications, []); // non fourni → []
});
