import 'package:arena/data/models/match_stream.dart';

/// État du cycle de vie d'une preuve anti-triche « commitment hash »
/// (Phase 3). Dérivé des timestamps `proof_*` d'une ligne `streams`.
enum ProofStatus {
  /// Aucun commitment engagé (la ligne n'est pas une preuve P3).
  none,

  /// Hash engagé à la fin du match, vidéo pas encore réclamée.
  committed,

  /// Un admin a réclamé la vidéo ; on attend que le joueur l'uploade.
  claimed,

  /// Uploadée mais pas encore vérifiée (état transitoire avant proof-verify).
  uploaded,

  /// Uploadée et le hash correspond au commitment → preuve engageante.
  verified,

  /// Uploadée mais le hash DIFFÈRE du commitment → charge contre le joueur.
  mismatch,
}

/// Décision PURE (testable) : statut d'une preuve à partir de ses champs.
/// L'ordre des tests reflète la progression du cycle de vie (du plus avancé
/// au plus initial).
ProofStatus proofStatusFor({
  required String? sha256,
  required DateTime? uploadedAt,
  required bool? hashVerified,
  required DateTime? claimedAt,
}) {
  if (sha256 == null || sha256.isEmpty) return ProofStatus.none;
  if (uploadedAt != null) {
    if (hashVerified == true) return ProofStatus.verified;
    if (hashVerified == false) return ProofStatus.mismatch;
    return ProofStatus.uploaded;
  }
  if (claimedAt != null) return ProofStatus.claimed;
  return ProofStatus.committed;
}

extension ProofStatusLabel on ProofStatus {
  /// Libellé court FR du statut, pour les écrans litiges (mobile + desktop).
  String get label => switch (this) {
        ProofStatus.none => 'Aucune preuve',
        ProofStatus.committed => 'Engagée (hash)',
        ProofStatus.claimed => "Réclamée · en attente d'envoi",
        ProofStatus.uploaded => 'Livrée · vérification…',
        ProofStatus.verified => 'Hash vérifié',
        ProofStatus.mismatch => 'Hash falsifié',
      };
}

extension MatchStreamProof on MatchStream {
  /// Statut du commitment hash de cette ligne `streams`.
  ProofStatus get proofStatus => proofStatusFor(
        sha256: proofSha256,
        uploadedAt: proofUploadedAt,
        hashVerified: proofHashVerified,
        claimedAt: proofClaimedAt,
      );

  /// `true` si cette ligne porte un commitment P3 (à afficher dans la
  /// section « Preuves engagées » des litiges).
  bool get hasProofCommitment => proofStatus != ProofStatus.none;

  /// `true` si l'admin peut réclamer la vidéo : engagée, pas encore livrée.
  bool get canClaimProof =>
      proofStatus == ProofStatus.committed ||
      proofStatus == ProofStatus.claimed;

  /// `true` si la vidéo de preuve a été livrée et porte un objet signable
  /// (le joueur l'a uploadée, `proof-verify` a posé `storage_path`) — l'admin
  /// peut alors la visionner via une URL signée.
  bool get proofVideoAvailable =>
      proofUploadedAt != null &&
      storagePath != null &&
      storagePath!.isNotEmpty;
}
