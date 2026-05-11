import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Action requested by the expanded menu inside the overlay isolate.
///
/// The main app subscribes via [RecordingOverlayController.actions] and
/// reacts (resume / pause → freeze auto-stop, saveAndStop → stop +
/// export MP4, forfeit → stop + mark forfeit).
enum OverlayAction {
  focusMain,
  resume,
  pause,
  forfeit,
  saveAndStop,
  unknown,
}

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
  ReceivePort? _port;
  StreamSubscription<dynamic>? _portSub;
  Timer? _tickTimer;
  DateTime? _startedAt;
  // While paused: Duration the chronometer was at when the user paused.
  // null while running. Set in pause(), cleared in resume() after rebasing
  // _startedAt so the next ticks resume from the same MM:SS.
  Duration? _pausedElapsed;

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
    _bindIsolatePort();
    _startTicking();
  }

  /// Hides the overlay and stops the tick timer.
  Future<void> stop() async {
    _tickTimer?.cancel();
    _tickTimer = null;
    _startedAt = null;
    _pausedElapsed = null;
    await _listener?.cancel();
    _listener = null;
    await _portSub?.cancel();
    _portSub = null;
    _port?.close();
    _port = null;
    IsolateNameServer.removePortNameMapping(
      RecordingOverlayMessages.mainPortName,
    );
    await _platform.closeOverlay();
  }

  /// Freezes the chronometer in the overlay isolate and pushes a
  /// `paused` tick so the floating button switches to the yellow
  /// "PAUSE" face. Idempotent.
  Future<void> pause() async {
    final start = _startedAt;
    if (start == null || _pausedElapsed != null) return;
    _pausedElapsed = DateTime.now().difference(start);
    await _platform.shareData(
      RecordingOverlayMessages.tick(
        elapsedSeconds: _pausedElapsed!.inSeconds,
        warning: false,
        paused: true,
      ),
    );
  }

  /// Resumes the chronometer from the paused MM:SS without losing the
  /// elapsed time accumulated before the pause. Idempotent.
  Future<void> resume() async {
    final paused = _pausedElapsed;
    if (paused == null) return;
    // Rebase the start anchor so DateTime.now() - _startedAt == paused
    // immediately after resume — keeps the existing tick formula intact.
    _startedAt = DateTime.now().subtract(paused);
    _pausedElapsed = null;
    // Push an immediate tick so the overlay UI flips to red without
    // waiting for the next 1-second period.
    await _platform.shareData(
      RecordingOverlayMessages.tick(
        elapsedSeconds: paused.inSeconds,
        warning: totalDuration - paused <= const Duration(seconds: 30),
      ),
    );
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

  /// Registers a `ReceivePort` so the overlay isolate can deliver
  /// action strings via `SendPort.send`. This is the resilient
  /// fallback to `flutter_overlay_window`'s `shareData` channel which
  /// stops delivering on MIUI / Android 12+ once the main activity is
  /// paused.
  void _bindIsolatePort() {
    // Defensive: drop any leftover mapping from a previous run.
    IsolateNameServer.removePortNameMapping(
      RecordingOverlayMessages.mainPortName,
    );
    final port = ReceivePort();
    final registered = IsolateNameServer.registerPortWithName(
      port.sendPort,
      RecordingOverlayMessages.mainPortName,
    );
    if (!registered && kDebugMode) {
      debugPrint('[overlay-ctrl] failed to register isolate port');
    }
    _port = port;
    _portSub = port.listen((event) {
      _actions.add(_parseAction(event));
    });
  }

  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // While paused, _pausedElapsed is non-null and pause() already
      // pushed the frozen frame — skip until resume() reseats _startedAt.
      if (_pausedElapsed != null) return;
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
      RecordingOverlayMessages.askSaveStopType => OverlayAction.saveAndStop,
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
    // `flutter_overlay_window` interprets width/height as raw pixels, not
    // dp. On a 3x density display 220 px is only ~73 dp — the four mini
    // buttons (offset 64 dp from the centre of the cluster) would render
    // outside the native window and stay invisible. Scale by the device
    // pixel ratio so the rendered SizedBox(220, 220) actually fits.
    final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
    final sizePx = (220 * dpr).round();
    return FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      positionGravity: PositionGravity.auto,
      width: sizePx,
      height: sizePx,
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
