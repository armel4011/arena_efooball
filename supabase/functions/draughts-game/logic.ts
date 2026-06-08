// =============================================================================
// ARENA — Edge Function draughts-game : logique pure (testable sans DB).
// =============================================================================
// Fonctions sans I/O réutilisées par index.ts (la coquille HTTP + accès DB).
// Isolées ici pour être couvertes par logic.test.ts.
// =============================================================================

import { type Move, Outcome, Side } from "../_shared/draughts/mod.ts";

export const DEFAULT_CLOCK_MS = 10 * 60 * 1000; // cadence rapide ~10 min/joueur

/// Attribue les couleurs : le `home_player` (sinon player1) joue les Blancs.
export function assignColors(
  homePlayerId: string | null,
  player1Id: string,
  player2Id: string,
): { whiteId: string; blackId: string } {
  const white = homePlayerId === player2Id ? player2Id : player1Id;
  const black = white === player1Id ? player2Id : player1Id;
  return { whiteId: white, blackId: black };
}

/// Couleur du joueur dans une partie donnée, ou null s'il n'y participe pas.
export function colorOf(
  uid: string,
  whiteId: string,
  blackId: string,
): Side | null {
  if (uid === whiteId) return Side.White;
  if (uid === blackId) return Side.Black;
  return null;
}

/// Décompte l'horloge : retourne le temps restant (≥ 0) et si le drapeau tombe.
/// `clockMs` null = partie sans horloge (jamais de flag).
export function chargeClock(
  clockMs: number | null,
  elapsedMs: number,
): { remaining: number | null; flagged: boolean } {
  if (clockMs === null) return { remaining: null, flagged: false };
  const remaining = clockMs - Math.max(0, elapsedMs);
  if (remaining <= 0) return { remaining: 0, flagged: true };
  return { remaining, flagged: false };
}

/// Traduit l'issue d'une partie + l'identité des camps en résultat de MATCH
/// (winner_id + score1/score2 selon player1/player2). winnerSide null = nulle.
export function matchResult(
  winnerSide: Side | null,
  whiteId: string,
  blackId: string,
  player1Id: string,
  player2Id: string,
): { winnerId: string | null; score1: number; score2: number } {
  if (winnerSide === null) {
    return { winnerId: null, score1: 0, score2: 0 };
  }
  const winnerId = winnerSide === Side.White ? whiteId : blackId;
  return {
    winnerId,
    score1: winnerId === player1Id ? 1 : 0,
    score2: winnerId === player2Id ? 1 : 0,
  };
}

/// Camp gagnant d'une issue décisive, ou null si nulle / en cours.
export function winnerSideOf(outcome: Outcome): Side | null {
  if (outcome === Outcome.WhiteWins) return Side.White;
  if (outcome === Outcome.BlackWins) return Side.Black;
  return null;
}

/// Une nulle doit-elle être départagée en mort subite ?
/// Oui en élimination directe (pas de `group_id`) ; en poule la nulle est
/// acceptée (winner_id null).
export function needsSuddenDeath(groupId: string | null): boolean {
  return groupId === null;
}

/// Hash léger et déterministe d'une FEN (continuité d'état / anti-rejeu).
/// Pas cryptographique : sert juste à vérifier que le coup s'applique bien à
/// l'état parent attendu. djb2.
export function hashFen(fen: string): string {
  let h = 5381;
  for (let i = 0; i < fen.length; i++) {
    h = ((h << 5) + h + fen.charCodeAt(i)) >>> 0;
  }
  return h.toString(16);
}

/// Sélectionne, parmi les coups légaux, celui demandé par le client
/// (from→to, désambiguïsé par l'ensemble des cases capturées si fourni).
/// Retourne null si aucun coup légal ne correspond (= coup illégal / triche).
export function selectMove(
  legal: Move[],
  from: number,
  to: number,
  capturedHint: number[] | null,
): Move | null {
  const candidates = legal.filter((m) => m.from === from && m.to === to);
  if (candidates.length === 0) return null;
  if (candidates.length === 1) return candidates[0];
  if (capturedHint !== null) {
    const want = [...capturedHint].sort((a, b) => a - b).join(",");
    const match = candidates.find(
      (m) => [...m.captured].sort((a, b) => a - b).join(",") === want,
    );
    if (match) return match;
  }
  return candidates[0];
}
