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

part 'sync_queue_actions.dart';

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

/// `true` si un statut HTTP d'Edge Function est DÉFINITIF (drop l'action) :
/// 4xx hors 401 (déjà engagé 409, payload invalide 400, pas joueur 403,
/// match introuvable 404…). 401 = token périmé (transitoire → retry), 5xx =
/// serveur (retry).
bool isTerminalCommitStatus(int? status) {
  if (status == null) return false;
  if (status == 401) return false;
  return status >= 400 && status < 500;
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
