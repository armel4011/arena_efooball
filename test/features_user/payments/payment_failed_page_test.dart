// Tests UI du flux ARGENT — P5 : paiement échoué.
//
// PaymentFailedPage est un StatelessWidget piloté par `reason` + `adminReason`.
// On vérifie que la justification du super-admin est affichée en cas de refus,
// et que les deux CTA (réessayer / contacter le support) déclenchent leurs
// callbacks. Assertions basées sur les entrées (pas sur les strings l10n).

import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/payments/payment_failed_page.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('refus admin → affiche la justification saisie', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(
        const PaymentFailedPage(
          reason: PaymentFailReason.rejected,
          adminReason: 'Montant incorrect reçu',
          method: PaymentMethod.mtnMoMo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Montant incorrect reçu'), findsOneWidget);
  });

  testWidgets('bouton réessayer → déclenche onRetry', (tester) async {
    await bumpViewport(tester);
    var retried = false;
    await tester.pumpWidget(
      _scoped(
        PaymentFailedPage(
          reason: PaymentFailReason.network,
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ArenaButton));
    await tester.pumpAndSettle();

    expect(retried, isTrue);
  });

  testWidgets('lien support → déclenche onContactSupport', (tester) async {
    await bumpViewport(tester);
    var contacted = false;
    await tester.pumpWidget(
      _scoped(
        PaymentFailedPage(
          reason: PaymentFailReason.unknown,
          onContactSupport: () => contacted = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(contacted, isTrue);
  });
}
