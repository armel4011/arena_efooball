// =============================================================================
// ARENA — Moteur de dames internationales 10×10 (port TypeScript).
// =============================================================================
// Miroir EXACT du moteur Dart (lib/features_user/draughts/engine/). Sert
// d'AUTORITÉ côté Edge Function : validation de chaque coup, détection de fin
// de partie. La parité Dart↔TS est verrouillée par les vecteurs de test
// partagés (test/draughts/vectors/engine_cases.json), exécutés des deux côtés.
//
// Toute modification d'une règle DOIT être répliquée dans les deux moteurs et
// couverte par un vecteur partagé.
// =============================================================================

// ───────────────────────────── Géométrie ────────────────────────────────────
export const SQUARES = 50;
export const BOARD_SIZE = 10;

/// 4 directions diagonales (dRow, dCol).
export const DIAGONALS: ReadonlyArray<readonly [number, number]> = [
  [-1, -1],
  [-1, 1],
  [1, -1],
  [1, 1],
];

export function rowOf(index: number): number {
  return Math.floor(index / 5);
}

export function colOf(index: number): number {
  const row = Math.floor(index / 5);
  const pos = index % 5;
  return row % 2 === 0 ? 2 * pos + 1 : 2 * pos;
}

export function indexAt(row: number, col: number): number {
  if (row < 0 || row >= BOARD_SIZE || col < 0 || col >= BOARD_SIZE) return -1;
  const isDark = row % 2 === 0 ? col % 2 === 1 : col % 2 === 0;
  if (!isDark) return -1;
  const pos = row % 2 === 0 ? (col - 1) / 2 : col / 2;
  return row * 5 + pos;
}

export function squareNumber(index: number): number {
  return index + 1;
}

export function indexFromSquare(square: number): number {
  return square - 1;
}

// ───────────────────────────── Pièces / camps ───────────────────────────────
export enum Side {
  White,
  Black,
}

export enum Piece {
  Empty,
  WhiteMan,
  BlackMan,
  WhiteKing,
  BlackKing,
}

export function isEmpty(p: Piece): boolean {
  return p === Piece.Empty;
}

export function isWhite(p: Piece): boolean {
  return p === Piece.WhiteMan || p === Piece.WhiteKing;
}

export function isBlack(p: Piece): boolean {
  return p === Piece.BlackMan || p === Piece.BlackKing;
}

export function isKing(p: Piece): boolean {
  return p === Piece.WhiteKing || p === Piece.BlackKing;
}

export function isMan(p: Piece): boolean {
  return p === Piece.WhiteMan || p === Piece.BlackMan;
}

export function sideOf(p: Piece): Side | null {
  if (isWhite(p)) return Side.White;
  if (isBlack(p)) return Side.Black;
  return null;
}

export function opponent(s: Side): Side {
  return s === Side.White ? Side.Black : Side.White;
}

export function forward(s: Side): number {
  return s === Side.White ? -1 : 1;
}

export function promotionRow(s: Side): number {
  return s === Side.White ? 0 : 9;
}

export function manOf(s: Side): Piece {
  return s === Side.White ? Piece.WhiteMan : Piece.BlackMan;
}

export function kingOf(s: Side): Piece {
  return s === Side.White ? Piece.WhiteKing : Piece.BlackKing;
}

// ───────────────────────────── Coup ─────────────────────────────────────────
export interface Move {
  from: number;
  to: number;
  captured: number[];
  path: number[];
}

export function isCapture(m: Move): boolean {
  return m.captured.length > 0;
}

// ───────────────────────────── Plateau ──────────────────────────────────────
export function emptyBoard(): Piece[] {
  return new Array<Piece>(SQUARES).fill(Piece.Empty);
}

export function initialBoard(): Piece[] {
  const cells = emptyBoard();
  for (let i = 0; i < 20; i++) cells[i] = Piece.BlackMan; // cases 1-20
  for (let i = 30; i < 50; i++) cells[i] = Piece.WhiteMan; // cases 31-50
  return cells;
}

export function indicesOf(cells: Piece[], side: Side): number[] {
  const out: number[] = [];
  for (let i = 0; i < cells.length; i++) {
    if (sideOf(cells[i]) === side) out.push(i);
  }
  return out;
}

export function countOf(cells: Piece[], side: Side): number {
  return indicesOf(cells, side).length;
}

// ───────────────────────────── FEN ──────────────────────────────────────────
export function encodeFen(cells: Piece[], turn: Side): string {
  const whites: string[] = [];
  const blacks: string[] = [];
  for (let i = 0; i < SQUARES; i++) {
    const p = cells[i];
    if (isEmpty(p)) continue;
    const sq = squareNumber(i);
    const token = isKing(p) ? `K${sq}` : `${sq}`;
    if (isWhite(p)) {
      whites.push(token);
    } else {
      blacks.push(token);
    }
  }
  const t = turn === Side.White ? "W" : "B";
  return `${t}:W${whites.join(",")}:B${blacks.join(",")}`;
}

export function decodeFen(fen: string): { cells: Piece[]; turn: Side } {
  const parts = fen.split(":");
  if (parts.length !== 3) {
    throw new Error(`FEN invalide (3 segments attendus): ${fen}`);
  }
  let turn: Side;
  const tt = parts[0].trim().toUpperCase();
  if (tt === "W") {
    turn = Side.White;
  } else if (tt === "B") {
    turn = Side.Black;
  } else {
    throw new Error(`Trait invalide: ${parts[0]}`);
  }

  const cells = emptyBoard();

  const parseSegment = (seg: string, side: Side): void => {
    const prefix = side === Side.White ? "W" : "B";
    if (!seg.startsWith(prefix)) {
      throw new Error(`Segment "${seg}" doit commencer par ${prefix}`);
    }
    const body = seg.substring(1).trim();
    if (body.length === 0) return;
    for (const raw of body.split(",")) {
      const token = raw.trim();
      if (token.length === 0) continue;
      const king = token.startsWith("K");
      const numStr = king ? token.substring(1) : token;
      const sq = Number(numStr);
      if (!Number.isInteger(sq) || sq < 1 || sq > SQUARES) {
        throw new Error(`Case invalide: ${token}`);
      }
      cells[indexFromSquare(sq)] = king ? kingOf(side) : manOf(side);
    }
  };

  parseSegment(parts[1].trim(), Side.White);
  parseSegment(parts[2].trim(), Side.Black);

  return { cells, turn };
}

// ───────────────────────────── Coups légaux ─────────────────────────────────
export function legalMoves(cells: Piece[], side: Side): Move[] {
  const captures = allCaptures(cells, side);
  if (captures.length > 0) {
    let max = 0;
    for (const m of captures) {
      if (m.captured.length > max) max = m.captured.length;
    }
    return captures.filter((m) => m.captured.length === max);
  }
  return allSimpleMoves(cells, side);
}

function allSimpleMoves(cells: Piece[], side: Side): Move[] {
  const moves: Move[] = [];
  for (const idx of indicesOf(cells, side)) {
    if (isKing(cells[idx])) {
      kingSimpleMoves(cells, idx, moves);
    } else {
      manSimpleMoves(cells, idx, side, moves);
    }
  }
  return moves;
}

function manSimpleMoves(
  cells: Piece[],
  idx: number,
  side: Side,
  out: Move[],
): void {
  const row = rowOf(idx);
  const col = colOf(idx);
  const dr = forward(side);
  for (const dc of [-1, 1]) {
    const dest = indexAt(row + dr, col + dc);
    if (dest >= 0 && isEmpty(cells[dest])) {
      out.push({ from: idx, to: dest, captured: [], path: [idx, dest] });
    }
  }
}

function kingSimpleMoves(cells: Piece[], idx: number, out: Move[]): void {
  const row = rowOf(idx);
  const col = colOf(idx);
  for (const [dr, dc] of DIAGONALS) {
    let r = row + dr;
    let c = col + dc;
    let dest = indexAt(r, c);
    while (dest >= 0 && isEmpty(cells[dest])) {
      out.push({ from: idx, to: dest, captured: [], path: [idx, dest] });
      r += dr;
      c += dc;
      dest = indexAt(r, c);
    }
  }
}

function allCaptures(cells: Piece[], side: Side): Move[] {
  const results: Move[] = [];
  for (const idx of indicesOf(cells, side)) {
    const work = cells.slice();
    const captured = new Set<number>();
    const path = [idx];
    if (isKing(cells[idx])) {
      searchKingCaptures(work, idx, idx, side, captured, path, results);
    } else {
      searchManCaptures(work, idx, idx, side, captured, path, results);
    }
  }
  return results;
}

function searchManCaptures(
  cells: Piece[],
  start: number,
  current: number,
  side: Side,
  captured: Set<number>,
  path: number[],
  out: Move[],
): void {
  const row = rowOf(current);
  const col = colOf(current);
  let extended = false;

  for (const [dr, dc] of DIAGONALS) {
    const midIdx = indexAt(row + dr, col + dc);
    if (midIdx < 0) continue;
    const landIdx = indexAt(row + 2 * dr, col + 2 * dc);
    if (landIdx < 0) continue;

    const canTake = sideOf(cells[midIdx]) === opponent(side) &&
      !captured.has(midIdx) &&
      isEmpty(cells[landIdx]);
    if (!canTake) continue;

    const moving = cells[current];
    cells[current] = Piece.Empty;
    cells[landIdx] = moving;
    captured.add(midIdx);
    path.push(landIdx);

    searchManCaptures(cells, start, landIdx, side, captured, path, out);

    path.pop();
    captured.delete(midIdx);
    cells[landIdx] = Piece.Empty;
    cells[current] = moving;
    extended = true;
  }

  if (!extended && captured.size > 0) {
    out.push({
      from: start,
      to: current,
      captured: [...captured],
      path: [...path],
    });
  }
}

function searchKingCaptures(
  cells: Piece[],
  start: number,
  current: number,
  side: Side,
  captured: Set<number>,
  path: number[],
  out: Move[],
): void {
  const row = rowOf(current);
  const col = colOf(current);
  let extended = false;

  for (const [dr, dc] of DIAGONALS) {
    // 1) Avance sur les cases vides jusqu'à la première pièce.
    let r = row + dr;
    let c = col + dc;
    let scan = indexAt(r, c);
    while (scan >= 0 && isEmpty(cells[scan])) {
      r += dr;
      c += dc;
      scan = indexAt(r, c);
    }
    if (scan < 0) continue;

    // 2) Capturable seulement si ennemie et pas déjà prise.
    if (sideOf(cells[scan]) !== opponent(side) || captured.has(scan)) {
      continue;
    }
    const enemyIdx = scan;

    // 3) Cases d'arrivée : toutes les cases vides au-delà de l'ennemi.
    let lr = rowOf(enemyIdx) + dr;
    let lc = colOf(enemyIdx) + dc;
    let landIdx = indexAt(lr, lc);
    while (landIdx >= 0 && isEmpty(cells[landIdx])) {
      const moving = cells[current];
      cells[current] = Piece.Empty;
      cells[landIdx] = moving;
      captured.add(enemyIdx);
      path.push(landIdx);

      searchKingCaptures(cells, start, landIdx, side, captured, path, out);

      path.pop();
      captured.delete(enemyIdx);
      cells[landIdx] = Piece.Empty;
      cells[current] = moving;
      extended = true;

      lr += dr;
      lc += dc;
      landIdx = indexAt(lr, lc);
    }
  }

  if (!extended && captured.size > 0) {
    out.push({
      from: start,
      to: current,
      captured: [...captured],
      path: [...path],
    });
  }
}

// ───────────────────────────── État de partie ───────────────────────────────
export enum Outcome {
  Ongoing,
  WhiteWins,
  BlackWins,
  Draw,
}

export const DRAW_PLY_LIMIT = 50;

export interface GameState {
  cells: Piece[];
  turn: Side;
  sterilePlies: number;
}

export function initialState(): GameState {
  return { cells: initialBoard(), turn: Side.White, sterilePlies: 0 };
}

export function stateFromFen(fen: string, sterilePlies = 0): GameState {
  const { cells, turn } = decodeFen(fen);
  return { cells, turn, sterilePlies };
}

export function toFen(s: GameState): string {
  return encodeFen(s.cells, s.turn);
}

export function stateLegalMoves(s: GameState): Move[] {
  return legalMoves(s.cells, s.turn);
}

export function applyMove(s: GameState, move: Move): GameState {
  const cells = s.cells.slice();
  const moving = cells[move.from];
  cells[move.from] = Piece.Empty;
  for (const c of move.captured) cells[c] = Piece.Empty;

  let placed = moving;
  if (isMan(moving) && rowOf(move.to) === promotionRow(s.turn)) {
    placed = kingOf(s.turn);
  }
  cells[move.to] = placed;

  const progress = isCapture(move) || isMan(moving);
  return {
    cells,
    turn: opponent(s.turn),
    sterilePlies: progress ? 0 : s.sterilePlies + 1,
  };
}

export function outcome(s: GameState): Outcome {
  if (countOf(s.cells, s.turn) === 0) {
    return s.turn === Side.White ? Outcome.BlackWins : Outcome.WhiteWins;
  }
  if (stateLegalMoves(s).length === 0) {
    return s.turn === Side.White ? Outcome.BlackWins : Outcome.WhiteWins;
  }
  if (s.sterilePlies >= DRAW_PLY_LIMIT) return Outcome.Draw;
  return Outcome.Ongoing;
}
