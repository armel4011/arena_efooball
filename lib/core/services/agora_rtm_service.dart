import 'dart:async';
import 'dart:convert';

import 'package:agora_rtm/agora_rtm.dart' as rtm;
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Outcome of a presence change on a channel — emitted to UI listeners.
@immutable
class PresenceUpdate {
  const PresenceUpdate({
    required this.matchId,
    required this.account,
    required this.isOnline,
  });

  final String matchId;
  final String account;
  final bool isOnline;
}

/// "User X is typing on channel C" — emitted whenever a peer publishes a
/// `{kind:"typing"}` payload. Consumer combines with a debounce timer to
/// show / hide the indicator.
@immutable
class TypingEvent {
  const TypingEvent({required this.matchId, required this.account});

  final String matchId;
  final String account;
}

/// Connects to Agora RTM v2 for presence + typing in match-scoped chats.
///
/// Persistent chat messages stay in `chat_messages` (Supabase Realtime).
/// RTM is purely ephemeral — when no peer is connected, nothing est
/// stocké, et c'est voulu (typing est un "live hint", pas un state).
///
/// Lifecycle :
///   1. `connect()` — fetch token via Edge Function, login RTM client.
///   2. `joinMatchChannel(matchId)` — subscribe with presence+messages.
///   3. `sendTyping(matchId)` — publish a typing JSON payload.
///   4. listen to `typingEvents` / `presenceEvents` streams.
///   5. `leaveMatchChannel(matchId)` when the page disposes.
///   6. `dispose()` when the user signs out (or app shuts down).
class AgoraRtmService {
  AgoraRtmService(this._client);

  final SupabaseClient _client;

  rtm.RtmClient? _rtm;
  String? _account;

  final _typingCtrl = StreamController<TypingEvent>.broadcast();
  final _presenceCtrl = StreamController<PresenceUpdate>.broadcast();

  Stream<TypingEvent> get typingEvents => _typingCtrl.stream;
  Stream<PresenceUpdate> get presenceEvents => _presenceCtrl.stream;

  bool get isConnected => _rtm != null;

  Future<void> connect() async {
    if (_rtm != null) return;

    // Mint RTM token côté EF — l'App Certificate ne doit jamais fuir
    // côté client. L'EF lit l'identité du JWT, donc pas de body à passer.
    final res = await _client.functions.invoke('get-agora-rtm-token');
    final data = res.data;
    if (data is! Map ||
        data['appId'] is! String ||
        data['account'] is! String ||
        data['token'] is! String) {
      throw rtm.AgoraRtmException(
        code: -1,
        message: 'get-agora-rtm-token:malformed_response',
      );
    }
    final appId = data['appId'] as String;
    _account = data['account'] as String;
    final token = data['token'] as String;

    final (createStatus, client) = await rtm.RTM(appId, _account!);
    if (createStatus.error) {
      throw rtm.AgoraRtmException(
        code: int.tryParse(createStatus.errorCode) ?? -1,
        message: 'rtm_init_failed:${createStatus.reason}',
      );
    }
    _rtm = client;

    client.addListener(
      message: _handleMessage,
      presence: _handlePresence,
    );

    final (loginStatus, _) = await client.login(token);
    if (loginStatus.error) {
      // Rollback : on libère le client pour qu'un retry next-connect ait
      // une chance de réussir sur un fresh state.
      await client.release().catchError(
            (_) => const rtm.RtmStatus.success(
              operation: 'release_after_login_failure',
            ),
          );
      _rtm = null;
      throw rtm.AgoraRtmException(
        code: int.tryParse(loginStatus.errorCode) ?? -1,
        message: 'rtm_login_failed:${loginStatus.reason}',
      );
    }
  }

  Future<void> joinMatchChannel(String matchId) async {
    final client = _rtm;
    if (client == null) {
      throw rtm.AgoraRtmException(code: -1, message: 'rtm_not_connected');
    }
    final (status, _) = await client.subscribe(
      _channelFor(matchId),
      // withMessage = on veut recevoir les typing payloads.
      // withPresence = on veut savoir quand le peer rejoint/quitte.
      withPresence: true,
    );
    if (status.error) {
      throw rtm.AgoraRtmException(
        code: int.tryParse(status.errorCode) ?? -1,
        message: 'rtm_subscribe_failed:${status.reason}',
      );
    }
  }

  Future<void> leaveMatchChannel(String matchId) async {
    final client = _rtm;
    if (client == null) return;
    await client.unsubscribe(_channelFor(matchId)).catchError(
          (_) => (
            const rtm.RtmStatus.success(operation: 'unsubscribe_swallow'),
            null,
          ),
        );
  }

  /// Publishes a typing hint. UI doit appeler ça avec un throttle (
  /// max ~1 envoi / 2-3s) pour ne pas saturer le channel.
  Future<void> sendTyping(String matchId) async {
    final client = _rtm;
    if (client == null) return;
    final payload = jsonEncode({
      'kind': 'typing',
      'at': DateTime.now().millisecondsSinceEpoch,
    });
    await client.publish(_channelFor(matchId), payload).catchError(
          (_) => (
            const rtm.RtmStatus.success(operation: 'publish_swallow'),
            null,
          ),
        );
  }

  Future<void> dispose() async {
    final client = _rtm;
    _rtm = null;
    _account = null;
    if (client != null) {
      client.removeListener(
        message: _handleMessage,
        presence: _handlePresence,
      );
      await client.logout().catchError(
            (_) => (
              const rtm.RtmStatus.success(operation: 'logout_swallow'),
              null,
            ),
          );
      await client.release().catchError(
            (_) =>
                const rtm.RtmStatus.success(operation: 'release_swallow'),
          );
    }
    await _typingCtrl.close();
    await _presenceCtrl.close();
  }

  void _handleMessage(rtm.MessageEvent event) {
    final channel = event.channelName;
    final publisher = event.publisher;
    final raw = event.message;
    if (channel == null || publisher == null || raw == null) return;
    if (publisher == _account) return; // ignore loopback
    final matchId = _matchIdFromChannel(channel);
    if (matchId == null) return;
    try {
      // `message` est un Uint8List côté SDK ; on décode UTF8 puis JSON.
      final decoded = jsonDecode(utf8.decode(raw));
      if (decoded is Map && decoded['kind'] == 'typing') {
        _typingCtrl.add(TypingEvent(matchId: matchId, account: publisher));
      }
    } catch (_) {
      // Payload non-JSON ou autre kind — silently ignore (RTM est un
      // transport ouvert, on ne casse pas la session sur un payload
      // inattendu d'un éventuel autre publisher).
    }
  }

  void _handlePresence(rtm.PresenceEvent event) {
    final channel = event.channelName;
    final publisher = event.publisher;
    if (channel == null || publisher == null) return;
    final matchId = _matchIdFromChannel(channel);
    if (matchId == null) return;

    switch (event.type) {
      case rtm.RtmPresenceEventType.remoteJoinChannel:
        _presenceCtrl.add(
          PresenceUpdate(
            matchId: matchId,
            account: publisher,
            isOnline: true,
          ),
        );
      case rtm.RtmPresenceEventType.remoteLeaveChannel:
      case rtm.RtmPresenceEventType.remoteTimeout:
        _presenceCtrl.add(
          PresenceUpdate(
            matchId: matchId,
            account: publisher,
            isOnline: false,
          ),
        );
      // snapshot/interval/etc. ne sont pas exploités en V1 (la chat 1v1
      // n'a pas besoin du list complet de présents — un seul peer).
      case rtm.RtmPresenceEventType.none:
      case rtm.RtmPresenceEventType.snapshot:
      case rtm.RtmPresenceEventType.interval:
      case rtm.RtmPresenceEventType.remoteStateChanged:
      case rtm.RtmPresenceEventType.errorOutOfService:
      case null:
        break;
    }
  }

  String _channelFor(String matchId) => 'match_$matchId';

  String? _matchIdFromChannel(String channel) {
    const prefix = 'match_';
    if (!channel.startsWith(prefix)) return null;
    return channel.substring(prefix.length);
  }
}

/// Singleton-style provider — un seul client RTM par session app.
final agoraRtmServiceProvider = Provider<AgoraRtmService>((ref) {
  final service = AgoraRtmService(ref.watch(supabaseClientProvider));
  ref.onDispose(service.dispose);
  return service;
});
