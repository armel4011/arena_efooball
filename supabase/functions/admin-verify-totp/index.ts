// =============================================================================
// ARENA — Edge Function : admin-verify-totp
// =============================================================================
// Vérifie le code TOTP juste après le sign-in email + password de l'admin.
//
// Flow côté Flutter :
//   1. `LoginAdminScreen` → `signInAdmin(email, password)` → Supabase
//      crée une session standard, le router redirige vers
//      `TotpVerifyScreen` si `profile.totp_enabled == true`.
//   2. L'écran appelle cette EF avec le code 6 chiffres (ou un backup
//      code single-use). Sur 200, le router file vers le dashboard.
//      Sur 401, on incrémente le compteur d'échecs et on demande un
//      nouveau code.
//
// Important : la session Supabase est déjà valide à ce stade (le user a
// fourni son password). Cette EF n'attribue pas de session, elle
// confirme juste que le 2e facteur a passé. Les actions sensibles
// déclenchent ensuite `admin-stepup-totp` au cas par cas.
//
// Inputs (POST JSON) : { code: string }
// Output             : { profile: {...} } (subset Profile pour le client)
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { consumeBackupCodeHashed, verifyTotp } from "../_shared/totp.ts";

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

  // On lit le profil complet (`select *`) puis on retire `totp_secret`
  // avant de retourner — c'est plus robuste qu'une allowlist qui dérive
  // à chaque ajout de colonne. Le freezed Profile.fromJson côté Flutter
  // ignore aussi `backup_codes` / `totp_secret` via son `_normalize`.
  const { data: profile, error: profileErr } = await service
    .from("profiles")
    .select("*")
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

  let method: "totp" | "backup";
  if (isTotp) {
    const ok = await verifyTotp({
      secretBase32: profile.totp_secret,
      code,
    });
    if (!ok) {
      return jsonResponse({ error: "invalid_code" }, 401);
    }
    method = "totp";
  } else {
    const stored = Array.isArray(profile.backup_codes)
      ? profile.backup_codes as string[]
      : [];
    const result = await consumeBackupCodeHashed(stored, code, hmacKey);
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
    method = "backup";
  }

  // On *ne* renvoie *pas* le secret ni les codes de secours au client.
  const safeProfile: Record<string, unknown> = { ...profile };
  delete safeProfile.totp_secret;
  delete safeProfile.backup_codes;
  return jsonResponse({ method, profile: safeProfile });
});
