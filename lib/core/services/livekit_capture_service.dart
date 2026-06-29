import 'dart:async';
import 'dart:io';

import 'package:arena/core/services/bring_to_front.dart';
import 'package:arena/core/services/livekit_token_client.dart';
import 'package:arena/core/services/recording_overlay_controller.dart';
import 'package:arena/core/utils/error_reporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

/// Capture anti-triche via LiveKit Cloud (publish-only).
///
/// Chaque joueur publie SON propre gameplay (screen-share) dans la room
/// `match_<id>`. Le flux n'est pas relu par l'adversaire (le jeton émis par
/// `livekit-token` a `canSubscribe = false`) : c'est Track Egress, côté
/// serveur, qui enregistre la piste pour consultation admin (cf.
/// `livekit-anticheat-start`, PHASE 5).
///
/// Android-only pour la capture d'écran (comme le recorder natif). iOS exige
/// une Broadcast Upload Extension ReplayKit (manip Xcode) — documenté, reporté.
///
/// ⚠️ Contrainte MediaProjection (Android 14+) : une seule capture d'écran
/// peut tourner à la fois. Ce service et le recorder natif sont donc
/// MUTUELLEMENT EXCLUSIFS — seul le provider anti-triche actif démarre une
/// capture (cf. `AntiCheatProvider`, PHASE 3+).
sealed class LiveKitCaptureState {
  const LiveKitCaptureState();
}

class LiveKitCaptureIdle extends LiveKitCaptureState {
  const LiveKitCaptureIdle();
}

class LiveKitCaptureConnecting extends LiveKitCaptureState {
  const LiveKitCaptureConnecting();
}

class LiveKitCapturePublishing extends LiveKitCaptureState {
  const LiveKitCapturePublishing({
    required this.room,
    required this.startedAt,
  });

  final String room;
  final DateTime startedAt;

  Duration elapsed({DateTime? now}) =>
      (now ?? DateTime.now()).difference(startedAt);
}

class LiveKitCaptureStopping extends LiveKitCaptureState {
  const LiveKitCaptureStopping();
}

class LiveKitCaptureError extends LiveKitCaptureState {
  const LiveKitCaptureError(this.message);
  final String message;
}

/// Pilote une session de capture LiveKit (connexion room + publication
/// screen-share). N'enregistre rien lui-même : l'enregistrement est délégué
/// à Track Egress côté serveur.
class LiveKitCaptureService {
  LiveKitCaptureService({
    required LiveKitTokenClient tokenClient,
    LiveKitRoomFactory? roomFactory,
    ScreenCaptureForegroundService? foregroundService,
    RecordingOverlayController? overlay,
    BringToFront? bringToFront,
    this.maxDuration = const Duration(minutes: 25),
    bool? supportsCapture,
  })  : _tokenClient = tokenClient,
        _roomFactory = roomFactory ?? const _DefaultLiveKitRoomFactory(),
        _foregroundService =
            foregroundService ?? const _PlatformScreenCaptureForegroundService(),
        _overlay = overlay,
        _bringToFront = bringToFront,
        // Capture d'écran = Android uniquement (comme le recorder natif).
        // Injectable pour les tests sur l'hôte.
        _supportsCapture = supportsCapture ?? Platform.isAndroid;

  final LiveKitTokenClient _tokenClient;
  final LiveKitRoomFactory _roomFactory;
  final ScreenCaptureForegroundService _foregroundService;
  // Bouton flottant overlay (mode « simple ») pour revenir à ARENA / arrêter
  // pendant la capture egress. Null = pas d'overlay (tests / iOS).
  final RecordingOverlayController? _overlay;
  final BringToFront? _bringToFront;
  StreamSubscription<OverlayAction>? _overlaySub;
  final bool _supportsCapture;

  /// Plafond dur, aligné sur le recorder natif (25 min couvrent match +
  /// prolongations + tirs au but eFootball / EA FC Mobile).
  final Duration maxDuration;

  final _stateController = StreamController<LiveKitCaptureState>.broadcast();
  LiveKitCaptureState _state = const LiveKitCaptureIdle();
  LiveKitRoomHandle? _room;
  Timer? _autoStop;

  LiveKitCaptureState get state => _state;
  Stream<LiveKitCaptureState> get stateStream => _stateController.stream;

  /// Récupère un jeton publish-only, se connecte à la room du match et
  /// publie le partage d'écran. Lève [StateError] si déjà actif.
  Future<void> start({required String matchId}) async {
    if (_state is! LiveKitCaptureIdle && _state is! LiveKitCaptureError) {
      throw StateError('LiveKit capture already active');
    }
    if (!_supportsCapture) {
      // iOS : la capture d'écran tierce passe par ReplayKit (extension
      // Broadcast Upload), non câblée ici. No-op silencieux.
      _emit(const LiveKitCaptureIdle());
      return;
    }

    _emit(const LiveKitCaptureConnecting());

    LiveKitToken token;
    try {
      token = await _tokenClient.fetch(matchId: matchId);
    } catch (e, st) {
      await reportError(e, st, context: 'LiveKitCaptureService.fetchToken');
      _emit(LiveKitCaptureError('Failed to fetch LiveKit token: $e'));
      rethrow;
    }

    LiveKitRoomHandle room;
    try {
      room = await _roomFactory.connect(url: token.url, token: token.token);
      // On suit la room dès la connexion pour que le rollback ci-dessous la
      // libère (et coupe le FGS) si `enableScreenShare` échoue.
      _room = room;
      // Android 14+ : un foreground service de type mediaProjection doit
      // tourner AVANT de démarrer la capture d'écran, sinon l'OS tue l'app.
      // flutter_webrtc n'en fournit pas — on lance notre coquille Kotlin.
      await _foregroundService.start();
      await room.enableScreenShare();
    } catch (e, st) {
      await reportError(e, st, context: 'LiveKitCaptureService.connect');
      // Rollback : on coupe le FGS + ferme une room à moitié connectée.
      try {
        await _releaseRoom();
      } catch (_) {}
      _emit(LiveKitCaptureError('Failed to start LiveKit capture: $e'));
      rethrow;
    }

    final startedAt = DateTime.now();
    _emit(LiveKitCapturePublishing(room: token.room, startedAt: startedAt));

    // Bouton flottant overlay (mode simple : ouvrir ARENA + stop) — comme le
    // recorder natif, il permet de revenir à ARENA et de couper la capture
    // depuis l'app de jeu. Best-effort : si l'overlay/permission échoue, la
    // capture continue (la notif système reste le filet). La permission
    // SYSTEM_ALERT_WINDOW est demandée en amont par MatchRecordingLifecycle.
    final overlay = _overlay;
    if (overlay != null && _supportsCapture) {
      try {
        await overlay.start(matchId: matchId, simpleMode: true);
        _overlaySub = overlay.actions.listen(_onOverlayAction);
      } catch (e, st) {
        unawaited(
          reportError(e, st, context: 'LiveKitCaptureService.overlayStart'),
        );
      }
    }

    _autoStop?.cancel();
    _autoStop = Timer(maxDuration, () {
      if (_state is LiveKitCapturePublishing) {
        unawaited(stop());
      }
    });
  }

  /// Coupe le partage d'écran, se déconnecte et libère la room. Idempotent.
  Future<void> stop() async {
    if (_state is! LiveKitCapturePublishing) {
      // Rien d'actif : on libère quand même une room résiduelle au cas où.
      await _releaseRoom();
      if (_state is! LiveKitCaptureIdle) _emit(const LiveKitCaptureIdle());
      return;
    }
    _autoStop?.cancel();
    _autoStop = null;

    _emit(const LiveKitCaptureStopping());
    await _releaseRoom();
    _emit(const LiveKitCaptureIdle());
  }

  /// Réagit aux taps du bouton flottant overlay (mode simple) :
  ///   * `focusMain` (ouvrir ARENA) → ramène l'activité au premier plan ;
  ///   * `saveAndStop` (stop) → coupe la capture (room → egress_ended).
  /// Les autres actions (pause/forfait/live) n'existent pas en mode simple.
  void _onOverlayAction(OverlayAction action) {
    switch (action) {
      case OverlayAction.focusMain:
        unawaited(_bringToFront?.bringArenaToFront() ?? Future.value());
      case OverlayAction.saveAndStop:
        unawaited(stop());
      case OverlayAction.resume:
      case OverlayAction.pause:
      case OverlayAction.forfeit:
      case OverlayAction.goLive:
      case OverlayAction.unknown:
        break;
    }
  }

  /// Libère la room courante sans changer d'état (helper interne).
  Future<void> _releaseRoom() async {
    // Coupe l'overlay AVANT la room — idempotent, et évite que le bouton
    // flottant reste affiché si la fermeture de room traîne.
    await _overlaySub?.cancel();
    _overlaySub = null;
    try {
      await _overlay?.stop();
    } catch (_) {}

    final room = _room;
    _room = null;
    if (room == null) return;
    try {
      await room.disableScreenShare();
    } catch (_) {}
    try {
      await room.disconnect();
    } catch (_) {}
    try {
      await room.dispose();
    } catch (_) {}
    // Le FGS n'est démarré qu'après l'assignation de `_room` : on le coupe
    // donc ici, une fois la capture terminée (idempotent côté natif).
    try {
      await _foregroundService.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _autoStop?.cancel();
    await _releaseRoom();
    await _stateController.close();
  }

  void _emit(LiveKitCaptureState next) {
    _state = next;
    _stateController.add(next);
  }
}

/// Seam au-dessus de `livekit_client` — les tests injectent un faux sans
/// monter le plugin natif WebRTC (façon `RecordingPlatform`).
// ignore: one_member_abstracts
abstract class LiveKitRoomFactory {
  Future<LiveKitRoomHandle> connect({
    required String url,
    required String token,
  });
}

/// Poignée minimale sur une [Room] LiveKit connectée.
abstract class LiveKitRoomHandle {
  Future<void> enableScreenShare();
  Future<void> disableScreenShare();
  Future<void> disconnect();
  Future<void> dispose();
}

/// Pilote le foreground service de capture d'écran natif (Android).
///
/// flutter_webrtc lance la MediaProjection lui-même mais ne fournit aucun
/// foreground service ; Android 14+ en exige un de type `mediaProjection`
/// AVANT le démarrage de la projection. Ce seam déclenche notre coquille
/// Kotlin [`LivekitCaptureFgsService`] via le canal `arena/native`. Injectable
/// pour les tests (no-op).
abstract class ScreenCaptureForegroundService {
  Future<void> start();
  Future<void> stop();
}

class _PlatformScreenCaptureForegroundService
    implements ScreenCaptureForegroundService {
  const _PlatformScreenCaptureForegroundService();

  static const _channel = MethodChannel('arena/native');

  @override
  Future<void> start() async {
    await _channel.invokeMethod<void>('startLivekitCaptureFgs');
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod<void>('stopLivekitCaptureFgs');
  }
}

class _DefaultLiveKitRoomFactory implements LiveKitRoomFactory {
  const _DefaultLiveKitRoomFactory();

  @override
  Future<LiveKitRoomHandle> connect({
    required String url,
    required String token,
  }) async {
    final room = Room(
      roomOptions: const RoomOptions(
        // Publish-only : pas d'abonnement, donc adaptiveStream inutile.
        adaptiveStream: false,
        // Réduit CPU/bande passante côté publieur quand aucun abonné.
        dynacast: true,
      ),
    );
    await room.connect(url, token);
    return _LiveKitRoomHandle(room);
  }
}

class _LiveKitRoomHandle implements LiveKitRoomHandle {
  _LiveKitRoomHandle(this._room);

  final Room _room;

  @override
  Future<void> enableScreenShare() async {
    // Déclenche la demande MediaProjection système + le foreground service
    // de capture d'écran (flutter_webrtc). Mutuellement exclusif avec le
    // recorder natif (cf. AntiCheatProvider).
    //
    // Plafond d'encodage explicite : sans options, LiveKit publie au défaut
    // `screenShareH1080FPS15` = 1080p / 2,5 Mbps. Pour la REVUE anti-triche,
    // 720p / 15 fps / 1,5 Mbps suffit largement à lire le HUD et le score, et
    // ~divise par deux le coût Track Egress (bande passante facturée) ET le
    // stockage Supabase (J+1). Aligné sur le preset screen-share 720p validé
    // par LiveKit. Descendre à 540p/0,8 Mbps (= recorder natif) si besoin de
    // serrer encore, au prix d'un texte plus mou.
    await _room.localParticipant?.setScreenShareEnabled(
      true,
      screenShareCaptureOptions: const ScreenShareCaptureOptions(
        maxFrameRate: 15,
        params: VideoParameters(
          dimensions: VideoDimensions(1280, 720),
          encoding: VideoEncoding(maxFramerate: 15, maxBitrate: 1500 * 1000),
        ),
      ),
    );
  }

  @override
  Future<void> disableScreenShare() async {
    await _room.localParticipant?.setScreenShareEnabled(false);
  }

  @override
  Future<void> disconnect() => _room.disconnect();

  @override
  Future<void> dispose() => _room.dispose();
}

final liveKitCaptureServiceProvider = Provider<LiveKitCaptureService>((ref) {
  final service = LiveKitCaptureService(
    tokenClient: ref.watch(liveKitTokenClientProvider),
    overlay: ref.watch(recordingOverlayControllerProvider),
    bringToFront: ref.watch(bringToFrontProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Flux d'état de la capture LiveKit (pour la bannière du cycle de vie).
final liveKitCaptureStateProvider =
    StreamProvider<LiveKitCaptureState>((ref) {
  final service = ref.watch(liveKitCaptureServiceProvider);
  return service.stateStream;
});
