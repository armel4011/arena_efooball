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
  type GameState,
  decodeFen,
  encodeFen,
  Endgame,
  endgameCategory,
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

// ── Règles de nulle FMJD fines ──────────────────────────────────────────────
Deno.test("endgameCategory : classification matériel", () => {
  const cat = (fen: string) => endgameCategory(decodeFen(fen).cells);
  assertEquals(cat("W:WK1:BK50"), Endgame.FiveMove); // roi vs roi
  assertEquals(cat("W:WK1,K2:BK50"), Endgame.FiveMove); // 2 dames vs roi
  assertEquals(cat("W:WK1,K2,K3:BK50"), Endgame.SixteenMove); // 3 dames vs roi
  assertEquals(cat("W:WK1,5,6:BK50"), Endgame.SixteenMove); // 1 dame+2 pions
  assertEquals(cat("W:W5,6,7:BK50"), Endgame.None); // 3 pions sans dame
});

Deno.test("nulle 16 coups : à 32 demi-coups, pas avant", () => {
  const fen = "W:WK1,K2,K3:BK50";
  assertEquals(outcome(stateFromFen(fen, 0, 31)), Outcome.Ongoing);
  assertEquals(outcome(stateFromFen(fen, 0, 32)), Outcome.Draw);
});

Deno.test("nulle 5 coups : à 10 demi-coups", () => {
  const fen = "W:WK1,K2:BK50";
  assertEquals(outcome(stateFromFen(fen, 0, 9)), Outcome.Ongoing);
  assertEquals(outcome(stateFromFen(fen, 0, 10)), Outcome.Draw);
});

Deno.test("apply incrémente le compteur d'endgame", () => {
  const s = stateFromFen("W:WK1,K2,K3:BK50");
  const move = stateLegalMoves(s).find((m) => m.captured.length === 0)!;
  const next = applyMove(s, move);
  assertEquals(next.endgamePlies, 1);
  assertEquals(endgameCategory(next.cells), Endgame.SixteenMove);
});

Deno.test("répétition triple → nulle", () => {
  const fen = "W:WK1,K2,K3,K4:BK47,K48,K49,K50";
  const { cells, turn } = decodeFen(fen);
  const key = encodeFen(cells, turn);
  const s3: GameState = {
    cells,
    turn,
    sterilePlies: 0,
    endgamePlies: 0,
    positionCounts: { [key]: 3 },
  };
  assertEquals(outcome(s3), Outcome.Draw);
  const s2: GameState = { ...s3, positionCounts: { [key]: 2 } };
  assertEquals(outcome(s2), Outcome.Ongoing);
});
