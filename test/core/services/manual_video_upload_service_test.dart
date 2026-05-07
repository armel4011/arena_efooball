import 'dart:io';

import 'package:arena/core/services/manual_video_upload_service.dart';
import 'package:arena/core/services/recording_uploader.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements MatchStreamRepository {}

class _MockUploader extends Mock implements RecordingUploader {}

class _FakeFile extends Fake implements File {}

class _StubPicker implements FilePickerWrapper {
  _StubPicker(this.payload);
  final PickedVideo? payload;
  @override
  Future<PickedVideo?> pickVideo() async => payload;
}

const _stubSession = MatchStream(
  id: 'stream-2',
  matchId: 'match-2',
  playerId: 'player-2',
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeFile());
  });

  late _MockRepo repo;
  late _MockUploader uploader;

  setUp(() {
    repo = _MockRepo();
    uploader = _MockUploader();
  });

  test('returns cancelled outcome when picker is dismissed', () async {
    final service = ManualVideoUploadService(
      streamRepository: repo,
      uploader: uploader,
      picker: _StubPicker(null),
    );

    final outcome = await service.pickAndUpload(
      matchId: 'match-2',
      playerId: 'player-2',
    );

    expect(outcome.cancelled, isTrue);
    expect(outcome.result, isNull);
    expect(outcome.session, isNull);
  });

  test('opens session, uploads via path, and closes session', () async {
    final service = ManualVideoUploadService(
      streamRepository: repo,
      uploader: uploader,
      picker: _StubPicker(
        const PickedVideo(path: '/tmp/proof.mp4', name: 'proof.mp4'),
      ),
    );

    when(() => repo.openSession(matchId: 'match-2', playerId: 'player-2'))
        .thenAnswer((_) async => _stubSession);
    when(
      () => uploader.upload(
        streamId: any(named: 'streamId'),
        matchId: any(named: 'matchId'),
        playerId: any(named: 'playerId'),
        file: any(named: 'file'),
      ),
    ).thenAnswer(
      (_) async =>
          const UploadResult(streamId: 'stream-2', objectPath: 'match-2/player-2/123.mp4'),
    );
    when(() => repo.markEnded(any())).thenAnswer((_) async {});

    final outcome = await service.pickAndUpload(
      matchId: 'match-2',
      playerId: 'player-2',
    );

    expect(outcome.cancelled, isFalse);
    expect(outcome.result?.objectPath, 'match-2/player-2/123.mp4');
    verify(() => repo.markEnded('stream-2')).called(1);
  });

  test('closes session even when uploader throws', () async {
    final service = ManualVideoUploadService(
      streamRepository: repo,
      uploader: uploader,
      picker: _StubPicker(
        const PickedVideo(path: '/tmp/proof.mp4', name: 'proof.mp4'),
      ),
    );

    when(() => repo.openSession(matchId: 'match-2', playerId: 'player-2'))
        .thenAnswer((_) async => _stubSession);
    when(
      () => uploader.upload(
        streamId: any(named: 'streamId'),
        matchId: any(named: 'matchId'),
        playerId: any(named: 'playerId'),
        file: any(named: 'file'),
      ),
    ).thenThrow(const RecordingUploadException('boom'));
    when(() => repo.markEnded(any())).thenAnswer((_) async {});

    await expectLater(
      service.pickAndUpload(matchId: 'match-2', playerId: 'player-2'),
      throwsA(isA<RecordingUploadException>()),
    );
    verify(() => repo.markEnded('stream-2')).called(1);
  });
}
