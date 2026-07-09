import 'package:arena/data/repositories/admin/admin_payments_repository.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_admin_desktop/finance/desktop_payments_validation_page.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premier test widget de la console admin DESKTOP (surface argent). Établit le
/// harnais Fluent + ProviderScope et couvre le rendu de la file de validation
/// des paiements (état vide + une ligne en attente) — filet contre une
/// régression silencieuse sur l'écran qui valide de l'argent réel.

PaymentRecord _payment() => PaymentRecord(
      id: 'pay-1',
      userId: 'user-1',
      competitionId: 'comp-1',
      amountLocal: 1000,
      currency: 'XAF',
      status: 'awaiting_admin',
      payerMethod: 'mtn_momo',
      payerPhone: '677000000',
      createdAt: DateTime.utc(2026, 7, 1, 10),
    );

AdminPaymentRow _row() => AdminPaymentRow(
      payment: _payment(),
      username: 'joueur_test',
      competitionName: 'Coupe Test',
    );

Widget _harness(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const FluentApp(
        debugShowCheckedModeBanner: false,
        home: DesktopPaymentsValidationPage(),
      ),
    );

void main() {
  setUpAll(() {
    // Pas de fetch réseau des polices en test (offline CI) : fallback local.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('file vide → message « aucun paiement à valider »',
      (tester) async {
    await tester.pumpWidget(_harness([
      adminPendingPaymentsProvider.overrideWith(
        (ref) => Stream.value(const <AdminPaymentRow>[]),
      ),
      adminRefundPendingProvider.overrideWith(
        (ref) => Stream.value(const <AdminPaymentRow>[]),
      ),
      adminPaymentsHistoryProvider.overrideWith(
        (ref) => Stream.value(const <AdminPaymentRow>[]),
      ),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('VALIDATION DES PAIEMENTS'), findsOneWidget);
    expect(
      find.text('Aucun paiement à valider pour le moment.'),
      findsOneWidget,
    );
  });

  testWidgets('un paiement en attente → carte avec joueur, compétition, montant',
      (tester) async {
    await tester.pumpWidget(_harness([
      adminPendingPaymentsProvider.overrideWith(
        (ref) => Stream.value(<AdminPaymentRow>[_row()]),
      ),
      adminRefundPendingProvider.overrideWith(
        (ref) => Stream.value(const <AdminPaymentRow>[]),
      ),
      adminPaymentsHistoryProvider.overrideWith(
        (ref) => Stream.value(const <AdminPaymentRow>[]),
      ),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('joueur_test'), findsOneWidget);
    expect(find.text('Coupe Test'), findsOneWidget);
    // Montant formaté (adminMoney) suivi de la devise.
    expect(find.textContaining('XAF'), findsWidgets);
  });
}
