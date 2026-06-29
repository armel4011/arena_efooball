import 'dart:async';

import 'package:arena/core/services/proof_file_store.dart';
import 'package:arena/core/services/sync_queue_service.dart';
import 'package:arena/core/utils/error_reporter.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Côté joueur de la réclamation de preuve (Phase 3 anti-triche).
///
/// Quand un admin réclame la vidéo (RPC `admin_claim_proof`), le joueur reçoit
/// une notif FCM `proof_claim_request` ET `streams.proof_claimed_at` est posé.
/// Ce service enfile l'upload du fichier engagé (resumable via la sync queue),
/// puis l'EF `proof-verify` re-hashe l'objet livré.
///
/// Deux déclencheurs, complémentaires :
///   * [handleClaim] — immédiat, sur réception de la notif FCM (foreground).
///   * [reconcilePendingClaims] — backstop, au démarrage/à la connexion :
///     rattrape les réclamations reçues app fermée (la notif FCM n'a pas été
///     traitée par un isolate). Idempotent : `proof-verify` et l'upsert le sont.
class ProofClaimService {
  ProofClaimService(this._ref);

  final Ref _ref;

  /// Traite une réclamation pour [matchId] / [streamId] : si on a encore le
  /// fichier engagé localement, on enfile son upload. Sinon, rien à livrer
  /// (fichier purgé) — l'admin verra une preuve réclamée jamais livrée.
  Future<void> handleClaim({
    required String matchId,
    required String streamId,
  }) async {
    final entry = _ref.read(proofFileStoreProvider).get(matchId);
    if (entry == null) {
      if (kDebugMode) {
        debugPrint('[proof] réclamation $matchId : aucun fichier local connu');
      }
      return;
    }

    final action = ProofUploadAction(
      id: generateUuidV4(),
      createdAt: DateTime.now().toUtc(),
      matchId: matchId,
      streamId: streamId,
      playerId: entry.playerId,
      filePath: entry.filePath,
    );

    final queue = _ref.read(syncQueueServiceProvider).valueOrNull;
    if (queue == null) {
      try {
        await action.execute(_ref.read(supabaseClientProvider));
      } catch (e, st) {
        unawaited(reportError(e, st, context: 'ProofClaim.handleClaim'));
      }
      return;
    }
    await queue.enqueue(action);
  }

  /// Rattrape les preuves réclamées non encore livrées pour [userId] : utile
  /// quand la notif FCM est arrivée app fermée. Lit les lignes `streams` de soi
  /// avec un commitment, réclamées (`proof_claimed_at`), pas encore uploadées.
  Future<void> reconcilePendingClaims(String userId) async {
    try {
      final rows = await _ref
          .read(supabaseClientProvider)
          .from('streams')
          .select('id, match_id')
          .eq('player_id', userId)
          .not('proof_sha256', 'is', null)
          .not('proof_claimed_at', 'is', null)
          .filter('proof_uploaded_at', 'is', null);
      for (final row in rows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final streamId = map['id'] as String?;
        final matchId = map['match_id'] as String?;
        if (streamId == null || matchId == null) continue;
        await handleClaim(matchId: matchId, streamId: streamId);
      }
    } catch (e, st) {
      unawaited(reportError(e, st, context: 'ProofClaim.reconcile'));
    }
  }
}

final proofClaimServiceProvider = Provider<ProofClaimService>(
  ProofClaimService.new,
);
