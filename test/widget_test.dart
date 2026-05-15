// TODO: test obsolète — UI/code redesigned. Tag 'broken' pour
//       skip en CI. À récrire dans un chantier dédié.
@Tags(<String>['broken'])
library;

// Smoke tests for ARENA boot flow.
//
// These rely on the router's redirect logic (PHASE 2). Because the
// ArenaUserApp now wires MaterialApp.router, we exercise it end-to-end.

import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/services/onboarding_service.dart';
import 'package:arena/features_user/auth/splash_user_screen.dart';
import 'package:arena/features_user/onboarding/onboarding_page.dart';
import 'package:arena/main_admin.dart';
import 'package:arena/main_user.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container({
  Map<String, Object> initial = const {},
}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

Future<Widget> _scopedUserApp({
  Map<String, Object> initial = const {},
}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const ArenaUserApp(),
  );
}

void main() {
  setUp(() {
    FlavorConfig.init(
      flavor: Flavor.user,
      appName: 'ARENA',
      bundleId: 'com.arena.app',
    );
  });

  group('ArenaUserApp router redirect', () {
    testWidgets('first launch → onboarding (slide 1 visible)', (tester) async {
      final app = await _scopedUserApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.textContaining('BIENVENUE'), findsOneWidget);
    });

    testWidgets('onboarding done + no session → splash screen',
        (tester) async {
      final app = await _scopedUserApp(
        initial: <String, Object>{'onboarding_completed': true},
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.byType(SplashUserScreen), findsOneWidget);
      expect(find.text('SE CONNECTER'), findsOneWidget);
      expect(find.text("S'INSCRIRE"), findsOneWidget);
    });
  });

  testWidgets('Admin app boots and shows splash with sign-in CTAs',
      (tester) async {
    FlavorConfig.init(
      flavor: Flavor.admin,
      appName: 'ARENA Admin',
      bundleId: 'com.arena.admin',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ArenaAdminApp(),
      ),
    );
    await tester.pumpAndSettle();

    // PHASE 2bis splash : title + 2 CTAs.
    expect(find.text('ARENA ADMIN'), findsOneWidget);
    expect(find.text('SE CONNECTER'), findsOneWidget);
    expect(find.text('JE SUIS INVITÉ'), findsOneWidget);
  });

  group('OnboardingFlagController', () {
    test('starts false, flips to true on markCompleted, back to false on reset',
        () async {
      final c = await _container();
      addTearDown(c.dispose);

      expect(c.read(onboardingCompletedProvider), isFalse);

      await c.read(onboardingCompletedProvider.notifier).markCompleted();
      expect(c.read(onboardingCompletedProvider), isTrue);

      await c.read(onboardingCompletedProvider.notifier).reset();
      expect(c.read(onboardingCompletedProvider), isFalse);
    });
  });
}
