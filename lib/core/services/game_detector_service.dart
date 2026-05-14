import 'dart:async';
import 'dart:io';

import 'package:app_usage/app_usage.dart';
import 'package:arena/data/models/target_game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:installed_apps/installed_apps.dart';

/// Detects whether the player has a target football game installed and
/// when one of them moves to the foreground during a match.
///
/// Backed by `installed_apps` (one-shot installation check) and
/// `app_usage` (rolling poll over a short window to spot the
/// foreground app). Both plugins are Android-only — iOS sandboxing
/// forbids inspecting other applications, so on iOS every method
/// returns an empty result without throwing.
///
/// PHASE 8.3 will subscribe to [foregroundGameStream] to gate the
/// recording start: as soon as eFootball / FIFA enters foreground the
/// foreground service flips on; when the player swipes back to ARENA
/// the stream emits `null` and we can offer the "did you finish?" CTA.
class GameDetectorService {
  GameDetectorService({GameDetectorPlatform? platform})
      : _platform = platform ?? const _DefaultGameDetectorPlatform();

  final GameDetectorPlatform _platform;

  /// Polling window for [foregroundGameStream]. Two seconds is the
  /// sweet spot for our use case: the OS coalesces usage events on a
  /// ~1s tick, so anything tighter just burns battery without
  /// meaningfully reducing detection lag.
  static const Duration defaultPollInterval = Duration(seconds: 2);

  /// Sliding window queried each tick. Must stay larger than
  /// [defaultPollInterval] to absorb scheduling jitter — at 1.5×
  /// poll, we never miss a tick even if the previous query took ~1s.
  static const Duration _foregroundLookback = Duration(seconds: 5);

  /// Returns the subset of [TargetGame] currently installed on the
  /// device. Empty on iOS or if the underlying plugin throws (typical
  /// when the manifest `<queries>` block is missing on Android 11+).
  Future<List<TargetGame>> checkInstalledTargetGames() async {
    final installed = <TargetGame>[];
    for (final game in TargetGame.values) {
      try {
        final present = await _platform.isAppInstalled(game.packageAndroid);
        if (present) installed.add(game);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[game-detector] isAppInstalled(${game.packageAndroid}) failed: $e\n$st');
        }
      }
    }
    return installed;
  }

  /// Probes whether the user has granted PACKAGE_USAGE_STATS.
  ///
  /// Best-effort: when the permission is missing, the underlying
  /// `UsageStatsManager` silently returns an empty list rather than
  /// throwing, so we can only flag "definitely denied" when the plugin
  /// itself raises a [PlatformException]. PHASE 8.3 may add a native
  /// `AppOpsManager.checkOpNoThrow` channel for a stronger signal.
  Future<bool> hasUsageStatsAccess() async {
    try {
      final now = DateTime.now();
      await _platform.getAppUsage(now.subtract(const Duration(seconds: 1)), now);
      return true;
    } on PlatformException {
      return false;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[game-detector] hasUsageStatsAccess failed: $e\n$st');
      }
      return false;
    }
  }

  /// One-shot foreground probe.
  ///
  /// Returns the target game whose `endDate` falls inside the
  /// [_foregroundLookback] window — that's our proxy for "the user is
  /// looking at this app right now". When two targets show up (rare —
  /// they share no UI affordance), we keep the most recently active.
  Future<TargetGame?> currentForegroundGame() async {
    final now = DateTime.now();
    List<AppUsageInfo> infos;
    try {
      infos = await _platform.getAppUsage(now.subtract(_foregroundLookback), now);
    } on PlatformException {
      return null;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[game-detector] currentForegroundGame failed: $e\n$st');
      }
      return null;
    }

    AppUsageInfo? mostRecent;
    for (final info in infos) {
      if (TargetGame.fromAndroidPackage(info.packageName) == null) continue;
      if (mostRecent == null || info.endDate.isAfter(mostRecent.endDate)) {
        mostRecent = info;
      }
    }
    if (mostRecent == null) return null;

    // Ignore stale entries: app_usage returns the cumulative usage
    // bucket since the period start, even if the app left foreground
    // 4 seconds ago. We only count it as foreground if `endDate` is
    // recent enough.
    final sinceLastActive = now.difference(mostRecent.endDate);
    if (sinceLastActive > _foregroundLookback) return null;

    return TargetGame.fromAndroidPackage(mostRecent.packageName);
  }

  /// Stream that emits whenever the foreground target game changes.
  ///
  /// Emits the current state immediately, then a new value only when
  /// the detected game transitions (`null` → game, game → `null`,
  /// game A → game B). Cancelling the subscription tears down the
  /// internal poll timer. On iOS the default platform implementation
  /// short-circuits so the stream only ever emits a single `null`.
  Stream<TargetGame?> foregroundGameStream({
    Duration pollInterval = defaultPollInterval,
  }) async* {
    TargetGame? last;
    // First tick is immediate so the UI is never empty for a poll
    // cycle on subscribe.
    final initial = await currentForegroundGame();
    last = initial;
    yield initial;

    while (true) {
      await Future<void>.delayed(pollInterval);
      final TargetGame? current;
      try {
        current = await currentForegroundGame();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[game-detector] poll failed: $e\n$st');
        }
        continue;
      }
      if (current != last) {
        last = current;
        yield current;
      }
    }
  }
}

/// Seam over the Android plugins, so tests can drive the service
/// without a running device.
abstract class GameDetectorPlatform {
  Future<bool> isAppInstalled(String packageName);
  Future<List<AppUsageInfo>> getAppUsage(DateTime start, DateTime end);
}

class _DefaultGameDetectorPlatform implements GameDetectorPlatform {
  const _DefaultGameDetectorPlatform();

  @override
  Future<bool> isAppInstalled(String packageName) async {
    if (!Platform.isAndroid) return false;
    final result = await InstalledApps.isAppInstalled(packageName);
    return result ?? false;
  }

  @override
  Future<List<AppUsageInfo>> getAppUsage(DateTime start, DateTime end) {
    if (!Platform.isAndroid) return Future.value(const <AppUsageInfo>[]);
    return AppUsage().getAppUsage(start, end);
  }
}
