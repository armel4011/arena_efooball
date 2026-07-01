import 'package:arena/core/services/anticheat/anticheat_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AntiCheatProviderKind.fromWire', () {
    test('maps known wire values', () {
      expect(
        AntiCheatProviderKind.fromWire('native_recorder'),
        AntiCheatProviderKind.nativeRecorder,
      );
      expect(
        AntiCheatProviderKind.fromWire('livekit_track_egress'),
        AntiCheatProviderKind.livekitTrackEgress,
      );
    });

    test('falls back on unknown / null / non-string', () {
      expect(
        AntiCheatProviderKind.fromWire('bogus'),
        AntiCheatProviderKind.fallback,
      );
      expect(
        AntiCheatProviderKind.fromWire(null),
        AntiCheatProviderKind.fallback,
      );
      expect(
        AntiCheatProviderKind.fromWire(42),
        AntiCheatProviderKind.fallback,
      );
    });

    test('default fallback is the native recorder (safe net, no cold crash)',
        () {
      expect(
        AntiCheatProviderKind.fallback,
        AntiCheatProviderKind.nativeRecorder,
      );
    });

    test('wire values are stable snake_case', () {
      expect(AntiCheatProviderKind.nativeRecorder.wire, 'native_recorder');
      expect(
        AntiCheatProviderKind.livekitTrackEgress.wire,
        'livekit_track_egress',
      );
    });
  });
}
