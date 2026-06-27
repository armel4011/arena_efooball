import 'package:arena/core/services/anticheat/anticheat_provider.dart';
import 'package:arena/core/services/livekit_capture_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider anti-triche par défaut : capture LiveKit Cloud publish-only
/// ([LiveKitCaptureService]) + enregistrement serveur via Track Egress.
///
/// Enveloppe le service de capture derrière [AntiCheatProvider]. L'Egress
/// (enregistrement effectif des pistes) est démarré côté serveur — cf. Edge
/// Function `livekit-anticheat-start` (PHASE 5).
class LiveKitAntiCheatProvider implements AntiCheatProvider {
  const LiveKitAntiCheatProvider(this._capture);

  final LiveKitCaptureService _capture;

  @override
  AntiCheatProviderKind get kind => AntiCheatProviderKind.livekitTrackEgress;

  @override
  Future<void> startForMatch({
    required String matchId,
    required String playerId,
    String? opponentId, // ignoré : LiveKit ne gère pas l'auto-forfait natif.
  }) {
    return _capture.start(matchId: matchId);
  }

  @override
  Future<void> stopCleanly() => _capture.stop();

  @override
  bool get isCapturing => _capture.state is LiveKitCapturePublishing;
}

final liveKitAntiCheatProviderProvider =
    Provider<LiveKitAntiCheatProvider>((ref) {
  return LiveKitAntiCheatProvider(ref.watch(liveKitCaptureServiceProvider));
});
