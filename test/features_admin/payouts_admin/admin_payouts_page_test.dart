// Tests UI — AdminPayoutsPage (validation des versements / argent sortant).
//
// Liste les payouts `pending_admin_validation` et affiche le total à verser.
// On override le StreamProvider pour rendre la page sans backend : état vide
// + résumé chiffré. (E1 audit 2026-06-24 — payouts_admin 0 test UI.)

import 'package:arena/data/models/payout.dart';
import 'package:arena/data/repositories/admin/admin_payouts_repository.dart';
import 'package:arena/features_admin/payouts_admin/admin_payouts_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped(List<Payout> payouts) {
  return ProviderScope(
    overrides: [
      adminPendingPayoutsProvider.overrideWith((ref) => Stream.value(payouts)),
    ],
    child: const MaterialApp(
      locale: Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AdminPayoutsPage(),
    ),
  );
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('liste vide : titre + état « Aucun payout »', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(const []));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('PAYOUTS ⚠'), findsOneWidget);
    expect(find.text('✅ Aucun payout en attente.'), findsOneWidget);
  });

  testWidgets('avec données : résumé du total + nombre de payouts',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(const [
        Payout(
          id: 'payout-0001',
          userId: 'user-aaaa-0001',
          competitionId: 'comp-aaaa-0001',
          amountLocal: 50000,
          status: 'pending_admin_validation',
        ),
        Payout(
          id: 'payout-0002',
          userId: 'user-bbbb-0002',
          competitionId: 'comp-aaaa-0001',
          amountLocal: 20000,
          status: 'pending_admin_validation',
        ),
      ]),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('À verser'), findsOneWidget);
    expect(find.text('2 payouts pending'), findsOneWidget);
  });
}
