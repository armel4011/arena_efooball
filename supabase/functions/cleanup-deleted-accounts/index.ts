// =============================================================================
// ARENA — Edge Function : cleanup-deleted-accounts
// =============================================================================
// Job de purge RGPD : supprime physiquement les comptes soft-deleted depuis
// plus de 30 jours.
//
// Workflow :
//   1. Cherche `profiles` avec `deleted_at < now() - 30d` AND `is_active = false`.
//   2. Pour chaque user_id :
//        a. Supprime les objets storage : `match-proofs/*/{user_id}/*`
//           + `match-recordings/*/{user_id}/*`.
//        b. Appelle `auth.admin.deleteUser(id)` → cascade FK supprime le
//           profile + matches/payments/notifications/etc.
//   3. Retourne un résumé { processed, deleted, errors }.
//
// Auth : webhook secret partagé (réutilisé du flux notifications). Pas de
// JWT user, c'est un job cron — `verify_jwt = false`.
//
// Idempotence : si une exécution échoue partiellement, la prochaine reprend
// le même set (filtre toujours sur `deleted_at < 30d ago`). Pas de race
// condition critique — au pire on tente une 2e fois `deleteUser` sur un
// id déjà supprimé, Supabase renvoie 404 qu'on traite comme succès.
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

/// Listing récursif des objets dans un bucket sous un préfixe arbitraire.
/// Supabase ne fait pas de glob `*/userId/*` — on doit lister par dossier
/// puis filtrer. On se limite à 1000 entrées par appel (max API) ; pour
/// V1.0 c'est largement assez (< 100 utilisateurs supprimés / mois
/// attendus).
async function listAllUnderUser(
  client: ReturnType<typeof createClient>,
  bucket: string,
  userId: string,
): Promise<string[]> {
  // Les chemins sont {matchId}/{userId}/file.ext — donc on liste d'abord
  // les "dossiers" (matchId) à la racine, puis pour chacun on regarde
  // si le sous-dossier userId existe.
  const out: string[] = [];
  const { data: roots, error: rootErr } = await client.storage
    .from(bucket)
    .list("", { limit: 1000 });
  if (rootErr || !roots) return out;

  for (const root of roots) {
    // `list("")` retourne des "folders" comme entries avec id=null. Si
    // c'est un fichier à la racine on l'ignore (pas notre convention).
    if (root.id !== null) continue;
    const prefix = `${root.name}/${userId}`;
    const { data: files } = await client.storage
      .from(bucket)
      .list(prefix, { limit: 1000 });
    if (!files) continue;
    for (const f of files) {
      // Seulement les fichiers (id non null).
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
  // platform, pour éviter qu'un curl anonyme déclenche le purge.
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

  // Fenêtre RGPD : suppression définitive 30 jours après le soft-delete.
  // Le user a eu cette période pour annuler en se reconnectant.
  const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    .toISOString();

  const { data: candidates, error: queryErr } = await service
    .from("profiles")
    .select("id, email, deleted_at")
    .lt("deleted_at", cutoff)
    .eq("is_active", false)
    .limit(100); // batch — si > 100 / jour, la prochaine itération prend la suite.
  if (queryErr) {
    return jsonResponse(
      { error: "candidates_lookup_failed", detail: queryErr.message },
      500,
    );
  }
  if (!candidates || candidates.length === 0) {
    return jsonResponse({ processed: 0, deleted: 0, errors: [] });
  }

  const errors: Array<{ id: string; step: string; message: string }> = [];
  let deleted = 0;

  for (const profile of candidates) {
    const userId = profile.id as string;

    // 1. Purge storage. On itère sur les buckets connus de la phase 8.
    //    Les buckets sont privés — service role peut les vider.
    for (const bucket of ["match-recordings", "match-proofs"]) {
      try {
        const paths = await listAllUnderUser(service, bucket, userId);
        if (paths.length > 0) {
          const { error: rmErr } = await service.storage
            .from(bucket)
            .remove(paths);
          if (rmErr) {
            errors.push({
              id: userId,
              step: `storage:${bucket}`,
              message: rmErr.message,
            });
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

    // 2. Supprime auth.users — la FK `profiles.id REFERENCES auth.users
    //    ON DELETE CASCADE` détruit le profile, et les FK des tables
    //    métier (matches, payments, notifications, ...) propagent.
    //    Les tables avec FK `ON DELETE SET NULL` (ex. audit_log.actor_id)
    //    conservent les rows en NULL pour préserver l'historique métier
    //    sans exposer l'identité — comportement attendu en RGPD.
    const { error: delErr } = await service.auth.admin.deleteUser(userId);
    if (delErr) {
      // 404 = déjà supprimé manuellement (race ou cleanup précédent
      // partiel). On considère ça comme un succès.
      const msg = delErr.message ?? "";
      if (!/not found/i.test(msg) && !/404/.test(msg)) {
        errors.push({
          id: userId,
          step: "auth.admin.deleteUser",
          message: msg,
        });
        continue;
      }
    }
    deleted++;
  }

  return jsonResponse({
    processed: candidates.length,
    deleted,
    errors,
    cutoff,
  });
});
