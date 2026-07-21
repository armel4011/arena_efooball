import 'dart:async';

import 'package:arena/core/utils/error_reporter.dart';
import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
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
  // Score saisi dans la notif (ScoreInputActivity, Étape B) — même type que le
  // score de l'overlay pour réutiliser le handler `_onOverlayScore`.
  final _scoreController = StreamController<OverlayScore>.broadcast();

  // Canal method pour POUSSER vers le natif (mise à jour de la notif de code).
  static const MethodChannel _method = MethodChannel('arena/native');

  Stream<NativeLifecycleEvent> get stream => _controller.stream;

  /// Le HOME a envoyé le code room via la réponse directe de la notification
  /// (repli Pixel 9 du panneau overlay). Le listener écrit `matches.room_code`.
  Stream<String> get roomCodeSubmitted => _codeController.stream;

  /// Score saisi depuis le bouton « Score » de la notif de contrôle (Étape B).
  /// Le listener (MatchRecordingLifecycle) le route vers `_onOverlayScore` :
  /// mappe selon le rôle, soumet le score et scelle la vidéo.
  Stream<OverlayScore> get scoreSubmitted => _scoreController.stream;

  /// Met à jour l'échange de code room dans la notif de contrôle native :
  ///   * [isHome] true → pastille « Envoyer » (puis « Renvoyer » une fois [code]
  ///     partagé : une room recréée dans eFootball change de code) ;
  ///   * [isHome] false → le code reçu s'affiche avec un bouton « Copier ».
  Future<void> updateRoomCodeNotification({
    required bool isHome,
    String? code,
  }) async {
    try {
      await _method.invokeMethod<void>('updateRoomCodeNotification', {
        'code': code,
        'isHome': isHome,
      });
    } catch (_) {
      // Canal down (CI / autre OS / service pas encore démarré) — non bloquant.
    }
  }

  /// Ouvre le dialogue de score natif (`ScoreInputActivity`) — LE MÊME que le
  /// bouton « Score » de la notif. Appelé quand le joueur tape « Score » sur le
  /// bouton flottant : l'app a SYSTEM_ALERT_WINDOW (overlay actif) donc peut
  /// démarrer l'activité en arrière-plan. Unifie les deux points d'entrée.
  Future<void> showScoreDialog() async {
    try {
      await _method.invokeMethod<void>('showScoreDialog');
    } catch (_) {
      // Canal down / autre OS — non bloquant.
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
      case 'recorder_bitrate_drift':
        _reportBitrateDrift(raw);
      case 'recorder_score_submitted':
        final my = raw['my'];
        final opp = raw['opp'];
        if (my is int && opp is int) {
          final myPen = raw['myPen'];
          final oppPen = raw['oppPen'];
          _scoreController.add(
            OverlayScore(
              my: my,
              opp: opp,
              viaPenalties: raw['viaPenalties'] == true,
              myPen: myPen is int ? myPen : null,
              oppPen: oppPen is int ? oppPen : null,
            ),
          );
        }
    }
  }

  /// Télémétrie prod : l'encodeur natif a produit un fichier au débit très
  /// supérieur à la cible (encodeur matériel qui ne respecte pas le CBR, cf.
  /// Samsung SD888). Remonté à Sentry pour repérer les MODÈLES fautifs sans
  /// avoir à les posséder. Le natif a déjà activé le repli logiciel pour ce
  /// modèle (`switchedToSoftware`) — c'est un signal d'observabilité, pas un
  /// crash. Voir `ArenaRecorderService.maybeReportBitrateDrift`.
  void _reportBitrateDrift(Map<dynamic, dynamic> raw) {
    final model = raw['model'];
    final actual = raw['actualKbps'];
    final target = raw['targetKbps'];
    final switched = raw['switchedToSoftware'] == true;
    unawaited(
      reportError(
        'Recorder bitrate drift: ${actual}kbps vs target ${target}kbps '
        'on $model',
        StackTrace.current,
        context: 'ArenaRecorder.bitrateDrift',
        extra: {
          'recorder_drift': {
            'model': raw['model'],
            'encoder': raw['encoder'],
            'targetKbps': raw['targetKbps'],
            'actualKbps': raw['actualKbps'],
            'sizeBytes': raw['sizeBytes'],
            'durationMs': raw['durationMs'],
            'switchedToSoftware': switched,
          },
        },
        hint: switched
            ? 'repli encodeur logiciel activé pour les prochaines captures'
            : 'déjà en logiciel — dérive persistante (à investiguer)',
      ),
    );
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
    await _codeController.close();
    await _scoreController.close();
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

/// Score saisi depuis le bouton « Score » de la notif de contrôle (Étape B) →
/// routé par `MatchRecordingLifecycle` vers `_onOverlayScore` (submit + scelle).
final nativeScoreSubmittedProvider = StreamProvider<OverlayScore>((ref) {
  return ref.watch(nativeLifecycleEventsProvider).scoreSubmitted;
});
