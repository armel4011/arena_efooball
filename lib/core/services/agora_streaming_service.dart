import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/core/services/agora_token_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State machine of the local Agora session.
sealed class AgoraSessionState {
  const AgoraSessionState();
}

class AgoraIdle extends AgoraSessionState {
  const AgoraIdle();
}

class AgoraJoining extends AgoraSessionState {
  const AgoraJoining({required this.channel, required this.role});
  final String channel;
  final AgoraRole role;
}

class AgoraJoined extends AgoraSessionState {
  const AgoraJoined({
    required this.channel,
    required this.role,
    required this.localUid,
    this.remoteUid,
  });
  final String channel;
  final AgoraRole role;
  final int localUid;

  /// First remote uid we picked up — used by the audience UI to render
  /// the broadcaster's video. Stays null on the broadcaster's side.
  final int? remoteUid;

  AgoraJoined copyWith({int? remoteUid}) => AgoraJoined(
        channel: channel,
        role: role,
        localUid: localUid,
        remoteUid: remoteUid ?? this.remoteUid,
      );
}

class AgoraLeft extends AgoraSessionState {
  const AgoraLeft();
}

class AgoraFailed extends AgoraSessionState {
  const AgoraFailed(this.reason);
  final String reason;
}

/// Bridges the Agora RTC engine and the rest of the app (PHASE 8.7).
///
/// The HOME of the match becomes the broadcaster, every other client
/// joins as audience. All callers must obtain a fresh token from
/// [AgoraTokenClient] first — the App Certificate is server-side only.
///
/// The class is platform-agnostic: on web, the engine binds to its
/// JS implementation transparently.
class AgoraStreamingService {
  AgoraStreamingService({
    required AgoraTokenClient tokenClient,
    AgoraEnginePlatform? platform,
  })  : _tokenClient = tokenClient,
        _platform = platform ?? _DefaultAgoraEnginePlatform();

  final AgoraTokenClient _tokenClient;
  final AgoraEnginePlatform _platform;

  final _stateController = StreamController<AgoraSessionState>.broadcast();
  AgoraSessionState _state = const AgoraIdle();

  /// `null` until [_ensureEngine] runs — kept exposed so the UI can
  /// pass it to `AgoraVideoView` for rendering local + remote feeds.
  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  AgoraSessionState get state => _state;
  Stream<AgoraSessionState> get stateStream => _stateController.stream;

  Future<void> joinAsBroadcaster({required String matchId}) =>
      _join(matchId: matchId, role: AgoraRole.broadcaster);

  Future<void> joinAsAudience({required String matchId}) =>
      _join(matchId: matchId, role: AgoraRole.audience);

  Future<void> leave() async {
    final eng = _engine;
    if (eng == null) {
      _emit(const AgoraLeft());
      return;
    }
    try {
      await _platform.leaveChannel(eng);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[agora] leaveChannel failed: $e\n$st');
      }
    }
    _emit(const AgoraLeft());
  }

  Future<void> dispose() async {
    final eng = _engine;
    if (eng != null) {
      try {
        await _platform.leaveChannel(eng);
        await _platform.releaseEngine(eng);
      } catch (e) {
        debugPrint('[agora] dispose cleanup failed: $e');
      }
    }
    _engine = null;
    await _stateController.close();
  }

  Future<void> _join({
    required String matchId,
    required AgoraRole role,
  }) async {
    _emit(AgoraJoining(channel: 'pending', role: role));

    AgoraToken token;
    try {
      token = await _tokenClient.fetch(matchId: matchId, role: role);
    } catch (e) {
      _emit(AgoraFailed('token_fetch_failed: $e'));
      rethrow;
    }

    _emit(AgoraJoining(channel: token.channelName, role: role));

    try {
      _engine = await _ensureEngine();
      await _platform.joinChannel(
        engine: _engine!,
        token: token.token,
        channelId: token.channelName,
        uid: token.uid,
        role: role,
        onLocalJoined: () {
          _emit(
            AgoraJoined(
              channel: token.channelName,
              role: role,
              localUid: token.uid,
            ),
          );
        },
        onRemoteJoined: (remoteUid) {
          final cur = _state;
          if (cur is AgoraJoined) {
            _emit(cur.copyWith(remoteUid: remoteUid));
          }
        },
      );
    } catch (e) {
      _emit(AgoraFailed('join_failed: $e'));
      rethrow;
    }
  }

  Future<RtcEngine> _ensureEngine() async {
    final existing = _engine;
    if (existing != null) return existing;
    final appId = dotenv.maybeGet('AGORA_APP_ID');
    if (appId == null || appId.isEmpty) {
      throw StateError(
        'AGORA_APP_ID missing from .env — cannot start streaming',
      );
    }
    final eng = await _platform.createAndInit(appId: appId);
    _engine = eng;
    return eng;
  }

  void _emit(AgoraSessionState next) {
    _state = next;
    _stateController.add(next);
  }
}

/// Seam over the Agora native engine — tests inject a fake.
abstract class AgoraEnginePlatform {
  Future<RtcEngine> createAndInit({required String appId});
  Future<void> joinChannel({
    required RtcEngine engine,
    required String token,
    required String channelId,
    required int uid,
    required AgoraRole role,
    required VoidCallback onLocalJoined,
    required void Function(int remoteUid) onRemoteJoined,
  });
  Future<void> leaveChannel(RtcEngine engine);
  Future<void> releaseEngine(RtcEngine engine);
}

class _DefaultAgoraEnginePlatform implements AgoraEnginePlatform {
  @override
  Future<RtcEngine> createAndInit({required String appId}) async {
    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: appId));
    await engine.enableAudio();
    await engine.enableVideo();
    return engine;
  }

  @override
  Future<void> joinChannel({
    required RtcEngine engine,
    required String token,
    required String channelId,
    required int uid,
    required AgoraRole role,
    required VoidCallback onLocalJoined,
    required void Function(int remoteUid) onRemoteJoined,
  }) async {
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) => onLocalJoined(),
        onUserJoined: (connection, remoteUid, elapsed) =>
            onRemoteJoined(remoteUid),
      ),
    );
    await engine.setClientRole(
      role: role == AgoraRole.broadcaster
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );
    if (role == AgoraRole.broadcaster) {
      await engine.startPreview();
    }
    await engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: ChannelMediaOptions(
        clientRoleType: role == AgoraRole.broadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        publishCameraTrack: role == AgoraRole.broadcaster,
        publishMicrophoneTrack: role == AgoraRole.broadcaster,
        autoSubscribeAudio: role == AgoraRole.audience,
        autoSubscribeVideo: role == AgoraRole.audience,
      ),
    );
  }

  @override
  Future<void> leaveChannel(RtcEngine engine) async {
    await engine.leaveChannel();
    await engine.stopPreview();
  }

  @override
  Future<void> releaseEngine(RtcEngine engine) async {
    await engine.release();
  }
}

final agoraStreamingServiceProvider = Provider<AgoraStreamingService>((ref) {
  final svc = AgoraStreamingService(
    tokenClient: ref.watch(agoraTokenClientProvider),
  );
  ref.onDispose(svc.dispose);
  return svc;
});
