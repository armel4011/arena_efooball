// Tests UI du flux ARGENT — P4 : paiement réussi (reçu + accès compétition).
//
// PaymentSuccessPage est un StatelessWidget d'affichage. On vérifie le rendu du
// reçu (nom du tournoi), le CTA retour accueil, et la présence conditionnelle
// du bouton « voir la compétition » selon competitionId.

import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/features_user/payments/payment_success_page.dart';
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

  testWidgets('affiche le reçu avec le nom du tournoi', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(
        const PaymentSuccessPage(
          amountXaf: 1500,
          operator: PaymentOperator(
            label: 'MTN MoMo',
            code: 'MTN_MOMO',
            countryCode: 'CM',
          ),
          transactionId: 'ARENA-ABCD1234',
          dateLabel: '14/06 10:30',
          tournamentName: 'COUPE TEST',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('COUPE TEST'), findsOneWidget);
  });

  testWidgets('sans competitionId → un seul bouton (retour) → onBackHome',
      (tester) async {
    await bumpViewport(tester);
    var backHome = false;
    await tester.pumpWidget(
      _scoped(
        PaymentSuccessPage(
          amountXaf: 1500,
          operator: const PaymentOperator(
            label: 'Orange Money',
            code: 'ORANGE_MONEY',
            countryCode: 'CM',
          ),
          transactionId: 'ARENA-ABCD1234',
          dateLabel: '14/06 10:30',
          onBackHome: () => backHome = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ArenaButton), findsOneWidget);
    await tester.tap(find.byType(ArenaButton));
    await tester.pumpAndSettle();
    expect(backHome, isTrue);
  });

  testWidgets('avec competitionId → bouton voir la compétition en plus',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(
        const PaymentSuccessPage(
          amountXaf: 1500,
          operator: PaymentOperator(
            label: 'MTN MoMo',
            code: 'MTN_MOMO',
            countryCode: 'CM',
          ),
          transactionId: 'ARENA-ABCD1234',
          dateLabel: '14/06 10:30',
          competitionId: 'c-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Bouton "voir la compétition" + bouton "retour accueil".
    expect(find.byType(ArenaButton), findsNWidgets(2));
  });
}
