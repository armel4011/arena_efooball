// =============================================================================
// ARENA — Edge Function: get_agora_token
// =============================================================================
// Issues an Agora RTC token for a given match channel.
//
// Why server-side:
//   * the App Certificate is the secret half of the Agora credentials —
//     anyone who reads it can mint tokens against our project.
//     Keeping it inside an Edge Function lets the client call this
//     function with just its Supabase auth, never seeing the cert.
//
// Inputs (POST JSON):
//   { matchId: string, role: "broadcaster" | "audience" }
//
// Outputs:
//   { token, channelName, uid, expiresAt }
//
// Authorization:
//   * The Supabase JWT must be valid (Authorization: Bearer ...).
//   * For role = broadcaster, the caller must be one of the seated
//     players of `matchId` and the matching `streams` row for the
//     match must already have `is_public = true` (admin enabled it).
//   * For role = audience, any authenticated user can pull a token —
//     the bandwidth cost matters only when actually joining, and we
//     gate the channel name itself behind the public flag.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { RtcTokenBuilder, RtcRole } from "npm:agora-token@2.0.5";

const APP_ID = Deno.env.get("AGORA_APP_ID");
const APP_CERTIFICATE = Deno.env.get("AGORA_APP_CERTIFICATE");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");

const TOKEN_EXPIRE_SECONDS = 60 * 60; // 1h — refreshed by client when low.

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

  let body: { matchId?: unknown; role?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "bad_json" }, 400);
  }

  const matchId = typeof body.matchId === "string" ? body.matchId : null;
  const role = body.role === "broadcaster" ? "broadcaster" : "audience";
  if (!matchId) {
    return jsonResponse({ error: "matchId_required" }, 400);
  }

  // Both roles: the channel must correspond to a stream row that the
  // admin has marked as `is_public = true`. This is what gates the
  // overall "Agora costs" lever — until an admin flips the bit, no
  // token can be minted.
  const { data: stream, error: streamErr } = await supabase
    .from("streams")
    .select("id, match_id, player_id, is_public, is_active")
    .eq("match_id", matchId)
    .eq("is_public", true)
    .eq("is_active", true)
    .maybeSingle();

  if (streamErr) {
    return jsonResponse({ error: "stream_lookup_failed" }, 500);
  }
  if (!stream) {
    return jsonResponse({ error: "stream_not_published" }, 403);
  }

  if (role === "broadcaster") {
    // Only the owner of the stream row (the HOME player) may broadcast.
    if (stream.player_id !== user.id) {
      return jsonResponse({ error: "not_broadcaster" }, 403);
    }
  }

  const channelName = `match_${matchId}`;
  const expiresAt = Math.floor(Date.now() / 1000) + TOKEN_EXPIRE_SECONDS;
  // Agora uids are unsigned 32-bit ints; we hash the auth uid into one
  // so two users on the same channel never collide. `0` is reserved
  // for "auto-assign" and we want stable ids for analytics.
  const uid = stableUidFromUuid(user.id);
  const agoraRole =
    role === "broadcaster" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERTIFICATE,
    channelName,
    uid,
    agoraRole,
    expiresAt,
    expiresAt,
  );

  return jsonResponse({
    token,
    channelName,
    uid,
    expiresAt,
    role,
  });
});

/**
 * Derives a deterministic 32-bit unsigned int from a Supabase auth
 * uuid. Lossy by design — collisions are theoretically possible but
 * negligible at our scale, and the uid is only used inside Agora's
 * channel namespace.
 */
function stableUidFromUuid(uuid: string): number {
  let h = 2166136261;
  for (let i = 0; i < uuid.length; i++) {
    h ^= uuid.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  // Force unsigned 32-bit, also avoid 0 (Agora reserved value).
  const unsigned = h >>> 0;
  return unsigned === 0 ? 1 : unsigned;
}
