import 'package:arena/core/services/recording_service.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements MatchStreamRepository {}

class _MockPlatform extends Mock implements RecordingPlatform {}

const _stubSession = MatchStream(
  id: 'stream-1',
  matchId: 'match-1',
  playerId: 'player-1',
);

void main() {
  late _MockRepo repo;
  late _MockPlatform platform;
  late RecordingService service;

  setUp(() {
    repo = _MockRepo();
    platform = _MockPlatform();
    service = RecordingService(
      streamRepository: repo,
      platform: platform,
    );
  });

  tearDown(() async {
    await service.dispose();
  });

  group('RecordingService.start', () {
    test('opens DB session and transitions idle → active', () async {
      when(() => repo.openSession(matchId: 'match-1', playerId: 'player-1'))
          .thenAnswer((_) async => _stubSession);
      when(
        () => platform.startRecording(
          filename: any(named: 'filename'),
          notificationTitle: any(named: 'notificationTitle'),
          notificationMessage: any(named: 'notificationMessage'),
        ),
      ).thenAnswer((_) async => true);

      final session = await service.start(
        matchId: 'match-1',
        playerId: 'player-1',
      );

      expect(session.id, 'stream-1');
      expect(service.state, isA<RecordingActive>());
    });

    test('rolls back DB session when MediaProjection denied', () async {
      when(() => repo.openSession(matchId: any(named: 'matchId'), playerId: any(named: 'playerId')))
          .thenAnswer((_) async => _stubSession);
      when(
        () => platform.startRecording(
          filename: any(named: 'filename'),
          notificationTitle: any(named: 'notificationTitle'),
          notificationMessage: any(named: 'notificationMessage'),
        ),
      ).thenAnswer((_) async => false);
      when(() => repo.markEnded(any())).thenAnswer((_) async {});

      await expectLater(
        service.start(matchId: 'match-1', playerId: 'player-1'),
        throwsA(isA<RecordingException>()),
      );
      verify(() => repo.markEnded('stream-1')).called(1);
      expect(service.state, isA<RecordingError>());
    });

    test('throws StateError when called twice without stop', () async {
      when(() => repo.openSession(matchId: any(named: 'matchId'), playerId: any(named: 'playerId')))
          .thenAnswer((_) async => _stubSession);
      when(
        () => platform.startRecording(
          filename: any(named: 'filename'),
          notificationTitle: any(named: 'notificationTitle'),
          notificationMessage: any(named: 'notificationMessage'),
        ),
      ).thenAnswer((_) async => true);

      await service.start(matchId: 'match-1', playerId: 'player-1');

      expect(
        () => service.start(matchId: 'match-1', playerId: 'player-1'),
        throwsStateError,
      );
    });
  });

  group('RecordingService.stop', () {
    test('returns local path and marks session ended', () async {
      when(() => repo.openSession(matchId: any(named: 'matchId'), playerId: any(named: 'playerId')))
          .thenAnswer((_) async => _stubSession);
      when(
        () => platform.startRecording(
          filename: any(named: 'filename'),
          notificationTitle: any(named: 'notificationTitle'),
          notificationMessage: any(named: 'notificationMessage'),
        ),
      ).thenAnswer((_) async => true);
      when(() => platform.stopRecording())
          .thenAnswer((_) async => '/tmp/arena_match-1_stream-1.mp4');
      when(() => repo.markEnded(any())).thenAnswer((_) async {});

      await service.start(matchId: 'match-1', playerId: 'player-1');
      final result = await service.stop();

      expect(result, isNotNull);
      expect(result!.localPath, '/tmp/arena_match-1_stream-1.mp4');
      expect(result.session.id, 'stream-1');
      verify(() => repo.markEnded('stream-1')).called(1);
      expect(service.state, isA<RecordingIdle>());
    });

    test('returns null when called from idle state', () async {
      final result = await service.stop();
      expect(result, isNull);
    });
  });
}
