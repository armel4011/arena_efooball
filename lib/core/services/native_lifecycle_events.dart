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

  Stream<NativeLifecycleEvent> get stream => _controller.stream;

  void _onNative(dynamic raw) {
    if (raw is! Map) return;
    final name = raw['event'];
    switch (name) {
      case 'media_projection_died':
        _controller.add(NativeLifecycleEvent.mediaProjectionDied);
    }
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
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
