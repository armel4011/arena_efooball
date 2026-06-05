// Smoke tests boot ARENA. Exercice le router (PHASE 2) + redirect
// logic en isolation : on évite de pumper `ArenaUserApp` / `ArenaAdminApp`
// directement parce que leur `initState` lit `notificationRepositoryProvider`
// → `supabaseClientProvider`, ce qui crash sans `Supabase.initialize()`
// (et on ne veut pas init un vrai Supabase en test unitaire).
//
// On utilise ici les providers `userRouterProvider` / `adminRouterProvider`
// dans un MaterialApp.router minimal. Les helpers d'auth en cascade
// (currentSession, currentProfile) catchent leurs propres exceptions et
// renvoient null, ce qui équivaut à un user pas connecté — c'est l'état
// que ces smoke tests valident.

import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/onboarding_service.dart';
import 'package:arena/features_admin/auth_admin/splash_admin_screen.dart';
import 'package:arena/features_user/auth/splash_user_screen.dart';
import 'package:arena/features_user/onboarding/onboarding_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
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

Future<Widget> _routerHost({
  required Flavor flavor,
  Map<String, Object> initial = const {},
}) async {
  // `has_seen_splash_v1: true` court-circuite le splash cinématique 6.3s ;
  // on tombe sur le short splash 3.5s qu'on draine via `_pumpPastSplash`.
  final merged = <String, Object>{'has_seen_splash_v1': true, ...initial};
  SharedPreferences.setMockInitialValues(merged);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: Consumer(
      builder: (context, ref, _) {
        final router = flavor == Flavor.user
            ? ref.watch(userRouterProvider)
            : ref.watch(adminRouterProvider);
        return MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    ),
  );
}

/// Le route `/intro` affiche 3500ms le short splash avant de naviguer
/// vers la cible. On avance le temps pour franchir le `Future.delayed`.
Future<void> _pumpPastSplash(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 3600));
}

void main() {
  group('ArenaUserApp router redirect', () {
    setUp(() {
      FlavorConfig.init(
        flavor: Flavor.user,
        appName: 'ARENA',
        bundleId: 'com.arena.app',
      );
    });

    testWidgets('first launch → onboarding (slide 1 visible)', (tester) async {
      final app = await _routerHost(flavor: Flavor.user);
      await tester.pumpWidget(app);
      await _pumpPastSplash(tester);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
      // Slide 1 v2 : emoji + titre Bebas majuscules.
      expect(find.text('TOURNOIS E-SPORT PANAFRICAINS'), findsOneWidget);
    });

    testWidgets('onboarding done + no session → splash screen',
        (tester) async {
      final app = await _routerHost(
        flavor: Flavor.user,
        initial: <String, Object>{'onboarding_completed': true},
      );
      await tester.pumpWidget(app);
      await _pumpPastSplash(tester);
      await tester.pumpAndSettle();

      expect(find.byType(SplashUserScreen), findsOneWidget);
      expect(find.text('SE CONNECTER'), findsOneWidget);
      expect(find.text('CRÉER UN COMPTE'), findsOneWidget);
    });
  });

  testWidgets('Admin app boots and shows splash with sign-in CTAs',
      (tester) async {
    FlavorConfig.init(
      flavor: Flavor.admin,
      appName: 'ARENA Admin',
      bundleId: 'com.arena.admin',
    );
    final app = await _routerHost(flavor: Flavor.admin);
    await tester.pumpWidget(app);
    await _pumpPastSplash(tester);
    await tester.pumpAndSettle();

    expect(find.byType(SplashAdminScreen), findsOneWidget);
    expect(find.text('admin console'), findsOneWidget);
    expect(find.text('SE CONNECTER'), findsOneWidget);
    expect(find.text("🎟 J'AI UN CODE D'INVITATION"), findsOneWidget);
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
