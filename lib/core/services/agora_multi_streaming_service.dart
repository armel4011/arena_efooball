import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/core/services/agora_token_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// État par tuile dans la grille de modération multi-stream.
sealed class MultiTileState {
  const MultiTileState({required this.matchId});
  final String matchId;
}

class MultiTileJoining extends MultiTileState {
  const MultiTileJoining({required super.matchId});
}

class MultiTileJoined extends MultiTileState {
  const MultiTileJoined({
    required super.matchId,
    required this.connection,
    this.remoteUid,
    this.audioFocused = false,
  });

  final RtcConnection connection;
  final int? remoteUid;
  final bool audioFocused;

  MultiTileJoined copyWith({int? remoteUid, bool? audioFocused}) =>
      MultiTileJoined(
        matchId: matchId,
        connection: connection,
        remoteUid: remoteUid ?? this.remoteUid,
        audioFocused: audioFocused ?? this.audioFocused,
      );
}

class MultiTileFailed extends MultiTileState {
  const MultiTileFailed({required super.matchId, required this.reason});
  final String reason;
}

/// Service multi-channel pour la modération admin : 1 RtcEngine partagé,
/// N RtcConnection (1 par stream surveillé), audio mute par défaut sauf
/// la tuile « focus » désignée par [focusAudio].
///
/// Distinct du `AgoraStreamingService` (singleton mono-channel du flavor
/// user) pour isoler les cycles de vie : l'admin n'a jamais besoin de
/// broadcaster, et libérer l'engine multi-stream ne doit pas casser une
/// éventuelle session user en cours.
class AgoraMultiStreamingService {
  AgoraMultiStreamingService({
    required AgoraTokenClient tokenClient,
    AgoraMultiEnginePlatform? platform,
  })  : _tokenClient = tokenClient,
        _platform = platform ?? _DefaultAgoraMultiEnginePlatform();

  final AgoraTokenClient _tokenClient;
  final AgoraMultiEnginePlatform _platform;

  final _statesController =
      StreamController<Map<String, MultiTileState>>.broadcast();
  final Map<String, MultiTileState> _states = {};

  RtcEngineEx? _engine;
  RtcEngineEx? get engine => _engine;

  Stream<Map<String, MultiTileState>> get statesStream =>
      _statesController.stream;
  Map<String, MultiTileState> get states => Map.unmodifiable(_states);

  /// matchId actuellement « focus audio » (un seul à la fois, sinon
  /// 4 flux audio simultanés = bouillie inintelligible).
  String? _audioFocusedMatchId;

  Future<void> joinAudience(String matchId) async {
    if (_states.containsKey(matchId)) return;
    _emit(MultiTileJoining(matchId: matchId));

    AgoraToken token;
    try {
      token = await _tokenClient.fetch(
        matchId: matchId,
        role: AgoraRole.audience,
      );
    } on SocketException catch (e) {
      _emit(MultiTileFailed(matchId: matchId, reason: 'token_failed: $e'));
      return;
    } on TimeoutException catch (e) {
      _emit(MultiTileFailed(matchId: matchId, reason: 'token_failed: $e'));
      return;
    } catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      _emit(MultiTileFailed(matchId: matchId, reason: 'token_failed: $e'));
      return;
    }

    final connection = RtcConnection(
      channelId: token.channelName,
      localUid: token.uid,
    );

    try {
      _engine = await _ensureEngine();
      await _platform.joinChannelEx(
        engine: _engine!,
        token: token.token,
        connection: connection,
        onRemoteJoined: (remoteUid) {
          final cur = _states[matchId];
          if (cur is MultiTileJoined) {
            _emit(cur.copyWith(remoteUid: remoteUid));
          }
        },
      );
      _emit(MultiTileJoined(matchId: matchId, connection: connection));
    } on PlatformException catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      _emit(MultiTileFailed(matchId: matchId, reason: 'join_failed: $e'));
    } catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      _emit(MultiTileFailed(matchId: matchId, reason: 'join_failed: $e'));
    }
  }

  Future<void> leave(String matchId) async {
    final cur = _states.remove(matchId);
    if (cur is MultiTileJoined && _engine != null) {
      try {
        await _platform.leaveChannelEx(
          engine: _engine!,
          connection: cur.connection,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('[agora-multi] leave failed for $matchId: $e');
      }
    }
    if (_audioFocusedMatchId == matchId) _audioFocusedMatchId = null;
    _statesController.add(Map.unmodifiable(_states));
  }

  /// Bascule l'audio sur cette tuile (mute tous les autres). Passer null
  /// = mute tout. Idempotent : retap sur la même tuile remet en mute.
  Future<void> focusAudio(String? matchId) async {
    final eng = _engine;
    if (eng == null) return;
    final next = (_audioFocusedMatchId == matchId) ? null : matchId;
    _audioFocusedMatchId = next;
    for (final entry in _states.entries) {
      final s = entry.value;
      if (s is! MultiTileJoined) continue;
      final shouldHearAudio = entry.key == next;
      try {
        await _platform.setAudioSubscription(
          engine: eng,
          connection: s.connection,
          subscribed: shouldHearAudio,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('[agora-multi] audio toggle failed: $e');
      }
      _states[entry.key] = s.copyWith(audioFocused: shouldHearAudio);
    }
    _statesController.add(Map.unmodifiable(_states));
  }

  Future<void> leaveAll() async {
    final eng = _engine;
    for (final entry in _states.entries.toList()) {
      final s = entry.value;
      if (s is MultiTileJoined && eng != null) {
        try {
          await _platform.leaveChannelEx(engine: eng, connection: s.connection);
        } catch (_) {/* swallow */}
      }
    }
    _states.clear();
    _audioFocusedMatchId = null;
    _statesController.add(Map.unmodifiable(_states));
  }

  Future<void> dispose() async {
    final eng = _engine;
    if (eng != null) {
      try {
        await leaveAll();
        await _platform.releaseEngine(eng);
      } catch (e) {
        if (kDebugMode) debugPrint('[agora-multi] dispose cleanup failed: $e');
      }
    }
    _engine = null;
    if (!_statesController.isClosed) await _statesController.close();
  }

  Future<RtcEngineEx> _ensureEngine() async {
    final existing = _engine;
    if (existing != null) return existing;
    final appId = dotenv.maybeGet('AGORA_APP_ID');
    if (appId == null || appId.isEmpty) {
      throw StateError('AGORA_APP_ID missing from .env');
    }
    return _engine = await _platform.createAndInit(appId: appId);
  }

  void _emit(MultiTileState next) {
    _states[next.matchId] = next;
    _statesController.add(Map.unmodifiable(_states));
  }
}

/// Seam pour les tests — n'importe quelle implémentation peut remplacer
/// les appels natifs Agora.
abstract class AgoraMultiEnginePlatform {
  Future<RtcEngineEx> createAndInit({required String appId});
  Future<void> joinChannelEx({
    required RtcEngineEx engine,
    required String token,
    required RtcConnection connection,
    required void Function(int remoteUid) onRemoteJoined,
  });
  Future<void> leaveChannelEx({
    required RtcEngineEx engine,
    required RtcConnection connection,
  });
  Future<void> setAudioSubscription({
    required RtcEngineEx engine,
    required RtcConnection connection,
    required bool subscribed,
  });
  Future<void> releaseEngine(RtcEngineEx engine);
}

class _DefaultAgoraMultiEnginePlatform implements AgoraMultiEnginePlatform {
  final Map<String, RtcEngineEventHandler> _handlers = {};

  String _key(RtcConnection c) => '${c.channelId}#${c.localUid}';

  @override
  Future<RtcEngineEx> createAndInit({required String appId}) async {
    final engine = createAgoraRtcEngineEx();
    await engine.initialize(RtcEngineContext(appId: appId));
    await engine.enableVideo();
    await engine.enableAudio();
    return engine;
  }

  @override
  Future<void> joinChannelEx({
    required RtcEngineEx engine,
    required String token,
    required RtcConnection connection,
    required void Function(int remoteUid) onRemoteJoined,
  }) async {
    final handler = RtcEngineEventHandler(
      onError: (err, msg) =>
          debugPrint('[agora-multi] err ${connection.channelId} $err: $msg'),
      onJoinChannelSuccess: (conn, elapsed) => debugPrint(
        '[agora-multi] joined ${conn.channelId} uid=${conn.localUid}',
      ),
      onUserJoined: (conn, remoteUid, elapsed) {
        if (conn.channelId != connection.channelId) return;
        debugPrint(
          '[agora-multi] remote uid=$remoteUid joined ${conn.channelId}',
        );
        onRemoteJoined(remoteUid);
      },
      onUserOffline: (conn, remoteUid, reason) => debugPrint(
        '[agora-multi] remote uid=$remoteUid left ${conn.channelId} ($reason)',
      ),
    );
    _handlers[_key(connection)] = handler;
    engine.registerEventHandler(handler);
    await engine.joinChannelEx(
      token: token,
      connection: connection,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
        publishScreenCaptureVideo: false,
        publishScreenCaptureAudio: false,
        autoSubscribeVideo: true,
        // Audio off par défaut : 4 streams audio simultanés sur un phone
        // d'admin = bouillie. Activé par tuile via [focusAudio].
        autoSubscribeAudio: false,
      ),
    );
  }

  @override
  Future<void> leaveChannelEx({
    required RtcEngineEx engine,
    required RtcConnection connection,
  }) async {
    final handler = _handlers.remove(_key(connection));
    if (handler != null) {
      engine.unregisterEventHandler(handler);
    }
    await engine.leaveChannelEx(connection: connection);
  }

  @override
  Future<void> setAudioSubscription({
    required RtcEngineEx engine,
    required RtcConnection connection,
    required bool subscribed,
  }) async {
    await engine.updateChannelMediaOptionsEx(
      options: ChannelMediaOptions(autoSubscribeAudio: subscribed),
      connection: connection,
    );
  }

  @override
  Future<void> releaseEngine(RtcEngineEx engine) async {
    for (final h in _handlers.values) {
      engine.unregisterEventHandler(h);
    }
    _handlers.clear();
    await engine.release();
  }
}

/// Autodispose : l'engine multi-stream consomme 4+ decoders H.264 +
/// les RtcConnection, on libère dès que la page de modération sort de
/// l'arbre widgets pour rendre la mémoire/batterie.
final agoraMultiStreamingServiceProvider =
    Provider.autoDispose<AgoraMultiStreamingService>((ref) {
  final svc = AgoraMultiStreamingService(
    tokenClient: ref.watch(agoraTokenClientProvider),
  );
  ref.onDispose(svc.dispose);
  return svc;
});
