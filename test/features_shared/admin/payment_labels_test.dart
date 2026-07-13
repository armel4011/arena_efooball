import 'package:arena/data/models/payout.dart';
import 'package:arena/features_shared/admin/payment_labels.dart';
import 'package:arena/features_shared/admin/payout_checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('paymentMethodLabel', () {
    test('codes connus', () {
      expect(paymentMethodLabel('MTN_MOMO'), 'MTN MoMo');
      expect(paymentMethodLabel('ORANGE_MONEY'), 'Orange Money');
    });
    test('null / inconnu → tiret', () {
      expect(paymentMethodLabel(null), '—');
      expect(paymentMethodLabel('BITCOIN'), '—');
    });
  });

  group('payoutCheckLabel', () {
    test('clés connues + alias', () {
      expect(payoutCheckLabel('kyc'), 'KYC vérifié');
      expect(payoutCheckLabel('kyc_verified'), 'KYC vérifié');
      expect(payoutCheckLabel('anti_cheat'), "Pas d'alerte anti-cheat");
      expect(payoutCheckLabel('payment_destination'), 'Destination paiement valide');
    });
    test('clé inconnue → underscores en espaces', () {
      expect(payoutCheckLabel('some_new_key'), 'some new key');
    });
  });

  group('buildPayoutChecks', () {
    test('checks vides → 1 entrée empty (label paramétrable)', () {
      final p = _payout(const {});
      expect(buildPayoutChecks(p).single.ok, isFalse);
      expect(
        buildPayoutChecks(p, emptyLabel: 'Aucun contrôle auto').single.label,
        'Aucun contrôle auto',
      );
    });
    test('mappe chaque entrée (label + ok booléen)', () {
      final checks = buildPayoutChecks(_payout(const {
        'kyc': true,
        'no_dispute': false,
      }));
      expect(checks.length, 2);
      expect(checks[0].label, 'KYC vérifié');
      expect(checks[0].ok, isTrue);
      expect(checks[1].ok, isFalse);
    });
  });
}

Payout _payout(Map<String, dynamic> autoChecks) => Payout(
      id: 'po1',
      competitionId: 'c1',
      userId: 'u1',
      amountLocal: 1000,
      currency: 'XAF',
      status: 'pending_admin_validation',
      autoChecks: autoChecks,
    );
