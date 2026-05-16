// =============================================================================
// ARENA — Edge Function : setup-totp
// =============================================================================
// Génère un secret TOTP pour l'admin connecté et le stocke côté serveur.
// L'app reçoit l'URI `otpauth://...` (pour QR code) + le secret base32
// (pour saisie manuelle dans Google Authenticator/Authy/1Password).
//
// Le secret n'est *pas* marqué actif tant que `verify-totp-setup` n'a pas
// reçu un premier code valide — l'admin peut donc relancer cette EF
// autant qu'il veut tant qu'il n'a pas confirmé (le précédent secret est
// écrasé).
//
// Auth : JWT Supabase. Refuse si rôle ≠ admin/super_admin.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { generateSecretBase32, otpauthUri } from "../_shared/totp.ts";

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

  // Client "user" : utilisé uniquement pour résoudre l'identité depuis le JWT.
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }
  const user = userData.user;

  // Client "service" : lit/écrit `profiles.totp_secret` (champ jamais
  // exposé côté client). On passe par service role pour court-circuiter
  // RLS et garder la colonne strictement server-only.
  const service = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: profile, error: profileErr } = await service
    .from("profiles")
    .select("id, role, email, username, totp_enabled")
    .eq("id", user.id)
    .maybeSingle();
  if (profileErr || !profile) {
    return jsonResponse({ error: "profile_not_found" }, 404);
  }
  if (profile.role !== "admin" && profile.role !== "super_admin") {
    return jsonResponse({ error: "forbidden_role" }, 403);
  }
  if (profile.totp_enabled) {
    // Le re-setup d'un TOTP déjà actif passe par une procédure dédiée
    // (reset par super-admin ou par backup code). Cette EF est l'enroll
    // initial uniquement.
    return jsonResponse({ error: "totp_already_enabled" }, 409);
  }

  const secret = generateSecretBase32();
  const uri = otpauthUri({
    issuer: "Arena",
    accountName: profile.email ?? profile.username ?? user.id,
    secret,
  });

  // On stocke le secret *avant* la confirmation : la colonne reste
  // `totp_enabled = false` pour signaler "pas encore vérifié". Quand
  // `verify-totp-setup` valide le premier code, on flip à true.
  const { error: updateErr } = await service
    .from("profiles")
    .update({ totp_secret: secret })
    .eq("id", user.id);
  if (updateErr) {
    return jsonResponse(
      { error: "secret_persist_failed", detail: updateErr.message },
      500,
    );
  }

  return jsonResponse({
    otpauthUri: uri,
    secret,
  });
});
