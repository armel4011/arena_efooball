// =============================================================================
// ARENA — Edge Function : draughts-game (AUTORITÉ serveur du jeu de dames).
// =============================================================================
// Validation serveur dure de chaque coup (décision d'audit). Le client peut
// jouer en optimistic, mais SEUL le serveur fait foi : il rejoue les règles
// internationales (moteur _shared/draughts), tient l'horloge, détecte la fin
// de partie et écrit le résultat sur `matches` (service_role → contourne le
// guard de colonnes ; déclenche `cascade_match_winner` → le bracket avance).
//
// Auth : JWT joueur requis (Authorization: Bearer <user_jwt>).
//
// Actions (POST JSON { action, matchId, move? }) :
//   * start   : crée/retourne la partie active (couleurs : home_player = blancs)
//   * move    : { from, to, captured? } — valide & applique un coup
//   * timeout : réclame la chute de drapeau de l'adversaire au trait
//
// Fin de partie :
//   * décisive → matches.completed + winner_id (score 1-0)
//   * nulle en élimination directe (pas de group_id) → MORT SUBITE : nouvelle
//     partie (couleurs inversées, horloges neuves), le match reste ouvert
//   * nulle en poule (group_id) → matches.completed, winner_id null (1-1... ici 0-0)
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  applyMove,
  encodeFen,
  initialBoard,
  type Move,
  Outcome,
  outcome,
  Side,
  stateFromFen,
  stateLegalMoves,
  toFen,
} from "../_shared/draughts/mod.ts";
import {
  assignColors,
  chargeClock,
  colorOf,
  DEFAULT_CLOCK_MS,
  hashFen,
  matchResult,
  needsSuddenDeath,
  selectMove,
  winnerSideOf,
} from "./logic.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const INITIAL_FEN = encodeFen(initialBoard(), Side.White);

// deno-lint-ignore no-explicit-any
type ServiceClient = any;
// deno-lint-ignore no-explicit-any
type GameRow = Record<string, any>;
// deno-lint-ignore no-explicit-any
type MatchRow = Record<string, any>;

function sideToTurn(s: Side): string {
  return s === Side.White ? "white" : "black";
}

/// Écrit le résultat du match (service_role → contourne le guard) et clôt la
/// partie. winnerSide null = nulle.
async function finishMatch(
  service: ServiceClient,
  match: MatchRow,
  game: GameRow,
  winnerSide: Side | null,
  moverUid: string,
): Promise<void> {
  const gameStatus = winnerSide === null
    ? "draw"
    : winnerSide === Side.White
    ? "white_won"
    : "black_won";
  await service
    .from("draughts_games")
    .update({ status: gameStatus, updated_at: new Date().toISOString() })
    .eq("id", game.id);

  const res = matchResult(
    winnerSide,
    game.white_id,
    game.black_id,
    match.player1_id,
    match.player2_id,
  );
  await service
    .from("matches")
    .update({
      score1: res.score1,
      score2: res.score2,
      winner_id: res.winnerId,
      status: "completed",
      finished_at: new Date().toISOString(),
    })
    .eq("id", match.id);

  await service.from("match_events").insert({
    match_id: match.id,
    type: "score_validated",
    created_by: moverUid,
    payload: {
      via: "draughts",
      winner_id: res.winnerId,
      score1: res.score1,
      score2: res.score2,
    },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SERVICE_ROLE_KEY) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userResult, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userResult.user) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }
  const uid = userResult.user.id;

  let body: {
    action?: unknown;
    matchId?: unknown;
    move?: { from?: unknown; to?: unknown; captured?: unknown };
  };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "bad_json" }, 400);
  }
  const action = typeof body.action === "string" ? body.action : "";
  const matchId = typeof body.matchId === "string" ? body.matchId : "";
  if (!matchId) return jsonResponse({ error: "matchId_required" }, 400);

  const service = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Charge le match et vérifie que l'appelant en est un joueur.
  const { data: match, error: matchErr } = await service
    .from("matches")
    .select(
      "id, player1_id, player2_id, home_player_id, group_id, status",
    )
    .eq("id", matchId)
    .maybeSingle();
  if (matchErr) {
    return jsonResponse({ error: "match_lookup_failed" }, 500);
  }
  if (!match) return jsonResponse({ error: "match_not_found" }, 404);
  if (uid !== match.player1_id && uid !== match.player2_id) {
    return jsonResponse({ error: "not_a_player" }, 403);
  }

  // ─────────────────────────────── start ────────────────────────────────
  if (action === "start") {
    const { data: existing } = await service
      .from("draughts_games")
      .select("*")
      .eq("match_id", matchId)
      .eq("status", "active")
      .order("game_number", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (existing) {
      return jsonResponse({ game: existing, created: false });
    }
    if (["completed", "cancelled", "forfeited"].includes(match.status)) {
      return jsonResponse({ error: "match_already_finalized" }, 409);
    }
    const colors = assignColors(
      match.home_player_id ?? null,
      match.player1_id,
      match.player2_id,
    );
    const { data: created, error: createErr } = await service
      .from("draughts_games")
      .insert({
        match_id: matchId,
        game_number: 1,
        white_id: colors.whiteId,
        black_id: colors.blackId,
        current_turn: "white",
        board_fen: INITIAL_FEN,
        ply: 0,
        sterile_plies: 0,
        status: "active",
        white_clock_ms: DEFAULT_CLOCK_MS,
        black_clock_ms: DEFAULT_CLOCK_MS,
        last_move_at: new Date().toISOString(),
      })
      .select("*")
      .single();
    if (createErr || !created) {
      return jsonResponse({ error: "start_failed" }, 500);
    }
    return jsonResponse({ game: created, created: true });
  }

  // Charge la partie active pour move / timeout.
  const { data: game } = await service
    .from("draughts_games")
    .select("*")
    .eq("match_id", matchId)
    .eq("status", "active")
    .order("game_number", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!game) return jsonResponse({ error: "no_active_game" }, 404);

  const callerSide = colorOf(uid, game.white_id, game.black_id);
  if (callerSide === null) return jsonResponse({ error: "not_a_player" }, 403);

  const turnSide = game.current_turn === "white" ? Side.White : Side.Black;
  const elapsedMs = Date.now() - new Date(game.last_move_at).getTime();

  // ────────────────────────────── timeout ───────────────────────────────
  if (action === "timeout") {
    const clockOfTurn = turnSide === Side.White
      ? game.white_clock_ms
      : game.black_clock_ms;
    const charged = chargeClock(clockOfTurn, elapsedMs);
    if (!charged.flagged) {
      return jsonResponse({ error: "not_flagged", flagged: false }, 409);
    }
    // Le joueur au trait a épuisé son temps → l'adversaire gagne.
    const winnerSide = turnSide === Side.White ? Side.Black : Side.White;
    await finishMatch(service, match, game, winnerSide, uid);
    return jsonResponse({ status: "finished", reason: "timeout", winnerSide });
  }

  // ─────────────────────────────── move ─────────────────────────────────
  if (action !== "move") {
    return jsonResponse({ error: "unknown_action" }, 400);
  }
  if (callerSide !== turnSide) {
    return jsonResponse({ error: "not_your_turn" }, 409);
  }

  const from = typeof body.move?.from === "number" ? body.move.from : -1;
  const to = typeof body.move?.to === "number" ? body.move.to : -1;
  const capturedHint = Array.isArray(body.move?.captured)
    ? (body.move.captured as number[])
    : null;
  if (from < 0 || to < 0) {
    return jsonResponse({ error: "move_from_to_required" }, 400);
  }

  // Horloge : le temps écoulé est imputé au joueur au trait (= l'appelant).
  const callerClock = callerSide === Side.White
    ? game.white_clock_ms
    : game.black_clock_ms;
  const charged = chargeClock(callerClock, elapsedMs);
  if (charged.flagged) {
    const winnerSide = callerSide === Side.White ? Side.Black : Side.White;
    await finishMatch(service, match, game, winnerSide, uid);
    return jsonResponse({ status: "finished", reason: "timeout", winnerSide });
  }

  // Validation dure : on rejoue les règles côté serveur.
  const state = stateFromFen(game.board_fen, game.sterile_plies);
  const legal = stateLegalMoves(state);
  const chosen: Move | null = selectMove(legal, from, to, capturedHint);
  if (chosen === null) {
    return jsonResponse({ error: "illegal_move" }, 422);
  }

  const next = applyMove(state, chosen);
  const newFen = toFen(next);
  const newPly = game.ply + 1;

  const { error: moveErr } = await service.from("draughts_moves").insert({
    game_id: game.id,
    ply: newPly,
    player_id: uid,
    move_json: {
      from: chosen.from,
      to: chosen.to,
      captured: chosen.captured,
      path: chosen.path,
    },
    board_after_fen: newFen,
    parent_fen_hash: hashFen(game.board_fen),
  });
  if (moveErr) {
    // Conflit d'unicité (game_id, ply) = coup concurrent / rejeu.
    return jsonResponse({ error: "move_conflict" }, 409);
  }

  const remaining = charged.remaining;
  const clockPatch = callerSide === Side.White
    ? { white_clock_ms: remaining }
    : { black_clock_ms: remaining };

  const result = outcome(next);
  const winnerSide = winnerSideOf(result);

  // Partie en cours → on met simplement à jour l'état.
  if (result === Outcome.Ongoing) {
    await service
      .from("draughts_games")
      .update({
        board_fen: newFen,
        current_turn: sideToTurn(next.turn),
        ply: newPly,
        sterile_plies: next.sterilePlies,
        last_move_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        ...clockPatch,
      })
      .eq("id", game.id);
    return jsonResponse({
      status: "ongoing",
      board_fen: newFen,
      turn: sideToTurn(next.turn),
      ply: newPly,
    });
  }

  // Issue décisive → résultat de match.
  if (winnerSide !== null) {
    await service
      .from("draughts_games")
      .update({ board_fen: newFen, ply: newPly, ...clockPatch })
      .eq("id", game.id);
    await finishMatch(service, match, game, winnerSide, uid);
    return jsonResponse({ status: "finished", reason: "decisive", winnerSide });
  }

  // Nulle.
  if (needsSuddenDeath(match.group_id ?? null)) {
    // Élimination directe : on rejoue (couleurs inversées, horloges neuves).
    await service
      .from("draughts_games")
      .update({
        board_fen: newFen,
        ply: newPly,
        status: "draw",
        updated_at: new Date().toISOString(),
        ...clockPatch,
      })
      .eq("id", game.id);
    const { data: newGame } = await service
      .from("draughts_games")
      .insert({
        match_id: matchId,
        game_number: game.game_number + 1,
        white_id: game.black_id,
        black_id: game.white_id,
        current_turn: "white",
        board_fen: INITIAL_FEN,
        ply: 0,
        sterile_plies: 0,
        status: "active",
        white_clock_ms: DEFAULT_CLOCK_MS,
        black_clock_ms: DEFAULT_CLOCK_MS,
        last_move_at: new Date().toISOString(),
      })
      .select("*")
      .single();
    return jsonResponse({
      status: "sudden_death",
      game: newGame,
      gameNumber: game.game_number + 1,
    });
  }

  // Poule : nulle acceptée.
  await service
    .from("draughts_games")
    .update({ board_fen: newFen, ply: newPly, ...clockPatch })
    .eq("id", game.id);
  await finishMatch(service, match, game, null, uid);
  return jsonResponse({ status: "finished", reason: "draw", winnerSide: null });
});
