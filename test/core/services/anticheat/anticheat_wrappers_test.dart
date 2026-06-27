import 'package:arena/core/services/anticheat/anticheat_provider.dart';
import 'package:arena/core/services/anticheat/livekit_anticheat_provider.dart';
import 'package:arena/core/services/anticheat/native_anticheat_provider.dart';
import 'package:arena/core/services/livekit_capture_service.dart';
import 'package:arena/core/services/match_recording_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCoordinator extends Mock implements MatchRecordingCoordinator {}

class _MockCapture extends Mock implements LiveKitCaptureService {}

void main() {
  group('NativeAntiCheatProvider', () {
    late _MockCoordinator coord;
    late NativeAntiCheatProvider provider;

    setUp(() {
      coord = _MockCoordinator();
      provider = NativeAntiCheatProvider(coord);
    });

    test('kind is nativeRecorder', () {
      expect(provider.kind, AntiCheatProviderKind.nativeRecorder);
    });

    test('delegates startForMatch with opponentId', () async {
      when(() => coord.startForMatch(
            matchId: any(named: 'matchId'),
            playerId: any(named: 'playerId'),
            opponentId: any(named: 'opponentId'),
          )).thenAnswer((_) async {});

      await provider.startForMatch(
        matchId: 'm1',
        playerId: 'p1',
        opponentId: 'p2',
      );

      verify(() => coord.startForMatch(
            matchId: 'm1',
            playerId: 'p1',
            opponentId: 'p2',
          )).called(1);
    });

    test('throws when opponentId is missing (auto-forfait natif)', () {
      expect(
        () => provider.startForMatch(matchId: 'm1', playerId: 'p1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('isCapturing reflects coordinator recording state', () {
      when(() => coord.state).thenReturn(
        const CoordinatorRecording(matchId: 'm1', playerId: 'p1'),
      );
      expect(provider.isCapturing, isTrue);

      when(() => coord.state).thenReturn(const CoordinatorIdle());
      expect(provider.isCapturing, isFalse);
    });
  });

  group('LiveKitAntiCheatProvider', () {
    late _MockCapture capture;
    late LiveKitAntiCheatProvider provider;

    setUp(() {
      capture = _MockCapture();
      provider = LiveKitAntiCheatProvider(capture);
    });

    test('kind is livekitTrackEgress', () {
      expect(provider.kind, AntiCheatProviderKind.livekitTrackEgress);
    });

    test('startForMatch delegates to capture.start (ignores opponentId)',
        () async {
      when(() => capture.start(matchId: any(named: 'matchId')))
          .thenAnswer((_) async {});

      await provider.startForMatch(
        matchId: 'm1',
        playerId: 'p1',
        opponentId: 'p2',
      );

      verify(() => capture.start(matchId: 'm1')).called(1);
    });

    test('stopCleanly delegates to capture.stop', () async {
      when(() => capture.stop()).thenAnswer((_) async {});
      await provider.stopCleanly();
      verify(() => capture.stop()).called(1);
    });

    test('isCapturing reflects publishing state', () {
      when(() => capture.state).thenReturn(
        LiveKitCapturePublishing(room: 'match_m1', startedAt: DateTime(2026)),
      );
      expect(provider.isCapturing, isTrue);

      when(() => capture.state).thenReturn(const LiveKitCaptureIdle());
      expect(provider.isCapturing, isFalse);
    });
  });
}
