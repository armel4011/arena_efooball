import 'package:arena/core/utils/poll_stream.dart';
import 'package:arena/data/models/anticheat_plan.dart';
import 'package:arena/data/models/dispute.dart';
import 'package:arena/data/models/dispute_proof.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin-side reads + writes over `disputes` (PHASE 11).
///
/// Players open disputes via the user-facing flow (RLS
/// `disputes_party_insert`). Admins read everything via
/// `disputes_admin_all` and resolve from here — the resolution path
/// commits the verdict on the underlying match too, so the bracket
/// progresses.
class AdminDisputesRepository {
  const AdminDisputesRepository(this._client);

  static const _table = 'disputes';
  static const _eventsTable = 'match_events';
  static const _proofBucket = 'match-proofs';
  static const _streamsTable = 'streams';
  static const _recordingsBucket = 'match-recordings';
  static const _plansTable = 'match_anticheat_plans';

  final SupabaseClient _client;

  /// One-shot fetch de tous les litiges, plus récents en tête.
  ///
  /// Le filtre `status` est client-side (on veut `open` + `escalated`
  /// ensemble). Consommé en polling plutôt qu'en Realtime : un litige
  /// s'ouvre rarement, pas la peine d'un WebSocket dédié par admin.
  Future<List<Dispute>> listAll({bool openOnly = true}) async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    final list = [for (final row in rows) Dispute.fromJson(row)];
    if (!openOnly) return list;
    return list.where((d) => d.isOpen).toList(growable: false);
  }

  Stream<Dispute?> watchById(String id) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : Dispute.fromJson(rows.first));
  }

  Future<Dispute?> getByMatchId(String matchId) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('match_id', matchId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return Dispute.fromJson(row);
  }

  /// Proof files (screenshots / clips) the players submitted for [matchId].
  ///
  /// Les preuves sont attachées au **`payload` JSONB** des events
  /// `score_submitted` (`match_events.payload->>'proof_path'` /
  /// `->>'proof_mime'`, cf. `MatchRepository.submitScore` /
  /// `ScoreProofUploader`) — `match_events` n'a PAS de colonnes dédiées.
  /// On lit le payload de chaque event du match et on ne garde que ceux
  /// qui portent un `proof_path`, plus récents en tête. Le bucket est privé
  /// — l'appelant signe chaque `DisputeProof.path` via [signedProofUrl]
  /// juste avant l'affichage.
  Future<List<DisputeProof>> fetchProofs(String matchId) async {
    final rows = await _client
        .from(_eventsTable)
        .select('payload, created_by, created_at')
        .eq('match_id', matchId)
        .order('created_at', ascending: false);
    final out = <DisputeProof>[];
    for (final row in rows as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final payload = map['payload'];
      if (payload is! Map<String, dynamic>) continue;
      final path = payload['proof_path'] as String?;
      if (path == null || path.isEmpty) continue;
      out.add(
        DisputeProof(
          path: path,
          mime: payload['proof_mime'] as String?,
          playerId: map['created_by'] as String?,
          createdAt: map['created_at'] == null
              ? null
              : DateTime.tryParse(map['created_at'] as String),
        ),
      );
    }
    return out;
  }

  /// Dernier score SOUMIS par chaque joueur (map `player_id → SubmittedScore`),
  /// lu depuis les events `score_submitted` de `match_events`. C'est la source
  /// de vérité pour l'admin en litige : `matches.score1/2` sont NULL tant que le
  /// match n'est pas validé, donc seule cette lecture révèle ce que chaque
  /// joueur a réellement déclaré (et leur divergence). Plus récent par joueur.
  Future<Map<String, SubmittedScore>> fetchSubmittedScores(
    String matchId,
  ) async {
    final rows = await _client
        .from(_eventsTable)
        .select('payload, created_by, created_at')
        .eq('match_id', matchId)
        .eq('type', 'score_submitted')
        .order('created_at', ascending: false);
    final out = <String, SubmittedScore>{};
    for (final row in rows as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final playerId = map['created_by'] as String?;
      // rows triés desc → la première occurrence d'un joueur est sa plus récente.
      if (playerId == null || out.containsKey(playerId)) continue;
      final payload = map['payload'];
      if (payload is! Map<String, dynamic>) continue;
      final s1 = (payload['score1'] as num?)?.toInt();
      final s2 = (payload['score2'] as num?)?.toInt();
      if (s1 == null || s2 == null) continue;
      out[playerId] = SubmittedScore(
        score1: s1,
        score2: s2,
        viaPenalties: payload['via_penalties'] == true,
        penalty1: (payload['penalty1'] as num?)?.toInt(),
        penalty2: (payload['penalty2'] as num?)?.toInt(),
        createdAt: map['created_at'] == null
            ? null
            : DateTime.tryParse(map['created_at'] as String),
      );
    }
    return out;
  }

  /// Signs a private `match-proofs` storage [path] for read (default 1h),
  /// mirroring the chat-media convention (`ChatRepository.signedMediaUrl`).
  Future<String> signedProofUrl(
    String path, {
    Duration expiresIn = const Duration(hours: 1),
  }) {
    return _client.storage
        .from(_proofBucket)
        .createSignedUrl(path, expiresIn.inSeconds);
  }

  /// Enregistrements anti-triche AUTO de [matchId] (système DUAL).
  ///
  /// Lit les lignes `streams` de preuve (anti-triche) : on exclut les flux
  /// Agora LIVE (`is_public = true`, `url` = nom de canal, pas un objet) et on
  /// ne garde que celles qui portent un chemin de fichier — `storage_path`
  /// (LiveKit Track Egress) ou `url` (recorder natif, cf.
  /// `RecordingUploader.attachUrl`). Plus récentes en tête.
  Future<List<MatchStream>> fetchRecordings(String matchId) async {
    final rows = await _client
        .from(_streamsTable)
        .select()
        .eq('match_id', matchId)
        .eq('is_public', false)
        .order('started_at', ascending: false);
    final out = <MatchStream>[];
    for (final row in rows as List<dynamic>) {
      final s = MatchStream.fromJson(row as Map<String, dynamic>);
      if (recordingPathOf(s) != null) out.add(s);
    }
    return out;
  }

  /// Chemin objet à signer pour un enregistrement : `storage_path` (LiveKit)
  /// en priorité, sinon `url` (natif). Null si la ligne ne porte aucun fichier.
  String? recordingPathOf(MatchStream s) {
    final sp = s.storagePath;
    if (sp != null && sp.isNotEmpty) return sp;
    final u = s.url;
    if (u != null && u.isNotEmpty) return u;
    return null;
  }

  /// Signe un objet privé du bucket `match-recordings` pour lecture (1h).
  Future<String> signedRecordingUrl(
    String path, {
    Duration expiresIn = const Duration(hours: 1),
  }) {
    return _client.storage
        .from(_recordingsBucket)
        .createSignedUrl(path, expiresIn.inSeconds);
  }

  /// Preuves anti-triche « commitment hash » (Phase 3) de [matchId] : lignes
  /// `streams` qui portent un commitment (`proof_sha256`), qu'elles aient déjà
  /// été uploadées ou non. Sert la section « Preuves engagées » des litiges —
  /// distincte des « Enregistrements auto » qui n'affiche que les fichiers déjà
  /// présents. Plus récentes en tête.
  Future<List<MatchStream>> fetchProofCommitments(String matchId) async {
    final rows = await _client
        .from(_streamsTable)
        .select()
        .eq('match_id', matchId)
        .not('proof_sha256', 'is', null)
        .order('proof_committed_at', ascending: false);
    return [
      for (final row in rows as List<dynamic>)
        MatchStream.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Plan anti-triche (tiering) du match : `native_only` (hash seul) ou
  /// `livekit` (egress d'un joueur tiré au hasard) + la raison de la décision.
  /// Null si aucun plan n'a été assigné (match jamais passé par `livekit-token`,
  /// ex. provider natif). Lecture gatée `is_admin()` (RLS).
  Future<AnticheatPlan?> fetchAnticheatPlan(String matchId) async {
    final row = await _client
        .from(_plansTable)
        .select('mode, recorded_player_id, reason, decided_at')
        .eq('match_id', matchId)
        .maybeSingle();
    if (row == null) return null;
    return AnticheatPlan.fromJson(row);
  }

  /// Admin « réclamer la vidéo » : appelle la RPC `admin_claim_proof` qui
  /// estampille `streams.proof_claimed_at` et notifie le joueur (FCM). Le
  /// joueur uploadera le proxy à sa prochaine connexion ; proof-verify
  /// comparera alors le hash livré au commitment.
  Future<void> claimProof(String streamId) async {
    await _client.rpc<void>(
      'admin_claim_proof',
      params: {'p_stream_id': streamId},
    );
  }

  /// Résolution ATOMIQUE via la RPC `resolve_dispute` : verdict
  /// (score/winner/completed) OU annulation du match + résolution du litige +
  /// trace d'audit, dans UNE seule transaction (gate `is_admin()` serveur).
  /// Remplace l'enchaînement de 3 écritures non transactionnelles qui pouvait
  /// laisser un litige `open` alors que le bracket avait avancé.
  Future<void> resolveAtomic({
    required String matchId,
    required String justification,
    String? disputeId,
    bool cancel = false,
    String? winnerId,
    int? scoreP1,
    int? scoreP2,
  }) async {
    await _client.rpc<void>(
      'resolve_dispute',
      params: {
        'p_match_id': matchId,
        'p_dispute_id': disputeId,
        'p_justification': justification,
        'p_cancel': cancel,
        'p_winner_id': winnerId,
        'p_score1': scoreP1,
        'p_score2': scoreP2,
      },
    );
  }

  /// Remet un match EN JEU quand le litige n'est pas tranchable (RPC
  /// `replay_match`, SECURITY DEFINER).
  ///
  /// Troisième issue à côté du tapis vert et de l'annulation : quand les
  /// preuves ne départagent pas, donner le match à l'un punit peut-être un
  /// innocent, et l'annuler efface un match qui a eu lieu.
  ///
  /// Le serveur annule le résultat précédent (stats décrémentées, vainqueur
  /// dé-propagé du bracket, compétition rouverte si elle avait été clôturée),
  /// replanifie à [scheduledAt] et clôture le litige SANS désigner de coupable.
  /// Lève si des gains ont déjà été générés ou si le match suivant est engagé.
  Future<void> replayMatch({
    required String matchId,
    required String justification,
    required DateTime scheduledAt,
    String? disputeId,
  }) async {
    await _client.rpc<void>(
      'replay_match',
      params: {
        'p_match_id': matchId,
        'p_dispute_id': disputeId,
        'p_justification': justification,
        'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
      },
    );
  }
}

final adminDisputesRepositoryProvider =
    Provider<AdminDisputesRepository>((ref) {
  return AdminDisputesRepository(ref.watch(supabaseClientProvider));
});

/// Polling 120 s (Realtime dégradé) — un litige s'ouvre ~1×/jour, pas
/// besoin d'un canal WebSocket dédié par admin connecté.
final adminOpenDisputesProvider =
    StreamProvider.autoDispose<List<Dispute>>((ref) {
  final repo = ref.watch(adminDisputesRepositoryProvider);
  return pollStream(const Duration(seconds: 120), repo.listAll);
});

final adminDisputeByMatchProvider =
    FutureProvider.family.autoDispose<Dispute?, String>((ref, matchId) {
  return ref.watch(adminDisputesRepositoryProvider).getByMatchId(matchId);
});

/// Le scoreline qu'un joueur A DÉCLARÉ (payload d'un event `score_submitted`).
class SubmittedScore {
  const SubmittedScore({
    required this.score1,
    required this.score2,
    this.viaPenalties = false,
    this.penalty1,
    this.penalty2,
    this.createdAt,
  });

  final int score1;
  final int score2;
  final bool viaPenalties;
  final int? penalty1;
  final int? penalty2;
  final DateTime? createdAt;

  /// « 2-1 » ou « 2-2 (tab 5-4) » pour les tirs au but.
  String get label {
    final base = '$score1-$score2';
    if (viaPenalties && penalty1 != null && penalty2 != null) {
      return '$base (tab $penalty1-$penalty2)';
    }
    return base;
  }
}

/// Score déclaré par CHAQUE joueur (map `player_id → SubmittedScore`) — alimente
/// la carte des scores de l'écran litige. Source de vérité quand
/// `matches.score1/2` sont NULL (litige non tranché).
final matchSubmittedScoresProvider = FutureProvider.family
    .autoDispose<Map<String, SubmittedScore>, String>((ref, matchId) {
  return ref
      .watch(adminDisputesRepositoryProvider)
      .fetchSubmittedScores(matchId);
});

/// A proof paired with a freshly-signed read URL, ready for display.
class SignedDisputeProof {
  const SignedDisputeProof({required this.proof, required this.url});

  final DisputeProof proof;
  final String url;

  bool get isVideo => proof.isVideo;
  String? get playerId => proof.playerId;
  DateTime? get createdAt => proof.createdAt;
}

/// Fetches every proof attached to `matchId` and signs each one (1h).
/// Drives the « Preuves » section in both the mobile and desktop dispute
/// screens. autoDispose so the signed URLs aren't kept around stale.
final adminDisputeProofsProvider = FutureProvider.family
    .autoDispose<List<SignedDisputeProof>, String>((ref, matchId) async {
  final repo = ref.watch(adminDisputesRepositoryProvider);
  final proofs = await repo.fetchProofs(matchId);
  final signed = <SignedDisputeProof>[];
  for (final proof in proofs) {
    final url = await repo.signedProofUrl(proof.path);
    signed.add(SignedDisputeProof(proof: proof, url: url));
  }
  return signed;
});

/// Un enregistrement anti-triche AUTO + son URL signée prête à l'affichage.
class SignedMatchRecording {
  const SignedMatchRecording({required this.stream, required this.url});

  final MatchStream stream;
  final String url;

  /// Provider d'origine (`native_recorder` | `livekit_track_egress`).
  String get provider => stream.provider;
  String? get playerId => stream.playerId;
  DateTime? get startedAt => stream.startedAt;
  bool get isLiveKit => stream.provider == 'livekit_track_egress';
}

/// Récupère les enregistrements anti-triche AUTO de `matchId` et signe chacun
/// (1h). Alimente la section « Enregistrements auto » des litiges. autoDispose
/// pour ne pas garder d'URL signées périmées.
final adminMatchRecordingsProvider = FutureProvider.family
    .autoDispose<List<SignedMatchRecording>, String>((ref, matchId) async {
  final repo = ref.watch(adminDisputesRepositoryProvider);
  final recordings = await repo.fetchRecordings(matchId);
  final signed = <SignedMatchRecording>[];
  for (final rec in recordings) {
    final path = repo.recordingPathOf(rec);
    if (path == null) continue;
    final url = await repo.signedRecordingUrl(path);
    signed.add(SignedMatchRecording(stream: rec, url: url));
  }
  return signed;
});

/// Preuves « commitment hash » (Phase 3) d'un match : lignes `streams` portant
/// un `proof_sha256`, qu'elles soient encore à réclamer, réclamées, ou déjà
/// livrées (vérifiées / mismatch). Alimente la section « Preuves engagées »
/// des litiges (badge de statut + bouton « Réclamer la vidéo »). autoDispose
/// pour refléter les changements de statut après une réclamation.
final adminMatchProofCommitmentsProvider = FutureProvider.family
    .autoDispose<List<MatchStream>, String>((ref, matchId) {
  return ref.watch(adminDisputesRepositoryProvider).fetchProofCommitments(matchId);
});

/// Plan anti-triche (tiering) d'un match : tier (natif seul / egress LiveKit) +
/// raison de la décision serveur. Null si aucun plan assigné (provider natif).
/// Alimente le bandeau « Plan anti-triche » des litiges.
final adminMatchAnticheatPlanProvider = FutureProvider.family
    .autoDispose<AnticheatPlan?, String>((ref, matchId) {
  return ref.watch(adminDisputesRepositoryProvider).fetchAnticheatPlan(matchId);
});
