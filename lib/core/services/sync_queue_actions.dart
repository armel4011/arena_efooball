part of 'sync_queue_service.dart';

// ─────────────────────────────────────────────────────────────────────
// Actions concretes
// ─────────────────────────────────────────────────────────────────────

class MarkNotificationReadAction extends SyncAction {
  const MarkNotificationReadAction({
    required super.id,
    required super.createdAt,
    required this.notificationId,
    super.attempts = 0,
  });

  factory MarkNotificationReadAction.fromPayload({
    required String id,
    required DateTime createdAt,
    required Map<String, dynamic> payload,
  }) =>
      MarkNotificationReadAction(
        id: id,
        createdAt: createdAt,
        notificationId: payload['notification_id'] as String,
      );

  static const _type = 'notif.read';
  final String notificationId;

  @override
  String get type => _type;

  @override
  Map<String, dynamic> get payload => {'notification_id': notificationId};

  @override
  SyncAction copyWithAttempts(int attempts) => MarkNotificationReadAction(
        id: id,
        createdAt: createdAt,
        notificationId: notificationId,
        attempts: attempts,
      );

  @override
  Future<bool> execute(SupabaseClient client) async {
    try {
      await client
          .from('notifications')
          .update({'read_at': createdAt.toIso8601String()})
          .eq('id', notificationId)
          // LWW : ne ecrase pas un read_at deja stampé localement OU
          // serveur — un read_at plus ancien que celui-ci gagne pas.
          .filter('read_at', 'is', null);
      return true;
    } catch (e, st) {
      // RLS denied / row absente = definitif → drop (attendu, pas de report).
      if (e is PostgrestException &&
          (e.code == '42501' || e.code == 'PGRST116')) {
        return true;
      }
      // Échec non-terminal (réseau/serveur) : on remonte pour observabilité,
      // l'action sera rejouée.
      unawaited(reportError(e, st, context: 'SyncQueue.markNotificationRead'));
      return false;
    }
  }
}

class SendChatMessageAction extends SyncAction {
  const SendChatMessageAction({
    required super.id,
    required super.createdAt,
    required this.channelId,
    required this.senderId,
    required this.text,
    super.attempts = 0,
  });

  factory SendChatMessageAction.fromPayload({
    required String id,
    required DateTime createdAt,
    required Map<String, dynamic> payload,
  }) =>
      SendChatMessageAction(
        id: id,
        createdAt: createdAt,
        channelId: payload['channel_id'] as String,
        senderId: payload['sender_id'] as String,
        text: payload['text'] as String,
      );

  static const _type = 'chat.send';
  final String channelId;
  final String senderId;
  final String text;

  @override
  String get type => _type;

  @override
  Map<String, dynamic> get payload => {
        'channel_id': channelId,
        'sender_id': senderId,
        'text': text,
      };

  @override
  SyncAction copyWithAttempts(int attempts) => SendChatMessageAction(
        id: id,
        createdAt: createdAt,
        channelId: channelId,
        senderId: senderId,
        text: text,
        attempts: attempts,
      );

  @override
  Future<bool> execute(SupabaseClient client) async {
    try {
      // `id` de la queue sert d'idempotency key — l'INSERT utilise
      // cet id comme PK pour eviter le double-envoi si flush rejoue.
      // Colonnes alignees sur `ChatRepository.sendMessage` :
      // channel_id / sender_id / content / type. La moderation tourne
      // cote serveur (trigger AFTER INSERT) — elle s'applique donc
      // aussi aux messages rejoues depuis la queue.
      await client.from('chat_messages').insert({
        'id': id,
        'channel_id': channelId,
        'sender_id': senderId,
        'content': text,
        'type': 'text',
        'created_at': createdAt.toIso8601String(),
      });
      return true;
    } catch (e, st) {
      if (e is PostgrestException) {
        // 23505 = unique_violation (deja insere par un flush precedent)
        // → idempotent OK, drop.
        if (e.code == '23505') return true;
        // RLS denied = definitif
        if (e.code == '42501') return true;
      }
      // Échec non-terminal : remonté pour observabilité, action rejouée.
      unawaited(reportError(e, st, context: 'SyncQueue.sendChatMessage'));
      return false;
    }
  }
}

class RegisterFreeCompetitionAction extends SyncAction {
  const RegisterFreeCompetitionAction({
    required super.id,
    required super.createdAt,
    required this.competitionId,
    required this.playerId,
    super.attempts = 0,
  });

  factory RegisterFreeCompetitionAction.fromPayload({
    required String id,
    required DateTime createdAt,
    required Map<String, dynamic> payload,
  }) =>
      RegisterFreeCompetitionAction(
        id: id,
        createdAt: createdAt,
        competitionId: payload['competition_id'] as String,
        playerId: payload['player_id'] as String,
      );

  static const _type = 'competition.register_free';
  final String competitionId;
  final String playerId;

  @override
  String get type => _type;

  @override
  Map<String, dynamic> get payload => {
        'competition_id': competitionId,
        'player_id': playerId,
      };

  @override
  SyncAction copyWithAttempts(int attempts) => RegisterFreeCompetitionAction(
        id: id,
        createdAt: createdAt,
        competitionId: competitionId,
        playerId: playerId,
        attempts: attempts,
      );

  @override
  Future<bool> execute(SupabaseClient client) async {
    try {
      // Insert aligne sur `CompetitionRepository.registerSelfFree`. La
      // policy `registrations_free_self_insert` valide cote DB que la
      // compet est gratuite (registration_fee = 0) — si elle est devenue
      // payante entre-temps, l'INSERT est rejete (42501) et on drop.
      await client.from('competition_registrations').insert({
        'competition_id': competitionId,
        'player_id': playerId,
        'status': 'confirmed',
      });
      return true;
    } catch (e, st) {
      if (e is PostgrestException) {
        // 23505 = unique(competition_id, player_id) → deja inscrit, OK.
        // 42501 = RLS denied (devenue payante / pleine) = definitif.
        if (e.code == '23505' || e.code == '42501') return true;
      }
      // Échec non-terminal : remonté pour observabilité, action rejouée.
      unawaited(
          reportError(e, st, context: 'SyncQueue.registerFreeCompetition'));
      return false;
    }
  }
}

/// Engage le commitment hash anti-triche (Phase 3) auprès de l'EF
/// `anticheat-commit`. Le hash + la taille sont calculés UNE fois à la fin du
/// match (cf. ProofCommitmentService) et transportés ici : le flush ne refait
/// pas le hash (le fichier peut avoir disparu). L'EF est write-once idempotent
/// → un rejeu (même hash) est sans danger.
class ProofCommitmentAction extends SyncAction {
  const ProofCommitmentAction({
    required super.id,
    required super.createdAt,
    required this.matchId,
    required this.sha256,
    required this.bytes,
    super.attempts = 0,
  });

  factory ProofCommitmentAction.fromPayload({
    required String id,
    required DateTime createdAt,
    required Map<String, dynamic> payload,
  }) =>
      ProofCommitmentAction(
        id: id,
        createdAt: createdAt,
        matchId: payload['match_id'] as String,
        sha256: payload['sha256'] as String,
        bytes: (payload['bytes'] as num).toInt(),
      );

  static const _type = 'anticheat.commit';
  final String matchId;
  final String sha256;
  final int bytes;

  @override
  String get type => _type;

  @override
  Map<String, dynamic> get payload => {
        'match_id': matchId,
        'sha256': sha256,
        'bytes': bytes,
      };

  @override
  SyncAction copyWithAttempts(int attempts) => ProofCommitmentAction(
        id: id,
        createdAt: createdAt,
        matchId: matchId,
        sha256: sha256,
        bytes: bytes,
        attempts: attempts,
      );

  @override
  Future<bool> execute(SupabaseClient client) async {
    try {
      await client.functions.invoke(
        'anticheat-commit',
        body: {
          'matchId': matchId,
          'proofSha256': sha256,
          'proofBytes': bytes,
        },
      );
      return true;
    } on FunctionException catch (e, st) {
      // 4xx (hors 401) = définitif → drop. Le 409 « already_committed » en
      // particulier est un succès logique (write-once).
      if (isTerminalCommitStatus(e.status)) return true;
      unawaited(reportError(e, st, context: 'SyncQueue.anticheatCommit'));
      return false;
    } catch (e, st) {
      // Réseau / inattendu → retry.
      unawaited(reportError(e, st, context: 'SyncQueue.anticheatCommit'));
      return false;
    }
  }
}

/// Rapporte au serveur que la capture anti-triche N'A PAS PU démarrer
/// (permission refusée / échec device) — P1 #5. Transporte quelques octets, donc
/// passe en 2G comme le commit. L'EF `anticheat-commit` matérialise la trace
/// (`capture_status='unavailable'`) SANS jamais écraser un commitment déjà
/// engagé → un rapport tardif est inoffensif, et le rejeu est idempotent.
class ProofUnavailableAction extends SyncAction {
  const ProofUnavailableAction({
    required super.id,
    required super.createdAt,
    required this.matchId,
    required this.reason,
    super.attempts = 0,
  });

  factory ProofUnavailableAction.fromPayload({
    required String id,
    required DateTime createdAt,
    required Map<String, dynamic> payload,
  }) =>
      ProofUnavailableAction(
        id: id,
        createdAt: createdAt,
        matchId: payload['match_id'] as String,
        reason: payload['reason'] as String?,
      );

  static const _type = 'anticheat.unavailable';
  final String matchId;

  /// Raison courte (permission_denied, start_failed, …) — trace de triage admin.
  final String? reason;

  @override
  String get type => _type;

  @override
  Map<String, dynamic> get payload => {
        'match_id': matchId,
        if (reason != null) 'reason': reason,
      };

  @override
  SyncAction copyWithAttempts(int attempts) => ProofUnavailableAction(
        id: id,
        createdAt: createdAt,
        matchId: matchId,
        reason: reason,
        attempts: attempts,
      );

  @override
  Future<bool> execute(SupabaseClient client) async {
    try {
      await client.functions.invoke(
        'anticheat-commit',
        body: {
          'matchId': matchId,
          'captureStatus': 'unavailable',
          if (reason != null) 'captureNote': reason,
        },
      );
      return true;
    } on FunctionException catch (e, st) {
      // 4xx (hors 401) = définitif → drop (même politique que le commit).
      if (isTerminalCommitStatus(e.status)) return true;
      unawaited(reportError(e, st, context: 'SyncQueue.anticheatUnavailable'));
      return false;
    } catch (e, st) {
      unawaited(reportError(e, st, context: 'SyncQueue.anticheatUnavailable'));
      return false;
    }
  }
}

/// Upload-on-claim (Phase 3) : sur réclamation admin, le joueur livre le
/// fichier de capture engagé, puis l'EF `proof-verify` re-hashe l'objet et le
/// compare au commitment. Resumable via la sync queue (gros fichier + réseau
/// instable) ; chemin d'objet DÉTERMINISTE (upsert) → un rejeu écrase au lieu
/// de multiplier les objets, et `proof-verify` reste idempotent.
class ProofUploadAction extends SyncAction {
  const ProofUploadAction({
    required super.id,
    required super.createdAt,
    required this.matchId,
    required this.streamId,
    required this.playerId,
    required this.filePath,
    super.attempts = 0,
  });

  factory ProofUploadAction.fromPayload({
    required String id,
    required DateTime createdAt,
    required Map<String, dynamic> payload,
  }) =>
      ProofUploadAction(
        id: id,
        createdAt: createdAt,
        matchId: payload['match_id'] as String,
        streamId: payload['stream_id'] as String,
        playerId: payload['player_id'] as String,
        filePath: payload['file_path'] as String,
      );

  static const _type = 'anticheat.upload';
  static const _bucket = 'match-recordings';
  final String matchId;
  final String streamId;
  final String playerId;
  final String filePath;

  @override
  String get type => _type;

  @override
  Map<String, dynamic> get payload => {
        'match_id': matchId,
        'stream_id': streamId,
        'player_id': playerId,
        'file_path': filePath,
      };

  @override
  SyncAction copyWithAttempts(int attempts) => ProofUploadAction(
        id: id,
        createdAt: createdAt,
        matchId: matchId,
        streamId: streamId,
        playerId: playerId,
        filePath: filePath,
        attempts: attempts,
      );

  @override
  Future<bool> execute(SupabaseClient client) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      // Preuve introuvable avant la réclamation : on ne peut plus livrer.
      // Depuis le volet C le proxy est archivé en dossier persistant (survit à
      // la purge cache OS), donc ce cas se limite aux entrées legacy / purge
      // J+30 dépassée. Drop définitif — l'admin verra une preuve non livrée.
      if (kDebugMode) {
        debugPrint('[sync] proof upload: fichier absent $filePath — drop');
      }
      return true;
    }

    // Chemin déterministe dans le dossier du (match, joueur) : `proof-verify`
    // exige cette appartenance, et l'upsert rend le rejeu idempotent.
    final objectPath = '$matchId/$playerId/proof.mp4';
    try {
      await client.storage.from(_bucket).upload(
            objectPath,
            file,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'video/mp4',
            ),
          );
      await client.functions.invoke(
        'proof-verify',
        body: {'streamId': streamId, 'objectPath': objectPath},
      );
      return true;
    } on FunctionException catch (e, st) {
      // proof-verify a répondu : 4xx (hors 401) = définitif (déjà vérifié,
      // chemin refusé, pas propriétaire…) → drop.
      if (isTerminalCommitStatus(e.status)) return true;
      unawaited(reportError(e, st, context: 'SyncQueue.proofUpload.verify'));
      return false;
    } catch (e, st) {
      // Storage / réseau → retry (le fichier local reste disponible).
      unawaited(reportError(e, st, context: 'SyncQueue.proofUpload'));
      return false;
    }
  }
}
