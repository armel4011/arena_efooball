import 'dart:async';

import 'package:arena/core/services/recording_overlay_controller.dart';
import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOverlayPlatform implements OverlayPlatform {
  bool granted = true;
  bool requestResult = true;
  bool overlayShown = false;
  Object? lastSharedData;
  final _controller = StreamController<dynamic>.broadcast();

  void emit(dynamic event) => _controller.add(event);

  @override
  Future<bool> isPermissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async => requestResult;

  @override
  Future<void> showOverlay() async {
    overlayShown = true;
  }

  @override
  Future<void> closeOverlay() async {
    overlayShown = false;
  }

  @override
  Future<void> shareData(Object data) async {
    lastSharedData = data;
  }

  @override
  Stream<dynamic> get overlayListener => _controller.stream;
}

void main() {
  late _FakeOverlayPlatform platform;
  late RecordingOverlayController controller;

  setUp(() {
    platform = _FakeOverlayPlatform();
    controller = RecordingOverlayController(platform: platform);
  });

  tearDown(() async {
    await controller.dispose();
  });

  test('start() shows overlay when permission already granted', () async {
    await controller.start();
    expect(platform.overlayShown, isTrue);
  });

  test('start() requests permission when missing and shows on grant', () async {
    platform
      ..granted = false
      ..requestResult = true;
    await controller.start();
    expect(platform.overlayShown, isTrue);
  });

  test('start() does not show overlay when permission denied', () async {
    platform
      ..granted = false
      ..requestResult = false;
    await controller.start();
    expect(platform.overlayShown, isFalse);
  });

  test('stop() closes overlay', () async {
    await controller.start();
    expect(platform.overlayShown, isTrue);
    await controller.stop();
    expect(platform.overlayShown, isFalse);
  });

  test('emits OverlayAction.pause when overlay broadcasts ask_pause', () async {
    await controller.start();

    final next = controller.actions.first;
    platform.emit(RecordingOverlayMessages.askPauseType);
    expect(await next, OverlayAction.pause);
  });

  test('emits OverlayAction.forfeit on ask_forfeit', () async {
    await controller.start();
    final next = controller.actions.first;
    platform.emit(RecordingOverlayMessages.askForfeitType);
    expect(await next, OverlayAction.forfeit);
  });

  test('emits OverlayAction.unknown on bogus payload', () async {
    await controller.start();
    final next = controller.actions.first;
    platform.emit('not_a_known_type');
    expect(await next, OverlayAction.unknown);
  });

  group('OverlayTick', () {
    test('formatted pads MM:SS', () {
      expect(
        const OverlayTick(elapsedSeconds: 3, isWarning: false).formatted,
        '00:03',
      );
      expect(
        const OverlayTick(elapsedSeconds: 65, isWarning: false).formatted,
        '01:05',
      );
      expect(
        const OverlayTick(elapsedSeconds: 1500, isWarning: true).formatted,
        '25:00',
      );
    });

    test('fromMap reads warning vs tick type', () {
      final warn = OverlayTick.fromMap({
        'type': RecordingOverlayMessages.warnType,
        'elapsed': 1485,
      });
      expect(warn.isWarning, isTrue);
      expect(warn.elapsedSeconds, 1485);

      final tick = OverlayTick.fromMap({
        'type': RecordingOverlayMessages.tickType,
        'elapsed': 30,
      });
      expect(tick.isWarning, isFalse);
      expect(tick.elapsedSeconds, 30);
    });

    test('fromMap is null-safe', () {
      final empty = OverlayTick.fromMap(null);
      expect(empty.elapsedSeconds, 0);
      expect(empty.isWarning, isFalse);
    });
  });
}
