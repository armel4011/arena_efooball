import 'package:arena/data/repositories/referral_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late ReferralRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = ReferralRepository(client);
  });

  group('countMyReferrals (RPC)', () {
    test('renvoie le nombre de filleuls', () async {
      when(
        () => client.rpc<dynamic>(
          'count_user_referrals',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<dynamic>(Future<dynamic>.value(4)));
      expect(await repo.countMyReferrals('u1'), 4);
    });

    test('null → 0', () async {
      when(
        () => client.rpc<dynamic>(
          'count_user_referrals',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<dynamic>(Future<dynamic>.value(null)));
      expect(await repo.countMyReferrals('u1'), 0);
    });
  });

  group('checkEligibility (anti-abus parrainage)', () {
    test('parse eligible/current/target + passe les bons params', () async {
      when(
        () => client.rpc<dynamic>(
          'can_register_via_referral',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) => FakeQueryChain<dynamic>(
          Future<dynamic>.value({
            'eligible': true,
            'current': 3,
            'target': 2,
            'reason': 'ok',
          }),
        ),
      );

      final e = await repo.checkEligibility(userId: 'u1', competitionId: 'c1');

      expect(e.eligible, isTrue);
      expect(e.current, 3);
      expect(e.target, 2);
      expect(e.hasQuota, isTrue);
      verify(
        () => client.rpc<dynamic>(
          'can_register_via_referral',
          params: {'p_user_id': 'u1', 'p_competition_id': 'c1'},
        ),
      ).called(1);
    });

    test('champs manquants → defaults (non éligible, quota 0)', () async {
      when(
        () => client.rpc<dynamic>(
          'can_register_via_referral',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) => FakeQueryChain<dynamic>(
          Future<dynamic>.value(<String, dynamic>{}),
        ),
      );
      final e = await repo.checkEligibility(userId: 'u1', competitionId: 'c1');
      expect(e.eligible, isFalse);
      expect(e.target, 0);
      expect(e.hasQuota, isFalse);
    });
  });
}
