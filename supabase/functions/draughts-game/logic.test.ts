// Tests de la logique pure de l'autorité dames (draughts-game/logic.ts).
// Lancer : deno test --allow-read  (depuis supabase/functions/)

import { assert, assertEquals } from "jsr:@std/assert@1";
import { Outcome, Side } from "../_shared/draughts/mod.ts";
import {
  assignColors,
  chargeClock,
  colorOf,
  hashFen,
  matchResult,
  needsSuddenDeath,
  selectMove,
  winnerSideOf,
} from "./logic.ts";

Deno.test("assignColors : home_player joue les blancs", () => {
  assertEquals(assignColors("p1", "p1", "p2"), {
    whiteId: "p1",
    blackId: "p2",
  });
  assertEquals(assignColors("p2", "p1", "p2"), {
    whiteId: "p2",
    blackId: "p1",
  });
  // home_player absent → player1 = blancs.
  assertEquals(assignColors(null, "p1", "p2"), {
    whiteId: "p1",
    blackId: "p2",
  });
});

Deno.test("colorOf", () => {
  assertEquals(colorOf("w", "w", "b"), Side.White);
  assertEquals(colorOf("b", "w", "b"), Side.Black);
  assertEquals(colorOf("x", "w", "b"), null);
});

Deno.test("chargeClock : flag quand le temps est épuisé", () => {
  assertEquals(chargeClock(null, 999999), { remaining: null, flagged: false });
  assertEquals(chargeClock(10000, 3000), { remaining: 7000, flagged: false });
  assertEquals(chargeClock(3000, 3000), { remaining: 0, flagged: true });
  assertEquals(chargeClock(3000, 5000), { remaining: 0, flagged: true });
});

Deno.test("matchResult : décisif et nulle", () => {
  // Blanc = player1 gagne.
  assertEquals(matchResult(Side.White, "p1", "p2", "p1", "p2"), {
    winnerId: "p1",
    score1: 1,
    score2: 0,
  });
  // Noir = player1 gagne (couleurs inversées en mort subite).
  assertEquals(matchResult(Side.Black, "p2", "p1", "p1", "p2"), {
    winnerId: "p1",
    score1: 1,
    score2: 0,
  });
  // Nulle.
  assertEquals(matchResult(null, "p1", "p2", "p1", "p2"), {
    winnerId: null,
    score1: 0,
    score2: 0,
  });
});

Deno.test("winnerSideOf", () => {
  assertEquals(winnerSideOf(Outcome.WhiteWins), Side.White);
  assertEquals(winnerSideOf(Outcome.BlackWins), Side.Black);
  assertEquals(winnerSideOf(Outcome.Draw), null);
  assertEquals(winnerSideOf(Outcome.Ongoing), null);
});

Deno.test("needsSuddenDeath : oui hors poule (group_id null)", () => {
  assert(needsSuddenDeath(null));
  assert(!needsSuddenDeath("group-123"));
});

Deno.test("hashFen : déterministe et sensible au contenu", () => {
  assertEquals(hashFen("W:W31:B1"), hashFen("W:W31:B1"));
  assert(hashFen("W:W31:B1") !== hashFen("B:W31:B1"));
});

Deno.test("selectMove : from/to + désambiguïsation par captures", () => {
  const a = { from: 27, to: 5, captured: [21, 10], path: [27, 16, 5] };
  const b = { from: 27, to: 5, captured: [22, 11], path: [27, 17, 5] };
  // Coup inexistant.
  assertEquals(selectMove([a], 0, 1, null), null);
  // Unique candidat.
  assertEquals(selectMove([a], 27, 5, null), a);
  // Ambigu → désambiguïsé par l'ensemble capturé.
  assertEquals(selectMove([a, b], 27, 5, [22, 11]), b);
});
