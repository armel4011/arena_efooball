import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// État d'un appel audio Agora (Phase 12.5 — item 3 B1).
enum CallState { idle, connecting, ringing, connected, ended, failed }

/// Snapshot exposé à l'UI.
@immutable
class CallSnapshot {
  const CallSnapshot({
    required this.state,
    this.errorMessage,
    this.remoteUid,
    this.micMuted = false,
    this.speakerOn = true,
  });

  final CallState state;
  final String? errorMessage;
  final int? remoteUid;
  final bool micMuted;
  final bool speakerOn;

  CallSnapshot copyWith({
    CallState? state,
    String? errorMessage,
    int? remoteUid,
    bool? micMuted,
    bool? speakerOn,
  }) =>
      CallSnapshot(
        state: state ?? this.state,
        errorMessage: errorMessage ?? this.errorMessage,
        remoteUid: remoteUid ?? this.remoteUid,
        micMuted: micMuted ?? this.micMuted,
        speakerOn: speakerOn ?? this.speakerOn,
      );
}

/// Service voice-call 1v1 Agora RTC.
///
/// Différent du service streaming match (HOME→audience). Ici les 2
/// peers sont PUBLISHER audio. Pas d'enregistrement, pas de vidéo.
class AgoraCallService {
  AgoraCallService({
    required SupabaseClient client,
    AgoraCallPlatform? platform,
  })  : _client = client,
        _platform = platform ?? const _DefaultAgoraCallPlatform();

  final SupabaseClient _client;
  final AgoraCallPlatform _platform;

  RtcEngine? _engine;
  CallSnapshot _snapshot = const CallSnapshot(state: CallState.idle);
  final _controller = StreamController<CallSnapshot>.broadcast();

  CallSnapshot get snapshot => _snapshot;
  Stream<CallSnapshot> get stream => _controller.stream;

  /// Lance un appel sortant. [scope] = `match` ou `friend`,
  /// [id] = le matchId ou friendshipId associé.
  Future<void> startCall({
    required String scope,
    required String id,
  }) async {
    _emit(_snapshot.copyWith(state: CallState.connecting, errorMessage: null));

    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        _emit(
          _snapshot.copyWith(
            state: CallState.failed,
            errorMessage: 'Permission micro refusée.',
          ),
        );
        return;
      }

      final appId = dotenv.env['AGORA_APP_ID']?.trim() ?? '';
      if (appId.isEmpty) {
        _emit(
          _snapshot.copyWith(
            state: CallState.failed,
            errorMessage: 'AGORA_APP_ID manquant.',
          ),
        );
        return;
      }

      final res = await _client.functions.invoke(
        'get-agora-call-token',
        body: {'scope': scope, 'id': id},
      );
      if (res.status != 200) {
        _emit(
          _snapshot.copyWith(
            state: CallState.failed,
            errorMessage: 'Token refusé (${res.status}).',
          ),
        );
        return;
      }
      final data = res.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final channelName = data['channelName'] as String;
      final uid = (data['uid'] as num).toInt();

      _engine = await _platform.createEngine(appId: appId);
      await _platform.joinAudioChannel(
        engine: _engine!,
        token: token,
        channelName: channelName,
        uid: uid,
        onJoined: () =>
            _emit(_snapshot.copyWith(state: CallState.ringing)),
        onRemoteJoined: (rUid) => _emit(
          _snapshot.copyWith(
            state: CallState.connected,
            remoteUid: rUid,
          ),
        ),
        onUserOffline: (rUid) {
          if (_snapshot.remoteUid == rUid) {
            _emit(_snapshot.copyWith(state: CallState.ended));
          }
        },
      );
    } catch (e) {
      _emit(
        _snapshot.copyWith(
          state: CallState.failed,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> toggleMute() async {
    final engine = _engine;
    if (engine == null) return;
    final next = !_snapshot.micMuted;
    await engine.muteLocalAudioStream(next);
    _emit(_snapshot.copyWith(micMuted: next));
  }

  Future<void> toggleSpeaker() async {
    final engine = _engine;
    if (engine == null) return;
    final next = !_snapshot.speakerOn;
    await engine.setEnableSpeakerphone(next);
    _emit(_snapshot.copyWith(speakerOn: next));
  }

  Future<void> hangup() async {
    final engine = _engine;
    if (engine != null) {
      try {
        await _platform.leaveChannel(engine);
        await _platform.releaseEngine(engine);
      } catch (_) {/* swallow */}
    }
    _engine = null;
    _emit(const CallSnapshot(state: CallState.ended));
  }

  Future<void> dispose() async {
    await hangup();
    await _controller.close();
  }

  void _emit(CallSnapshot next) {
    _snapshot = next;
    _controller.add(next);
  }
}

abstract class AgoraCallPlatform {
  const AgoraCallPlatform();
  Future<RtcEngine> createEngine({required String appId});
  Future<void> joinAudioChannel({
    required RtcEngine engine,
    required String token,
    required String channelName,
    required int uid,
    required VoidCallback onJoined,
    required void Function(int remoteUid) onRemoteJoined,
    required void Function(int remoteUid) onUserOffline,
  });
  Future<void> leaveChannel(RtcEngine engine);
  Future<void> releaseEngine(RtcEngine engine);
}

class _DefaultAgoraCallPlatform implements AgoraCallPlatform {
  const _DefaultAgoraCallPlatform();

  @override
  Future<RtcEngine> createEngine({required String appId}) async {
    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: appId));
    await engine.enableAudio();
    // Audio-only V1.
    await engine.setEnableSpeakerphone(true);
    return engine;
  }

  @override
  Future<void> joinAudioChannel({
    required RtcEngine engine,
    required String token,
    required String channelName,
    required int uid,
    required VoidCallback onJoined,
    required void Function(int remoteUid) onRemoteJoined,
    required void Function(int remoteUid) onUserOffline,
  }) async {
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) => onJoined(),
        onUserJoined: (connection, remoteUid, elapsed) =>
            onRemoteJoined(remoteUid),
        onUserOffline: (connection, remoteUid, reason) =>
            onUserOffline(remoteUid),
      ),
    );
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: false,
      ),
    );
  }

  @override
  Future<void> leaveChannel(RtcEngine engine) async {
    await engine.leaveChannel();
  }

  @override
  Future<void> releaseEngine(RtcEngine engine) async {
    await engine.release();
  }
}

final agoraCallServiceProvider = Provider<AgoraCallService>((ref) {
  final svc = AgoraCallService(client: ref.watch(supabaseClientProvider));
  ref.onDispose(svc.dispose);
  return svc;
});
