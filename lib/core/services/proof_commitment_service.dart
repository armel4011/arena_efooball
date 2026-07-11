import 'dart:async';
import 'dart:io';

import 'package:arena/core/services/proof_archive.dart';
import 'package:arena/core/services/proof_file_store.dart';
import 'package:arena/core/services/proof_transcoder.dart';
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
  ///
  /// [playerId] : le joueur (soi) — mémorisé avec le chemin du fichier pour
  /// pouvoir le livrer plus tard sur réclamation admin (cf. ProofClaimService).
  Future<void> commitForMatch({
    required String matchId,
    required String filePath,
    required String playerId,
  }) async {
    try {
      // Sync stat (avoid_slow_async_io) : un simple existence/taille, pas de
      // lecture — négligeable, et on est déjà hors chemin critique.
      if (!File(filePath).existsSync()) return;

      // WRITE-ONCE CÔTÉ CLIENT (intégrité anti-triche). Le commitment SERVEUR
      // est write-once (`anticheat-commit` n'écrase jamais un hash engagé).
      // Or `ProofFileStore` est keyé par MATCH : un ré-enregistrement du même
      // match (ré-entrées dans la salle, redémarrage capture MIUI, coordinator
      // relancé…) écraserait l'entrée et pointerait l'upload vers un AUTRE
      // fichier que celui dont le hash a été engagé → `proof-verify` le
      // déclarerait « falsifié » alors que le joueur n'a rien modifié.
      // Le PREMIER enregistrement engagé est donc canonique : si une entrée
      // existe déjà pour ce match, on ignore les captures ultérieures (ne pas
      // ré-hasher / ré-archiver / ré-committer), gardant fichier stocké et hash
      // engagé strictement alignés.
      if (_ref.read(proofFileStoreProvider).get(matchId) != null) return;

      // Transcode le 540p en proxy 360p (allègement). GARDE-FOU : si le
      // transcodage échoue, on retombe sur le 540p (on engage/uploade le 540p).
      // Le fichier RÉELLEMENT hashé/stocké/uploadé est `proofPath`.
      final proxy = await _ref.read(proofTranscoderProvider).to360pProxy(filePath);
      final proofPath = proxy ?? filePath;

      final file = File(proofPath);
      if (!file.existsSync()) return;
      final size = file.lengthSync();
      if (size <= 0) return;

      final sha = await sha256OfFile(file);

      // RÉTENTION DURABLE (volet C) : copie le fichier hashé du cache purgeable
      // vers le dossier applicatif persistant. La copie préserve les octets →
      // le SHA-256 reste celui du commitment. Garde-fou : si la copie échoue,
      // on retombe sur le chemin d'origine (comportement cache antérieur).
      final durable = await _ref.read(proofArchiveProvider).persist(
            matchId: matchId,
            sourcePath: proofPath,
          );
      final storedPath = durable ?? proofPath;

      // Mémorise OÙ se trouve le fichier hashé (proxy archivé si dispo) : la
      // réclamation admin peut arriver bien après le match (cf. ProofFileStore).
      await _ref.read(proofFileStoreProvider).put(
            matchId: matchId,
            filePath: storedPath,
            playerId: playerId,
          );

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

  /// Signale au serveur que la capture anti-triche N'A PAS PU démarrer pour
  /// [matchId] (permission refusée / échec device) — P1 #5. Best-effort : c'est
  /// la TRACE qui distingue « le joueur ne pouvait pas filmer » d'une capture
  /// silencieusement absente. Ne lève jamais, ne bloque pas le flux de match.
  /// L'EF n'écrase jamais un commitment déjà engagé.
  Future<void> reportUnavailableForMatch({
    required String matchId,
    required String reason,
  }) async {
    try {
      final action = ProofUnavailableAction(
        id: generateUuidV4(),
        createdAt: DateTime.now().toUtc(),
        matchId: matchId,
        reason: reason,
      );
      final queue = _ref.read(syncQueueServiceProvider).valueOrNull;
      if (queue == null) {
        await action.execute(_ref.read(supabaseClientProvider));
        return;
      }
      await queue.enqueue(action);
    } catch (e, st) {
      unawaited(
        reportError(e, st, context: 'ProofCommitment.reportUnavailable'),
      );
    }
  }
}

final proofCommitmentServiceProvider = Provider<ProofCommitmentService>(
  ProofCommitmentService.new,
);
