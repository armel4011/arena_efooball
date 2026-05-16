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

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { consumeBackupCode, verifyTotp } from "../_shared/totp.ts";

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
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
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
  const isTotp = /^\d{6}$/.test(code);
  const isBackup = /^[A-Za-z0-9]{4}-[A-Za-z0-9]{4}$/.test(code);
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
  if (profile.role !== "admin" && profile.role !== "super_admin") {
    return jsonResponse({ error: "forbidden_role" }, 403);
  }
  if (!profile.totp_enabled || !profile.totp_secret) {
    return jsonResponse({ error: "totp_not_configured" }, 412);
  }

  if (isTotp) {
    const ok = await verifyTotp({
      secretBase32: profile.totp_secret,
      code,
    });
    if (!ok) {
      return jsonResponse({ error: "invalid_code" }, 401);
    }
    return jsonResponse({ ok: true, method: "totp" });
  }

  // Backup code : consommé (single-use) puis ré-écrit en DB sans lui.
  const stored = Array.isArray(profile.backup_codes)
    ? profile.backup_codes as string[]
    : [];
  const result = consumeBackupCode(stored, code);
  if (!result.matched) {
    return jsonResponse({ error: "invalid_code" }, 401);
  }
  const { error: updateErr } = await service
    .from("profiles")
    .update({ backup_codes: result.remaining })
    .eq("id", user.id);
  if (updateErr) {
    return jsonResponse(
      { error: "backup_consume_failed", detail: updateErr.message },
      500,
    );
  }
  return jsonResponse({
    ok: true,
    method: "backup",
    remainingBackupCodes: result.remaining.length,
  });
});
