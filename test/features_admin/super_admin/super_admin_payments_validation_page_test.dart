// Tests UI — SuperAdminPaymentsValidationPage (validation des paiements, argent).
//
// Écran le plus sensible de la console super-admin : il liste les paiements
// `awaiting_admin` à valider, la file des remboursements et l'historique. On
// override les 3 StreamProviders pour rendre la page sans backend et verrouiller
// le rendu des cartes + l'état vide. (E1 audit 2026-06-24 — finance admin 0 test UI.)

import 'package:arena/data/repositories/admin/admin_payments_repository.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_admin/super_admin/super_admin_payments_validation_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AdminPaymentRow _row({
  required String id,
  required String username,
  required String competitionName,
  String status = 'awaiting_admin',
}) {
  return AdminPaymentRow(
    username: username,
    competitionName: competitionName,
    payment: PaymentRecord(
      id: id,
      userId: 'u_$id',
      competitionId: 'c_$id',
      amountLocal: 1000,
      currency: 'XAF',
      status: status,
      payerMethod: 'MTN_MOMO',
      payerPhone: '670000000',
      createdAt: DateTime.utc(2026, 6, 24, 10),
    ),
  );
}

Widget _scoped({
  List<AdminPaymentRow> pending = const [],
  List<AdminPaymentRow> refund = const [],
  List<AdminPaymentRow> history = const [],
}) {
  return ProviderScope(
    overrides: [
      adminPendingPaymentsProvider.overrideWith((ref) => Stream.value(pending)),
      adminRefundPendingProvider.overrideWith((ref) => Stream.value(refund)),
      adminPaymentsHistoryProvider.overrideWith((ref) => Stream.value(history)),
    ],
    child: const MaterialApp(
      locale: Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SuperAdminPaymentsValidationPage(),
    ),
  );
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('rend le shell : titre + 3 onglets', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pump();

    expect(tester.takeException(), isNull);
    // ArenaAppBar rend le titre en majuscules.
    expect(find.text('VALIDATION PAIEMENTS'), findsOneWidget);
    expect(find.text('EN ATTENTE'), findsOneWidget);
    expect(find.text('REMBOURSEMENTS'), findsOneWidget);
    expect(find.text('HISTORIQUE'), findsOneWidget);
  });

  testWidgets('onglet EN ATTENTE : affiche une carte par paiement à valider',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(
        pending: [
          _row(
            id: 'aaaaaaaa-1111',
            username: 'joueur_alpha',
            competitionName: 'Coupe ARENA',
          ),
          _row(
            id: 'bbbbbbbb-2222',
            username: 'joueur_beta',
            competitionName: 'Ligue Dames',
          ),
        ],
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('joueur_alpha'), findsOneWidget);
    expect(find.text('joueur_beta'), findsOneWidget);
    expect(find.textContaining('Coupe ARENA'), findsOneWidget);
  });

  testWidgets('onglet EN ATTENTE vide : état « Rien à valider »',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Rien à valider pour le moment.'), findsOneWidget);
  });
}
