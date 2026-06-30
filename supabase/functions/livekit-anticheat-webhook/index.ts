// =============================================================================
// ARENA — Edge Function: livekit-anticheat-webhook
// =============================================================================
// Enregistrement anti-triche via LiveKit Track Egress (système DUAL).
//
// LiveKit Cloud appelle cette fonction (webhook projet) à chaque événement de
// room. On démarre/clôture l'Egress côté SERVEUR — aucun client à coordonner,
// ça survit aux déconnexions joueur :
//
//   * `track_published` (piste VIDÉO) → démarre 1 Track Egress qui écrit la
//     piste dans Supabase Storage (bucket `match-recordings`, endpoint S3),
//     puis upsert une ligne `streams` (provider=livekit_track_egress).
//     → TIERING (P2) : seuls les matchs en tier `livekit` sont egressés, et
//       pour ceux-là UN SEUL joueur (`recorded_player_id` du plan, tiré au
//       hasard côté serveur) ⇒ 1 egress / match (au lieu de 2). Réduit le
//       nombre d'egress concurrents = plus de matchs simultanés en compétition.
//
//   * `egress_ended` → clôture la ligne `streams` (ended_at, expires_at J+30,
//     is_active=false) et ré-aligne `storage_path` sur le nom de fichier
//     réellement écrit (le conteneur dépend du codec : vidéo WebRTC → .webm).
//
// Auth : le webhook LiveKit est signé (JWT dans l'en-tête Authorization),
// vérifié par WebhookReceiver(API_KEY, API_SECRET). verify_jwt=false côté
// gateway (ce n'est pas un JWT Supabase). Écritures via service-role.
//
// ⚠️ Secrets (LIVEKIT_API_SECRET, clés S3) côté serveur uniquement.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.108.2";
import {
  DirectFileOutput,
  EgressClient,
  RoomServiceClient,
  S3Upload,
  TrackType,
  WebhookReceiver,
} from "npm:livekit-server-sdk@2.9.0";
import { safeDetail } from "../_shared/errors.ts";
import type { ServiceClient } from "../_shared/db.ts";

const LIVEKIT_URL = Deno.env.get("LIVEKIT_URL");
const LIVEKIT_API_KEY = Deno.env.get("LIVEKIT_API_KEY");
const LIVEKIT_API_SECRET = Deno.env.get("LIVEKIT_API_SECRET");

// Cible de stockage Egress = endpoint S3 de Supabase Storage.
const S3_ENDPOINT = Deno.env.get("LIVEKIT_S3_ENDPOINT");
const S3_REGION = Deno.env.get("LIVEKIT_S3_REGION");
const S3_ACCESS_KEY = Deno.env.get("LIVEKIT_S3_ACCESS_KEY");
const S3_SECRET = Deno.env.get("LIVEKIT_S3_SECRET");
const S3_BUCKET = Deno.env.get("LIVEKIT_S3_BUCKET") ?? "match-recordings";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// Rétention alignée sur la purge cleanup-streams : les captures anti-triche
// ne sont gardées qu'UN JOUR (sauf litige ouvert — géré par cleanup-streams).
const RETENTION_DAYS = 1;

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** wss://x.livekit.cloud → https://x.livekit.cloud (EgressClient = HTTP). */
function toHttpUrl(url: string): string {
  return url.replace(/^wss:\/\//, "https://").replace(/^ws:\/\//, "http://");
}

/** `match_<uuid>` → `<uuid>` (null si la room n'est pas un match ARENA). */
function matchIdFromRoom(roomName: string | undefined): string | null {
  if (!roomName || !roomName.startsWith("match_")) return null;
  const id = roomName.slice("match_".length);
  return id.length > 0 ? id : null;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }
  if (
    !LIVEKIT_URL || !LIVEKIT_API_KEY || !LIVEKIT_API_SECRET ||
    !S3_ENDPOINT || !S3_REGION || !S3_ACCESS_KEY || !S3_SECRET ||
    !SUPABASE_URL || !SERVICE_KEY
  ) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  // 1) Valider la signature LiveKit sur le corps brut.
  const bodyText = await req.text();
  const authHeader = req.headers.get("Authorization") ?? undefined;
  const receiver = new WebhookReceiver(LIVEKIT_API_KEY, LIVEKIT_API_SECRET);
  let event;
  try {
    event = await receiver.receive(bodyText, authHeader);
  } catch (e) {
    return jsonResponse(
      { error: "invalid_signature", detail: safeDetail(String(e), "livekit-webhook") },
      401,
    );
  }

  const sb = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    switch (event.event) {
      case "track_published":
        return await onTrackPublished(sb, event);
      case "egress_ended":
        return await onEgressEnded(sb, event);
      default:
        // room_started / participant_joined / egress_started / … : ignorés.
        return jsonResponse({ ok: true, ignored: event.event });
    }
  } catch (e) {
    return jsonResponse(
      { error: "handler_failed", detail: safeDetail(String(e), "livekit-webhook") },
      500,
    );
  }
});

async function onTrackPublished(
  sb: ServiceClient,
  // deno-lint-ignore no-explicit-any
  event: any,
): Promise<Response> {
  const track = event.track;
  const participant = event.participant;
  const roomName = event.room?.name as string | undefined;
  const matchId = matchIdFromRoom(roomName);
  const playerId = participant?.identity as string | undefined;
  const trackId = track?.sid as string | undefined;

  // On n'enregistre que la piste VIDÉO (le partage d'écran gameplay).
  if (
    !matchId || !roomName || !playerId || !trackId ||
    track?.type !== TrackType.VIDEO
  ) {
    return jsonResponse({ ok: true, skipped: "not_a_match_video_track" });
  }

  // TIERING (P2) : charger le plan anti-triche du match. On n'egress QUE si
  // tier=livekit, et alors seulement la piste de `recorded_player_id` (design
  // opaque : les deux publient, un seul est enregistré → 1 egress / match).
  // Le plan est posé (idempotent) par l'EF `livekit-token` au début du match.
  const { data: plan } = await sb
    .from("match_anticheat_plans")
    .select("mode, recorded_player_id")
    .eq("match_id", matchId)
    .maybeSingle();
  if (!plan || plan.mode !== "livekit" || !plan.recorded_player_id) {
    return jsonResponse({ ok: true, skipped: "no_livekit_plan" });
  }

  const egressClient = new EgressClient(
    toHttpUrl(LIVEKIT_URL!),
    LIVEKIT_API_KEY!,
    LIVEKIT_API_SECRET!,
  );

  // GATE PRÉSENCE : on ne démarre l'egress de l'élu QUE lorsque les DEUX joueurs
  // publient leur écran (évite d'enregistrer un no-show et de gaspiller un slot
  // egress concurrent — la capacité = matchs simultanés). Présence NATIVE
  // LiveKit, pas de canal Realtime Supabase.
  const videoTracks = await listVideoTracks(roomName);
  // listParticipants peut accuser un léger retard de propagation : on garantit
  // que la piste de l'événement courant est comptée.
  if (!videoTracks.some((v) => v.playerId === playerId)) {
    videoTracks.push({ playerId, trackId });
  }
  if (videoTracks.length < 2) {
    return jsonResponse({ ok: true, skipped: "waiting_for_opponent" });
  }

  // Les deux sont là : egress de l'ÉLU uniquement (1 egress / match). L'autre
  // joueur publie mais n'est jamais enregistré (il ne le sait pas → dissuasion).
  const elected = videoTracks.find(
    (v) => v.playerId === plan.recorded_player_id,
  );
  if (!elected) {
    // L'élu n'a pas encore (re)publié sa piste — on attend son track_published.
    return jsonResponse({ ok: true, skipped: "elected_not_publishing" });
  }
  const r = await startTrackEgressFor(
    sb,
    egressClient,
    roomName,
    matchId,
    elected.playerId,
    elected.trackId,
  );
  return jsonResponse({
    ok: true,
    started: r.egressId ? 1 : 0,
    skipped: r.skipped,
  });
}

/// Liste les pistes VIDÉO publiées dans la room (une par joueur), via la
/// présence native LiveKit. Retourne [] si la room n'est pas listable —
/// l'appelant retombe alors sur la seule piste de l'événement courant.
async function listVideoTracks(
  roomName: string,
): Promise<{ playerId: string; trackId: string }[]> {
  const roomClient = new RoomServiceClient(
    toHttpUrl(LIVEKIT_URL!),
    LIVEKIT_API_KEY!,
    LIVEKIT_API_SECRET!,
  );
  const out: { playerId: string; trackId: string }[] = [];
  try {
    const participants = await roomClient.listParticipants(roomName);
    const seen = new Set<string>();
    for (const p of participants) {
      const pid = p.identity as string | undefined;
      if (!pid || seen.has(pid)) continue;
      for (const t of p.tracks ?? []) {
        if (t.type === TrackType.VIDEO && t.sid) {
          out.push({ playerId: pid, trackId: t.sid });
          seen.add(pid);
          break; // une seule piste vidéo par joueur
        }
      }
    }
  } catch (_) {
    // Room non listable (course / propagation) : on laisse l'appelant gérer
    // avec la piste courante. Mieux vaut filmer que perdre la preuve.
  }
  return out;
}

/// Démarre un Track Egress pour une piste donnée et upsert la ligne `streams`.
/// Idempotent par (match, joueur). Lève sur erreur dure d'insertion.
async function startTrackEgressFor(
  sb: ServiceClient,
  egressClient: EgressClient,
  roomName: string,
  matchId: string,
  playerId: string,
  trackId: string,
): Promise<{ egressId?: string; skipped?: string }> {
  // Idempotence : si un egress LiveKit actif existe déjà pour ce joueur sur
  // ce match (reconnexion, re-publication), ne pas en relancer un second.
  const { data: existing } = await sb
    .from("streams")
    .select("id")
    .eq("match_id", matchId)
    .eq("player_id", playerId)
    .eq("provider", "livekit_track_egress")
    .eq("is_active", true)
    .maybeSingle();
  if (existing) {
    return { skipped: "already_recording" };
  }

  // Chemin déterministe dans le bucket : aligné sur la convention
  // {matchId}/{playerId}/… déjà purgée par cleanup-streams.
  // Extension .webm : Track Egress d'une piste vidéo WebRTC (VP8/VP9) écrit un
  // conteneur WebM. Demander .mp4 ne change rien au conteneur — LiveKit écrirait
  // quand même un .webm et `storage_path` (.mp4) ne pointerait plus sur l'objet
  // réel (URL signée admin → 404). On fixe donc .webm dès le départ, et on
  // ré-aligne storage_path sur le vrai nom de fichier à `egress_ended`.
  const filepath = `${matchId}/${playerId}/livekit_${Date.now()}.webm`;

  const output = new DirectFileOutput({
    filepath,
    output: {
      case: "s3",
      value: new S3Upload({
        accessKey: S3_ACCESS_KEY!,
        secret: S3_SECRET!,
        region: S3_REGION!,
        endpoint: S3_ENDPOINT!,
        bucket: S3_BUCKET,
        forcePathStyle: true,
      }),
    },
  });

  const info = await egressClient.startTrackEgress(roomName, output, trackId);

  const { error: insErr } = await sb.from("streams").insert({
    match_id: matchId,
    player_id: playerId,
    provider: "livekit_track_egress",
    egress_id: info.egressId,
    storage_path: filepath,
    is_active: true,
    is_public: false,
  });
  if (insErr) {
    // 23505 = unique_violation sur l'index partiel « une seule ligne LiveKit
    // active par (match, joueur) ». Course : deux `track_published` quasi
    // simultanés ont tous deux passé le garde `maybeSingle` ci-dessus puis
    // lancé un egress. On annule celui qu'on vient de démarrer pour ne pas
    // enregistrer (et facturer) en double.
    if ((insErr as { code?: string }).code === "23505") {
      try {
        await egressClient.stopEgress(info.egressId);
      } catch (_) { /* best-effort : l'egress orphelin s'arrêtera seul */ }
      return { skipped: "already_recording_race" };
    }
    throw new Error(insErr.message);
  }

  return { egressId: info.egressId };
}

async function onEgressEnded(
  sb: ServiceClient,
  // deno-lint-ignore no-explicit-any
  event: any,
): Promise<Response> {
  const info = event.egressInfo;
  const egressId = info?.egressId as string | undefined;
  if (!egressId) {
    return jsonResponse({ ok: true, skipped: "no_egress_id" });
  }

  const expiresAt = new Date(
    Date.now() + RETENTION_DAYS * 24 * 60 * 60 * 1000,
  ).toISOString();

  // deno-lint-ignore no-explicit-any
  const patch: Record<string, any> = {
    is_active: false,
    ended_at: new Date().toISOString(),
    expires_at: expiresAt,
  };

  // Ré-aligner storage_path sur le NOM RÉEL écrit par LiveKit : le conteneur
  // dépend du codec (vidéo WebRTC → .webm), donc l'extension peut différer de
  // celle demandée au démarrage. `egressInfo.fileResults[].filename` (ou
  // l'ancien `file.filename`) porte la clé d'objet réelle. Sans ça, l'URL
  // signée admin pointerait sur un objet inexistant.
  const fileResult = (Array.isArray(info?.fileResults) && info.fileResults[0]) ||
    info?.file;
  const actualPath = fileResult?.filename;
  if (typeof actualPath === "string" && actualPath.length > 0 &&
      !actualPath.includes("://")) {
    patch.storage_path = actualPath;
  }

  const { error: updErr } = await sb
    .from("streams")
    .update(patch)
    .eq("egress_id", egressId);
  if (updErr) {
    return jsonResponse(
      { error: "stream_finalize_failed", detail: safeDetail(updErr.message, "livekit-webhook") },
      500,
    );
  }

  return jsonResponse({ ok: true, finalized: egressId });
}
