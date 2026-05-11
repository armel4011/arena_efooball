import 'dart:async';

import 'package:arena/core/services/bring_to_front.dart';
import 'package:arena/core/services/recording_overlay_controller.dart';
import 'package:arena/core/services/recording_service.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// High-level state of an in-progress recorded match.
sealed class CoordinatorState {
  const CoordinatorState();
}

class CoordinatorIdle extends CoordinatorState {
  const CoordinatorIdle();
}

class CoordinatorRecording extends CoordinatorState {
  const CoordinatorRecording({required this.matchId, required this.playerId});
  final String matchId;
  final String playerId;
}

class CoordinatorPaused extends CoordinatorState {
  const CoordinatorPaused({
    required this.matchId,
    required this.playerId,
    required this.graceUntil,
  });
  final String matchId;
  final String playerId;
  final DateTime graceUntil;
}

class CoordinatorForfeited extends CoordinatorState {
  const CoordinatorForfeited({required this.matchId, required this.reason});
  final String matchId;
  final String reason;
}

class CoordinatorStopped extends CoordinatorState {
  const CoordinatorStopped({required this.matchId, this.localRecordingPath});
  final String matchId;
  final String? localRecordingPath;
}

/// Orchestrates a recorded match end-to-end.
///
/// Glues together:
///   * [RecordingService] — actual screen recorder + DB session,
///   * [RecordingOverlayController] — floating button + IPC actions,
///   * [MatchRepository] — forfeit / event logging,
///   * [BringToFront] — best-effort "tap-short → wake ARENA".
///
/// The pause grace window (Q5 = 2 min) is enforced here, not in
/// [RecordingService]: the recorder keeps running, but if the player
/// doesn't tap "Continuer" within the window we declare the forfeit
/// automatically.
class MatchRecordingCoordinator {
  MatchRecordingCoordinator({
    required RecordingService recording,
    required RecordingOverlayController overlay,
    required MatchRepository matchRepository,
    required BringToFront bringToFront,
    Duration pauseGrace = const Duration(minutes: 2),
  })  : _recording = recording,
        _overlay = overlay,
        _matches = matchRepository,
        _bringToFront = bringToFront,
        _pauseGrace = pauseGrace;

  final RecordingService _recording;
  final RecordingOverlayController _overlay;
  final MatchRepository _matches;
  final BringToFront _bringToFront;
  final Duration _pauseGrace;

  final _stateController = StreamController<CoordinatorState>.broadcast();
  CoordinatorState _state = const CoordinatorIdle();

  // Fires every time the overlay sends focusMain, so the main app can
  // open the actions sheet alongside the activity coming to front.
  final _focusController = StreamController<void>.broadcast();
  Stream<void> get focusRequests => _focusController.stream;

  // Fires when the overlay's mini "screenshot" button is tapped — main
  // app exports a PNG via GalleryExporter and shows a snackbar.
  final _screenshotController = StreamController<void>.broadcast();
  Stream<void> get screenshotRequests => _screenshotController.stream;

  // Fires when the overlay's mini "save & stop" button is tapped — main
  // app calls stopCleanly() + GalleryExporter and shows a snackbar.
  // The Future-returning local-path is published as the event so the
  // listener can call gallery.saveVideoToGallery without re-reading
  // coordinator state (which has already moved to Stopped).
  final _saveStopController = StreamController<String?>.broadcast();
  Stream<String?> get saveStopRequests => _saveStopController.stream;

  StreamSubscription<OverlayAction>? _actionsSub;
  Timer? _graceTimer;

  // Captured for the duration of a session — needed to call markForfeit.
  String? _matchId;
  String? _playerId;
  String? _opponentId;

  CoordinatorState get state => _state;
  Stream<CoordinatorState> get stateStream => _stateController.stream;

  /// Starts recording + shows the overlay + listens to overlay actions.
  Future<void> startForMatch({
    required String matchId,
    required String playerId,
    required String opponentId,
  }) async {
    if (_state is! CoordinatorIdle &&
        _state is! CoordinatorStopped &&
        _state is! CoordinatorForfeited) {
      throw StateError('Coordinator already active for $_matchId');
    }

    _matchId = matchId;
    _playerId = playerId;
    _opponentId = opponentId;

    await _recording.start(matchId: matchId, playerId: playerId);
    await _overlay.start(matchId: matchId);

    await _actionsSub?.cancel();
    _actionsSub = _overlay.actions.listen(_onOverlayAction);

    _emit(CoordinatorRecording(matchId: matchId, playerId: playerId));
  }

  /// Normal stop — the match ended on its own (score validated, etc.).
  ///
  /// Returns the local path of the recorded file so the caller can
  /// hand it to `RecordingUploader`.
  Future<String?> stopCleanly() async {
    final result = await _recording.stop();
    await _overlay.stop();
    _graceTimer?.cancel();
    _graceTimer = null;
    await _actionsSub?.cancel();
    _actionsSub = null;
    final matchId = _matchId ?? '';
    _emit(
      CoordinatorStopped(
        matchId: matchId,
        localRecordingPath: result?.localPath,
      ),
    );
    _matchId = null;
    _playerId = null;
    _opponentId = null;
    return result?.localPath;
  }

  Future<void> dispose() async {
    _graceTimer?.cancel();
    await _actionsSub?.cancel();
    await _stateController.close();
    await _focusController.close();
    await _screenshotController.close();
    await _saveStopController.close();
  }

  // ─── Overlay action plumbing ───────────────────────────────────────────

  Future<void> _onOverlayAction(OverlayAction action) async {
    switch (action) {
      case OverlayAction.focusMain:
        await _bringToFront.bringArenaToFront();
        _focusController.add(null);
      case OverlayAction.resume:
        await _onResume();
      case OverlayAction.pause:
        await _onPause();
      case OverlayAction.forfeit:
        await _declareForfeit('user_chose_forfeit');
      case OverlayAction.screenshot:
        // Bring ARENA to front so the snackbar emitted by the listener
        // is visible — the actual capture is best-effort and the file
        // ends up in Download/ARENA either way.
        await _bringToFront.bringArenaToFront();
        _screenshotController.add(null);
      case OverlayAction.saveAndStop:
        // Stop the recorder first (closes the file), then publish the
        // local path so the listener can hand it to GalleryExporter.
        // Using stopCleanly here also flips the coordinator state to
        // Stopped, which collapses the lifecycle banner.
        await _bringToFront.bringArenaToFront();
        try {
          final localPath = await stopCleanly();
          _saveStopController.add(localPath);
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('[coordinator] saveAndStop failed: $e\n$st');
          }
          _saveStopController.add(null);
        }
      case OverlayAction.unknown:
        if (kDebugMode) {
          debugPrint('[coordinator] received OverlayAction.unknown');
        }
    }
  }

  /// Public entry for the in-app actions sheet to pause the recording.
  /// Mirrors the overlay "Pause" tile.
  Future<void> pause() => _onPause();

  /// Public entry for the in-app actions sheet to resume from pause.
  /// Mirrors the overlay "Continuer" tile.
  Future<void> resume() => _onResume();

  /// Public entry for the in-app actions sheet to declare a forfeit.
  /// Mirrors the overlay "Arrêter (forfait)" tile.
  Future<void> declareForfeit() =>
      _declareForfeit('user_chose_forfeit');

  Future<void> _onPause() async {
    final matchId = _matchId;
    final playerId = _playerId;
    if (matchId == null || playerId == null) return;
    _graceTimer?.cancel();
    final until = DateTime.now().add(_pauseGrace);
    _graceTimer = Timer(_pauseGrace, () {
      // Best-effort: ignore failures, the next layer will retry from a
      // dispute screen if needed.
      unawaited(_declareForfeit('pause_grace_expired'));
    });
    // Freeze the overlay chrono — without this the MM:SS keeps ticking
    // during the 2-min pause window, which made the user think their
    // pause was ignored.
    await _overlay.pause();
    _emit(
      CoordinatorPaused(
        matchId: matchId,
        playerId: playerId,
        graceUntil: until,
      ),
    );
  }

  Future<void> _onResume() async {
    final matchId = _matchId;
    final playerId = _playerId;
    if (matchId == null || playerId == null) return;
    _graceTimer?.cancel();
    _graceTimer = null;
    await _overlay.resume();
    _emit(CoordinatorRecording(matchId: matchId, playerId: playerId));
  }

  Future<void> _declareForfeit(String reason) async {
    final matchId = _matchId;
    final playerId = _playerId;
    final opponentId = _opponentId;
    if (matchId == null || playerId == null || opponentId == null) return;

    _graceTimer?.cancel();
    _graceTimer = null;

    // Stop the recorder *before* writing the forfeit so the file is
    // closed by the time the admin pulls it up for review.
    try {
      await _recording.stop();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[coordinator] recording.stop() failed: $e\n$st');
      }
    }
    try {
      await _overlay.stop();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[coordinator] overlay.stop() failed: $e\n$st');
      }
    }

    await _matches.markForfeit(
      matchId: matchId,
      forfeitingPlayerId: playerId,
      opponentId: opponentId,
      reason: reason,
    );

    _emit(CoordinatorForfeited(matchId: matchId, reason: reason));

    _matchId = null;
    _playerId = null;
    _opponentId = null;
  }

  void _emit(CoordinatorState next) {
    _state = next;
    _stateController.add(next);
  }
}

final matchRecordingCoordinatorProvider =
    Provider<MatchRecordingCoordinator>((ref) {
  final coord = MatchRecordingCoordinator(
    recording: ref.watch(recordingServiceProvider),
    overlay: ref.watch(recordingOverlayControllerProvider),
    matchRepository: ref.watch(matchRepositoryProvider),
    bringToFront: ref.watch(bringToFrontProvider),
  );
  ref.onDispose(coord.dispose);
  return coord;
});
