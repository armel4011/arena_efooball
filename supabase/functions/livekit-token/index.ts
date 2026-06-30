// =============================================================================
// ARENA — Edge Function: livekit-token
// =============================================================================
// Émet un jeton d'accès LiveKit Cloud pour la CAPTURE anti-triche (publish-only).
//
// Pourquoi côté serveur :
//   * l'API Secret LiveKit est la moitié secrète des credentials — quiconque
//     le lit peut forger des jetons. Il reste donc dans les secrets de cette
//     Edge Function (LIVEKIT_API_SECRET), jamais dans l'app. Le client appelle
//     cette fonction avec sa seule session Supabase et ne voit que l'URL + le
//     jeton signé.
//
// Modèle anti-triche DUAL (coexistence avec le recorder natif) :
//   * Chaque joueur PUBLIE son propre flux gameplay (screen-share) dans la
//     room `match_<id>` — c'est ce flux qui est ensuite enregistré par Track
//     Egress (cf. livekit-anticheat-webhook).
//   * publish-only : canPublish = true, canSubscribe = FALSE. Un joueur ne
//     s'abonne JAMAIS au flux de l'adversaire (anti-triche : pas de fuite de
//     l'écran adverse ; coût réseau minimal).
//
// TIERING + EGRESS RANDOMISÉ (P0/P1) — design « opaque » :
//   * On assigne (idempotent) un plan anti-triche au match via le RPC
//     `assign_anticheat_plan` : `native_only` (aucun egress, P3 seul) ou
//     `livekit` (1 egress de l'élu, tiré au hasard côté serveur).
//   * `native_only` → on NE délivre PAS de jeton : le client retombe sur le
//     recorder natif. Le match ne consomme alors AUCUN egress LiveKit (capacité
//     = matchs simultanés en compétition).
//   * `livekit` → les DEUX joueurs reçoivent un jeton publish et publient
//     (UX identique). Le webhook n'egress QUE `recorded_player_id` — l'app
//     ignore si c'est elle l'élue (dissuasion préservée). Le rôle renvoyé est
//     volontairement OPAQUE : côté client, `native` = recorder natif normal.
//
// Entrées (POST JSON) :
//   { matchId: string }
//
// Sorties :
//   { role: "native" }                                          // tier native_only
//   { role: "livekit", token, url, room, identity, expiresAt }  // tier livekit
//
// Autorisation :
//   * JWT Supabase valide (Authorization: Bearer ...).
//   * L'appelant doit être un des deux joueurs assis du match (player1_id /
//     player2_id). Contrairement à get_agora_token (gaté sur is_public), la
//     capture anti-triche est OBLIGATOIRE et ne dépend pas du flag public.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.108.2";
import { AccessToken } from "npm:livekit-server-sdk@2.9.0";
import { safeDetail } from "../_shared/errors.ts";

const LIVEKIT_URL = Deno.env.get("LIVEKIT_URL");
const LIVEKIT_API_KEY = Deno.env.get("LIVEKIT_API_KEY");
const LIVEKIT_API_SECRET = Deno.env.get("LIVEKIT_API_SECRET");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
// Service-role : pour appeler le RPC interne `assign_anticheat_plan` (revoke
// authenticated), pas accessible avec le client porté par la session joueur.
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const TOKEN_TTL_SECONDS = 60 * 60; // 1h — le client rafraîchit si nécessaire.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (
    !LIVEKIT_URL || !LIVEKIT_API_KEY || !LIVEKIT_API_SECRET ||
    !SUPABASE_URL || !SUPABASE_ANON_KEY || !SERVICE_KEY
  ) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userResult, error: userErr } = await supabase.auth.getUser();
  if (userErr || !userResult.user) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }
  const user = userResult.user;

  let body: { matchId?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "bad_json" }, 400);
  }

  const matchId = typeof body.matchId === "string" ? body.matchId : null;
  if (!matchId) {
    return jsonResponse({ error: "matchId_required" }, 400);
  }

  // L'appelant doit être un des deux joueurs assis du match.
  const { data: match, error: matchErr } = await supabase
    .from("matches")
    .select("id, player1_id, player2_id")
    .eq("id", matchId)
    .maybeSingle();

  if (matchErr) {
    return jsonResponse(
      { error: "match_lookup_failed", detail: safeDetail(matchErr.message, "livekit-token") },
      500,
    );
  }
  if (!match) {
    return jsonResponse({ error: "match_not_found" }, 404);
  }
  if (match.player1_id !== user.id && match.player2_id !== user.id) {
    return jsonResponse({ error: "not_a_player" }, 403);
  }

  // Assigner (idempotent) le plan anti-triche du match. Service-role : le RPC
  // est interne (revoke authenticated). La décision est figée au premier appel,
  // identique pour les deux joueurs.
  const sb = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: planResult, error: planErr } = await sb.rpc(
    "assign_anticheat_plan",
    { p_match_id: matchId },
  );
  if (planErr) {
    return jsonResponse(
      { error: "plan_assign_failed", detail: safeDetail(planErr.message, "livekit-token") },
      500,
    );
  }
  // Un RPC `returns <composite>` renvoie l'objet (ou un tableau d'1 élément
  // selon PostgREST) — on normalise.
  const plan = Array.isArray(planResult) ? planResult[0] : planResult;

  // Tier `native_only` : pas d'egress LiveKit. On ne délivre AUCUN jeton →
  // le client reste sur le recorder natif (rôle opaque).
  if (!plan || plan.mode !== "livekit") {
    return jsonResponse({ role: "native" });
  }

  // Tier `livekit` : les deux joueurs publient (opaque) ; seul l'élu sera
  // egressé côté webhook.
  const room = `match_${matchId}`;

  // Jeton publish-only : le joueur publie son gameplay, ne s'abonne à rien.
  const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
    identity: user.id,
    ttl: TOKEN_TTL_SECONDS,
  });
  at.addGrant({
    roomJoin: true,
    room,
    canPublish: true,
    canSubscribe: false,
    canPublishData: false,
  });

  const token = await at.toJwt();
  const expiresAt = Math.floor(Date.now() / 1000) + TOKEN_TTL_SECONDS;

  return jsonResponse({
    role: "livekit",
    token,
    url: LIVEKIT_URL,
    room,
    identity: user.id,
    expiresAt,
  });
});
