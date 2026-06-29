import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:arena/core/services/network_status_service.dart';
import 'package:arena/core/utils/error_reporter.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Genere un UUID v4 — utilise comme idempotency key + chat_messages.id
/// pour eviter les double-envois si le flush est rejoue. Evite d'ajouter
/// la dep `uuid` pour ce seul cas d'usage.
String generateUuidV4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant
  String h(int x) => x.toRadixString(16).padLeft(2, '0');
  return '${h(b[0])}${h(b[1])}${h(b[2])}${h(b[3])}-'
      '${h(b[4])}${h(b[5])}-'
      '${h(b[6])}${h(b[7])}-'
      '${h(b[8])}${h(b[9])}-'
      '${h(b[10])}${h(b[11])}${h(b[12])}${h(b[13])}${h(b[14])}${h(b[15])}';
}

/// Action utilisateur effectuée hors-ligne et mise en queue pour
/// rejouer au retour du reseau.
///
/// Chaque action a :
///   * `id` : UUID local, sert d'idempotency key cote serveur (pour
///     eviter les double-envois si flush est lance deux fois).
///   * `type` : tag de la concrete class (cf. `_fromJson`).
///   * `createdAt` : horodatage local de l'action — sert au Last
///     Write Wins (LWW) si conflit avec une mutation serveur.
///   * `payload` : map specifique a chaque type.
sealed class SyncAction {
  const SyncAction({
    required this.id,
    required this.createdAt,
    this.attempts = 0,
  });

  final String id;
  final DateTime createdAt;

  /// Nombre de tentatives de flush échouées (erreurs non-définitives).
  /// Au-delà de [SyncQueueService.maxAttempts], l'action part en dead-letter
  /// (drop + log) au lieu d'être rejouée indéfiniment (« poison message »).
  final int attempts;

  String get type;
  Map<String, dynamic> get payload;

  /// Copie de l'action avec un compteur de tentatives mis à jour.
  SyncAction copyWithAttempts(int attempts);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'created_at': createdAt.toIso8601String(),
        'attempts': attempts,
        'payload': payload,
      };

  /// Tente d'executer l'action en ligne. Si l'erreur est definitive
  /// (ex: payload invalide, RLS denied), retourne `true` pour drop
  /// l'action de la queue. Sinon `false` pour la garder (retry plus tard).
  Future<bool> execute(SupabaseClient client);

  static SyncAction? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final id = json['id'] as String;
    final createdAt = DateTime.parse(json['created_at'] as String);
    final attempts = json['attempts'] as int? ?? 0;
    final payload = (json['payload'] as Map).cast<String, dynamic>();
    final SyncAction action;
    switch (type) {
      case MarkNotificationReadAction._type:
        action = MarkNotificationReadAction.fromPayload(
          id: id,
          createdAt: createdAt,
          payload: payload,
        );
      case SendChatMessageAction._type:
        action = SendChatMessageAction.fromPayload(
          id: id,
          createdAt: createdAt,
          payload: payload,
        );
      case RegisterFreeCompetitionAction._type:
        action = RegisterFreeCompetitionAction.fromPayload(
          id: id,
          createdAt: createdAt,
          payload: payload,
        );
      case ProofCommitmentAction._type:
        action = ProofCommitmentAction.fromPayload(
          id: id,
          createdAt: createdAt,
          payload: payload,
        );
      case ProofUploadAction._type:
        action = ProofUploadAction.fromPayload(
          id: id,
          createdAt: createdAt,
          payload: payload,
        );
      default:
        if (kDebugMode) {
          debugPrint('[sync] unknown action type "$type" — dropping');
        }
        return null;
    }
    return action.copyWithAttempts(attempts);
  }
}

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

/// `true` si un statut HTTP d'Edge Function est DÉFINITIF (drop l'action) :
/// 4xx hors 401 (déjà engagé 409, payload invalide 400, pas joueur 403,
/// match introuvable 404…). 401 = token périmé (transitoire → retry), 5xx =
/// serveur (retry).
bool isTerminalCommitStatus(int? status) {
  if (status == null) return false;
  if (status == 401) return false;
  return status >= 400 && status < 500;
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
      // Fichier purgé (cache OS) avant la réclamation : on ne peut plus livrer.
      // Drop définitif — l'admin verra une preuve réclamée jamais livrée.
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

// ─────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────

/// Snapshot reactif de l'etat de la queue — alimente l'indicateur de
/// synchronisation dans la bannière (nombre d'actions en attente +
/// flush en cours).
@immutable
class SyncState {
  const SyncState({required this.pending, required this.flushing});

  final int pending;
  final bool flushing;

  static const idle = SyncState(pending: 0, flushing: false);

  SyncState copyWith({int? pending, bool? flushing}) => SyncState(
        pending: pending ?? this.pending,
        flushing: flushing ?? this.flushing,
      );

  @override
  bool operator ==(Object other) =>
      other is SyncState &&
      other.pending == pending &&
      other.flushing == flushing;

  @override
  int get hashCode => Object.hash(pending, flushing);
}

/// File d'attente locale des mutations offline. Persiste dans
/// SharedPreferences (JSON list) — suffisant pour <100 actions
/// typiques avant un flush.
///
/// **Auto-flush** : ecoute `NetworkStatusService` et tente de drainer la
/// queue des qu'une interface reseau redevient active (online OU slow).
/// Le service est aussi flushable manuellement (ex: bouton "reessayer").
class SyncQueueService {
  SyncQueueService({
    required SharedPreferences prefs,
    required SupabaseClient client,
    required NetworkStatusService network,
  })  : _prefs = prefs,
        _client = client,
        _network = network;

  static const _key = 'arena.sync_queue.v1';

  /// Au-delà de ce nombre de tentatives de flush échouées, une action est
  /// considérée « poison » et part en dead-letter (drop + Sentry) au lieu
  /// d'être rejouée à chaque flush indéfiniment.
  static const maxAttempts = 10;

  final SharedPreferences _prefs;
  final SupabaseClient _client;
  final NetworkStatusService _network;
  StreamSubscription<NetworkStatus>? _sub;
  bool _flushing = false;

  /// Etat reactif (pending + flushing) pour l'UI. Mis a jour a chaque
  /// enqueue / flush / persist.
  final ValueNotifier<SyncState> state = ValueNotifier(SyncState.idle);

  /// A appeler 1 fois au boot pour brancher l'auto-flush.
  void attach() {
    state.value = SyncState(pending: pending.length, flushing: false);
    _sub = _network.stream.listen((s) {
      // Des qu'une interface est active (online ou slow), on draine.
      if (s == NetworkStatus.online || s == NetworkStatus.slow) {
        unawaited(flush());
      }
    });
    // Si on demarre deja connecte avec une queue non vide, flush immediat.
    if (_network.isConnected && pending.isNotEmpty) {
      unawaited(flush());
    }
  }

  void dispose() {
    _sub?.cancel();
    state.dispose();
  }

  /// Snapshot synchrone des actions en attente (pour UI badge).
  List<SyncAction> get pending {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final j in list)
          if (SyncAction.fromJson(j as Map<String, dynamic>) case final a?) a,
      ];
    } catch (e, st) {
      // Queue corrompue (JSON illisible) → on purge pour repartir propre.
      unawaited(reportError(e, st,
          context: 'SyncQueue.pending', hint: 'queue corrompue — purge'));
      _prefs.remove(_key);
      return const [];
    }
  }

  /// Ajoute une action a la queue. Persisting est synchrone (await OK
  /// dans un onTap UI).
  Future<void> enqueue(SyncAction action) async {
    final current = pending.toList()..add(action);
    await _persist(current);
    // Tentative immediate si une interface est active — pas la peine
    // d'attendre la prochaine transition.
    if (_network.isConnected) {
      unawaited(flush());
    }
  }

  /// Drain la queue. Garde les actions qui echouent (non-definitif).
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    state.value = state.value.copyWith(flushing: true);
    try {
      final actions = pending;
      if (actions.isEmpty) return;
      final remaining = <SyncAction>[];
      for (final a in actions) {
        final done = await a.execute(_client);
        if (done) continue;
        final next = a.attempts + 1;
        if (next >= maxAttempts) {
          // Dead-letter : action « poison » qui échoue indéfiniment. On la
          // drop (au lieu de la rejouer à chaque flush) avec visibilité prod.
          if (kDebugMode) {
            debugPrint(
              '[sync] dead-letter ${a.type} (${a.id}) après $next échecs',
            );
          }
          unawaited(
            Sentry.captureMessage(
              'sync dead-letter: ${a.type} dropped after $next attempts',
              level: SentryLevel.warning,
            ),
          );
          continue; // drop
        }
        remaining.add(a.copyWithAttempts(next));
      }
      await _persist(remaining);
    } finally {
      _flushing = false;
      state.value = SyncState(pending: pending.length, flushing: false);
    }
  }

  Future<void> _persist(List<SyncAction> actions) async {
    final json = jsonEncode([for (final a in actions) a.toJson()]);
    await _prefs.setString(_key, json);
    // Reflete le compte courant sans toucher au flag flushing.
    state.value = state.value.copyWith(pending: actions.length);
  }
}

/// Provider singleton — attach au boot, dispose en fin de session.
final syncQueueServiceProvider = FutureProvider<SyncQueueService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final svc = SyncQueueService(
    prefs: prefs,
    client: ref.watch(supabaseClientProvider),
    network: ref.watch(networkStatusServiceProvider),
  )..attach();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Helper UI : nombre d'actions en attente — alimente un badge dans le
/// profil si tu veux le surfacer.
final pendingSyncCountProvider = Provider<int>((ref) {
  final svc = ref.watch(syncQueueServiceProvider).valueOrNull;
  return svc?.pending.length ?? 0;
});

// ─────────────────────────────────────────────────────────────────────
// Helper de haut niveau : "execute si online, enqueue sinon"
// ─────────────────────────────────────────────────────────────────────

/// Facade pour les mutations sensibles a l'offline. Les call sites
/// utilisent `ref.read(offlineAwareActionsProvider).markNotificationRead(id)`
/// au lieu d'appeler le repository directement — la facade decide si
/// elle execute ou enqueue selon `NetworkStatus.current`.
class OfflineAwareActions {
  OfflineAwareActions(this._ref);

  final Ref _ref;

  bool get _offline =>
      _ref.read(networkStatusServiceProvider).current == NetworkStatus.offline;

  Future<void> _enqueue(SyncAction action) async {
    final queue = _ref.read(syncQueueServiceProvider).valueOrNull;
    if (queue == null) {
      // Queue pas encore prete au tout debut du boot — fallback online.
      if (kDebugMode) {
        debugPrint('[sync] queue not ready, dropping action ${action.type}');
      }
      return;
    }
    await queue.enqueue(action);
  }

  /// Marque une notification comme lue. Offline → queue, online → direct.
  Future<void> markNotificationRead(String notificationId) async {
    if (_offline) {
      await _enqueue(
        MarkNotificationReadAction(
          id: generateUuidV4(),
          createdAt: DateTime.now().toUtc(),
          notificationId: notificationId,
        ),
      );
    } else {
      await _ref.read(notificationRepositoryProvider).markRead(notificationId);
    }
  }

  /// Envoie un message de chat texte. Offline → queue (rejoue au retour
  /// reseau, idempotent via l'id local), online → INSERT direct via le
  /// repository. La moderation tourne cote serveur (trigger AFTER
  /// INSERT) donc elle s'applique dans les deux cas.
  ///
  /// Retourne `true` si l'action a ete mise en file (offline) — l'UI
  /// peut alors afficher un feedback "message en attente".
  Future<bool> sendChatMessage({
    required String channelId,
    required String senderId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;
    final capped = trimmed.length > 2000 ? trimmed.substring(0, 2000) : trimmed;
    if (_offline) {
      await _enqueue(
        SendChatMessageAction(
          id: generateUuidV4(),
          createdAt: DateTime.now().toUtc(),
          channelId: channelId,
          senderId: senderId,
          text: capped,
        ),
      );
      return true;
    }
    await _ref.read(chatRepositoryProvider).sendMessage(
          channelId: channelId,
          senderId: senderId,
          content: capped,
        );
    return false;
  }

  /// Inscription a une competition GRATUITE. Offline → queue, online →
  /// INSERT direct. Idempotent cote serveur (unique competition/player).
  ///
  /// Retourne `true` si l'action a ete mise en file (offline).
  Future<bool> registerFreeCompetition({
    required String competitionId,
    required String playerId,
  }) async {
    if (_offline) {
      await _enqueue(
        RegisterFreeCompetitionAction(
          id: generateUuidV4(),
          createdAt: DateTime.now().toUtc(),
          competitionId: competitionId,
          playerId: playerId,
        ),
      );
      return true;
    }
    await _ref
        .read(competitionRepositoryProvider)
        .registerSelfFree(competitionId);
    return false;
  }
}

final offlineAwareActionsProvider =
    Provider<OfflineAwareActions>(OfflineAwareActions.new);
