// =============================================================================
// ARENA — Edge Function: anticheat-commit
// =============================================================================
// Phase 3 du système anti-triche (« commitment hash »). À la FIN d'un match, le
// client transcode un proxy 360p de sa capture, en calcule le SHA-256 et
// l'ENGAGE ici. On ne reçoit que quelques octets (le hash + métadonnées) — donc
// ça passe en 2G, et la soumission de score peut être débloquée immédiatement
// sur cet engagement, JAMAIS sur l'upload vidéo lourd (qui n'a lieu que sur
// litige, à la demande de l'admin — cf. proof-verify).
//
// ⚠️ LIMITE (P1 #4, cf. docs/anticheat-threat-model.md) : le hash est calculé
// sur un device NON FIABLE — un APK repackagé peut engager le hash d'une vidéo
// retouchée. Le commitment est donc une DÉTERRENCE forte (write-once + horodaté
// serveur), pas une preuve infalsifiable. La preuve infalsifiable = tier egress
// (capture serveur LiveKit). Risque résiduel du tier natif assumé et documenté.
//
// Pourquoi côté serveur :
//   * `proof_committed_at` est estampillé par le SERVEUR (now()) → un client ne
//     peut pas antidater son engagement avec son horloge locale.
//   * WRITE-ONCE : une fois un hash engagé pour (match, joueur), il est figé.
//     Un re-commit avec le MÊME hash est idempotent (retries réseau OK) ; un
//     re-commit avec un hash DIFFÉRENT est refusé (409) — sinon un tricheur
//     pourrait, après coup, ré-engager le hash d'une vidéo trafiquée.
//
// Entrées (POST JSON) — DEUX modes :
//   A) COMMIT : { matchId, proofSha256, proofBytes, proofDurationSeconds? }
//      proofDurationSeconds est OPTIONNEL (métadonnée litige, coûteuse à calculer
//      côté client sur un gros MP4) — si absent/null, la colonne reste null.
//      Marque capture_status='committed'.
//   B) INDISPONIBLE (P1 #5) : { matchId, captureStatus: 'unavailable', captureNote? }
//      Le client n'a PAS pu capturer (permission refusée / échec device). On
//      matérialise la TRACE (capture_status='unavailable' + raison) pour que
//      l'admin distingue « joueur ne pouvait pas filmer » d'une capture
//      silencieusement absente. N'écrase JAMAIS un commitment déjà engagé.
//
// Sorties :
//   { ok: true, streamId, committedAt?, captureStatus?, idempotent? }
//
// Autorisation :
//   * JWT Supabase valide (Authorization: Bearer …).
//   * L'appelant doit être un des deux joueurs assis du match.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.108.2";
import { safeDetail } from "../_shared/errors.ts";
import {
  isPlayerOfMatch,
  isPositiveInt,
  normalizeSha256,
} from "../_shared/anticheat.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

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

  // Client porté par la session de l'appelant (vérifie le JWT).
  const asUser = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userResult, error: userErr } = await asUser.auth.getUser();
  if (userErr || !userResult.user) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }
  const userId = userResult.user.id;

  let body: {
    matchId?: unknown;
    proofSha256?: unknown;
    proofBytes?: unknown;
    proofDurationSeconds?: unknown;
    captureStatus?: unknown;
    captureNote?: unknown;
  };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "bad_json" }, 400);
  }

  const matchId = typeof body.matchId === "string" ? body.matchId : null;
  if (!matchId) return jsonResponse({ error: "matchId_required" }, 400);

  // Mode B — rapport « capture indisponible » (P1 #5). On ne valide PAS de hash.
  const isUnavailable = body.captureStatus === "unavailable";

  const sha256 = normalizeSha256(body.proofSha256);
  const bytes = body.proofBytes;
  // Durée optionnelle : null/absent accepté ; si fourni, doit être > 0.
  const durationRaw = body.proofDurationSeconds;
  const duration = durationRaw === undefined || durationRaw === null
    ? null
    : durationRaw;
  // Raison libre du mode B, bornée pour éviter tout abus de stockage.
  const captureNote = typeof body.captureNote === "string"
    ? body.captureNote.trim().slice(0, 200) || null
    : null;

  if (!isUnavailable) {
    if (!sha256) return jsonResponse({ error: "invalid_sha256" }, 400);
    if (!isPositiveInt(bytes)) {
      return jsonResponse({ error: "invalid_bytes" }, 400);
    }
    if (duration !== null && !isPositiveInt(duration)) {
      return jsonResponse({ error: "invalid_duration" }, 400);
    }
  }

  // Écritures via service-role : estampille serveur + write-once, indépendamment
  // de la RLS du joueur sur `streams`.
  const sb = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // L'appelant doit être un des deux joueurs du match.
  const { data: match, error: matchErr } = await sb
    .from("matches")
    .select("id, player1_id, player2_id")
    .eq("id", matchId)
    .maybeSingle();
  if (matchErr) {
    return jsonResponse(
      { error: "match_lookup_failed", detail: safeDetail(matchErr.message, "anticheat-commit") },
      500,
    );
  }
  if (!match) return jsonResponse({ error: "match_not_found" }, 404);
  if (!isPlayerOfMatch(match, userId)) {
    return jsonResponse({ error: "not_a_player" }, 403);
  }

  // Ligne `streams` du proxy natif de CE joueur sur CE match. Le recorder natif
  // ouvre déjà une session (provider native_recorder) au début du match ; on s'y
  // rattache. À défaut (capture livekit-only, ou session jamais ouverte), on en
  // crée une — le commit est le plancher de preuve, il ne dépend pas du provider.
  const { data: existing, error: selErr } = await sb
    .from("streams")
    .select("id, proof_sha256, proof_committed_at, capture_status")
    .eq("match_id", matchId)
    .eq("player_id", userId)
    .eq("provider", "native_recorder")
    .order("started_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (selErr) {
    return jsonResponse(
      { error: "stream_lookup_failed", detail: safeDetail(selErr.message, "anticheat-commit") },
      500,
    );
  }

  // ─── Mode B : rapport « capture indisponible » ────────────────────────────
  // Trace-seule. N'écrase JAMAIS un commitment déjà engagé (le commit est un
  // signal plus fort). Idempotent : re-rapporter unavailable est un no-op.
  if (isUnavailable) {
    if (existing?.proof_sha256) {
      // Déjà committé → on ignore le rapport d'indisponibilité (incohérent).
      return jsonResponse({
        ok: true,
        streamId: existing.id,
        captureStatus: "committed",
        idempotent: true,
      });
    }
    const trace = { capture_status: "unavailable", capture_note: captureNote };
    if (existing) {
      const { error: updErr } = await sb
        .from("streams").update(trace).eq("id", existing.id);
      if (updErr) {
        return jsonResponse(
          { error: "commit_failed", detail: safeDetail(updErr.message, "anticheat-commit") },
          500,
        );
      }
      return jsonResponse({
        ok: true,
        streamId: existing.id,
        captureStatus: "unavailable",
      });
    }
    const { data: insUnavail, error: insUnavailErr } = await sb
      .from("streams")
      .insert({
        match_id: matchId,
        player_id: userId,
        provider: "native_recorder",
        is_public: false,
        is_active: false,
        ...trace,
      })
      .select("id")
      .single();
    if (insUnavailErr) {
      return jsonResponse(
        { error: "commit_failed", detail: safeDetail(insUnavailErr.message, "anticheat-commit") },
        500,
      );
    }
    return jsonResponse({
      ok: true,
      streamId: insUnavail.id,
      captureStatus: "unavailable",
    });
  }

  const committedAt = new Date().toISOString();

  // WRITE-ONCE : un hash déjà engagé est figé.
  if (existing?.proof_sha256) {
    if (existing.proof_sha256 === sha256) {
      // Même engagement → idempotent (retry réseau). On NE touche pas
      // proof_committed_at (l'instant d'origine fait foi).
      return jsonResponse({
        ok: true,
        streamId: existing.id,
        committedAt: existing.proof_committed_at,
        idempotent: true,
      });
    }
    return jsonResponse({ error: "already_committed" }, 409);
  }

  const patch = {
    proof_sha256: sha256,
    proof_bytes: bytes,
    proof_duration_seconds: duration,
    proof_committed_at: committedAt,
    capture_status: "committed",
  };

  if (existing) {
    const { error: updErr } = await sb
      .from("streams")
      .update(patch)
      .eq("id", existing.id);
    if (updErr) {
      return jsonResponse(
        { error: "commit_failed", detail: safeDetail(updErr.message, "anticheat-commit") },
        500,
      );
    }
    return jsonResponse({ ok: true, streamId: existing.id, committedAt });
  }

  const { data: inserted, error: insErr } = await sb
    .from("streams")
    .insert({
      match_id: matchId,
      player_id: userId,
      provider: "native_recorder",
      is_public: false,
      is_active: false,
      ...patch,
    })
    .select("id")
    .single();
  if (insErr) {
    return jsonResponse(
      { error: "commit_failed", detail: safeDetail(insErr.message, "anticheat-commit") },
      500,
    );
  }

  return jsonResponse({ ok: true, streamId: inserted.id, committedAt });
});
