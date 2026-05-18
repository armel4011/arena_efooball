// Golden path widget tests for the ARENA user app.
//
// These tests exercise the GoRouter redirect chain end-to-end and the
// most-trafficked interactive flows (splash → login → forgot, tab swap,
// CGU gate, 3-strikes ban gate). They run on the Dart VM via
// `flutter test test/golden_path_test.dart` and complement the smoke
// coverage in `test/widget_test.dart` (which only validates pre-auth
// router redirects).
//
// Strategy
// --------
// We DON'T pump `ArenaUserApp` directly — its `initState` reaches
// `notificationRepositoryProvider` → `supabaseClientProvider`, which
// crashes outside a real Supabase init. Instead we build a thin
// `MaterialApp.router` over `userRouterProvider` exactly like
// `test/widget_test.dart` does for smoke coverage, but with enough
// provider overrides to advance past the splash and into MainLayout.
//
// The auth state is mocked via:
//   * `SharedPreferences.setMockInitialValues` to control
//     `onboarding_completed`
//   * `currentSessionProvider` override returning a `Fake` Session — the
//     redirect only checks `session == null`, so a Fake is enough
//   * `currentProfileProvider` override returning a freshly built
//     `Profile` (CGU accepted, not banned) so the redirect resolves to
//     `/`
//
// Data-side overrides (`competitionsListProvider`, `playerStatsProvider`,
// `playerRecentMatchesProvider`) keep the tabs renderable without
// hitting Supabase — every tab in `MainLayout` is constructed eagerly
// because of the `IndexedStack`, so any unguarded provider would crash
// the whole tree.

import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/onboarding_service.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/arena_notification.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/models/player_stats.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/banned_account_page.dart';
import 'package:arena/features_user/auth/cgu_acceptance_page.dart';
import 'package:arena/features_user/auth/forgot_password_page.dart';
import 'package:arena/features_user/auth/login_user_screen.dart';
import 'package:arena/features_user/auth/splash_user_screen.dart';
import 'package:arena/features_user/home/main_layout.dart';
import 'package:arena/features_user/onboarding/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Stand-in for `sb.User`. Multiple widgets (UpcomingMatchesScroller,
/// BannedAccountPage, match_room…) read `session.user.id`, so we
/// stub the id explicitly. Anything else routes through `noSuchMethod`
/// and would throw — fine, since we override the data providers below.
class _FakeUser extends Fake implements sb.User {
  _FakeUser(this.id);
  @override
  final String id;
}

/// Stand-in for `sb.Session`. The router only checks `session == null`,
/// but downstream widgets read `session.user.id` — so we wire a
/// `_FakeUser` whose id matches the active Profile.
class _FakeSession extends Fake implements sb.Session {
  _FakeSession(String userId) : user = _FakeUser(userId);
  @override
  final sb.User user;
}

Profile _player({
  String id = 'p-1',
  String username = 'TestPlayer',
  DateTime? cguAcceptedAt,
  bool permanentBan = false,
}) =>
    Profile(
      id: id,
      username: username,
      email: '$id@arena.test',
      countryCode: 'CM',
      cguAcceptedAt: cguAcceptedAt ?? DateTime.utc(2026),
      permanentBan: permanentBan,
    );

/// Builds the router-backed app under test with the requested auth state.
/// Always supplies the data-side overrides MainLayout needs even when
/// the test only exercises pre-auth screens — keeps each test self
/// contained.
Future<Widget> _buildApp({
  bool onboardingCompleted = true,
  Profile? profile,
  bool useSession = true,
}) async {
  // `has_seen_splash_v1: true` court-circuite le splash cinématique 6.3s,
  // on tombe sur le _ShortSplashScreen 3.5s qu'on draine via
  // `_pumpPastSplash` après `pumpWidget`.
  final initial = <String, Object>{'has_seen_splash_v1': true};
  if (onboardingCompleted) initial['onboarding_completed'] = true;
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();

  final overrides = <Override>[
    sharedPreferencesProvider.overrideWithValue(prefs),
    competitionsListProvider
        .overrideWith((ref, _) => Stream<List<Competition>>.value(const [])),
    playerStatsProvider
        .overrideWith((ref, _) async => const PlayerStats.empty()),
    playerRecentMatchesProvider
        .overrideWith((ref, _) async => const <ArenaMatch>[]),
    // MainLayout/HomePage eager-build every tab via IndexedStack, so we
    // mute the data sources they reach for — otherwise they hit Supabase
    // and crash the tree.
    myActiveMatchesProvider.overrideWith((ref) async => const <ArenaMatch>[]),
    activePublicStreamsProvider
        .overrideWith((ref) => Stream<List<MatchStream>>.value(const [])),
    myPaymentsProvider
        .overrideWith((ref) => Stream<List<PaymentRecord>>.value(const [])),
    userNotificationsProvider.overrideWith(
      (ref, _) => Stream<List<ArenaNotification>>.value(const []),
    ),
    if (profile != null) ...[
      if (useSession)
        currentSessionProvider.overrideWith((ref) => _FakeSession(profile.id)),
      currentProfileProvider.overrideWith((ref) async => profile),
    ],
  ];

  return ProviderScope(
    overrides: overrides,
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(userRouterProvider);
        return MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    ),
  );
}

/// Le route `/intro` (cold-start splash) affiche d'abord
/// `_SplashLoadingState` (FutureProvider lit SharedPreferences), puis
/// `_ShortSplashScreen` qui attend 3500ms avant `widget.onComplete()`.
/// On avance le temps de 3600ms pour franchir le `Future.delayed` puis
/// laisser le redirect GoRouter aiguiller vers la route cible.
Future<void> _pumpPastSplash(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 3600));
}

/// MainLayout embarks a continuously-pulsing LIVE card, so
/// `pumpAndSettle` would loop forever. Two short pumps drain the
/// initial frame + the first animation tick, which is enough for
/// our text-based assertions.
Future<void> _pumpAuthed(WidgetTester tester) async {
  await _pumpPastSplash(tester);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _bumpViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  setUp(() {
    FlavorConfig.init(
      flavor: Flavor.user,
      appName: 'ARENA',
      bundleId: 'com.arena.app',
    );
  });

  group('Router redirect chain', () {
    testWidgets('first launch routes to /onboarding', (tester) async {
      await _bumpViewport(tester);
      await tester.pumpWidget(await _buildApp(onboardingCompleted: false));
      await _pumpPastSplash(tester);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('TOURNOIS E-SPORT PANAFRICAINS'), findsOneWidget);
    });

    testWidgets('onboarding done + no session lands on /splash', (tester) async {
      await _bumpViewport(tester);
      await tester.pumpWidget(await _buildApp());
      await _pumpPastSplash(tester);
      await tester.pumpAndSettle();

      expect(find.byType(SplashUserScreen), findsOneWidget);
      expect(find.text('SE CONNECTER'), findsOneWidget);
      expect(find.text('CRÉER UN COMPTE'), findsOneWidget);
    });

    testWidgets('authed + CGU accepted lands on MainLayout (/)', (tester) async {
      await _bumpViewport(tester);
      await tester.pumpWidget(await _buildApp(profile: _player()));
      await _pumpAuthed(tester);

      expect(find.byType(MainLayout), findsOneWidget);
      expect(find.text('ACCUEIL'), findsOneWidget);
      // The 4 bottom-nav labels are part of MainLayout's BottomNav.
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Compétitions'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('authed without CGU is gated on /cgu-acceptance',
        (tester) async {
      await _bumpViewport(tester);
      // `cguAcceptedAt: null` via the sentinel below — _player defaults
      // to a non-null value, so we pass an explicitly-null marker by
      // constructing the Profile directly here.
      const noCguProfile = Profile(
        id: 'p-2',
        username: 'NoCGU',
        email: 'p2@arena.test',
        countryCode: 'CM',
      );
      await tester.pumpWidget(await _buildApp(profile: noCguProfile));
      await _pumpPastSplash(tester);
      await tester.pumpAndSettle();

      expect(find.byType(CguAcceptancePage), findsOneWidget);
    });

    testWidgets('permanent ban routes to /banned (3-strikes gate)',
        (tester) async {
      await _bumpViewport(tester);
      await tester.pumpWidget(
        await _buildApp(profile: _player(permanentBan: true)),
      );
      await _pumpPastSplash(tester);
      await tester.pumpAndSettle();

      expect(find.byType(BannedAccountPage), findsOneWidget);
    });
  });

  group('Pre-auth interactive flow', () {
    testWidgets('splash → tap SE CONNECTER → /login', (tester) async {
      await _bumpViewport(tester);
      await tester.pumpWidget(await _buildApp());
      await _pumpPastSplash(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('SE CONNECTER'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginUserScreen), findsOneWidget);
      expect(find.text('CONNEXION'), findsOneWidget);
    });

    testWidgets('login → tap "Mot de passe oublié ?" → /forgot-password',
        (tester) async {
      await _bumpViewport(tester);
      await tester.pumpWidget(await _buildApp());
      await _pumpPastSplash(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('SE CONNECTER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mot de passe oublié ?'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });
  });

  group('Authed tab navigation', () {
    testWidgets('Accueil → Compétitions swaps the AppBar title',
        (tester) async {
      await _bumpViewport(tester);
      await tester.pumpWidget(await _buildApp(profile: _player()));
      await _pumpAuthed(tester);

      expect(find.text('ACCUEIL'), findsOneWidget);

      await tester.tap(find.text('Compétitions'));
      await _pumpAuthed(tester);

      expect(find.text('COMPÉTITIONS'), findsOneWidget);
    });

    testWidgets('Profil tab surfaces the username', (tester) async {
      await _bumpViewport(tester);
      await tester.pumpWidget(
        await _buildApp(profile: _player(username: 'Drogba')),
      );
      await _pumpAuthed(tester);

      await tester.tap(find.text('Profil'));
      await _pumpAuthed(tester);

      expect(find.text('PROFIL'), findsOneWidget);
      // The username appears in the PlayerProfilePage header + avatar
      // initial, so >1 match is expected.
      expect(find.text('Drogba'), findsWidgets);
    });
  });
}
