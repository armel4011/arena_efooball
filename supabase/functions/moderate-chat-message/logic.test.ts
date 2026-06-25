// Tests de la logique pure de modération (moderate-chat-message/logic.ts).
// Lancer : deno test --allow-all  (depuis supabase/functions/)

import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  type BannedWord,
  findWord,
  normalize,
  redact,
  scanMessage,
} from "./logic.ts";

const bw = (word: string, severity = 1): BannedWord => ({
  word,
  language: "fr",
  severity,
  category: null,
});

Deno.test("normalize : minuscule + retrait des accents", () => {
  assertEquals(normalize("Héllo"), "hello");
  assertEquals(normalize("ÇA VA"), "ca va");
  assertEquals(normalize("ÉÈÊ"), "eee");
  assertEquals(normalize(""), "");
});

Deno.test("findWord : respecte les frontières de mot", () => {
  assertEquals(findWord("you are con", "con"), 8); // précédé d'un espace
  assertEquals(findWord("con man", "con"), 0); // début de chaîne
  assertEquals(findWord("a con", "con"), 2); // fin de chaîne
});

Deno.test("findWord : pas de faux positif sur sous-chaîne", () => {
  assertEquals(findWord("scon", "con"), -1); // 'con' collé à une lettre
  assertEquals(findWord("conman", "con"), -1);
  assertEquals(findWord("hello world", "con"), -1); // absent
});

Deno.test("redact : caviarde par des * de même longueur", () => {
  assertEquals(redact("you con man", ["con"]), "you *** man");
  assertEquals(redact("idiot total", ["idiot"]), "***** total"); // 5 lettres
});

Deno.test("redact : insensible à la casse, ignore les sous-chaînes", () => {
  assertEquals(redact("CON con", ["con"]), "*** ***");
  assertEquals(redact("scon", ["con"]), "scon"); // collé → pas caviardé
});

Deno.test("scanMessage : message propre → null", () => {
  assertEquals(scanMessage("hello world", [bw("con", 2)]), null);
  assertEquals(scanMessage("rien", []), null); // dictionnaire vide
});

Deno.test("scanMessage : détecte, caviarde et construit la raison", () => {
  const r = scanMessage("you con", [bw("con", 2)]);
  assert(r !== null);
  assertEquals(r.maxSeverity, 2);
  assertEquals(r.offendingWords, ["con"]);
  assertEquals(r.redacted, "you ***");
  assertEquals(r.reason, "banned_word(2):con");
});

Deno.test("scanMessage : plusieurs mots → sévérité max + raison agrégée", () => {
  const r = scanMessage("foo and bar", [bw("foo", 1), bw("bar", 3)]);
  assert(r !== null);
  assertEquals(r.maxSeverity, 3);
  assertEquals(r.offendingWords, ["foo", "bar"]);
  assertEquals(r.redacted, "*** and ***");
  assertEquals(r.reason, "banned_word(3):foo,bar");
});

Deno.test("scanMessage : détection insensible casse/accents", () => {
  const r = scanMessage("CON", [bw("con", 2)]);
  assert(r !== null);
  assertEquals(r.redacted, "***");
});

Deno.test("scanMessage : mot interdit vide ignoré (pas de match)", () => {
  assertEquals(scanMessage("hello", [bw("", 1)]), null);
});
