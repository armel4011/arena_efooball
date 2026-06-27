import 'dart:async';
import 'dart:io';

import 'package:arena/core/services/livekit_token_client.dart';
import 'package:arena/core/utils/error_reporter.dart';
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
    this.maxDuration = const Duration(minutes: 25),
    bool? supportsCapture,
  })  : _tokenClient = tokenClient,
        _roomFactory = roomFactory ?? const _DefaultLiveKitRoomFactory(),
        // Capture d'écran = Android uniquement (comme le recorder natif).
        // Injectable pour les tests sur l'hôte.
        _supportsCapture = supportsCapture ?? Platform.isAndroid;

  final LiveKitTokenClient _tokenClient;
  final LiveKitRoomFactory _roomFactory;
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
      await room.enableScreenShare();
    } catch (e, st) {
      await reportError(e, st, context: 'LiveKitCaptureService.connect');
      // Rollback : on ferme une room éventuellement à moitié connectée.
      try {
        await _releaseRoom();
      } catch (_) {}
      _emit(LiveKitCaptureError('Failed to start LiveKit capture: $e'));
      rethrow;
    }

    _room = room;
    final startedAt = DateTime.now();
    _emit(LiveKitCapturePublishing(room: token.room, startedAt: startedAt));

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

  /// Libère la room courante sans changer d'état (helper interne).
  Future<void> _releaseRoom() async {
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
    await _room.localParticipant?.setScreenShareEnabled(true);
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
  );
  ref.onDispose(service.dispose);
  return service;
});
