// =============================================================================
// ARENA — Edge Function : export-user-data
// =============================================================================
// Droit RGPD à la portabilité : agrège dans un JSON unique toutes les
// données personnelles du user appelant (profil + matchs + paiements +
// chats + notifs + …) et le retourne en download.
//
// Auth : JWT user requis (verify_jwt=true). On lit `auth.getUser()` et
// jamais un id passé dans le body — un user ne peut exporter que sa
// propre donnée. Super-admin peut techniquement exporter le sien comme
// tout autre user (pas d'endpoint cross-user en V1, ce serait un autre
// flux d'enquête).
//
// Inputs : POST sans body.
// Output : JSON contenant `{ format, exportedAt, userId, profile, matches,
//          competitionRegistrations, payments, payouts, notifications,
//          disputes, streams, chatMessages, antiCheatEvents,
//          reintegrationRequests }`. Headers Content-Disposition pour
//          forcer un download "arena-data-{userId}-{date}.json".
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

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

  // Récupère l'identité depuis le JWT — on n'accepte *jamais* un userId
  // côté body, pour éviter qu'un user puisse exporter celui d'un autre.
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }
  const userId = userData.user.id;

  // Pour la lecture on bypass RLS (service role) — sinon les tables avec
  // policies restrictives (anti_cheat_events, disputes) refuseraient. On
  // filtre *manuellement* par userId à chaque requête, double-checké.
  const service = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Profile — on lit sans le secret TOTP, mais on garde les autres champs
  // (les colonnes de conformité RGPD doivent être visibles à l'export).
  const { data: profile, error: profileErr } = await service
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .maybeSingle();
  if (profileErr || !profile) {
    return jsonResponse({ error: "profile_not_found" }, 404);
  }
  delete (profile as Record<string, unknown>).totp_secret;
  delete (profile as Record<string, unknown>).backup_codes;

  // Pour les matchs, le user peut être player1, player2, home, ou winner.
  // On utilise `or` Supabase pour récupérer en une requête.
  const matchesQ = service
    .from("matches")
    .select("*")
    .or(
      `player1_id.eq.${userId},player2_id.eq.${userId},home_player_id.eq.${userId},winner_id.eq.${userId}`,
    );

  const disputesQ = service
    .from("disputes")
    .select("*")
    .or(`opened_by.eq.${userId},guilty_party_id.eq.${userId}`);

  // Requêtes parallèles (latence cumulée vs séquentielle).
  const [
    registrations,
    matches,
    payments,
    payouts,
    notifications,
    disputes,
    streams,
    chatMessages,
    antiCheatEvents,
    reintegrationRequests,
  ] = await Promise.all([
    service.from("competition_registrations").select("*").eq("player_id", userId),
    matchesQ,
    service.from("payments").select("*").eq("user_id", userId),
    service.from("payouts").select("*").eq("user_id", userId),
    service.from("notifications").select("*").eq("user_id", userId),
    disputesQ,
    service.from("streams").select("*").eq("player_id", userId),
    service.from("chat_messages").select("*").eq("sender_id", userId),
    service.from("anti_cheat_events").select("*").eq("profile_id", userId),
    service.from("reintegration_requests").select("*").eq("user_id", userId),
  ]);

  const bundle = {
    format: "1.0",
    exportedAt: new Date().toISOString(),
    userId,
    profile,
    competitionRegistrations: registrations.data ?? [],
    matches: matches.data ?? [],
    payments: payments.data ?? [],
    payouts: payouts.data ?? [],
    notifications: notifications.data ?? [],
    disputes: disputes.data ?? [],
    streams: streams.data ?? [],
    chatMessages: chatMessages.data ?? [],
    antiCheatEvents: antiCheatEvents.data ?? [],
    reintegrationRequests: reintegrationRequests.data ?? [],
  };

  const filename = `arena-data-${userId}-${
    new Date().toISOString().slice(0, 10)
  }.json`;
  return new Response(JSON.stringify(bundle, null, 2), {
    status: 200,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Content-Disposition": `attachment; filename="${filename}"`,
    },
  });
});
