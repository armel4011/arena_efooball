import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/core/services/agora_token_client.dart';
import 'package:arena/core/services/native_lifecycle_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  /// `true` pendant qu'un join est en cours — neutralise les appels
  /// concurrents (double-tap « Démarrer », page de live ré-ouverte) qui
  /// feraient rejeter le second joinChannel par Agora (err -17).
  bool _joinInProgress = false;

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
    // Garde anti-concurrence — deux joinChannel en parallèle (double-tap,
    // page ré-ouverte) sont rejetés par Agora (ERR_JOIN_CHANNEL_REJECTED).
    if (_joinInProgress) return;
    _joinInProgress = true;
    try {
      // Une session déjà ouverte doit être quittée avant de rejoindre,
      // sinon Agora rejette le nouveau joinChannel (err -17).
      final existing = _engine;
      if (existing != null &&
          _state is! AgoraIdle &&
          _state is! AgoraLeft) {
        try {
          await _platform.leaveChannel(existing);
        } catch (_) {/* on tente le join malgré tout */}
      }
      await _doJoin(matchId: matchId, role: role);
    } finally {
      _joinInProgress = false;
    }
  }

  Future<void> _doJoin({
    required String matchId,
    required AgoraRole role,
  }) async {
    debugPrint('[agora] join role=$role match=$matchId');
    _emit(AgoraJoining(channel: 'pending', role: role));

    AgoraToken token;
    try {
      token = await _tokenClient.fetch(matchId: matchId, role: role);
    } on SocketException catch (e) {
      _emit(AgoraFailed('token_fetch_failed: $e'));
      rethrow;
    } on TimeoutException catch (e) {
      _emit(AgoraFailed('token_fetch_failed: $e'));
      rethrow;
    } catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      _emit(AgoraFailed('token_fetch_failed: $e'));
      rethrow;
    }

    debugPrint(
      '[agora] token ok channel=${token.channelName} uid=${token.uid}',
    );
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
    } on PlatformException catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      _emit(AgoraFailed('join_failed: $e'));
      rethrow;
    } on SocketException catch (e) {
      _emit(AgoraFailed('join_failed: $e'));
      rethrow;
    } on TimeoutException catch (e) {
      _emit(AgoraFailed('join_failed: $e'));
      rethrow;
    } catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
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
  /// Handler du dernier join — retiré avant d'en réenregistrer un, sinon
  /// les handlers s'accumulent à chaque rejoin (callbacks émis en double).
  RtcEngineEventHandler? _handler;

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
    final previous = _handler;
    if (previous != null) {
      engine.unregisterEventHandler(previous);
    }
    final handler = RtcEngineEventHandler(
      onError: (err, msg) => debugPrint('[agora] error $err: $msg'),
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint('[agora] joinChannelSuccess');
        onLocalJoined();
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        debugPrint('[agora] userJoined remoteUid=$remoteUid');
        onRemoteJoined(remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) =>
          debugPrint('[agora] userOffline remoteUid=$remoteUid'),
      onLocalVideoStateChanged: (source, state, reason) => debugPrint(
        '[agora] localVideo source=$source state=$state reason=$reason',
      ),
      onRemoteVideoStateChanged:
          (connection, remoteUid, state, reason, elapsed) => debugPrint(
        '[agora] remoteVideo uid=$remoteUid state=$state reason=$reason',
      ),
    );
    _handler = handler;
    engine.registerEventHandler(handler);
    final isBroadcaster = role == AgoraRole.broadcaster;
    await engine.setClientRole(
      role: isBroadcaster
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );
    if (isBroadcaster) {
      // Le live diffuse l'ÉCRAN du téléphone (le gameplay), pas la
      // caméra. `startScreenCapture` déclenche le dialogue système
      // Android « Autoriser ARENA à diffuser l'écran ». `captureAudio`
      // capte le son du jeu ; le micro n'est pas publié (choix produit).
      debugPrint('[agora] startScreenCapture…');
      await engine.startScreenCapture(
        const ScreenCaptureParameters2(
          captureVideo: true,
          captureAudio: true,
        ),
      );
      debugPrint('[agora] startScreenCapture OK');
    }
    debugPrint('[agora] joinChannel($channelId)…');
    await engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: ChannelMediaOptions(
        clientRoleType: isBroadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        // Broadcaster : publie le flux de capture d'écran (vidéo + son
        // du jeu). La caméra et le micro restent volontairement coupés.
        publishScreenCaptureVideo: isBroadcaster,
        publishScreenCaptureAudio: isBroadcaster,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
        autoSubscribeAudio: !isBroadcaster,
        autoSubscribeVideo: !isBroadcaster,
      ),
    );
  }

  @override
  Future<void> leaveChannel(RtcEngine engine) async {
    await engine.leaveChannel();
    // Coupe la capture d'écran si on diffusait — sans effet côté audience.
    await engine.stopScreenCapture();
  }

  @override
  Future<void> releaseEngine(RtcEngine engine) async {
    await engine.release();
    _handler = null;
  }
}

final agoraStreamingServiceProvider = Provider<AgoraStreamingService>((ref) {
  final svc = AgoraStreamingService(
    tokenClient: ref.watch(agoraTokenClientProvider),
  );
  // Quand le natif Android signale que MediaProjection est morte (user a
  // tapé Stop sur la notif système, ou perm révoquée), on doit libérer
  // Agora — sinon son AudioRecord retry en boucle (`AudioFlinger -22`)
  // jusqu'à saturer le main thread et freezer l'overlay flottant.
  final nativeEvents = ref.watch(nativeLifecycleEventsProvider);
  final sub = nativeEvents.stream.listen((event) async {
    if (event != NativeLifecycleEvent.mediaProjectionDied) return;
    final state = svc.state;
    // Pas de leave si on n'est pas connecté — évite un appel inutile au
    // plugin Agora et un warning "engine not initialized".
    if (state is AgoraIdle || state is AgoraLeft) return;
    try {
      await svc.leave();
    } catch (e) {
      debugPrint('[agora] leave on mediaProjectionDied failed: $e');
    }
  });
  ref
    ..onDispose(sub.cancel)
    ..onDispose(svc.dispose);
  return svc;
});
