import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Évènements bas-niveau poussés Native → Dart via l'EventChannel
/// `arena/native/events`. Permet au natif (ArenaRecorderService,
/// MainActivity) de signaler à Dart des situations hors-flow standard.
enum NativeLifecycleEvent {
  /// L'utilisateur a tapé "Stop" sur la notification système Android de
  /// MediaProjection, ou la permission a été révoquée. Quand Agora
  /// publie un screen capture via la même projection, son AudioRecord
  /// interne retry en boucle après ce signal (`AudioFlinger -22`) —
  /// les listeners doivent appeler `agoraStreamingService.leave()` pour
  /// libérer proprement.
  mediaProjectionDied,

  /// L'utilisateur a tapé "Arrêter" sur la notification de capture
  /// anti-triche LiveKit (LivekitCaptureFgsService) — ou sur le bouton
  /// flottant. Le listener doit appeler `liveKitCaptureService.stop()`
  /// (déconnexion room → egress_ended côté serveur + arrêt du FGS).
  liveKitStopRequested,

  /// L'utilisateur a tapé "Arrêter" sur la notification de contrôle native
  /// (ArenaRecorderService). Le listener doit appeler `coordinator.stopCleanly()`
  /// pour un arrêt COORDONNÉ des deux surfaces (recording + notif + bouton
  /// flottant), symétrique au stop du bouton flottant.
  recorderStopRequested,
}

/// Bridge l'EventChannel `arena/native/events` vers un broadcast Stream
/// Dart. Les listeners s'abonnent via [stream].
class NativeLifecycleEvents {
  NativeLifecycleEvents({EventChannel? channel})
      : _channel = channel ?? const EventChannel('arena/native/events') {
    _subscription = _channel.receiveBroadcastStream().listen(
          _onNative,
          onError: (_) {/* le canal peut être down côté CI / autres OS */},
        );
  }

  final EventChannel _channel;
  late final StreamSubscription<dynamic> _subscription;
  final _controller = StreamController<NativeLifecycleEvent>.broadcast();
  // Code room tapé par le HOME dans la réponse directe de la notif de contrôle.
  final _codeController = StreamController<String>.broadcast();

  // Canal method pour POUSSER vers le natif (mise à jour de la notif de code).
  static const MethodChannel _method = MethodChannel('arena/native');

  Stream<NativeLifecycleEvent> get stream => _controller.stream;

  /// Le HOME a envoyé le code room via la réponse directe de la notification
  /// (repli Pixel 9 du panneau overlay). Le listener écrit `matches.room_code`.
  Stream<String> get roomCodeSubmitted => _codeController.stream;

  /// Met à jour l'échange de code room dans la notif de contrôle native :
  ///   * HOME → [awaitingCode] true : affiche la réponse directe « Envoyer le code ».
  ///   * AWAY → [code] non nul : affiche le code reçu + un bouton « Copier ».
  Future<void> updateRoomCodeNotification({
    required bool awaitingCode,
    String? code,
  }) async {
    try {
      await _method.invokeMethod<void>('updateRoomCodeNotification', {
        'code': code,
        'awaitingCode': awaitingCode,
      });
    } catch (_) {
      // Canal down (CI / autre OS / service pas encore démarré) — non bloquant.
    }
  }

  /// Affiche la notif « Enregistrement arrêté » (bouton « Ouvrir ») : surface
  /// FIABLE de reprise après un arrêt propre EN COURS de match, portée du
  /// bouton flottant idle (gris « Reprendre ») dont le rendu reste intermittent
  /// (limite flutter_overlay_window). Marche sans superposition (Pixel 9) et
  /// app en arrière-plan (auto-stop 25 min). No-op hors Android / canal down.
  Future<void> showStoppedNotification() async {
    try {
      await _method.invokeMethod<void>('showStoppedNotification');
    } catch (_) {
      // Canal down (CI / autre OS) — non bloquant.
    }
  }

  /// Retire la notif « arrêté » : reprise, forfait, état terminal, sortie de
  /// salle. No-op si aucune n'est affichée.
  Future<void> hideStoppedNotification() async {
    try {
      await _method.invokeMethod<void>('hideStoppedNotification');
    } catch (_) {
      // Canal down (CI / autre OS) — non bloquant.
    }
  }

  void _onNative(dynamic raw) {
    if (raw is! Map) return;
    final name = raw['event'];
    switch (name) {
      case 'media_projection_died':
        _controller.add(NativeLifecycleEvent.mediaProjectionDied);
      case 'livekit_stop_requested':
        _controller.add(NativeLifecycleEvent.liveKitStopRequested);
      case 'recorder_stop_requested':
        _controller.add(NativeLifecycleEvent.recorderStopRequested);
      case 'room_code_submitted':
        final code = raw['code'];
        if (code is String && code.isNotEmpty) _codeController.add(code);
    }
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
    await _codeController.close();
  }
}

final nativeLifecycleEventsProvider = Provider<NativeLifecycleEvents>((ref) {
  final svc = NativeLifecycleEvents();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Wrapper StreamProvider pour pouvoir `ref.listen` les évènements
/// natifs depuis un widget ConsumerStatefulWidget. Le service sous-jacent
/// est déjà broadcast — pas de duplication d'écoute côté plugin natif.
final nativeLifecycleEventsStreamProvider =
    StreamProvider<NativeLifecycleEvent>((ref) {
  return ref.watch(nativeLifecycleEventsProvider).stream;
});

/// Codes room envoyés par le HOME via la réponse directe de la notif de
/// contrôle → à écrire dans `matches.room_code` par le listener.
final nativeRoomCodeSubmittedProvider = StreamProvider<String>((ref) {
  return ref.watch(nativeLifecycleEventsProvider).roomCodeSubmitted;
});
