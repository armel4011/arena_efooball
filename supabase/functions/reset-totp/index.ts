// =============================================================================
// ARENA — Edge Function : reset-totp
// =============================================================================
// Réinitialise la double authentification (TOTP) de l'admin connecté pour
// lui permettre de la réenrôler (ex. changement de téléphone). L'appelant
// doit fournir un code COURANT valide (6 chiffres TOTP OU backup code
// "XXXX-XXXX") : on ne peut donc réinitialiser que SA PROPRE 2FA, et
// seulement si on en possède encore un facteur valide.
//
// Sur succès : on efface `totp_secret`, on repasse `totp_enabled = false`
// et on vide `backup_codes`. Le router desktop redirige alors vers
// `/totp/setup` pour un enrôlement frais.
//
// Mêmes garde-fous que `admin-stepup-totp` : JWT admin, rate-limit partagé
// (3 échecs → verrou 30 min), pas d'oracle quand verrouillé.
//
// Inputs (POST JSON) : { code: string }
// Output             : { ok: true, method: "totp" | "backup" }
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.108.2";
import { consumeBackupCodeHashed, verifyTotp } from "../_shared/totp.ts";
import { safeDetail } from "../_shared/errors.ts";
import {
  checkTotpLock,
  lockedBody,
  recordTotpFailure,
  recordTotpSuccess,
} from "../_shared/totp_rate_limit.ts";
import {
  hasBearer,
  isAdminRole,
  isBackupCodeFormat,
  isSixDigitCode,
} from "../_shared/auth_guards.ts";

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
  const isTotp = isSixDigitCode(code);
  const isBackup = isBackupCodeFormat(code);
  if (!isTotp && !isBackup) {
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
    .select("id, role, totp_secret, totp_enabled, backup_codes")
    .eq("id", user.id)
    .maybeSingle();
  if (profileErr || !profile) {
    return jsonResponse({ error: "profile_not_found" }, 404);
  }
  if (!isAdminRole(profile.role)) {
    return jsonResponse({ error: "forbidden_role" }, 403);
  }
  if (!profile.totp_enabled || !profile.totp_secret) {
    return jsonResponse({ error: "totp_not_configured" }, 412);
  }

  // Rate-limit : verrou actif → 429 sans vérifier le code (pas d'oracle).
  const lock = await checkTotpLock(service, user.id);
  if (lock.locked) {
    return jsonResponse(lockedBody(lock), 429);
  }

  // Vérifie le facteur courant AVANT d'effacer quoi que ce soit.
  let method: "totp" | "backup";
  if (isTotp) {
    const ok = await verifyTotp({ secretBase32: profile.totp_secret, code });
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
    method = "totp";
  } else {
    const stored = Array.isArray(profile.backup_codes)
      ? profile.backup_codes as string[]
      : [];
    const result = await consumeBackupCodeHashed(stored, code, hmacKey);
    if (!result.matched) {
      const failure = await recordTotpFailure(service, user.id);
      if (failure.locked) {
        return jsonResponse(lockedBody(failure), 429);
      }
      return jsonResponse({
        error: "invalid_code",
        attempts_remaining: failure.attemptsRemaining,
      }, 401);
    }
    method = "backup";
  }

  // Facteur valide → on efface intégralement la config 2FA.
  const { error: clearErr } = await service
    .from("profiles")
    .update({
      totp_secret: null,
      totp_enabled: false,
      backup_codes: [],
    })
    .eq("id", user.id);
  if (clearErr) {
    return jsonResponse(
      { error: "reset_failed", detail: safeDetail(clearErr.message, "reset-totp") },
      500,
    );
  }

  await recordTotpSuccess(service, user.id);
  return jsonResponse({ ok: true, method });
});
