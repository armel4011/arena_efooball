import 'package:arena/features_shared/admin/dispute_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('disputeWalkoverScore', () {
    test('J1 vainqueur → 3-0', () {
      final s = disputeWalkoverScore(winnerId: 'p1', player1Id: 'p1');
      expect(s.scoreP1, 3);
      expect(s.scoreP2, 0);
    });

    test('J2 vainqueur → 0-3', () {
      final s = disputeWalkoverScore(winnerId: 'p2', player1Id: 'p1');
      expect(s.scoreP1, 0);
      expect(s.scoreP2, 3);
    });

    test('winnerId null (≠ player1) → orienté vers J2', () {
      final s = disputeWalkoverScore(winnerId: null, player1Id: 'p1');
      expect(s.scoreP1, 0);
      expect(s.scoreP2, 3);
    });
  });
}
