import 'package:arena/core/router/admin_router.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_admin/auth_admin/invitation_redeem_screen.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAdminAuthRepository extends Mock implements AdminAuthRepository {}

GoRouter _router(Widget body) => GoRouter(
      initialLocation: AdminRoutes.invitation,
      routes: [
        GoRoute(path: AdminRoutes.invitation, builder: (_, __) => body),
        GoRoute(
          path: AdminRoutes.splash,
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('SPLASH_STUB'))),
        ),
        GoRoute(
          path: AdminRoutes.totpSetup,
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('TOTP_SETUP_STUB'))),
        ),
      ],
    );

Widget _scoped(AdminAuthRepository repo) => ProviderScope(
      overrides: [adminAuthRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: _router(const InvitationRedeemScreen()),
      ),
    );

void main() {
  late _FakeAdminAuthRepository repo;

  setUp(() => repo = _FakeAdminAuthRepository());

  // The form is long: a 800x600 viewport hides the CGU tile + the submit
  // button below it, so taps would land on the empty area outside the
  // render tree. Bump the surface to fit everything.
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('renders all 5 fields and the CGU checkbox', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    expect(find.text('INSCRIPTION ADMIN'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5));
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('"create" button stays disabled until CGU checkbox is checked',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    final btn = tester.widget<ArenaButton>(find.byType(ArenaButton));
    expect(btn.onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    final btnAfter = tester.widget<ArenaButton>(find.byType(ArenaButton));
    expect(btnAfter.onPressed, isNotNull);
  });

  testWidgets('rejects malformed invitation code', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'INVALID-CODE');
    await tester.enterText(fields.at(1), 'admin@arena.app');
    await tester.enterText(fields.at(2), 'AdminUser');
    await tester.enterText(fields.at(3), 'Strong#Pass123!');
    await tester.enterText(fields.at(4), 'Strong#Pass123!');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    await tester.tap(find.text('CRÉER LE COMPTE'));
    await tester.pumpAndSettle();

    // The hint text and the validator both contain "ARENA-XXXX" — assert
    // the validator-specific prefix instead.
    expect(find.textContaining('Format attendu'), findsOneWidget);
    verifyNever(
      () => repo.redeemInvitation(
        code: any(named: 'code'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        username: any(named: 'username'),
        cguAcceptedAt: any(named: 'cguAcceptedAt'),
        cguVersionAccepted: any(named: 'cguVersionAccepted'),
      ),
    );
  });

  testWidgets('rejects weak admin password', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'ARENA-AAAA-BBBB-CCCC');
    await tester.enterText(fields.at(1), 'admin@arena.app');
    await tester.enterText(fields.at(2), 'AdminUser');
    await tester.enterText(fields.at(3), 'short'); // < 12 chars
    await tester.enterText(fields.at(4), 'short');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    await tester.tap(find.text('CRÉER LE COMPTE'));
    await tester.pumpAndSettle();

    expect(find.text('Minimum 12 caractères'), findsOneWidget);
  });

  // The full happy-path (form validates → repo is called → BackendUnavailable
  // surfaces) is intentionally not tested here: the long form makes the
  // tap on the bottom CTA flaky in widget-test viewports, and the
  // `BackendUnavailableFailure → user-facing message` mapping is already
  // exhaustively covered by `test/data/auth_failure_test.dart`. Once the
  // PHASE 12.5 Edge Function lands, we'll exercise the success branch
  // through an integration test instead.
}
