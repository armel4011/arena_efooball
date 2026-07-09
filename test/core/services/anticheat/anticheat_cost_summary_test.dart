import 'package:arena/core/services/anticheat/anticheat_tiering_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnticheatCostSummary.fromJson', () {
    test('parse complet (jsonb RPC anticheat_cost_summary)', () {
      final s = AnticheatCostSummary.fromJson(const {
        'since': null,
        'decided': 40,
        'livekit': 6,
        'native_only': 34,
        'livekit_fraction': 0.15,
        'by_reason': {
          'prize': 3,
          'surveillance': 1,
          'dispute': 1,
          'random': 1,
        },
        'cost_per_egress_usd': 0.034,
        'actual_cost_usd': 0.204,
        'baseline_cost_usd': 2.72,
        'savings_usd': 2.516,
        'savings_pct': 92.5,
      });
      expect(s.decided, 40);
      expect(s.livekit, 6);
      expect(s.nativeOnly, 34);
      expect(s.livekitFraction, 0.15);
      expect(s.prize, 3);
      expect(s.surveillance, 1);
      expect(s.dispute, 1);
      expect(s.random, 1);
      expect(s.costPerEgressUsd, 0.034);
      expect(s.actualCostUsd, 0.204);
      expect(s.baselineCostUsd, 2.72);
      expect(s.savingsUsd, 2.516);
      expect(s.savingsPct, 92.5);
    });

    test('valeurs numériques encodées en String tolérées', () {
      final s = AnticheatCostSummary.fromJson(const {
        'decided': '10',
        'livekit': '2',
        'native_only': '8',
        'livekit_fraction': '0.2',
        'by_reason': {'prize': '2'},
        'cost_per_egress_usd': '0.034',
        'actual_cost_usd': '0.068',
        'baseline_cost_usd': '0.68',
        'savings_usd': '0.612',
        'savings_pct': '90',
      });
      expect(s.decided, 10);
      expect(s.livekit, 2);
      expect(s.livekitFraction, 0.2);
      expect(s.prize, 2);
      expect(s.surveillance, 0);
      expect(s.actualCostUsd, 0.068);
    });

    test('by_reason ou clés manquantes → 0', () {
      final s = AnticheatCostSummary.fromJson(const {'decided': 0});
      expect(s.decided, 0);
      expect(s.livekit, 0);
      expect(s.prize, 0);
      expect(s.random, 0);
      expect(s.savingsPct, 0);
    });

    test('empty = résumé nul, coût unitaire par défaut', () {
      expect(AnticheatCostSummary.empty.decided, 0);
      expect(AnticheatCostSummary.empty.livekit, 0);
      expect(AnticheatCostSummary.empty.costPerEgressUsd, 0.034);
    });
  });
}
