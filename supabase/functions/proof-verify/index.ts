// =============================================================================
// ARENA — Edge Function: proof-verify
// =============================================================================
// Phase 3 anti-triche, second temps. Après qu'un admin a RÉCLAMÉ la vidéo sur un
// litige (cf. RPC admin_claim_proof) et que le joueur a uploadé son proxy 360p
// dans le bucket `match-recordings`, le client appelle cette fonction. Le SERVEUR
// re-hashe l'objet stocké et compare au commitment engagé à la fin du match
// (`streams.proof_sha256`, cf. anticheat-commit) :
//
//   * hash IDENTIQUE  → `proof_hash_verified = true`  : preuve infalsifiable,
//     le fichier livré est bien celui engagé. Le joueur est couvert.
//   * hash DIFFÉRENT  → `proof_hash_verified = false` : le fichier a été modifié
//     entre l'engagement et la livraison → charge contre le joueur (badge
//     « mismatch » côté admin).
//
// La vérification DOIT être serveur : si on faisait confiance au hash recalculé
// par le client, le commitment ne prouverait plus rien.
//
// Entrées (POST JSON) :
//   { streamId, objectPath }      // objectPath = clé uploadée dans le bucket
//
// Sorties :
//   { ok: true, verified: boolean, idempotent? }
//
// Autorisation :
//   * JWT Supabase valide ; l'appelant doit être LE joueur propriétaire de la
//     ligne `streams` (player_id). objectPath doit appartenir à son dossier.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.108.2";
import { safeDetail } from "../_shared/errors.ts";
import { objectPathBelongsTo } from "../_shared/anticheat.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const BUCKET = "match-recordings";

// Garde-fou mémoire : le proxy 360p est censé être petit (~50 Mo pour 25 min).
// On hashe EN MÉMOIRE (Web Crypto ne streame pas) : le Blob téléchargé + son
// arrayBuffer coexistent → ~2× la taille. Une Edge Function plafonne à ~256 Mo,
// donc 200 Mo faisait OOM (l'isolate était tué au lieu de renvoyer 413). On borne
// à 64 Mo (marge confortable sur le proxy 360p ciblé) ; au-delà → 413 et l'admin
// bascule en revue manuelle (le commitment reste engagé). Audit 2026-07-09 P2.
const MAX_VERIFY_BYTES = 64 * 1024 * 1024;

// Rétention prolongée d'une pièce de litige uploadée à la demande (vs J+1 des
// captures de routine purgées par cleanup-streams).
const DISPUTE_RETENTION_DAYS = 30;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** SHA-256 hex (minuscules) d'un buffer. */
async function sha256Hex(buf: ArrayBuffer): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", buf);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SERVICE_KEY) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }

  const asUser = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userResult, error: userErr } = await asUser.auth.getUser();
  if (userErr || !userResult.user) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }
  const userId = userResult.user.id;

  let body: { streamId?: unknown; objectPath?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "bad_json" }, 400);
  }
  const streamId = typeof body.streamId === "string" ? body.streamId : null;
  const objectPath = typeof body.objectPath === "string" ? body.objectPath : null;
  if (!streamId) return jsonResponse({ error: "streamId_required" }, 400);
  if (!objectPath) return jsonResponse({ error: "objectPath_required" }, 400);

  const sb = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: stream, error: selErr } = await sb
    .from("streams")
    .select(
      "id, match_id, player_id, proof_sha256, proof_claimed_at, proof_uploaded_at, proof_hash_verified",
    )
    .eq("id", streamId)
    .maybeSingle();
  if (selErr) {
    return jsonResponse(
      { error: "stream_lookup_failed", detail: safeDetail(selErr.message, "proof-verify") },
      500,
    );
  }
  if (!stream) return jsonResponse({ error: "stream_not_found" }, 404);

  // Seul le joueur propriétaire livre/vérifie sa propre preuve.
  if (stream.player_id !== userId) {
    return jsonResponse({ error: "not_owner" }, 403);
  }
  if (!stream.proof_sha256) {
    return jsonResponse({ error: "no_commitment" }, 409);
  }
  // Ne vérifier QUE ce qu'un admin a réellement réclamé (réduit la surface de
  // re-hash concurrent : une preuve non réclamée n'a pas à être hashée à la
  // demande). Audit 2026-07-09 P3.
  if (!stream.proof_claimed_at) {
    return jsonResponse({ error: "not_claimed" }, 409);
  }
  // Anti-traversée : l'objet doit être dans le dossier du (match, joueur).
  if (!objectPathBelongsTo(objectPath, stream.match_id, stream.player_id)) {
    return jsonResponse({ error: "object_path_forbidden" }, 403);
  }

  // Idempotence : déjà vérifié (retry réseau après une réponse perdue).
  if (stream.proof_uploaded_at && stream.proof_hash_verified !== null) {
    return jsonResponse({
      ok: true,
      verified: stream.proof_hash_verified,
      idempotent: true,
    });
  }

  // Télécharger l'objet uploadé et le re-hasher.
  const { data: blob, error: dlErr } = await sb.storage
    .from(BUCKET)
    .download(objectPath);
  if (dlErr || !blob) {
    return jsonResponse(
      { error: "object_not_found", detail: safeDetail(dlErr?.message, "proof-verify") },
      404,
    );
  }
  if (blob.size > MAX_VERIFY_BYTES) {
    // Trop volumineux pour un hash en mémoire (Web Crypto ne streame pas).
    // On SUPPRIME l'objet : sinon il reste orphelin dans le bucket (jamais
    // vérifié → pas d'expires_at posé → jamais purgé par cleanup-streams).
    // L'admin bascule en revue manuelle (le commitment reste engagé).
    const { error: rmErr } = await sb.storage.from(BUCKET).remove([objectPath]);
    if (rmErr) {
      console.error("oversized_proof_cleanup_failed:", rmErr.message);
    }
    return jsonResponse({ error: "object_too_large" }, 413);
  }

  const verified = (await sha256Hex(await blob.arrayBuffer())) ===
    stream.proof_sha256;

  const expiresAt = new Date(
    Date.now() + DISPUTE_RETENTION_DAYS * 24 * 60 * 60 * 1000,
  ).toISOString();

  const { error: updErr } = await sb
    .from("streams")
    .update({
      storage_path: objectPath,
      proof_uploaded_at: new Date().toISOString(),
      proof_hash_verified: verified,
      expires_at: expiresAt,
    })
    .eq("id", streamId);
  if (updErr) {
    return jsonResponse(
      { error: "verdict_persist_failed", detail: safeDetail(updErr.message, "proof-verify") },
      500,
    );
  }

  return jsonResponse({ ok: true, verified });
});
