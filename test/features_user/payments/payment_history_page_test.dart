// Tests UI — PaymentHistoryPage (P6, 2 onglets PAIEMENTS / GAINS).
//
// ConsumerWidget : flux `myPaymentsProvider` + `myPayoutsProvider`. On override
// les deux avec des listes vides et on vérifie le rendu des onglets et de leurs
// états vides respectifs.

import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/data/repositories/payout_repository.dart';
import 'package:arena/features_user/payments/payment_history_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped() => ProviderScope(
      overrides: [
        myPaymentsProvider.overrideWith(
          (ref) => Stream<List<PaymentRecord>>.value(const []),
        ),
        myPayoutsProvider.overrideWith((ref) async => <PayoutRecord>[]),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PaymentHistoryPage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('onglet PAIEMENTS vide → message vide', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('HISTORIQUE'), findsOneWidget);
    expect(find.text('PAIEMENTS'), findsOneWidget);
    expect(find.text('GAINS'), findsOneWidget);
    expect(find.text('Aucun paiement pour le moment.'), findsOneWidget);
  });

  testWidgets('onglet GAINS vide → message vide', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    await tester.tap(find.text('GAINS'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Aucun gain pour le moment'),
      findsOneWidget,
    );
  });
}
