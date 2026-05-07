import 'package:app_usage/app_usage.dart';
import 'package:arena/core/services/game_detector_service.dart';
import 'package:arena/data/models/target_game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlatform extends Mock implements GameDetectorPlatform {}

void main() {
  group('TargetGame.fromAndroidPackage', () {
    test('matches eFootball package', () {
      expect(
        TargetGame.fromAndroidPackage('jp.konami.pesam'),
        TargetGame.efootball,
      );
    });

    test('matches EA FC Mobile package', () {
      expect(
        TargetGame.fromAndroidPackage('com.ea.gp.fifamobile'),
        TargetGame.eaFcMobile,
      );
    });

    test('returns null for unknown package', () {
      expect(TargetGame.fromAndroidPackage('com.whatsapp'), isNull);
    });
  });

  group('GameDetectorService.checkInstalledTargetGames', () {
    late _MockPlatform platform;
    late GameDetectorService service;

    setUp(() {
      platform = _MockPlatform();
      service = GameDetectorService(platform: platform);
    });

    test('returns only installed targets', () async {
      when(() => platform.isAppInstalled('jp.konami.pesam'))
          .thenAnswer((_) async => true);
      when(() => platform.isAppInstalled('com.ea.gp.fifamobile'))
          .thenAnswer((_) async => false);

      final result = await service.checkInstalledTargetGames();

      expect(result, [TargetGame.efootball]);
    });

    test('swallows plugin exceptions and returns partial list', () async {
      when(() => platform.isAppInstalled('jp.konami.pesam'))
          .thenThrow(Exception('plugin missing'));
      when(() => platform.isAppInstalled('com.ea.gp.fifamobile'))
          .thenAnswer((_) async => true);

      final result = await service.checkInstalledTargetGames();

      expect(result, [TargetGame.eaFcMobile]);
    });
  });

  group('GameDetectorService.hasUsageStatsAccess', () {
    late _MockPlatform platform;
    late GameDetectorService service;

    setUp(() {
      platform = _MockPlatform();
      service = GameDetectorService(platform: platform);
    });

    test('true when app_usage returns without throwing', () async {
      when(() => platform.getAppUsage(any(), any()))
          .thenAnswer((_) async => const <AppUsageInfo>[]);

      expect(await service.hasUsageStatsAccess(), isTrue);
    });

    test('false on PlatformException (permission missing)', () async {
      when(() => platform.getAppUsage(any(), any()))
          .thenThrow(PlatformException(code: 'NO_PERMISSION'));

      expect(await service.hasUsageStatsAccess(), isFalse);
    });
  });

  group('GameDetectorService.currentForegroundGame', () {
    late _MockPlatform platform;
    late GameDetectorService service;

    setUp(() {
      platform = _MockPlatform();
      service = GameDetectorService(platform: platform);
    });

    test('returns the target game whose endDate is recent', () async {
      final now = DateTime.now();
      when(() => platform.getAppUsage(any(), any())).thenAnswer(
        (_) async => [
          _info('jp.konami.pesam', now.subtract(const Duration(seconds: 1))),
          _info(
            'com.android.chrome',
            now.subtract(const Duration(seconds: 2)),
          ),
        ],
      );

      final result = await service.currentForegroundGame();

      expect(result, TargetGame.efootball);
    });

    test('null when usage list is empty', () async {
      when(() => platform.getAppUsage(any(), any()))
          .thenAnswer((_) async => const <AppUsageInfo>[]);

      expect(await service.currentForegroundGame(), isNull);
    });

    test('null when no target game is in the recent window', () async {
      final now = DateTime.now();
      when(() => platform.getAppUsage(any(), any())).thenAnswer(
        (_) async => [
          _info('com.whatsapp', now.subtract(const Duration(seconds: 1))),
        ],
      );

      expect(await service.currentForegroundGame(), isNull);
    });
  });
}

/// Builds a synthetic [AppUsageInfo].
///
/// `app_usage 4.x` exposes a positional ctor — we mirror that here so the
/// tests do not have to know about its private fields.
AppUsageInfo _info(String packageName, DateTime endDate) {
  return AppUsageInfo(
    packageName,
    1,
    endDate.subtract(const Duration(seconds: 1)),
    endDate,
    DateTime.fromMillisecondsSinceEpoch(0),
  );
}
