import 'package:arena/core/services/livekit_capture_service.dart';
import 'package:arena/core/services/livekit_token_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenClient extends Mock implements LiveKitTokenClient {}

class _FakeRoom implements LiveKitRoomHandle {
  bool screenShareOn = false;
  bool disconnected = false;
  bool disposed = false;

  @override
  Future<void> enableScreenShare() async => screenShareOn = true;
  @override
  Future<void> disableScreenShare() async => screenShareOn = false;
  @override
  Future<void> disconnect() async => disconnected = true;
  @override
  Future<void> dispose() async => disposed = true;
}

class _FakeFactory implements LiveKitRoomFactory {
  _FakeFactory(this.room, {this.throwOnConnect = false});
  final _FakeRoom room;
  final bool throwOnConnect;

  @override
  Future<LiveKitRoomHandle> connect({
    required String url,
    required String token,
  }) async {
    if (throwOnConnect) throw Exception('connect failed');
    return room;
  }
}

const _stubToken = LiveKitToken(
  token: 'jwt',
  url: 'wss://x.livekit.cloud',
  room: 'match_match-1',
  identity: 'player-1',
  expiresAt: 9999999999,
);

void main() {
  late _MockTokenClient tokenClient;

  setUp(() {
    tokenClient = _MockTokenClient();
  });

  LiveKitCaptureService build(
    LiveKitRoomFactory factory, {
    bool supportsCapture = true,
  }) {
    return LiveKitCaptureService(
      tokenClient: tokenClient,
      roomFactory: factory,
      supportsCapture: supportsCapture,
    );
  }

  group('LiveKitCaptureService.start', () {
    test('fetches token, connects and publishes (idle → publishing)', () async {
      when(() => tokenClient.fetch(matchId: 'match-1'))
          .thenAnswer((_) async => _stubToken);
      final room = _FakeRoom();
      final service = build(_FakeFactory(room));

      await service.start(matchId: 'match-1');

      expect(service.state, isA<LiveKitCapturePublishing>());
      expect(room.screenShareOn, isTrue);
      await service.dispose();
    });

    test('no-op on unsupported platform (stays idle)', () async {
      final room = _FakeRoom();
      final service = build(_FakeFactory(room), supportsCapture: false);

      await service.start(matchId: 'match-1');

      expect(service.state, isA<LiveKitCaptureIdle>());
      verifyNever(() => tokenClient.fetch(matchId: any(named: 'matchId')));
      await service.dispose();
    });

    test('releases room and surfaces error when connect fails', () async {
      when(() => tokenClient.fetch(matchId: 'match-1'))
          .thenAnswer((_) async => _stubToken);
      final room = _FakeRoom();
      final service = build(_FakeFactory(room, throwOnConnect: true));

      await expectLater(
        service.start(matchId: 'match-1'),
        throwsA(isA<Exception>()),
      );
      expect(service.state, isA<LiveKitCaptureError>());
      await service.dispose();
    });

    test('rejects a second concurrent start', () async {
      when(() => tokenClient.fetch(matchId: 'match-1'))
          .thenAnswer((_) async => _stubToken);
      final service = build(_FakeFactory(_FakeRoom()));

      await service.start(matchId: 'match-1');

      expect(
        () => service.start(matchId: 'match-1'),
        throwsA(isA<StateError>()),
      );
      await service.dispose();
    });
  });

  group('LiveKitCaptureService.stop', () {
    test('tears down room and returns to idle', () async {
      when(() => tokenClient.fetch(matchId: 'match-1'))
          .thenAnswer((_) async => _stubToken);
      final room = _FakeRoom();
      final service = build(_FakeFactory(room));

      await service.start(matchId: 'match-1');
      await service.stop();

      expect(service.state, isA<LiveKitCaptureIdle>());
      expect(room.screenShareOn, isFalse);
      expect(room.disconnected, isTrue);
      expect(room.disposed, isTrue);
      await service.dispose();
    });

    test('is a no-op when already idle', () async {
      final service = build(_FakeFactory(_FakeRoom()));
      await service.stop();
      expect(service.state, isA<LiveKitCaptureIdle>());
      await service.dispose();
    });
  });
}
