// =============================================================================
// ARENA — Edge Function : cleanup-streams
// =============================================================================
// Maintenance horaire des streams Agora + des enregistrements stockés :
//
//   1. **Ferme les streams "stale"** — `is_active=true AND ended_at IS
//      NULL` mais le match est en `status='completed'` (admin a clos)
//      OU `started_at < now() - 6h` (le broadcaster a probablement
//      tué l'app sans ack). On flippe `is_active=false`, `is_public=false`,
//      `ended_at=now()` pour que la LiveStreamsPage ne montre plus le
//      flux et que le frontend n'essaye plus de réémettre un token Agora.
//
//   2. **Purge le storage des matchs completed > 30j** — vidéos uploadées
//      (`match-recordings/{matchId}/...`) + screenshots de preuve
//      (`match-proofs/{matchId}/...`). À J+30 les disputes ont eu leur
//      SLA + le client n'a plus besoin de visionner. On efface en bloc
//      par préfixe `{matchId}` pour limiter les list-API calls.
//
// Auth : webhook secret partagé (même que cleanup-deleted-accounts).
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

/// Liste tous les fichiers sous `bucket/{matchId}/...` et les supprime.
/// Récursif sur 1 niveau (convention `{matchId}/{userId}/file.ext`).
async function purgeMatchStorage(
  client: ReturnType<typeof createClient>,
  bucket: string,
  matchId: string,
): Promise<{ deleted: number; error?: string }> {
  // List les sous-dossiers du matchId (généralement `{userId}` ou un
  // niveau direct selon le bucket). On collecte tous les fichiers.
  const { data: rootEntries, error: listErr } = await client.storage
    .from(bucket)
    .list(matchId, { limit: 1000 });
  if (listErr) return { deleted: 0, error: listErr.message };
  if (!rootEntries || rootEntries.length === 0) return { deleted: 0 };

  const paths: string[] = [];
  for (const entry of rootEntries) {
    if (entry.id !== null) {
      // Fichier directement sous {matchId}/
      paths.push(`${matchId}/${entry.name}`);
      continue;
    }
    // Sous-dossier (e.g. {userId}) — liste son contenu.
    const subPrefix = `${matchId}/${entry.name}`;
    const { data: subFiles } = await client.storage
      .from(bucket)
      .list(subPrefix, { limit: 1000 });
    if (!subFiles) continue;
    for (const f of subFiles) {
      if (f.id === null) continue;
      paths.push(`${subPrefix}/${f.name}`);
    }
  }
  if (paths.length === 0) return { deleted: 0 };
  const { error: rmErr } = await client.storage.from(bucket).remove(paths);
  if (rmErr) return { deleted: 0, error: rmErr.message };
  return { deleted: paths.length };
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

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
  const sb = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // ─────────────────────────────────────────────────────────────────
  // 1) Stale streams : actifs mais le match est fini ou l'overlay a
  //    démarré il y a plus de 6h sans envoyer d'ack.
  // ─────────────────────────────────────────────────────────────────
  const sixHoursAgo = new Date(Date.now() - 6 * 60 * 60 * 1000)
    .toISOString();

  // Step 1a — streams dont le match a déjà bouclé.
  const { data: finishedMatchStreams, error: fmsErr } = await sb
    .from("streams")
    .select("id, match_id, matches!inner(status)")
    .eq("is_active", true)
    .is("ended_at", null)
    .eq("matches.status", "completed");

  const staleIds: string[] = [];
  if (fmsErr) {
    // Log mais continue — pas de blocker.
    console.error("finished_match_streams query failed:", fmsErr.message);
  } else if (finishedMatchStreams) {
    for (const s of finishedMatchStreams) staleIds.push(s.id as string);
  }

  // Step 1b — streams dont le started_at est trop ancien (>6h) sans
  // qu'on connaisse le statut du match : couvre le cas "broadcaster
  // a kill l'app sans appeler stop()".
  const { data: ancientStreams, error: ancientErr } = await sb
    .from("streams")
    .select("id")
    .eq("is_active", true)
    .is("ended_at", null)
    .lt("started_at", sixHoursAgo);
  if (ancientErr) {
    console.error("ancient_streams query failed:", ancientErr.message);
  } else if (ancientStreams) {
    for (const s of ancientStreams) {
      if (!staleIds.includes(s.id as string)) staleIds.push(s.id as string);
    }
  }

  let streamsClosed = 0;
  if (staleIds.length > 0) {
    const { error: updErr, count } = await sb
      .from("streams")
      .update({
        is_active: false,
        is_public: false,
        ended_at: new Date().toISOString(),
      }, { count: "exact" })
      .in("id", staleIds);
    if (updErr) {
      return jsonResponse(
        { error: "stale_stream_close_failed", detail: updErr.message },
        500,
      );
    }
    streamsClosed = count ?? staleIds.length;
  }

  // ─────────────────────────────────────────────────────────────────
  // 2) Purge storage des matchs completed depuis > 30 jours.
  //    On bat les matchs par batch — on ne supprime *pas* les rows
  //    `matches` ou `streams` (on garde l'historique pour les stats
  //    joueur), seulement les blobs.
  // ─────────────────────────────────────────────────────────────────
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    .toISOString();

  const { data: oldMatches, error: omErr } = await sb
    .from("matches")
    .select("id")
    .eq("status", "completed")
    .lt("finished_at", thirtyDaysAgo)
    .limit(50); // batch ; cron tourne chaque heure → catch-up rapide
  if (omErr) {
    return jsonResponse(
      { error: "old_matches_lookup_failed", detail: omErr.message },
      500,
    );
  }

  let recordingsDeleted = 0;
  let proofsDeleted = 0;
  const purgeErrors: Array<{ matchId: string; bucket: string; msg: string }>
    = [];

  for (const m of oldMatches ?? []) {
    const matchId = m.id as string;
    const r1 = await purgeMatchStorage(sb, "match-recordings", matchId);
    recordingsDeleted += r1.deleted;
    if (r1.error) {
      purgeErrors.push({ matchId, bucket: "match-recordings", msg: r1.error });
    }
    const r2 = await purgeMatchStorage(sb, "match-proofs", matchId);
    proofsDeleted += r2.deleted;
    if (r2.error) {
      purgeErrors.push({ matchId, bucket: "match-proofs", msg: r2.error });
    }
    // Reset `streams.url` pour ce match : sans le blob c'est un lien
    // mort. On laisse le row pour l'historique (qui a streamé quoi)
    // mais on évite de servir un 404 si le front essaye d'ouvrir le
    // lien (`createSignedUrl` retournerait 400 sur la prochaine req).
    await sb.from("streams").update({ url: null }).eq("match_id", matchId);
  }

  return jsonResponse({
    streamsClosed,
    purgedMatches: (oldMatches ?? []).length,
    recordingsDeleted,
    proofsDeleted,
    purgeErrors,
  });
});
