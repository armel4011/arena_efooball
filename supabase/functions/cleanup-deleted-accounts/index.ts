// =============================================================================
// ARENA — Edge Function : cleanup-deleted-accounts
// =============================================================================
// Job RGPD : ANONYMISE les comptes soft-deleted depuis plus de 30 jours.
//
// ⚠️ On n'appelle PLUS `auth.admin.deleteUser` (fix audit C-1) : les FK
// `ON DELETE RESTRICT` de payments/payouts/competition_registrations bloquaient
// la suppression du profile (cascade depuis auth.users) pour tout utilisateur
// ayant transigé → le compte restait en limbe indéfiniment. Décision produit :
// anonymiser en place et CONSERVER les pièces comptables (obligation légale).
//
// Workflow par compte :
//   1. Purge les médias storage personnels (match-proofs/recordings).
//   2. `anonymize_deleted_account(id)` (RPC service_role) : scrub les PII du
//      profile + pose `anonymized_at`.
//   3. Scrub l'identité côté auth.users (email anonymisé, métadonnées vidées,
//      mot de passe aléatoire, login banni) — on GARDE la ligne car
//      `profiles.id REFERENCES auth.users` et les FK compta y pendent.
//
// Idempotence : filtre `anonymized_at IS NULL` → un compte déjà anonymisé
// n'est jamais retraité.
//
// Auth : webhook secret partagé (même secret que dispatch_notification).
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import type { ServiceClient } from "../_shared/db.ts";

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

/// Listing récursif des objets dans un bucket sous un préfixe arbitraire.
/// Supabase ne fait pas de glob `*/userId/*` — on doit lister par dossier
/// puis filtrer. On se limite à 1000 entrées par appel (max API) ; pour
/// V1.0 c'est largement assez (< 100 utilisateurs supprimés / mois
/// attendus).
async function listAllUnderUser(
  client: ServiceClient,
  bucket: string,
  userId: string,
): Promise<string[]> {
  const out: string[] = [];
  const { data: roots, error: rootErr } = await client.storage
    .from(bucket)
    .list("", { limit: 1000 });
  if (rootErr || !roots) return out;

  for (const root of roots) {
    if (root.id !== null) continue;
    const prefix = `${root.name}/${userId}`;
    const { data: files } = await client.storage
      .from(bucket)
      .list(prefix, { limit: 1000 });
    if (!files) continue;
    for (const f of files) {
      if (f.id === null) continue;
      out.push(`${prefix}/${f.name}`);
    }
  }
  return out;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  // Auth : shared bearer entre pg_cron et l'EF (même secret que
  // dispatch_notification). On bloque même si verify_jwt=false côté
  // platform, pour éviter qu'un curl anonyme déclenche le job.
  const expected = `Bearer ${Deno.env.get("WEBHOOK_SECRET") ?? ""}`;
  const got = req.headers.get("authorization") ?? "";
  if (expected.length < "Bearer ".length + 8 || got !== expected) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  const service = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Fenêtre RGPD : anonymisation 30 jours après le soft-delete. Le user a eu
  // cette période pour annuler en se reconnectant.
  const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    .toISOString();

  const { data: candidates, error: queryErr } = await service
    .from("profiles")
    .select("id, deleted_at")
    .lt("deleted_at", cutoff)
    .eq("is_active", false)
    .is("anonymized_at", null) // idempotence : pas de retraitement.
    .limit(100);
  if (queryErr) {
    return jsonResponse(
      { error: "candidates_lookup_failed", detail: queryErr.message },
      500,
    );
  }
  if (!candidates || candidates.length === 0) {
    return jsonResponse({ processed: 0, anonymized: 0, errors: [] });
  }

  const errors: Array<{ id: string; step: string; message: string }> = [];
  let anonymized = 0;

  for (const profile of candidates) {
    const userId = profile.id as string;
    let failed = false;

    // 1. Purge des médias personnels (preuves / enregistrements de match).
    for (const bucket of ["match-recordings", "match-proofs"]) {
      try {
        const paths = await listAllUnderUser(service, bucket, userId);
        if (paths.length > 0) {
          const { error: rmErr } = await service.storage
            .from(bucket)
            .remove(paths);
          if (rmErr) {
            errors.push({ id: userId, step: `storage:${bucket}`, message: rmErr.message });
          }
        }
      } catch (e) {
        errors.push({
          id: userId,
          step: `storage:${bucket}`,
          message: e instanceof Error ? e.message : String(e),
        });
      }
    }

    // 2. Scrub des PII du profile + pose anonymized_at (RPC service_role).
    //    Les lignes compta (payments/payouts) survivent anonymisées.
    const { error: rpcErr } = await service.rpc("anonymize_deleted_account", {
      p_user_id: userId,
    });
    if (rpcErr) {
      errors.push({ id: userId, step: "anonymize_rpc", message: rpcErr.message });
      failed = true;
    }

    // 3. Scrub l'identité auth.users (on garde la ligne, on retire les PII et
    //    on désactive le login). On ne supprime PAS l'utilisateur auth car
    //    profiles.id y est rattaché et porte les FK comptables.
    const { error: authErr } = await service.auth.admin.updateUserById(userId, {
      email: `${userId}@deleted.invalid`,
      password: crypto.randomUUID() + crypto.randomUUID(),
      user_metadata: {},
      app_metadata: {},
      ban_duration: "876000h", // ~100 ans : login définitivement désactivé.
    });
    if (authErr) {
      const msg = authErr.message ?? "";
      // 404 = déjà supprimé manuellement → on ignore (le profile reste géré).
      if (!/not found/i.test(msg) && !/404/.test(msg)) {
        errors.push({ id: userId, step: "auth.updateUserById", message: msg });
        failed = true;
      }
    }

    if (!failed) anonymized++;
  }

  return jsonResponse({ processed: candidates.length, anonymized, errors, cutoff });
});
