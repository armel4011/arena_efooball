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

import { RtmRole, RtmTokenBuilder } from "npm:agora-token@2.0.5";

const APP_ID = Deno.env.get("AGORA_APP_ID");
const APP_CERTIFICATE = Deno.env.get("AGORA_APP_CERTIFICATE");

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
  if (!APP_ID || !APP_CERTIFICATE) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  // L'identité vient du JWT Supabase. On parse seulement le `sub` claim
  // sans un round-trip à auth.getUser() — le token est court (5 min de
  // TTL standard Supabase), donc la latence comptait pour le RTC qui
  // déjà fait un getUser ; ici on garde la même cohérence pour
  // simplicité.
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }
  const jwt = authHeader.slice("Bearer ".length).trim();
  const parts = jwt.split(".");
  if (parts.length !== 3) {
    return jsonResponse({ error: "bad_jwt" }, 401);
  }
  let userId: string | null = null;
  try {
    // base64url decode du payload — Deno a atob, base64url = base64
    // standard avec - + _ remplaçant + et /.
    const b64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = b64 + "==".slice(0, (4 - b64.length % 4) % 4);
    const payload = JSON.parse(atob(padded)) as { sub?: string };
    userId = payload.sub ?? null;
  } catch {
    return jsonResponse({ error: "bad_jwt" }, 401);
  }
  if (!userId) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }

  const expiresAt = Math.floor(Date.now() / 1000) + TOKEN_EXPIRE_SECONDS;
  // RTM v2 builder : buildToken(appId, certificate, userId, expirationTs).
  // Le RtmRole.Rtm_User n'existe que sur les anciennes API v1 ; sur v2
  // le token est simplement émis pour un account.
  const token = RtmTokenBuilder.buildToken(
    APP_ID,
    APP_CERTIFICATE,
    userId,
    RtmRole.Rtm_User,
    expiresAt,
  );

  return jsonResponse({
    appId: APP_ID,
    account: userId,
    token,
    expiresAt,
  });
});
