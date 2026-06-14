// Tests UI du flux ARGENT — P2 : détails Mobile Money + soumission "J'AI PAYÉ".
//
// MobileMoneyDetailsPage gate le bouton de soumission sur (numéro valide à 9
// chiffres ET code marchand présent), puis sur tap appelle
// PaymentRepository.submitManualPayment et navigue vers P3. On monte la page
// dans un GoRouter minimal pour que la navigation post-submit aboutisse.

import 'package:arena/core/router/user_router.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/payments/mobile_money_details_page.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakePaymentRepo extends Fake implements PaymentRepository {
  int calls = 0;
  String? lastMethodCode;
  String? lastPhone;
  double? lastAmount;

  @override
  Future<String> submitManualPayment({
    required String competitionId,
    required double amountLocal,
    required String currency,
    required String payerMethodCode,
    required String payerPhone,
  }) async {
    calls++;
    lastMethodCode = payerMethodCode;
    lastPhone = payerPhone;
    lastAmount = amountLocal;
    return 'pay-123';
  }
}

Widget _app({
  required _FakePaymentRepo repo,
  String merchantCode = '*126*1*ARENA#',
}) {
  final router = GoRouter(
    initialLocation: '/p2',
    routes: [
      GoRoute(
        path: '/p2',
        builder: (context, state) => MobileMoneyDetailsPage(
          method: PaymentMethod.mtnMoMo,
          amountXaf: 1500,
          competitionId: 'c1',
          competitionName: 'Coupe ARENA',
          merchantCode: merchantCode,
        ),
      ),
      GoRoute(
        path: UserRoutes.paymentProcessing,
        builder: (context, state) =>
            const Scaffold(body: Text('P3-PROCESSING')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [paymentRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  // Le bouton "J'AI PAYÉ" est le dernier ArenaButton (après copier/exécuter
  // de la carte code marchand).
  ArenaButton submitButton(WidgetTester tester) =>
      tester.widget<ArenaButton>(find.byType(ArenaButton).last);

  testWidgets('code présent mais numéro vide → bouton de paiement désactivé',
      (tester) async {
    await bumpViewport(tester);
    final repo = _FakePaymentRepo();
    await tester.pumpWidget(_app(repo: repo));
    await tester.pumpAndSettle();

    // Le code marchand est affiché.
    expect(find.text('*126*1*ARENA#'), findsOneWidget);
    // Sans numéro valide, le bouton est désactivé (onPressed null).
    expect(submitButton(tester).onPressed, isNull);
  });

  testWidgets('numéro valide → submit appelle submitManualPayment + va en P3',
      (tester) async {
    await bumpViewport(tester);
    final repo = _FakePaymentRepo();
    await tester.pumpWidget(_app(repo: repo));
    await tester.pumpAndSettle();

    // 9 chiffres → numéro valide.
    await tester.enterText(find.byType(TextField).last, '678451242');
    await tester.pumpAndSettle();

    expect(submitButton(tester).onPressed, isNotNull);

    await tester.tap(find.byType(ArenaButton).last);
    await tester.pumpAndSettle();

    expect(repo.calls, 1);
    expect(repo.lastMethodCode, 'MTN_MOMO');
    expect(repo.lastAmount, 1500.0);
    expect(repo.lastPhone, contains('678451242'));
    expect(repo.lastPhone, contains('+237'));
    // Navigation vers P3.
    expect(find.text('P3-PROCESSING'), findsOneWidget);
  });

  testWidgets('code marchand manquant → bannière + bouton désactivé même si '
      'le numéro est valide', (tester) async {
    await bumpViewport(tester);
    final repo = _FakePaymentRepo();
    await tester.pumpWidget(_app(repo: repo, merchantCode: ''));
    await tester.pumpAndSettle();

    // Pas de carte code marchand (donc pas le code affiché).
    expect(find.text('*126*1*ARENA#'), findsNothing);

    await tester.enterText(find.byType(TextField).last, '678451242');
    await tester.pumpAndSettle();

    // hasCode == false → bouton désactivé même avec un numéro valide.
    expect(submitButton(tester).onPressed, isNull);
    expect(repo.calls, 0);
  });
}
