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
//   2. **Purge les ENREGISTREMENTS anti-triche à J+1** — vidéos
//      `match-recordings/{matchId}/...` (recorder natif + LiveKit Track
//      Egress). On ne les garde qu'UN JOUR après la fin de la capture,
//      SAUF si un litige est ouvert sur le match (on conserve alors la
//      preuve). On efface les blobs et on remet `streams.url`/`storage_path`
//      à null (l'historique de la row reste).
//
//   3. **Purge les PREUVES utilisateur à J+30** — screenshots/vidéos de
//      litige `match-proofs/{matchId}/...` (matchs completed > 30j). Pièces
//      de litige, conservées plus longtemps que les captures anti-triche.
//
// Auth : webhook secret partagé (même que cleanup-deleted-accounts).
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.108.2";
import type { ServiceClient } from "../_shared/db.ts";
import { timingSafeEqual } from "../_shared/timing.ts";
import { safeDetail } from "../_shared/errors.ts";

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
  client: ServiceClient,
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
  if (expected.length < "Bearer ".length + 8 || !timingSafeEqual(got, expected)) {
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
        { error: "stale_stream_close_failed", detail: safeDetail(updErr.message, "cleanup-streams") },
        500,
      );
    }
    streamsClosed = count ?? staleIds.length;
  }

  const purgeErrors: Array<{ matchId: string; bucket: string; msg: string }>
    = [];

  // ─────────────────────────────────────────────────────────────────
  // 2) Enregistrements anti-triche (match-recordings) — rétention J+1,
  //    sauf si un litige est ouvert sur le match.
  // ─────────────────────────────────────────────────────────────────
  const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  // Statuts de litige « actif » (non résolus) — cf. disputes_status_check.
  const OPEN_DISPUTE_STATUS = ["open", "bot_review", "admin_review"];

  // Candidats : captures anti-triche (is_public=false) terminées depuis plus
  // d'un jour et dont un blob est encore référencé.
  const { data: recRows, error: recErr } = await sb
    .from("streams")
    .select("match_id")
    .eq("is_public", false)
    .eq("is_active", false)
    .lt("ended_at", oneDayAgo)
    .or("storage_path.not.is.null,url.not.is.null")
    .limit(500);
  if (recErr) {
    return jsonResponse(
      { error: "recordings_lookup_failed", detail: safeDetail(recErr.message, "cleanup-streams") },
      500,
    );
  }
  const candidateMatchIds = [
    ...new Set((recRows ?? []).map((r) => r.match_id as string)),
  ];

  // Exclure les matchs avec un litige ouvert (on garde la preuve).
  let recordingMatchIds = candidateMatchIds;
  if (candidateMatchIds.length > 0) {
    const { data: openDisputes, error: dispErr } = await sb
      .from("disputes")
      .select("match_id")
      .in("match_id", candidateMatchIds)
      .in("status", OPEN_DISPUTE_STATUS);
    if (dispErr) {
      console.error("open_disputes query failed:", dispErr.message);
    } else {
      const blocked = new Set(
        (openDisputes ?? []).map((d) => d.match_id as string),
      );
      recordingMatchIds = candidateMatchIds.filter((id) => !blocked.has(id));
    }
  }
  recordingMatchIds = recordingMatchIds.slice(0, 50); // batch horaire

  let recordingsDeleted = 0;
  for (const matchId of recordingMatchIds) {
    const r1 = await purgeMatchStorage(sb, "match-recordings", matchId);
    recordingsDeleted += r1.deleted;
    if (r1.error) {
      purgeErrors.push({ matchId, bucket: "match-recordings", msg: r1.error });
    }
    // Reset url/storage_path des captures purgées (lien mort sinon). On ne
    // touche qu'aux rows anti-triche déjà terminées depuis > 1j.
    await sb
      .from("streams")
      .update({ url: null, storage_path: null })
      .eq("match_id", matchId)
      .eq("is_public", false)
      .lt("ended_at", oneDayAgo);
  }

  // ─────────────────────────────────────────────────────────────────
  // 3) Preuves utilisateur (match-proofs) — rétention J+30 (matchs
  //    completed). Pièces de litige, gardées plus longtemps.
  // ─────────────────────────────────────────────────────────────────
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    .toISOString();

  const { data: oldMatches, error: omErr } = await sb
    .from("matches")
    .select("id")
    .eq("status", "completed")
    .lt("finished_at", thirtyDaysAgo)
    .limit(50);
  if (omErr) {
    return jsonResponse(
      { error: "old_matches_lookup_failed", detail: safeDetail(omErr.message, "cleanup-streams") },
      500,
    );
  }

  let proofsDeleted = 0;
  for (const m of oldMatches ?? []) {
    const matchId = m.id as string;
    const r2 = await purgeMatchStorage(sb, "match-proofs", matchId);
    proofsDeleted += r2.deleted;
    if (r2.error) {
      purgeErrors.push({ matchId, bucket: "match-proofs", msg: r2.error });
    }
  }

  return jsonResponse({
    streamsClosed,
    recordingMatchesPurged: recordingMatchIds.length,
    recordingsDeleted,
    proofsPurgedMatches: (oldMatches ?? []).length,
    proofsDeleted,
    purgeErrors,
  });
});
