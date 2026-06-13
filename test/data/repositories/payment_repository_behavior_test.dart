import 'package:arena/data/repositories/payment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '_supabase_mocks.dart';

/// Tests de COMPORTEMENT du repo paiement (au-delà du mapping `fromJson`),
/// ciblant les invariants « argent » côté client :
///  * un paiement ne part qu'authentifié ;
///  * il part toujours en `awaiting_admin` via le provider manuel (le client
///    ne forge jamais un status validé — défense en profondeur, doublée par
///    la RLS `payments_self_insert` côté serveur) ;
///  * `hasPendingPayments` couvre bien les 3 statuts « en vol » (fix P0 de la
///    suppression de compte : `awaiting_admin` ne devait pas passer entre les
///    mailles).
void main() {
  group('submitManualPayment', () {
    test('lève StateError si aucun utilisateur authentifié', () async {
      final client = MockSupabaseClient();
      stubAuthUser(client, null);
      final repo = PaymentRepository(client);

      expect(
        () => repo.submitManualPayment(
          competitionId: 'comp-1',
          amountLocal: 5000,
          currency: 'XOF',
          payerMethodCode: 'MTN_MOMO',
          payerPhone: '+237600000000',
        ),
        throwsStateError,
      );
    });

    test(
      'insère provider=mobile_money_manual + status=awaiting_admin + user courant',
      () async {
        final client = MockSupabaseClient();
        stubAuthUser(client, 'user-42');
        final probe = stubFrom(client, 'payments', {'id': 'pay-9'});
        final repo = PaymentRepository(client);

        final id = await repo.submitManualPayment(
          competitionId: 'comp-1',
          amountLocal: 5000,
          currency: 'XOF',
          payerMethodCode: 'ORANGE_MONEY',
          payerPhone: '+237600000000',
        );

        expect(id, 'pay-9');
        final payload = probe.insertedValues! as Map<String, dynamic>;
        expect(payload['provider'], 'mobile_money_manual');
        expect(payload['status'], 'awaiting_admin');
        expect(payload['user_id'], 'user-42');
        expect(payload['competition_id'], 'comp-1');
        // Le client ne doit JAMAIS pouvoir marquer un paiement réglé.
        expect(payload['status'], isNot(anyOf('succeeded', 'validated')));
      },
    );
  });

  group('hasPendingPayments', () {
    test(
      'filtre les 3 statuts en vol (pending/processing/awaiting_admin) '
      'sur le bon user',
      () async {
        final client = MockSupabaseClient();
        final probe = stubFrom(client, 'payments', <Map<String, dynamic>>[]);
        final repo = PaymentRepository(client);

        await repo.hasPendingPayments('user-7');

        expect(probe.hasFilter('eq', 'user_id'), isTrue);
        expect(probe.hasFilter('in', 'status'), isTrue);
        final statusFilter =
            probe.filters.firstWhere((f) => f.startsWith('in:status='));
        expect(statusFilter, contains('awaiting_admin'));
        expect(statusFilter, contains('pending'));
        expect(statusFilter, contains('processing'));
      },
    );

    test('true si au moins un paiement en vol, false sinon', () async {
      final clientEmpty = MockSupabaseClient();
      stubFrom(clientEmpty, 'payments', <Map<String, dynamic>>[]);
      expect(
        await PaymentRepository(clientEmpty).hasPendingPayments('u'),
        isFalse,
      );

      final clientHit = MockSupabaseClient();
      stubFrom(clientHit, 'payments', [
        {'id': 'pay-1'},
      ]);
      expect(
        await PaymentRepository(clientHit).hasPendingPayments('u'),
        isTrue,
      );
    });
  });

  group('myPendingPaymentByCompetitionProvider', () {
    PaymentRecord rec(String comp, String status) => PaymentRecord(
          id: 'pay-$comp',
          userId: 'u',
          competitionId: comp,
          amountLocal: 5000,
          currency: 'XOF',
          status: status,
          payerMethod: 'MTN_MOMO',
          payerPhone: '+237600000000',
          createdAt: DateTime.utc(2026, 6, 13),
        );

    test('ne mappe que les paiements awaiting_admin, par compétition',
        () async {
      final container = ProviderContainer(
        overrides: [
          myPaymentsProvider.overrideWith(
            (ref) => Stream.value([
              rec('comp-A', 'awaiting_admin'),
              rec('comp-B', 'succeeded'),
              rec('comp-C', 'rejected'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Laisse le StreamProvider émettre sa valeur.
      await container.read(myPaymentsProvider.future);
      final map = container.read(myPendingPaymentByCompetitionProvider);

      expect(map.keys, ['comp-A']);
      expect(map['comp-A']!.status, 'awaiting_admin');
    });
  });
}
