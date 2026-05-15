import 'package:arena/core/router/admin_router.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_admin/auth_admin/totp_setup_screen.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';

class _FakeAdminAuthRepository extends Mock implements AdminAuthRepository {}

GoRouter _router(Widget body) => GoRouter(
      initialLocation: AdminRoutes.totpSetup,
      routes: [
        GoRoute(path: AdminRoutes.totpSetup, builder: (_, __) => body),
        GoRoute(
          path: AdminRoutes.home,
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('HOME_STUB'))),
        ),
      ],
    );

Widget _scoped(AdminAuthRepository repo) => ProviderScope(
      overrides: [adminAuthRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: _router(const TotpSetupScreen()),
      ),
    );

void main() {
  late _FakeAdminAuthRepository repo;

  setUp(() => repo = _FakeAdminAuthRepository());

  // QR + 3 sections + code field + button — a default 800x600 viewport
  // hides the bottom CTA, so taps would miss it.
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('shows backend-unavailable error when Edge Function is missing',
      (tester) async {
    when(() => repo.setupTotp())
        .thenThrow(const BackendUnavailableFailure('setup-totp pending'));

    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('RÉESSAYER'), findsOneWidget);
  });

  testWidgets('renders QR + secret + code field once challenge arrives',
      (tester) async {
    when(() => repo.setupTotp()).thenAnswer(
      (_) async => const TotpSetupChallenge(
        otpauthUri: 'otpauth://totp/ARENA:admin@arena.app?secret=JBSWY3DPEHPK3PXP',
        secret: 'JBSWY3DPEHPK3PXP',
      ),
    );

    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
    expect(find.text('VÉRIFIER & ACTIVER'), findsOneWidget);
  });

  testWidgets('switches to backup-codes view after a successful verify',
      (tester) async {
    when(() => repo.setupTotp()).thenAnswer(
      (_) async => const TotpSetupChallenge(
        otpauthUri: 'otpauth://totp/...',
        secret: 'SECRET',
      ),
    );
    when(() => repo.verifyTotpSetup(any())).thenAnswer(
      (_) async => const ['AAAA-1111', 'BBBB-2222', 'CCCC-3333'],
    );

    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('VÉRIFIER & ACTIVER'));
    await tester.pumpAndSettle();

    expect(find.text('CODES DE RÉCUPÉRATION'), findsOneWidget);
    expect(find.text('AAAA-1111'), findsOneWidget);
    expect(find.text('BBBB-2222'), findsOneWidget);
  });

  testWidgets('"continue" button stays disabled until codes are acknowledged',
      (tester) async {
    when(() => repo.setupTotp()).thenAnswer(
      (_) async => const TotpSetupChallenge(
        otpauthUri: 'otpauth://totp/...',
        secret: 'SECRET',
      ),
    );
    when(() => repo.verifyTotpSetup(any()))
        .thenAnswer((_) async => const ['AAAA-1111']);

    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('VÉRIFIER & ACTIVER'));
    await tester.pumpAndSettle();

    final btn = tester.widget<ArenaButton>(
      find.widgetWithText(ArenaButton, 'CONTINUER →'),
    );
    expect(btn.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final btnAfter = tester.widget<ArenaButton>(
      find.widgetWithText(ArenaButton, 'CONTINUER →'),
    );
    expect(btnAfter.onPressed, isNotNull);
  });
}
