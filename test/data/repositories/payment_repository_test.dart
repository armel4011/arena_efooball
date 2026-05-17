import 'package:arena/data/repositories/payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentRecord.fromJson', () {
    Map<String, dynamic> baseRow() => <String, dynamic>{
          'id': 'pay-1',
          'user_id': 'user-1',
          'competition_id': 'comp-1',
          'amount_local': 1500,
          'currency': 'XAF',
          'status': 'awaiting_admin',
          'payer_method': 'MTN_MOMO',
          'payer_phone': '+237600000000',
          'created_at': '2026-05-17T10:00:00.000Z',
        };

    test('happy path : tous les champs renseignés', () {
      final row = baseRow()
        ..addAll({
          'validated_at': '2026-05-17T11:00:00.000Z',
          'validated_by_admin_id': 'admin-1',
          'rejection_reason': null,
        });

      final record = PaymentRecord.fromJson(row);

      expect(record.id, 'pay-1');
      expect(record.userId, 'user-1');
      expect(record.competitionId, 'comp-1');
      expect(record.amountLocal, 1500);
      expect(record.currency, 'XAF');
      expect(record.status, 'awaiting_admin');
      expect(record.payerMethod, 'MTN_MOMO');
      expect(record.payerPhone, '+237600000000');
      expect(record.createdAt, DateTime.utc(2026, 5, 17, 10));
      expect(record.validatedAt, DateTime.utc(2026, 5, 17, 11));
      expect(record.validatedByAdminId, 'admin-1');
      expect(record.rejectionReason, isNull);
    });

    test('currency null → fallback XAF', () {
      final record = PaymentRecord.fromJson(baseRow()..['currency'] = null);
      expect(record.currency, 'XAF');
    });

    test('amount_local int → cast en double', () {
      final record = PaymentRecord.fromJson(baseRow()..['amount_local'] = 2500);
      expect(record.amountLocal, isA<double>());
      expect(record.amountLocal, 2500.0);
    });

    test('amount_local double → conservé', () {
      final record =
          PaymentRecord.fromJson(baseRow()..['amount_local'] = 1234.56);
      expect(record.amountLocal, 1234.56);
    });

    test('validated_at absent → validatedAt null', () {
      final record = PaymentRecord.fromJson(baseRow());
      expect(record.validatedAt, isNull);
    });

    test('payer_method / payer_phone null → champs null', () {
      final row = baseRow()
        ..['payer_method'] = null
        ..['payer_phone'] = null;
      final record = PaymentRecord.fromJson(row);
      expect(record.payerMethod, isNull);
      expect(record.payerPhone, isNull);
    });

    test('rejection_reason renseigné', () {
      final row = baseRow()
        ..['status'] = 'rejected'
        ..['rejection_reason'] = 'numéro inconnu';
      final record = PaymentRecord.fromJson(row);
      expect(record.status, 'rejected');
      expect(record.rejectionReason, 'numéro inconnu');
    });
  });
}
