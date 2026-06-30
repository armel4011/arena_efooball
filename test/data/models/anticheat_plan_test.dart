import 'package:arena/data/models/anticheat_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnticheatPlan.fromJson', () {
    test('tier livekit + élu + raison + date', () {
      final p = AnticheatPlan.fromJson(const {
        'mode': 'livekit',
        'recorded_player_id': 'p1',
        'reason': 'prize',
        'decided_at': '2026-06-30T12:00:00Z',
      });
      expect(p.tier, AnticheatTier.livekit);
      expect(p.isLivekit, isTrue);
      expect(p.recordedPlayerId, 'p1');
      expect(p.reason, 'prize');
      expect(p.decidedAt, isNotNull);
    });

    test("tier native_only : pas d'élu", () {
      final p = AnticheatPlan.fromJson(const {'mode': 'native_only'});
      expect(p.tier, AnticheatTier.nativeOnly);
      expect(p.isLivekit, isFalse);
      expect(p.recordedPlayerId, isNull);
      expect(p.decidedAt, isNull);
    });

    test('mode inconnu → native_only (sûr)', () {
      expect(
        AnticheatPlan.fromJson(const {'mode': null}).tier,
        AnticheatTier.nativeOnly,
      );
    });
  });

  test('libellés de tier', () {
    expect(AnticheatTier.livekit.label, 'Egress LiveKit');
    expect(AnticheatTier.nativeOnly.label, 'Natif seul (hash)');
  });

  test('libellés de raison', () {
    expect(anticheatReasonLabel('prize'), 'Cagnotte élevée');
    expect(anticheatReasonLabel('surveillance'), 'Joueur sous surveillance');
    expect(anticheatReasonLabel('dispute'), 'Litige sur le match');
    expect(anticheatReasonLabel('random'), 'Échantillon aléatoire');
    expect(anticheatReasonLabel(null), 'Plancher de preuve (hash) seul');
  });
}
