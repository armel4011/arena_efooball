// Tests UI du flux ARGENT — P3 : attente de validation super-admin.
//
// PaymentProcessingPage stream le statut du paiement et bascule sur P4
// (succeeded) ou P5 (rejected). On override paymentByIdProvider et on vérifie :
// l'état d'attente (spinner + référence), puis les deux transitions de
// navigation. Monté dans un GoRouter avec des stubs P4/P5.

import 'package:arena/core/router/user_router.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/features_user/payments/payment_processing_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

PaymentRecord _rec(String status) => PaymentRecord(
      id: 'pay-12345678',
      userId: 'u1',
      competitionId: 'c1',
      amountLocal: 1500,
      currency: 'XAF',
      status: status,
      payerMethod: 'MTN_MOMO',
      payerPhone: '+237 678451242',
      createdAt: DateTime(2026, 6, 14, 10, 30),
    );

Widget _app(PaymentRecord rec) {
  final router = GoRouter(
    initialLocation: '/p3',
    routes: [
      GoRoute(
        path: '/p3',
        builder: (context, state) => const PaymentProcessingPage(
          paymentId: 'pay-12345678',
          operator: PaymentOperator(
            label: 'MTN MoMo',
            code: 'MTN_MOMO',
            countryCode: 'CM',
          ),
          amountXaf: 1500,
          competitionName: 'Coupe ARENA',
          maskedPhone: '+237 ••• •• •• 42',
        ),
      ),
      GoRoute(
        path: UserRoutes.paymentSuccess,
        builder: (context, state) => const Scaffold(body: Text('P4-SUCCESS')),
      ),
      GoRoute(
        path: UserRoutes.paymentFailed,
        builder: (context, state) => const Scaffold(body: Text('P5-FAILED')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      paymentByIdProvider.overrideWith((ref, id) => Stream.value(rec)),
    ],
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

  testWidgets("awaiting_admin → écran d'attente (spinner + référence)",
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_app(_rec('awaiting_admin')));
    // Pas de pumpAndSettle : le spinner d'attente tourne indéfiniment.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Référence dérivée des 8 premiers caractères de l'id.
    expect(find.text('ARENA-PAY-1234'), findsOneWidget);
    // Pas de navigation : on est toujours sur P3.
    expect(find.text('P4-SUCCESS'), findsNothing);
    expect(find.text('P5-FAILED'), findsNothing);
  });

  testWidgets('succeeded → navigue vers P4 (succès)', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_app(_rec('succeeded')));
    await tester.pumpAndSettle();

    expect(find.text('P4-SUCCESS'), findsOneWidget);
  });

  testWidgets('rejected → navigue vers P5 (échec)', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_app(_rec('rejected')));
    await tester.pumpAndSettle();

    expect(find.text('P5-FAILED'), findsOneWidget);
  });
}
