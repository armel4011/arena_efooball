// =============================================================================
// ARENA — Edge Function : get-agora-rtm-token
// =============================================================================
// Issue un token Agora **RTM** (Real-Time Messaging) pour l'utilisateur
// connecté. Le token authentifie l'identité côté Agora RTM ; le contrôle
// "qui peut écrire dans match_<matchId>" reste côté client (le router
// Flutter ouvre la page chat uniquement si tu es l'un des 2 joueurs
// seated, et l'INSERT chat_messages côté Supabase est gated par RLS de
// toute façon — RTM ne porte que presence/typing).
//
// Pourquoi server-side : l'App Certificate est l'autre moitié des creds
// Agora, jamais exposable au client (cf. [[fcm-stack]] pattern). Le RTC
// token (cf. `get_agora_token`) suit la même logique.
//
// Inputs (POST JSON) : aucun — l'identité vient du JWT Supabase.
// Output             : { appId, account, token, expiresAt }
//   - `account` = supabase user id (string, cohérent avec le RTC uid
//     hash) ; Agora RTM v2 supporte les userId string directement.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.108.2";
import { RtmTokenBuilder } from "npm:agora-token@2.0.5";

const APP_ID = Deno.env.get("AGORA_APP_ID");
const APP_CERTIFICATE = Deno.env.get("AGORA_APP_CERTIFICATE");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");

const TOKEN_EXPIRE_SECONDS = 60 * 60 * 24; // 24h — le RTM se renouvelle
// rarement (présence/typing low-traffic), et la connexion RTM est plus
// coûteuse à reset que la RTC.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
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
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }
  if (!APP_ID || !APP_CERTIFICATE || !SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  // L'identité vient du JWT Supabase, et on **vérifie sa signature** via
  // `supabase.auth.getUser()`. Sans ce contrôle, n'importe qui pouvait
  // forger un payload base64 avec un `sub` arbitraire et obtenir un
  // token RTM valide pour ce userId (audit sécu 2026-05-23). Même
  // pattern que `get-agora-call-token`.
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
  const userId = userResult.user.id;

  const expiresAt = Math.floor(Date.now() / 1000) + TOKEN_EXPIRE_SECONDS;
  // RTM v2 builder : buildToken(appId, certificate, userId, expirationTs).
  // agora-token@2.0.5 n'exporte PAS de RtmRole et `buildToken` ne prend que
  // 4 args (le rôle n'existe plus en RTM v2). L'ancien appel à 5 args avec
  // RtmRole.Rtm_User plantait au runtime (RtmRole === undefined). expiresAt
  // est un timestamp absolu, comme pour les tokens RTC (cf. get_agora_token).
  const token = RtmTokenBuilder.buildToken(
    APP_ID,
    APP_CERTIFICATE,
    userId,
    expiresAt,
  );

  return jsonResponse({
    appId: APP_ID,
    account: userId,
    token,
    expiresAt,
  });
});
