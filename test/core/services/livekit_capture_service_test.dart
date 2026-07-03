import 'dart:async';

import 'package:arena/core/services/bring_to_front.dart';
import 'package:arena/core/services/livekit_capture_service.dart';
import 'package:arena/core/services/livekit_token_client.dart';
import 'package:arena/core/services/recording_overlay_controller.dart';
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

class _FakeFgs implements ScreenCaptureForegroundService {
  int started = 0;
  int stopped = 0;

  @override
  Future<void> start() async => started++;
  @override
  Future<void> stop() async => stopped++;
}

class _FakeOverlay implements RecordingOverlayController {
  final _actions = StreamController<OverlayAction>.broadcast();
  int startCount = 0;
  int stopCount = 0;
  bool? lastSimpleMode;

  void emit(OverlayAction action) => _actions.add(action);

  @override
  Stream<OverlayAction> get actions => _actions.stream;

  @override
  Future<void> start({String? matchId, bool simpleMode = false}) async {
    startCount++;
    lastSimpleMode = simpleMode;
  }

  @override
  Future<void> startOrMorphToRecording({
    String? matchId,
    bool simpleMode = false,
  }) async {
    startCount++;
    lastSimpleMode = simpleMode;
  }

  @override
  Future<bool> showAsCodeSender({String? matchId}) async => true;

  @override
  Future<void> morphToRecording({bool simpleMode = false}) async {}

  @override
  Future<void> enterCodeEntry() async {}

  @override
  Future<void> exitCodeEntry() async {}

  @override
  Future<void> enterCodeView() async {}

  @override
  Future<void> exitCodeView() async {}

  @override
  // ignore: avoid_positional_boolean_parameters
  void setRoomCodeInfo(String? code, bool canSend) {}

  @override
  Stream<String> get roomCodeSubmissions => const Stream<String>.empty();

  @override
  Stream<void> get codeViewRequests => const Stream<void>.empty();

  @override
  bool get isShowing => false;

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  void setLiveAvailable(bool value) {}

  @override
  Duration totalDuration = const Duration(minutes: 25);

  @override
  Future<void> dispose() async => _actions.close();
}

class _FakeBringToFront implements BringToFront {
  int calls = 0;

  @override
  Future<bool> bringArenaToFront() async {
    calls++;
    return true;
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
  late _FakeFgs fgs;

  setUp(() {
    tokenClient = _MockTokenClient();
    fgs = _FakeFgs();
  });

  LiveKitCaptureService build(
    LiveKitRoomFactory factory, {
    bool supportsCapture = true,
    RecordingOverlayController? overlay,
    BringToFront? bringToFront,
  }) {
    return LiveKitCaptureService(
      tokenClient: tokenClient,
      roomFactory: factory,
      foregroundService: fgs,
      overlay: overlay,
      bringToFront: bringToFront,
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
      // Le FGS mediaProjection est démarré avant la capture (requis Android 14+).
      expect(fgs.started, 1);
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
      // Le FGS est coupé à la fin de la capture.
      expect(fgs.stopped, greaterThanOrEqualTo(1));
      await service.dispose();
    });

    test('is a no-op when already idle', () async {
      final service = build(_FakeFactory(_FakeRoom()));
      await service.stop();
      expect(service.state, isA<LiveKitCaptureIdle>());
      await service.dispose();
    });
  });

  group('LiveKitCaptureService overlay (bouton flottant)', () {
    test("démarre l'overlay en mode simple à la publication", () async {
      when(() => tokenClient.fetch(matchId: 'match-1'))
          .thenAnswer((_) async => _stubToken);
      final overlay = _FakeOverlay();
      final service = build(_FakeFactory(_FakeRoom()), overlay: overlay);

      await service.start(matchId: 'match-1');

      expect(overlay.startCount, 1);
      expect(overlay.lastSimpleMode, isTrue);
      await service.dispose();
    });

    test('action focusMain → ramène ARENA au premier plan', () async {
      when(() => tokenClient.fetch(matchId: 'match-1'))
          .thenAnswer((_) async => _stubToken);
      final overlay = _FakeOverlay();
      final btf = _FakeBringToFront();
      final service =
          build(_FakeFactory(_FakeRoom()), overlay: overlay, bringToFront: btf);

      await service.start(matchId: 'match-1');
      overlay.emit(OverlayAction.focusMain);
      await Future<void>.delayed(Duration.zero);

      expect(btf.calls, 1);
      await service.dispose();
    });

    test('action saveAndStop → coupe la capture (→ idle)', () async {
      when(() => tokenClient.fetch(matchId: 'match-1'))
          .thenAnswer((_) async => _stubToken);
      final overlay = _FakeOverlay();
      final service = build(_FakeFactory(_FakeRoom()), overlay: overlay);

      await service.start(matchId: 'match-1');
      overlay.emit(OverlayAction.saveAndStop);
      await Future<void>.delayed(Duration.zero);

      expect(service.state, isA<LiveKitCaptureIdle>());
      expect(overlay.stopCount, greaterThanOrEqualTo(1));
      await service.dispose();
    });

    test("stop ferme l'overlay", () async {
      when(() => tokenClient.fetch(matchId: 'match-1'))
          .thenAnswer((_) async => _stubToken);
      final overlay = _FakeOverlay();
      final service = build(_FakeFactory(_FakeRoom()), overlay: overlay);

      await service.start(matchId: 'match-1');
      await service.stop();

      expect(overlay.stopCount, greaterThanOrEqualTo(1));
      await service.dispose();
    });
  });
}
