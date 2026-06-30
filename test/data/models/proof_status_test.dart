import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/models/proof_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hash = 'a';

  group('proofStatusFor', () {
    test('aucun hash → none', () {
      expect(
        proofStatusFor(
          sha256: null,
          uploadedAt: null,
          hashVerified: null,
          claimedAt: null,
        ),
        ProofStatus.none,
      );
      expect(
        proofStatusFor(
          sha256: '',
          uploadedAt: null,
          hashVerified: null,
          claimedAt: null,
        ),
        ProofStatus.none,
      );
    });

    test('hash engagé, ni réclamé ni uploadé → committed', () {
      expect(
        proofStatusFor(
          sha256: hash,
          uploadedAt: null,
          hashVerified: null,
          claimedAt: null,
        ),
        ProofStatus.committed,
      );
    });

    test('réclamé mais pas encore uploadé → claimed', () {
      expect(
        proofStatusFor(
          sha256: hash,
          uploadedAt: null,
          hashVerified: null,
          claimedAt: DateTime(2026, 6, 29),
        ),
        ProofStatus.claimed,
      );
    });

    test('uploadé, hash conforme → verified (prime sur claimed)', () {
      expect(
        proofStatusFor(
          sha256: hash,
          uploadedAt: DateTime(2026, 6, 29, 12),
          hashVerified: true,
          claimedAt: DateTime(2026, 6, 29),
        ),
        ProofStatus.verified,
      );
    });

    test('uploadé, hash divergent → mismatch', () {
      expect(
        proofStatusFor(
          sha256: hash,
          uploadedAt: DateTime(2026, 6, 29, 12),
          hashVerified: false,
          claimedAt: DateTime(2026, 6, 29),
        ),
        ProofStatus.mismatch,
      );
    });

    test('uploadé, vérification pas encore faite → uploaded', () {
      expect(
        proofStatusFor(
          sha256: hash,
          uploadedAt: DateTime(2026, 6, 29, 12),
          hashVerified: null,
          claimedAt: DateTime(2026, 6, 29),
        ),
        ProofStatus.uploaded,
      );
    });
  });

  group('MatchStreamProof extension', () {
    MatchStream s({
      String? sha,
      DateTime? committedAt,
      DateTime? claimedAt,
      DateTime? uploadedAt,
      bool? verified,
      String? storagePath,
    }) =>
        MatchStream(
          id: 's1',
          matchId: 'm1',
          playerId: 'p1',
          proofSha256: sha,
          proofCommittedAt: committedAt,
          proofClaimedAt: claimedAt,
          proofUploadedAt: uploadedAt,
          proofHashVerified: verified,
          storagePath: storagePath,
        );

    test('hasProofCommitment false sans hash, true avec', () {
      expect(s().hasProofCommitment, isFalse);
      expect(s(sha: 'a').hasProofCommitment, isTrue);
    });

    test('canClaimProof : committed et claimed seulement', () {
      expect(s(sha: 'a').canClaimProof, isTrue); // committed
      expect(
        s(sha: 'a', claimedAt: DateTime(2026)).canClaimProof,
        isTrue, // claimed (relance)
      );
      // Uploadé+vérifié → plus réclamable.
      expect(
        s(sha: 'a', uploadedAt: DateTime(2026), verified: true).canClaimProof,
        isFalse,
      );
      // Pas de commitment → pas réclamable.
      expect(s().canClaimProof, isFalse);
    });

    test('proofVideoAvailable : uploadé ET storage_path présent', () {
      // Livrée avec objet stocké → visionnable.
      expect(
        s(
          sha: 'a',
          uploadedAt: DateTime(2026),
          verified: true,
          storagePath: 'm1/p1/proof.mp4',
        ).proofVideoAvailable,
        isTrue,
      );
      // Uploadée mais sans storage_path → pas (encore) signable.
      expect(
        s(sha: 'a', uploadedAt: DateTime(2026)).proofVideoAvailable,
        isFalse,
      );
      // Engagée mais pas uploadée → rien à voir.
      expect(
        s(sha: 'a', storagePath: 'm1/p1/proof.mp4').proofVideoAvailable,
        isFalse,
      );
    });

    test('label couvre chaque statut', () {
      expect(ProofStatus.verified.label, 'Hash vérifié');
      expect(ProofStatus.mismatch.label, 'Hash falsifié');
      expect(ProofStatus.committed.label, 'Engagée (hash)');
    });
  });
}
