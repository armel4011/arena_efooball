import 'dart:async';

import 'package:arena/core/services/bring_to_front.dart';
import 'package:arena/core/services/match_recording_coordinator.dart';
import 'package:arena/core/services/recording_overlay_controller.dart';
import 'package:arena/core/services/recording_service.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecording extends Mock implements RecordingService {}

class _MockOverlay extends Mock implements RecordingOverlayController {}

class _MockMatches extends Mock implements MatchRepository {}

class _MockBringer extends Mock implements BringToFront {}

const _stubSession = MatchStream(
  id: 'stream-1',
  matchId: 'match-1',
  playerId: 'player-1',
);

void main() {
  late _MockRecording recording;
  late _MockOverlay overlay;
  late _MockMatches matches;
  late _MockBringer bringer;
  late StreamController<OverlayAction> actions;
  late StreamController<String> roomCodes;
  late MatchRecordingCoordinator coordinator;

  setUp(() {
    recording = _MockRecording();
    overlay = _MockOverlay();
    matches = _MockMatches();
    bringer = _MockBringer();
    actions = StreamController<OverlayAction>.broadcast();
    roomCodes = StreamController<String>.broadcast();

    when(() => overlay.actions).thenAnswer((_) => actions.stream);
    when(() => overlay.roomCodeSubmissions).thenAnswer((_) => roomCodes.stream);
    when(
      () => recording.start(
        matchId: any(named: 'matchId'),
        playerId: any(named: 'playerId'),
      ),
    ).thenAnswer((_) async => _stubSession);
    when(() => recording.stop()).thenAnswer(
      (_) async => const RecordingResult(
        session: _stubSession,
        localPath: '/tmp/r.mp4',
        duration: Duration(seconds: 30),
      ),
    );
    when(() => overlay.start(matchId: any(named: 'matchId')))
        .thenAnswer((_) async {});
    when(
      () => overlay.startOrMorphToRecording(
        matchId: any(named: 'matchId'),
        simpleMode: any(named: 'simpleMode'),
      ),
    ).thenAnswer((_) async {});
    when(() => overlay.stop()).thenAnswer((_) async {});
    // `_doStopCleanly` gèle l'overlay via idle() (bouton gris « Reprendre »)
    // au lieu de le fermer — le stubber évite le mock null-default.
    when(() => overlay.idle()).thenAnswer((_) async {});
    // L'overlay a aussi pause()/resume() pour figer le chrono pendant
    // une pause — les stubber empêche les appels de tomber dans le
    // mock null-default (qui throw silently et bloque la transition).
    when(() => overlay.pause()).thenAnswer((_) async {});
    when(() => overlay.resume()).thenAnswer((_) async {});
    when(
      () => matches.markForfeit(
        matchId: any(named: 'matchId'),
        forfeitingPlayerId: any(named: 'forfeitingPlayerId'),
        opponentId: any(named: 'opponentId'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async {});
    when(() => bringer.bringArenaToFront()).thenAnswer((_) async => true);
    when(
      () => matches.sendRoomCode(
        matchId: any(named: 'matchId'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async {});

    coordinator = MatchRecordingCoordinator(
      recording: recording,
      overlay: overlay,
      matchRepository: matches,
      bringToFront: bringer,
      pauseGrace: const Duration(milliseconds: 100),
    );
  });

  tearDown(() async {
    await actions.close();
    await roomCodes.close();
    await coordinator.dispose();
  });

  test('startForMatch boots both recording + overlay and goes Recording',
      () async {
    await coordinator.startForMatch(
      matchId: 'match-1',
      playerId: 'player-1',
      opponentId: 'player-2',
    );

    verify(() => recording.start(matchId: 'match-1', playerId: 'player-1'))
        .called(1);
    verify(() => overlay.startOrMorphToRecording(matchId: 'match-1')).called(1);
    expect(coordinator.state, isA<CoordinatorRecording>());
  });

  test('overlay bring-up qui throw NE bloque PAS le démarrage (best-effort)',
      () async {
    // À la reprise, l'engine de l'overlay peut être mort → resizeOverlay lève
    // MissingPluginException. Le bouton flottant est du CONFORT : l'échec ne
    // doit pas faire échouer le redémarrage de l'enregistrement.
    when(
      () => overlay.startOrMorphToRecording(
        matchId: any(named: 'matchId'),
        simpleMode: any(named: 'simpleMode'),
      ),
    ).thenThrow(
      MissingPluginException(
        'No implementation found for method resizeOverlay '
        'on channel x-slayer/overlay',
      ),
    );

    await coordinator.startForMatch(
      matchId: 'match-1',
      playerId: 'player-1',
      opponentId: 'player-2',
    );

    // Recording a bien démarré ET l'état est passé à Recording malgré l'overlay.
    verify(() => recording.start(matchId: 'match-1', playerId: 'player-1'))
        .called(1);
    expect(coordinator.state, isA<CoordinatorRecording>());
  });

  test('un code room saisi dans le bouton → sendRoomCode(matchId, code)',
      () async {
    await coordinator.startForMatch(
      matchId: 'match-1',
      playerId: 'player-1',
      opponentId: 'player-2',
    );

    roomCodes.add('ABC123');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    verify(() => matches.sendRoomCode(matchId: 'match-1', code: 'ABC123'))
        .called(1);
  });

  test('focusMain action invokes BringToFront', () async {
    await coordinator.startForMatch(
      matchId: 'match-1',
      playerId: 'player-1',
      opponentId: 'player-2',
    );

    actions.add(OverlayAction.focusMain);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    verify(() => bringer.bringArenaToFront()).called(1);
    // No state transition for focus.
    expect(coordinator.state, isA<CoordinatorRecording>());
  });

  test('pause flips state to Paused with graceUntil ≈ now + grace', () async {
    await coordinator.startForMatch(
      matchId: 'match-1',
      playerId: 'player-1',
      opponentId: 'player-2',
    );

    actions.add(OverlayAction.pause);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(coordinator.state, isA<CoordinatorPaused>());
    final paused = coordinator.state as CoordinatorPaused;
    expect(paused.graceUntil.isAfter(DateTime.now()), isTrue);
  });

  test('resume cancels pause grace and returns to Recording', () async {
    await coordinator.startForMatch(
      matchId: 'match-1',
      playerId: 'player-1',
      opponentId: 'player-2',
    );

    actions.add(OverlayAction.pause);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(coordinator.state, isA<CoordinatorPaused>());

    actions.add(OverlayAction.resume);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(coordinator.state, isA<CoordinatorRecording>());

    // Wait long enough that the original grace timer would have fired
    // — markForfeit must NOT have been called.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    verifyNever(
      () => matches.markForfeit(
        matchId: any(named: 'matchId'),
        forfeitingPlayerId: any(named: 'forfeitingPlayerId'),
        opponentId: any(named: 'opponentId'),
        reason: any(named: 'reason'),
      ),
    );
  });

  test('pause grace expiry declares forfeit with pause_grace_expired',
      () async {
    await coordinator.startForMatch(
      matchId: 'match-1',
      playerId: 'player-1',
      opponentId: 'player-2',
    );

    actions.add(OverlayAction.pause);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    verify(
      () => matches.markForfeit(
        matchId: 'match-1',
        forfeitingPlayerId: 'player-1',
        opponentId: 'player-2',
        reason: 'pause_grace_expired',
      ),
    ).called(1);
    expect(coordinator.state, isA<CoordinatorForfeited>());
    final f = coordinator.state as CoordinatorForfeited;
    expect(f.reason, 'pause_grace_expired');
  });

  test('explicit forfeit action stops recording + markForfeit', () async {
    await coordinator.startForMatch(
      matchId: 'match-1',
      playerId: 'player-1',
      opponentId: 'player-2',
    );

    actions.add(OverlayAction.forfeit);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    verify(() => recording.stop()).called(1);
    verify(() => overlay.stop()).called(1);
    verify(
      () => matches.markForfeit(
        matchId: 'match-1',
        forfeitingPlayerId: 'player-1',
        opponentId: 'player-2',
        reason: 'user_chose_forfeit',
      ),
    ).called(1);
    expect(coordinator.state, isA<CoordinatorForfeited>());
  });

  test('stopCleanly returns local path and emits Stopped', () async {
    await coordinator.startForMatch(
      matchId: 'match-1',
      playerId: 'player-1',
      opponentId: 'player-2',
    );

    final path = await coordinator.stopCleanly();

    expect(path, '/tmp/r.mp4');
    verify(() => recording.stop()).called(1);
    // Le stop propre GÈLE l'overlay (bouton gris « Reprendre ») au lieu de le
    // fermer : la fenêtre survit pour permettre un redémarrage dans le match.
    verify(() => overlay.idle()).called(1);
    verifyNever(() => overlay.stop());
    verifyNever(
      () => matches.markForfeit(
        matchId: any(named: 'matchId'),
        forfeitingPlayerId: any(named: 'forfeitingPlayerId'),
        opponentId: any(named: 'opponentId'),
        reason: any(named: 'reason'),
      ),
    );
    expect(coordinator.state, isA<CoordinatorStopped>());
  });
}
