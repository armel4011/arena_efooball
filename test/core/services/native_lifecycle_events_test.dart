import 'package:arena/core/services/native_lifecycle_events.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('arena/native');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('showStoppedNotification invokes the native show method', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });

    await NativeLifecycleEvents().showStoppedNotification();

    expect(calls, ['showStoppedNotification']);
  });

  test('hideStoppedNotification invokes the native hide method', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });

    await NativeLifecycleEvents().hideStoppedNotification();

    expect(calls, ['hideStoppedNotification']);
  });

  test('show/hide swallow a channel error (no throw off-Android / CI)',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'UNAVAILABLE');
    });

    // Doit se terminer sans lever — le canal peut être down en CI.
    await NativeLifecycleEvents().showStoppedNotification();
    await NativeLifecycleEvents().hideStoppedNotification();
  });
}
