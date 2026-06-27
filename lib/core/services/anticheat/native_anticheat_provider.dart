import 'package:arena/core/services/anticheat/anticheat_provider.dart';
import 'package:arena/core/services/match_recording_coordinator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider anti-triche « filet de sécurité » : enveloppe le recorder d'écran
/// natif MediaProjection ([MatchRecordingCoordinator]) derrière le contrat
/// [AntiCheatProvider], SANS changer son comportement.
///
/// Les capacités riches du natif (overlay flottant, pause/forfait, export
/// galerie, bascule Live Agora) restent pilotées par le coordinator lui-même
/// et le cycle de vie du match — ce wrapper n'expose que le sous-ensemble
/// commun.
class NativeAntiCheatProvider implements AntiCheatProvider {
  const NativeAntiCheatProvider(this._coordinator);

  final MatchRecordingCoordinator _coordinator;

  @override
  AntiCheatProviderKind get kind => AntiCheatProviderKind.nativeRecorder;

  @override
  Future<void> startForMatch({
    required String matchId,
    required String playerId,
    String? opponentId,
  }) {
    // Le recorder natif a besoin de l'adversaire pour l'auto-forfait.
    if (opponentId == null) {
      throw ArgumentError(
        'NativeAntiCheatProvider requires opponentId (auto-forfait natif)',
      );
    }
    return _coordinator.startForMatch(
      matchId: matchId,
      playerId: playerId,
      opponentId: opponentId,
    );
  }

  @override
  Future<void> stopCleanly() => _coordinator.stopCleanly();

  @override
  bool get isCapturing =>
      _coordinator.state is CoordinatorRecording ||
      _coordinator.state is CoordinatorPaused;
}

final nativeAntiCheatProviderProvider =
    Provider<NativeAntiCheatProvider>((ref) {
  return NativeAntiCheatProvider(
    ref.watch(matchRecordingCoordinatorProvider),
  );
});
