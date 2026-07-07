// =============================================================================
// ARENA — Edge Function : admin-stepup-totp
// =============================================================================
// Step-up TOTP : re-vérifie le code 2FA avant d'autoriser une action
// admin sensible (validation payout, résolution litige, ban user, KYC
// override, reset TOTP d'un confrère, etc.).
//
// L'appelant côté Flutter ouvre `TotpGate` qui appelle cette EF avec le
// code 6 chiffres saisi. On retourne juste 200 / 401 — l'EF métier
// derrière (ex. `validate-payout`) est invoquée séparément, le client
// vérifie le succès du step-up *avant* d'appeler l'action.
//
// Pourquoi pas un seul appel atomique ? Parce qu'on a des actions métier
// faites directement en SQL/RLS (ex. `admin_payouts_page.dart` qui appelle
// `payouts_repository.validate`). On garde le step-up indépendant pour
// rester réutilisable sans coupler chaque action à une EF spécifique.
// Note : un attaquant qui contournerait `TotpGate` côté app pourrait
// quand même appeler l'action métier — la sécurité défensive principale
// reste les policies RLS + le rate-limit sur l'admin (cf. Phase 11).
//
// Inputs (POST JSON) : { code: string }
// Output             : { ok: true }
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.108.2";
import { consumeBackupCodeHashed, verifyTotpStep } from "../_shared/totp.ts";
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
  // Accepte 6 chiffres (TOTP) OU un backup code "XXXX-XXXX".
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
    .select("id, role, totp_secret, totp_enabled, backup_codes, last_totp_step")
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
  // Compteur partagé avec admin-verify-totp (même surface d'attaque).
  const lock = await checkTotpLock(service, user.id);
  if (lock.locked) {
    return jsonResponse(lockedBody(lock), 429);
  }

  if (isTotp) {
    const step = await verifyTotpStep({
      secretBase32: profile.totp_secret,
      code,
    });
    // Anti-rejeu (audit 2026-07-07) : step déjà consommé (<= dernier accepté)
    // refusé comme invalide. Compteur last_totp_step partagé avec
    // admin-verify-totp → un code utilisé au login ne peut pas être rejoué ici.
    const lastStep = profile.last_totp_step != null
      ? BigInt(profile.last_totp_step)
      : -1n;
    if (step === null || step <= lastStep) {
      const failure = await recordTotpFailure(service, user.id);
      if (failure.locked) {
        return jsonResponse(lockedBody(failure), 429);
      }
      return jsonResponse({
        error: "invalid_code",
        attempts_remaining: failure.attemptsRemaining,
      }, 401);
    }
    const { error: stepErr } = await service
      .from("profiles")
      .update({ last_totp_step: Number(step) })
      .eq("id", user.id);
    if (stepErr) {
      return jsonResponse(
        { error: "totp_step_persist_failed", detail: safeDetail(stepErr.message, "admin-stepup-totp") },
        500,
      );
    }
    await recordTotpSuccess(service, user.id);
    return jsonResponse({ ok: true, method: "totp" });
  }

  // Backup code : hashé puis comparé en constant-time, single-use.
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
  const { error: updateErr } = await service
    .from("profiles")
    .update({ backup_codes: result.remaining })
    .eq("id", user.id);
  if (updateErr) {
    return jsonResponse(
      { error: "backup_consume_failed", detail: safeDetail(updateErr.message, "admin-stepup-totp") },
      500,
    );
  }
  await recordTotpSuccess(service, user.id);
  return jsonResponse({
    ok: true,
    method: "backup",
    remainingBackupCodes: result.remaining.length,
  });
});
