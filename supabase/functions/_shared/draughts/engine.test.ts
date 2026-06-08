// Tests du moteur de dames TS (_shared/draughts/mod.ts) — AUTORITÉ serveur.
//
// Lancer : deno test --allow-read  (depuis supabase/functions/)
//
// Le test charge les vecteurs PARTAGÉS avec le moteur Dart
// (test/draughts/vectors/engine_cases.json). Toute divergence Dart↔TS sur
// ces cas = bug de parité → l'autorité serveur et l'UI client se
// contrediraient. Les mêmes cas sont exécutés côté Dart par
// test/draughts/engine_vectors_test.dart.

import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  applyMove,
  initialState,
  isKing,
  Outcome,
  outcome,
  Piece,
  Side,
  stateFromFen,
  stateLegalMoves,
  toFen,
} from "./mod.ts";

interface VectorCase {
  name: string;
  fen: string;
  legalMoveCount: number;
  maxCaptured: number;
}

function loadVectors(): VectorCase[] {
  const url = new URL(
    "../../../../test/draughts/vectors/engine_cases.json",
    import.meta.url,
  );
  const json = JSON.parse(Deno.readTextFileSync(url)) as {
    cases: VectorCase[];
  };
  return json.cases;
}

Deno.test("vecteurs partagés Dart ↔ TS", () => {
  const cases = loadVectors();
  assert(cases.length > 0, "vecteurs vides");
  for (const c of cases) {
    const state = stateFromFen(c.fen);
    const moves = stateLegalMoves(state);
    assertEquals(moves.length, c.legalMoveCount, `legalMoveCount ${c.name}`);
    let max = 0;
    for (const m of moves) {
      if (m.captured.length > max) max = m.captured.length;
    }
    assertEquals(max, c.maxCaptured, `maxCaptured ${c.name}`);
  }
});

Deno.test("position de départ : 20 pions / camp, blancs au trait", () => {
  const s = initialState();
  assertEquals(s.turn, Side.White);
  assertEquals(s.cells.filter((p) => p === Piece.WhiteMan).length, 20);
  assertEquals(s.cells.filter((p) => p === Piece.BlackMan).length, 20);
  assertEquals(stateLegalMoves(s).length, 9);
  assertEquals(outcome(s), Outcome.Ongoing);
});

Deno.test("FEN round-trip", () => {
  const s = initialState();
  const fen = toFen(s);
  assertEquals(toFen(stateFromFen(fen)), fen);
});

Deno.test("promotion d'un pion sur la dernière rangée", () => {
  const s = stateFromFen("W:W7:B");
  const promo = stateLegalMoves(s).find((m) => m.to === 0);
  assert(promo !== undefined, "coup de promotion attendu");
  const next = applyMove(s, promo);
  assert(isKing(next.cells[0]), "le pion doit devenir dame");
});

Deno.test("camp sans pièce a perdu", () => {
  assertEquals(outcome(stateFromFen("W:W:B1")), Outcome.BlackWins);
});
