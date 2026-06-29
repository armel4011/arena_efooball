import 'dart:async';
import 'dart:io';

import 'package:arena/core/services/sync_queue_service.dart';
import 'package:arena/core/utils/error_reporter.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SHA-256 (hex minuscules) d'un fichier, calculé EN FLUX (chunked) pour ne
/// jamais charger un MP4 de ~112 Mo entièrement en mémoire sur un device bas
/// de gamme. Exposé au niveau module pour être testable.
Future<String> sha256OfFile(File file) async {
  // `bind` consomme le flux d'octets et émet un unique Digest — hash chunked
  // sans charger tout le fichier en mémoire.
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}

/// Anti-triche Phase 3 (commitment hash), côté joueur — OPTION B : on engage
/// le hash À LA FIN DU MATCH, sans gater la soumission de score.
///
/// À la transition `CoordinatorStopped` (capture native terminée), on hashe le
/// fichier local et on enfile une [ProofCommitmentAction]. La sync queue flushe
/// immédiatement si le réseau est là, sinon au retour de connexion — donc le
/// commitment part même en 2G, et la perte réseau ne bloque rien (fire-and-
/// forget). La vidéo elle-même n'est uploadée que plus tard, sur réclamation
/// admin (cf. EF proof-verify / RPC admin_claim_proof).
///
/// On engage le hash du fichier 540p tel quel (garde-fou du plan : le proxy
/// 360p transcodé est une optimisation Kotlin ultérieure ; le commitment reste
/// valable sur le 540p).
class ProofCommitmentService {
  ProofCommitmentService(this._ref);

  final Ref _ref;

  /// Hashe le fichier local [filePath] et engage le commitment pour [matchId].
  /// No-op silencieux si le fichier est absent/vide. Ne lève jamais : un échec
  /// d'anti-triche ne doit pas casser le flux de fin de match.
  Future<void> commitForMatch({
    required String matchId,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      // Sync stat (avoid_slow_async_io) : un simple existence/taille, pas de
      // lecture — négligeable, et on est déjà hors chemin critique.
      if (!file.existsSync()) return;
      final size = file.lengthSync();
      if (size <= 0) return;

      final sha = await sha256OfFile(file);

      final action = ProofCommitmentAction(
        id: generateUuidV4(),
        createdAt: DateTime.now().toUtc(),
        matchId: matchId,
        sha256: sha,
        bytes: size,
      );

      final queue = _ref.read(syncQueueServiceProvider).valueOrNull;
      if (queue == null) {
        // Queue pas encore prête (rare, tôt au boot) : tentative directe
        // best-effort ; l'EF est idempotent si un rejeu survient.
        await action.execute(_ref.read(supabaseClientProvider));
        return;
      }
      await queue.enqueue(action);
    } catch (e, st) {
      unawaited(reportError(e, st, context: 'ProofCommitment.commitForMatch'));
    }
  }
}

final proofCommitmentServiceProvider = Provider<ProofCommitmentService>(
  ProofCommitmentService.new,
);
