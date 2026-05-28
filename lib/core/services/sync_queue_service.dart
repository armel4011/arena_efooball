import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:arena/core/services/network_status_service.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  });

  final String id;
  final DateTime createdAt;

  String get type;
  Map<String, dynamic> get payload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'created_at': createdAt.toIso8601String(),
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
    final payload = (json['payload'] as Map).cast<String, dynamic>();
    switch (type) {
      case MarkNotificationReadAction._type:
        return MarkNotificationReadAction.fromPayload(
          id: id,
          createdAt: createdAt,
          payload: payload,
        );
      case SendChatMessageAction._type:
        return SendChatMessageAction.fromPayload(
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
    } catch (e) {
      if (kDebugMode) debugPrint('[sync] notif.read failed: $e');
      // RLS denied / row absente = definitif → drop
      if (e is PostgrestException &&
          (e.code == '42501' || e.code == 'PGRST116')) {
        return true;
      }
      return false;
    }
  }
}

class SendChatMessageAction extends SyncAction {
  const SendChatMessageAction({
    required super.id,
    required super.createdAt,
    required this.channelId,
    required this.text,
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
        text: payload['text'] as String,
      );

  static const _type = 'chat.send';
  final String channelId;
  final String text;

  @override
  String get type => _type;

  @override
  Map<String, dynamic> get payload => {
        'channel_id': channelId,
        'text': text,
      };

  @override
  Future<bool> execute(SupabaseClient client) async {
    try {
      // `id` de la queue sert d'idempotency key — l'INSERT utilise
      // cet id comme PK pour eviter le double-envoi si flush rejoue.
      await client.from('chat_messages').insert({
        'id': id,
        'channel_id': channelId,
        'body': text,
        'created_at': createdAt.toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[sync] chat.send failed: $e');
      if (e is PostgrestException) {
        // 23505 = unique_violation (deja insere par un flush precedent)
        // → idempotent OK, drop.
        if (e.code == '23505') return true;
        // RLS denied = definitif
        if (e.code == '42501') return true;
      }
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────

/// File d'attente locale des mutations offline. Persiste dans
/// SharedPreferences (JSON list) — suffisant pour <100 actions
/// typiques avant un flush.
///
/// **Auto-flush** : ecoute `NetworkStatusService` et tente de drainer la
/// queue a chaque transition `offline → online`. Le service est aussi
/// flushable manuellement (ex: bouton "reessayer" dans un settings).
class SyncQueueService {
  SyncQueueService({
    required SharedPreferences prefs,
    required SupabaseClient client,
    required NetworkStatusService network,
  })  : _prefs = prefs,
        _client = client,
        _network = network;

  static const _key = 'arena.sync_queue.v1';

  final SharedPreferences _prefs;
  final SupabaseClient _client;
  final NetworkStatusService _network;
  StreamSubscription<NetworkStatus>? _sub;
  bool _flushing = false;

  /// A appeler 1 fois au boot pour brancher l'auto-flush.
  void attach() {
    _sub = _network.stream.listen((s) {
      if (s == NetworkStatus.online) {
        unawaited(flush());
      }
    });
    // Si on demarre deja online avec une queue non vide, flush immediat.
    if (_network.current == NetworkStatus.online && pending.isNotEmpty) {
      unawaited(flush());
    }
  }

  void dispose() {
    _sub?.cancel();
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
    } catch (e) {
      if (kDebugMode) debugPrint('[sync] decode queue failed: $e — wiping');
      _prefs.remove(_key);
      return const [];
    }
  }

  /// Ajoute une action a la queue. Persisting est synchrone (await OK
  /// dans un onTap UI).
  Future<void> enqueue(SyncAction action) async {
    final current = pending.toList()..add(action);
    await _persist(current);
    // Tentative immediate si on est online — pas la peine d'attendre
    // la prochaine transition.
    if (_network.current == NetworkStatus.online) {
      unawaited(flush());
    }
  }

  /// Drain la queue. Garde les actions qui echouent (non-definitif).
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final actions = pending;
      if (actions.isEmpty) return;
      final remaining = <SyncAction>[];
      for (final a in actions) {
        final done = await a.execute(_client);
        if (!done) remaining.add(a);
      }
      await _persist(remaining);
    } finally {
      _flushing = false;
    }
  }

  Future<void> _persist(List<SyncAction> actions) {
    final json = jsonEncode([for (final a in actions) a.toJson()]);
    return _prefs.setString(_key, json);
  }
}

/// Provider singleton — attach au boot, dispose en fin de session.
final syncQueueServiceProvider =
    FutureProvider<SyncQueueService>((ref) async {
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
      _ref.read(networkStatusServiceProvider).current ==
      NetworkStatus.offline;

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
      await _ref
          .read(notificationRepositoryProvider)
          .markRead(notificationId);
    }
  }

  // NOTE Phase 3 V1 : seul `markNotificationRead` est expose ici.
  // Les autres mutations identifiees (send chat message, register comp
  // gratuite, submit score) ont des pipelines existants complexes
  // (moderation EF, RPC validation, anti-cheat) qui ne supportent pas
  // un simple INSERT offline → il faut soit dupliquer la logique
  // serveur en local, soit accepter de bloquer l'action en offline.
  // `SendChatMessageAction` est dispo dans le code comme exemple pour
  // brancher plus tard quand la moderation pourra etre lazy-evaluee.
}

final offlineAwareActionsProvider =
    Provider<OfflineAwareActions>(OfflineAwareActions.new);
