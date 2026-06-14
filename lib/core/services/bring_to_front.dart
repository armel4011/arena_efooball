import 'dart:async';
import 'dart:io';

import 'package:arena/core/utils/error_reporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Brings the ARENA activity back to the foreground from the floating
/// overlay's "tap short" gesture (PHASE 8.5).
///
/// Backed by a tiny Kotlin method channel registered in
/// `MainActivity.kt`. On iOS it's a no-op — the iOS overlay flow does
/// not exist (iOS sandboxing forbids overlays on top of other apps).
class BringToFront {
  BringToFront({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('arena/native');

  final MethodChannel _channel;

  /// Best-effort: returns whether the platform reported a successful
  /// activity-relaunch. False on iOS, on missing native handler, or
  /// when the OS denies the launch (rare — typically when the app
  /// process was fully killed and relaunching it would require a fresh
  /// launcher intent).
  Future<bool> bringArenaToFront() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('bringToFront');
      return result ?? false;
    } on MissingPluginException {
      // Native handler not registered yet (debug build, hot reload race).
      // Fail silently — the overlay tap is best-effort.
      return false;
    } catch (e, st) {
      unawaited(reportError(e, st, context: 'BringToFront.bringArenaToFront'));
      return false;
    }
  }
}

final bringToFrontProvider = Provider<BringToFront>((_) => BringToFront());
