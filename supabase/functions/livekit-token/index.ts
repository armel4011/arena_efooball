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
//     Egress (cf. livekit-anticheat-start).
//   * publish-only : canPublish = true, canSubscribe = FALSE. Un joueur ne
//     s'abonne JAMAIS au flux de l'adversaire (anti-triche : pas de fuite de
//     l'écran adverse ; coût réseau minimal).
//
// Entrées (POST JSON) :
//   { matchId: string }
//
// Sorties :
//   { token, url, room, identity, expiresAt }
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
    !SUPABASE_URL || !SUPABASE_ANON_KEY
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
    token,
    url: LIVEKIT_URL,
    room,
    identity: user.id,
    expiresAt,
  });
});
