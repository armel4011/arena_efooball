import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';

final _filenameRandom = Random();

/// State machine for the anti-cheat screen recorder.
sealed class RecordingState {
  const RecordingState();
}

class RecordingIdle extends RecordingState {
  const RecordingIdle();
}

class RecordingStarting extends RecordingState {
  const RecordingStarting();
}

class RecordingActive extends RecordingState {
  const RecordingActive({
    required this.session,
    required this.startedAt,
  });

  final MatchStream session;
  final DateTime startedAt;

  Duration elapsed({DateTime? now}) =>
      (now ?? DateTime.now()).difference(startedAt);
}

class RecordingStopping extends RecordingState {
  const RecordingStopping();
}

class RecordingError extends RecordingState {
  const RecordingError(this.message);
  final String message;
}

/// Outcome of a stop() call.
class RecordingResult {
  const RecordingResult({
    required this.session,
    required this.localPath,
    required this.duration,
  });

  final MatchStream session;
  final String localPath;
  final Duration duration;
}

/// Records the player's screen during a match.
///
/// Android-only — iOS forbids third-party screen recording from outside
/// the app. The service auto-stops at [maxDuration] (25 min, mirroring
/// Q2 of the PHASE 8 product brief). Upload to Supabase Storage is the
/// caller's responsibility — see `RecordingUploader`.
class RecordingService {
  RecordingService({
    required MatchStreamRepository streamRepository,
    RecordingPlatform? platform,
    this.maxDuration = const Duration(minutes: 25),
  })  : _repo = streamRepository,
        _platform = platform ?? const _DefaultRecordingPlatform();

  final MatchStreamRepository _repo;
  final RecordingPlatform _platform;

  /// Hard cap enforced by the auto-stop timer. Mirrors Q2 in the PHASE 8
  /// product brief (25 min covers full match + extra time + penalty
  /// shootout for eFootball / EA FC Mobile).
  final Duration maxDuration;

  final _stateController = StreamController<RecordingState>.broadcast();
  RecordingState _state = const RecordingIdle();
  Timer? _autoStop;

  RecordingState get state => _state;
  Stream<RecordingState> get stateStream => _stateController.stream;

  /// Opens a recording session in DB, then starts the OS-level screen
  /// recording with branded foreground notification. Throws
  /// [StateError] if a recording is already in progress.
  Future<MatchStream> start({
    required String matchId,
    required String playerId,
    String notificationTitle = 'ARENA',
    String notificationMessage = 'Enregistrement du match en cours',
  }) async {
    if (_state is! RecordingIdle && _state is! RecordingError) {
      throw StateError('Recording already active');
    }

    _emit(const RecordingStarting());

    MatchStream session;
    try {
      session = await _repo.openSession(matchId: matchId, playerId: playerId);
    } catch (e) {
      _emit(RecordingError('Failed to open recording session: $e'));
      rethrow;
    }

    // User-facing filename — short, predictable, no PII. The full mapping
    // back to (matchId, streamId) lives in the streams DB row.
    final filename =
        'match_${_filenameRandom.nextInt(999999).toString().padLeft(6, '0')}';
    bool started;
    try {
      started = await _platform.startRecording(
        filename: filename,
        notificationTitle: notificationTitle,
        notificationMessage: notificationMessage,
      );
    } catch (e) {
      // Rollback DB session — recording never actually started.
      await _safeMarkEnded(session.id);
      _emit(RecordingError('Failed to start screen recorder: $e'));
      rethrow;
    }

    if (!started) {
      await _safeMarkEnded(session.id);
      _emit(const RecordingError('User denied MediaProjection consent'));
      throw const RecordingException('User denied MediaProjection consent');
    }

    final startedAt = DateTime.now();
    _emit(RecordingActive(session: session, startedAt: startedAt));

    _autoStop?.cancel();
    _autoStop = Timer(maxDuration, () {
      if (_state is RecordingActive) {
        // Best-effort: ignore errors in auto-stop, the user will see
        // an error state surfaced by stop() if anything blew up.
        unawaited(stop());
      }
    });

    return session;
  }

  /// Stops the active recording, closes the DB session, and returns the
  /// local file path. Idempotent — calling stop on an idle service is
  /// a no-op and returns null.
  Future<RecordingResult?> stop() async {
    final current = _state;
    if (current is! RecordingActive) {
      return null;
    }
    _autoStop?.cancel();
    _autoStop = null;

    _emit(const RecordingStopping());

    String localPath;
    try {
      localPath = await _platform.stopRecording();
    } catch (e) {
      _emit(RecordingError('Failed to stop screen recorder: $e'));
      // Don't rethrow — we still want to mark the session ended in DB
      // so it's not left dangling forever.
      await _safeMarkEnded(current.session.id);
      return null;
    }

    await _safeMarkEnded(current.session.id);

    final duration = DateTime.now().difference(current.startedAt);
    _emit(const RecordingIdle());

    return RecordingResult(
      session: current.session,
      localPath: localPath,
      duration: duration,
    );
  }

  Future<void> dispose() async {
    _autoStop?.cancel();
    await _stateController.close();
  }

  Future<void> _safeMarkEnded(String streamId) async {
    try {
      await _repo.markEnded(streamId);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[recording] markEnded($streamId) failed: $e\n$st');
      }
    }
  }

  void _emit(RecordingState next) {
    _state = next;
    _stateController.add(next);
  }
}

/// Thrown when the recording cannot start due to a user / OS decision
/// (consent dialog dismissed, permission revoked, etc.).
class RecordingException implements Exception {
  const RecordingException(this.message);
  final String message;
  @override
  String toString() => 'RecordingException: $message';
}

/// Seam over `flutter_screen_recording` — tests inject a fake without
/// bringing up the native plugin.
abstract class RecordingPlatform {
  Future<bool> startRecording({
    required String filename,
    required String notificationTitle,
    required String notificationMessage,
  });

  /// Returns the absolute path to the recorded file on the local
  /// filesystem (Android cache / Movies dir).
  Future<String> stopRecording();
}

class _DefaultRecordingPlatform implements RecordingPlatform {
  const _DefaultRecordingPlatform();

  @override
  Future<bool> startRecording({
    required String filename,
    required String notificationTitle,
    required String notificationMessage,
  }) {
    if (!Platform.isAndroid) {
      // iOS: third-party recording is sandboxed away. Manual upload
      // is the only flow on iOS.
      return Future.value(false);
    }
    // Recording the *microphone* leaks the player's voice / room
    // background to the admin reviewing the file — not what we want.
    // Internal/playback audio (the actual game sound) would require
    // AudioPlaybackCapture API which `flutter_screen_recording` does
    // not expose. Until we patch the package, ship a silent video.
    return FlutterScreenRecording.startRecordScreen(
      filename,
      titleNotification: notificationTitle,
      messageNotification: notificationMessage,
    );
  }

  @override
  Future<String> stopRecording() async {
    if (!Platform.isAndroid) return '';
    return FlutterScreenRecording.stopRecordScreen;
  }
}

final recordingServiceProvider = Provider<RecordingService>((ref) {
  final service = RecordingService(
    streamRepository: ref.watch(matchStreamRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
