import 'package:arena/core/services/permissions_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';

class _MockRequester extends Mock implements PermissionRequester {}

void main() {
  setUpAll(() {
    registerFallbackValue(Permission.microphone);
  });

  group('PermissionsService', () {
    late _MockRequester requester;
    late PermissionsService service;

    setUp(() {
      requester = _MockRequester();
      service = PermissionsService(requester: requester);
    });

    test('requestMicrophone delegates to Permission.microphone', () async {
      when(() => requester.request(Permission.microphone))
          .thenAnswer((_) async => PermissionOutcome.granted);

      final result = await service.requestMicrophone();

      expect(result, PermissionOutcome.granted);
      verify(() => requester.request(Permission.microphone)).called(1);
    });

    test('requestNotifications delegates to Permission.notification', () async {
      when(() => requester.request(Permission.notification))
          .thenAnswer((_) async => PermissionOutcome.denied);

      final result = await service.requestNotifications();

      expect(result, PermissionOutcome.denied);
      verify(() => requester.request(Permission.notification)).called(1);
    });

    test('requestRecordingBundle aggregates mic + notifications', () async {
      when(() => requester.request(Permission.microphone))
          .thenAnswer((_) async => PermissionOutcome.granted);
      when(() => requester.request(Permission.notification))
          .thenAnswer((_) async => PermissionOutcome.granted);

      final bundle = await service.requestRecordingBundle();

      expect(bundle.microphone, PermissionOutcome.granted);
      expect(bundle.notifications, PermissionOutcome.granted);
      expect(bundle.allGranted, isTrue);
    });

    test('RecordingPermissionsBundle.allGranted false if any denied', () {
      const bundle = RecordingPermissionsBundle(
        microphone: PermissionOutcome.granted,
        notifications: PermissionOutcome.denied,
      );

      expect(bundle.allGranted, isFalse);
    });

    test('PermissionOutcomeX exposes isGranted / needsSettings', () {
      expect(PermissionOutcome.granted.isGranted, isTrue);
      expect(PermissionOutcome.permanentlyDenied.isGranted, isFalse);
      expect(PermissionOutcome.permanentlyDenied.needsSettings, isTrue);
      expect(PermissionOutcome.denied.needsSettings, isFalse);
    });

    test('openAppSettingsPage forwards to requester', () async {
      when(() => requester.openSettings()).thenAnswer((_) async => true);

      final opened = await service.openAppSettingsPage();

      expect(opened, isTrue);
      verify(() => requester.openSettings()).called(1);
    });
  });
}
