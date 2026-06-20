// =============================================================================
// ARENA — Edge Function : verify-totp-setup
// =============================================================================
// Confirme l'enrôlement TOTP de l'admin connecté.
//
// Flow :
//   1. L'admin a précédemment appelé `setup-totp` → `profiles.totp_secret`
//      est rempli, `totp_enabled = false`.
//   2. Il scanne le QR avec Google Authenticator et tape le 1er code 6
//      chiffres dans l'écran TotpSetupScreen.
//   3. Cette EF vérifie le code, flippe `totp_enabled = true`, et
//      retourne 10 codes de récupération (à n'afficher qu'UNE fois).
//
// Inputs (POST JSON) : { code: string }
// Output             : { backupCodes: string[] }
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  generateBackupCodes,
  hashBackupCodes,
  verifyTotp,
} from "../_shared/totp.ts";
import {
  checkTotpLock,
  lockedBody,
  recordTotpFailure,
  recordTotpSuccess,
} from "../_shared/totp_rate_limit.ts";
import { hasBearer, isAdminRole, isSixDigitCode } from "../_shared/auth_guards.ts";

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

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const hmacKey = Deno.env.get("TOTP_BACKUP_HMAC_KEY");
  if (!supabaseUrl || !anonKey || !serviceKey || !hmacKey) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!hasBearer(authHeader)) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }

  let body: { code?: unknown };
  try {
    body = await req.json();
  } catch (_) {
    return jsonResponse({ error: "bad_json" }, 400);
  }
  const code = typeof body.code === "string" ? body.code.trim() : "";
  if (!isSixDigitCode(code)) {
    return jsonResponse({ error: "bad_code_format" }, 400);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }
  const user = userData.user;

  const service = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: profile, error: profileErr } = await service
    .from("profiles")
    .select("id, role, totp_secret, totp_enabled")
    .eq("id", user.id)
    .maybeSingle();
  if (profileErr || !profile) {
    return jsonResponse({ error: "profile_not_found" }, 404);
  }
  if (!isAdminRole(profile.role)) {
    return jsonResponse({ error: "forbidden_role" }, 403);
  }
  if (profile.totp_enabled) {
    return jsonResponse({ error: "totp_already_enabled" }, 409);
  }
  if (!profile.totp_secret) {
    return jsonResponse({ error: "no_secret_pending" }, 412);
  }

  // Rate-limit (M-4, audit 2026-06-14) : même protection que admin-verify-totp
  // / admin-stepup-totp — 3 échecs consécutifs → verrou 30 min, compteur
  // partagé via la table `totp_attempts`. Empêche le brute-force du code à
  // l'enrôlement. Lock vérifié AVANT verifyTotp (pas d'oracle).
  const lock = await checkTotpLock(service, user.id);
  if (lock.locked) {
    return jsonResponse(lockedBody(lock), 429);
  }

  const ok = await verifyTotp({
    secretBase32: profile.totp_secret,
    code,
  });
  if (!ok) {
    const failure = await recordTotpFailure(service, user.id);
    if (failure.locked) {
      return jsonResponse(lockedBody(failure), 429);
    }
    return jsonResponse({
      error: "invalid_code",
      attempts_remaining: failure.attemptsRemaining,
    }, 401);
  }
  await recordTotpSuccess(service, user.id);

  const backupCodes = generateBackupCodes();
  const backupCodesHashed = await hashBackupCodes(backupCodes, hmacKey);
  const { error: updateErr } = await service
    .from("profiles")
    .update({
      totp_enabled: true,
      backup_codes: backupCodesHashed,
    })
    .eq("id", user.id);
  if (updateErr) {
    return jsonResponse(
      { error: "enable_failed", detail: updateErr.message },
      500,
    );
  }

  return jsonResponse({ backupCodes });
});
