// =============================================================================
// ARENA — Edge Function: get-agora-call-token
// =============================================================================
// Mint un Agora RTC token pour un appel voice 1v1 (Phase 12.5 — item 3).
//
// Différent de `get_agora_token` (qui sert le streaming match
// broadcaster→audience). Ici les 2 peers sont PUBLISHER (audio
// bidirectionnel), channel = `call_<scope>_<id>` où scope=match|friend.
//
// Inputs (POST JSON):
//   { scope: "match" | "friend", id: string }
//
// Outputs:
//   { token, channelName, uid, expiresAt }
//
// Authorization:
//   * Supabase JWT requis (Authorization: Bearer <user_jwt>)
//   * scope=match : caller doit être player1 ou player2 du match
//   * scope=friend : caller doit être l'un des 2 membres de la
//     friendship et status='accepted'
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.108.2";
import { RtcTokenBuilder, RtcRole } from "npm:agora-token@2.0.5";

const APP_ID = Deno.env.get("AGORA_APP_ID");
const APP_CERTIFICATE = Deno.env.get("AGORA_APP_CERTIFICATE");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");

const TOKEN_EXPIRE_SECONDS = 60 * 60; // 1h

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

function stableUidFromUuid(uuid: string): number {
  let h = 2166136261;
  for (let i = 0; i < uuid.length; i++) {
    h ^= uuid.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  const unsigned = h >>> 0;
  return unsigned === 0 ? 1 : unsigned;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (!APP_ID || !APP_CERTIFICATE || !SUPABASE_URL || !SUPABASE_ANON_KEY) {
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

  let body: { scope?: unknown; id?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "bad_json" }, 400);
  }

  const scope = body.scope === "match" || body.scope === "friend"
    ? body.scope
    : null;
  const id = typeof body.id === "string" ? body.id : null;
  if (!scope || !id) {
    return jsonResponse({ error: "scope_and_id_required" }, 400);
  }

  // Authorization gate
  if (scope === "match") {
    const { data: m, error: mErr } = await supabase
      .from("matches")
      .select("id, player1_id, player2_id")
      .eq("id", id)
      .maybeSingle();
    if (mErr) return jsonResponse({ error: "lookup_failed" }, 500);
    if (!m || (m.player1_id !== user.id && m.player2_id !== user.id)) {
      return jsonResponse({ error: "not_a_participant" }, 403);
    }
  } else {
    const { data: f, error: fErr } = await supabase
      .from("friendships")
      .select("id, requester_id, addressee_id, status")
      .eq("id", id)
      .maybeSingle();
    if (fErr) return jsonResponse({ error: "lookup_failed" }, 500);
    if (!f || f.status !== "accepted" ||
        (f.requester_id !== user.id && f.addressee_id !== user.id)) {
      return jsonResponse({ error: "not_a_friend" }, 403);
    }
  }

  const channelName = `call_${scope}_${id}`;
  const expiresAt = Math.floor(Date.now() / 1000) + TOKEN_EXPIRE_SECONDS;
  const uid = stableUidFromUuid(user.id);

  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERTIFICATE,
    channelName,
    uid,
    RtcRole.PUBLISHER,
    expiresAt,
    expiresAt,
  );

  return jsonResponse({
    token,
    channelName,
    uid,
    expiresAt,
  });
});
