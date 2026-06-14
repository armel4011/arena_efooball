import 'package:arena/features_shared/player_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tierFor (paliers par victoires)', () {
    test('< 5 victoires → bronze', () {
      expect(tierFor(0), PlayerTier.bronze);
      expect(tierFor(4), PlayerTier.bronze);
    });

    test('5–14 victoires → argent', () {
      expect(tierFor(5), PlayerTier.silver);
      expect(tierFor(14), PlayerTier.silver);
    });

    test('15–29 victoires → or', () {
      expect(tierFor(15), PlayerTier.gold);
      expect(tierFor(29), PlayerTier.gold);
    });

    test('>= 30 victoires → élite', () {
      expect(tierFor(30), PlayerTier.elite);
      expect(tierFor(1000), PlayerTier.elite);
    });
  });

  test('chaque palier expose un gradient à 2 couleurs', () {
    for (final tier in PlayerTier.values) {
      expect(tier.gradient.length, 2, reason: 'tier $tier');
    }
  });
}
