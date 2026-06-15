// Tests UI — GameDetectorDebugPage (écran de debug interne PHASE 8.2).
//
// La page accepte un GameDetectorService injectable (prévu pour les tests). On
// fournit un mock mocktail aux données contrôlées et on vérifie le rendu des
// trois cartes : accès usage-stats, jeux installés, jeu au premier plan.

import 'package:arena/core/services/game_detector_service.dart';
import 'package:arena/data/models/target_game.dart';
import 'package:arena/features_user/recording/game_detector_debug_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDetector extends Mock implements GameDetectorService {}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('rend les 3 cartes avec les données du détecteur',
      (tester) async {
    final detector = _MockDetector();
    when(detector.checkInstalledTargetGames)
        .thenAnswer((_) async => [TargetGame.efootball]);
    when(detector.hasUsageStatsAccess).thenAnswer((_) async => true);
    when(detector.foregroundGameStream)
        .thenAnswer((_) => Stream<TargetGame?>.value(null));

    await bumpViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameDetectorDebugPage(detector: detector),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // ArenaAppBar met le titre en majuscules.
    expect(find.text('GAME DETECTOR — DEBUG'), findsOneWidget);
    expect(find.text('Usage stats access: GRANTED'), findsOneWidget);
    expect(find.text('Installed target games'), findsOneWidget);
    expect(find.text('eFootball'), findsOneWidget);
    expect(find.text('Foreground (live, polled every 2s)'), findsOneWidget);
    expect(find.text('— no target game in foreground —'), findsOneWidget);
  });

  testWidgets('usage stats refusé → DENIED + bouton settings', (tester) async {
    final detector = _MockDetector();
    when(detector.checkInstalledTargetGames).thenAnswer((_) async => []);
    when(detector.hasUsageStatsAccess).thenAnswer((_) async => false);
    when(detector.foregroundGameStream)
        .thenAnswer((_) => Stream<TargetGame?>.value(null));

    await bumpViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameDetectorDebugPage(detector: detector),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Usage stats access: DENIED'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
  });
}
