import 'dart:async';

import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Action requested by the long-press menu inside the overlay isolate.
///
/// The main app subscribes via [RecordingOverlayController.actions] and
/// reacts (resume → no-op, pause → freeze auto-stop, forfeit → stop
/// recording + flag the player as forfeit on the server).
enum OverlayAction { focusMain, resume, pause, forfeit, unknown }

/// Drives the floating button rendered by `flutter_overlay_window`.
///
/// Owned by the main app (lives in the main isolate). Responsibilities:
///   * show / hide the overlay,
///   * emit a tick every second so the overlay's MM:SS timer stays in
///     sync without each isolate having to compute time independently,
///   * forward the user's long-press choices back as a typed
///     [OverlayAction] stream.
///
/// The 25-min auto-stop logic itself lives in `RecordingService` —
/// this controller is purely about the floating button's life cycle
/// and IPC.
class RecordingOverlayController {
  RecordingOverlayController({OverlayPlatform? platform})
      : _platform = platform ?? const _DefaultOverlayPlatform();

  final OverlayPlatform _platform;
  final _actions = StreamController<OverlayAction>.broadcast();

  StreamSubscription<dynamic>? _listener;
  Timer? _tickTimer;
  DateTime? _startedAt;

  /// Total length of a recording — must match `RecordingService.maxDuration`.
  /// Used by the overlay to flash a warning in the last 30 s.
  Duration totalDuration = const Duration(minutes: 25);

  /// Stream of typed actions raised inside the overlay (long-press menu).
  Stream<OverlayAction> get actions => _actions.stream;

  /// Shows the floating button and starts the per-second tick.
  ///
  /// [matchId] is currently unused but accepted so the API stays
  /// stable when we wire deep-link "tap on overlay → open match-room"
  /// in PHASE 8.5.
  Future<void> start({String? matchId}) async {
    final granted = await _platform.isPermissionGranted();
    if (!granted) {
      final ok = await _platform.requestPermission();
      if (!ok) {
        if (kDebugMode) {
          debugPrint('[overlay] user denied SYSTEM_ALERT_WINDOW permission');
        }
        return;
      }
    }

    await _platform.showOverlay();
    _startedAt = DateTime.now();
    _bindListener();
    _startTicking();
  }

  /// Hides the overlay and stops the tick timer.
  Future<void> stop() async {
    _tickTimer?.cancel();
    _tickTimer = null;
    _startedAt = null;
    await _listener?.cancel();
    _listener = null;
    await _platform.closeOverlay();
  }

  Future<void> dispose() async {
    await stop();
    await _actions.close();
  }

  void _bindListener() {
    _listener?.cancel();
    _listener = _platform.overlayListener.listen((event) {
      _actions.add(_parseAction(event));
    });
  }

  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = _startedAt;
      if (start == null) return;
      final elapsed = DateTime.now().difference(start);
      final remaining = totalDuration - elapsed;
      final isWarning = remaining <= const Duration(seconds: 30);
      _platform.shareData(
        RecordingOverlayMessages.tick(
          elapsedSeconds: elapsed.inSeconds,
          warning: isWarning,
        ),
      );
    });
  }

  static OverlayAction _parseAction(Object? event) {
    final raw = event is String ? event : event?.toString();
    return switch (raw) {
      RecordingOverlayMessages.focusMainType => OverlayAction.focusMain,
      RecordingOverlayMessages.askResumeType => OverlayAction.resume,
      RecordingOverlayMessages.askPauseType => OverlayAction.pause,
      RecordingOverlayMessages.askForfeitType => OverlayAction.forfeit,
      _ => OverlayAction.unknown,
    };
  }
}

/// Seam over `flutter_overlay_window` static API for tests.
abstract class OverlayPlatform {
  Future<bool> isPermissionGranted();
  Future<bool> requestPermission();
  Future<void> showOverlay();
  Future<void> closeOverlay();
  Future<void> shareData(Object data);
  Stream<dynamic> get overlayListener;
}

class _DefaultOverlayPlatform implements OverlayPlatform {
  const _DefaultOverlayPlatform();

  @override
  Future<bool> isPermissionGranted() {
    return FlutterOverlayWindow.isPermissionGranted();
  }

  @override
  Future<bool> requestPermission() async {
    final res = await FlutterOverlayWindow.requestPermission();
    return res ?? false;
  }

  @override
  Future<void> showOverlay() {
    return FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      positionGravity: PositionGravity.auto,
      width: 220,
      height: 220,
      overlayTitle: 'ARENA',
      overlayContent: 'Enregistrement en cours',
    );
  }

  @override
  Future<void> closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Future<void> shareData(Object data) async {
    await FlutterOverlayWindow.shareData(data);
  }

  @override
  Stream<dynamic> get overlayListener => FlutterOverlayWindow.overlayListener;
}

final recordingOverlayControllerProvider =
    Provider<RecordingOverlayController>((ref) {
  final controller = RecordingOverlayController();
  ref.onDispose(controller.dispose);
  return controller;
});
