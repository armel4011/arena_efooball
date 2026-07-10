part of 'desktop_disputes_page.dart';

/// Section « Preuves engagées » (desktop, Fluent UI) : commitments hash
/// anti-triche (Phase 3). Badge de statut + bouton « Réclamer la vidéo » tant
/// que la vidéo n'a pas été livrée.
class _ProofCommitmentsSection extends ConsumerWidget {
  const _ProofCommitmentsSection({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proofs = ref.watch(adminMatchProofCommitmentsProvider(matchId));
    return proofs.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: ProgressRing()),
      ),
      error: (e, _) => InfoBar(
        title: const Text('Preuves indisponibles'),
        content: Text('$e'),
        severity: InfoBarSeverity.error,
      ),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            'Aucune preuve engagée pour ce match',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 13,
            ),
          );
        }
        final match = ref.watch(matchByIdProvider(matchId)).valueOrNull;
        return Column(
          children: [
            for (final s in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ProofCommitmentTile(
                  matchId: matchId,
                  stream: s,
                  homeId: match?.player1Id,
                  awayId: match?.player2Id,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProofCommitmentTile extends ConsumerStatefulWidget {
  const _ProofCommitmentTile({
    required this.matchId,
    required this.stream,
    this.homeId,
    this.awayId,
  });

  final String matchId;
  final MatchStream stream;
  final String? homeId;
  final String? awayId;

  @override
  ConsumerState<_ProofCommitmentTile> createState() =>
      _ProofCommitmentTileState();
}

class _ProofCommitmentTileState extends ConsumerState<_ProofCommitmentTile> {
  bool _claiming = false;
  bool _loadingVideo = false;

  static (Color, IconData) _decorFor(ProofStatus s) => switch (s) {
        ProofStatus.verified => (ArenaColors.success, FluentIcons.completed),
        ProofStatus.mismatch => (ArenaColors.danger, FluentIcons.blocked2),
        ProofStatus.claimed => (ArenaColors.warning, FluentIcons.recent),
        ProofStatus.uploaded => (ArenaColors.warning, FluentIcons.sync_status),
        _ => (ArenaColors.silver, FluentIcons.fingerprint),
      };

  @override
  Widget build(BuildContext context) {
    final s = widget.stream;
    final status = s.proofStatus;
    final (color, icon) = _decorFor(status);
    final who = _disputePlayerRole(
      s.playerId,
      homeId: widget.homeId,
      awayId: widget.awayId,
    );

    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              who,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.bone,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            status.label,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (s.canClaimProof) ...[
            const SizedBox(width: 12),
            Button(
              onPressed: _claiming ? null : _claim,
              child: Text(
                status == ProofStatus.claimed
                    ? 'Relancer'
                    : 'Réclamer la vidéo',
              ),
            ),
          ],
          if (s.proofVideoAvailable) ...[
            const SizedBox(width: 12),
            Button(
              onPressed: _loadingVideo ? null : _openVideo,
              child: const Text('Voir la vidéo'),
            ),
          ],
        ],
      ),
    );
  }

  /// Signe le `storage_path` du proxy livré (1h) et l'ouvre dans le lecteur
  /// externe — même mécanisme que la section « Enregistrements auto ».
  Future<void> _openVideo() async {
    final path = widget.stream.storagePath;
    if (path == null || path.isEmpty) return;
    setState(() => _loadingVideo = true);
    try {
      final signed = await ref
          .read(adminDisputesRepositoryProvider)
          .signedRecordingUrl(path);
      final uri = Uri.tryParse(signed);
      final ok = uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!ok) {
        await _showResult(
          context,
          'Impossible d’ouvrir la vidéo.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _loadingVideo = false);
    }
  }

  Future<void> _claim() async {
    setState(() => _claiming = true);
    try {
      await ref
          .read(adminDisputesRepositoryProvider)
          .claimProof(widget.stream.id);
      ref.invalidate(adminMatchProofCommitmentsProvider(widget.matchId));
      if (!mounted) return;
      await _showResult(context, 'Demande envoyée au joueur.', isError: false);
    } catch (e) {
      if (!mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }
}

class _VerdictButtons extends ConsumerWidget {
  const _VerdictButtons({
    required this.match,
    required this.dispute,
    required this.justificationController,
  });

  final ArenaMatch match;
  final Dispute? dispute;
  final TextEditingController justificationController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p1 = match.score1 ?? 0;
    final p2 = match.score2 ?? 0;
    // Verrou serveur (audit 2026-07-07) : re-arbitrer un match à cagnotte déjà
    // décidé est réservé au super-admin. On désactive les CTA verdict pour un
    // admin simple (parité app mobile).
    final isSuperAdmin =
        ref.watch(currentProfileProvider).valueOrNull?.isSuperAdmin ?? false;
    final competition =
        ref.watch(competitionByIdProvider(match.competitionId)).valueOrNull;
    final verdictLocked = competition != null &&
        matchResultLockedForAdmin(
          isSuperAdmin: isSuperAdmin,
          competition: competition,
          match: match,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (verdictLocked) ...[
          const InfoBar(
            title: Text('Réservé au super-admin'),
            content: Text(superAdminOnlyHint),
            severity: InfoBarSeverity.warning,
          ),
          const SizedBox(height: 8),
        ],
        FilledButton(
          onPressed: verdictLocked || match.player1Id == null
              ? null
              : () => _commit(
                    context,
                    ref,
                    winnerId: match.player1Id,
                    scoreP1: p1,
                    scoreP2: p2,
                  ),
          child: Text('Valider $p1-$p2 (J1 gagne)'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: verdictLocked || match.player2Id == null
              ? null
              : () => _commit(
                    context,
                    ref,
                    winnerId: match.player2Id,
                    scoreP1: p2,
                    scoreP2: p1,
                  ),
          child: Text('Valider $p2-$p1 (J2 gagne)'),
        ),
        const SizedBox(height: 8),
        Button(
          onPressed: () => _cancelMatch(context, ref),
          child: const Text('Annuler le match'),
        ),
      ],
    );
  }

  Future<void> _commit(
    BuildContext context,
    WidgetRef ref, {
    required String? winnerId,
    required int scoreP1,
    required int scoreP2,
  }) async {
    final justification = justificationController.text.trim();
    if (justification.isEmpty) {
      await _showResult(
        context,
        'Justification obligatoire.',
        isError: true,
      );
      return;
    }
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Résoudre le litige · verdict $scoreP1-$scoreP2',
    );
    if (!totpOk || !context.mounted) return;
    try {
      await ref.read(adminMatchesRepositoryProvider).setVerdict(
            matchId: match.id,
            scoreP1: scoreP1,
            scoreP2: scoreP2,
            winnerId: winnerId,
          );
      if (dispute != null) {
        await ref.read(adminDisputesRepositoryProvider).resolve(
              disputeId: dispute!.id,
              adminId: adminId,
              resolution: justification,
            );
      }
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'dispute_resolved',
        targetType: 'match',
        targetId: match.id,
        afterState: {
          'winner_id': winnerId,
          'score1': scoreP1,
          'score2': scoreP2,
          'justification': justification,
        },
      );
      if (!context.mounted) return;
      await _showResult(context, 'Verdict enregistré.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Future<void> _cancelMatch(BuildContext context, WidgetRef ref) async {
    final justification = justificationController.text.trim();
    if (justification.isEmpty) {
      await _showResult(
        context,
        'Justification obligatoire.',
        isError: true,
      );
      return;
    }
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Annuler le match (litige)',
    );
    if (!totpOk || !context.mounted) return;
    try {
      await ref.read(adminMatchesRepositoryProvider).cancel(match.id);
      if (dispute != null) {
        await ref.read(adminDisputesRepositoryProvider).resolve(
              disputeId: dispute!.id,
              adminId: adminId,
              resolution: justification,
              status: 'cancelled',
            );
      }
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'dispute_cancelled',
        targetType: 'match',
        targetId: match.id,
        afterState: {'justification': justification},
      );
      if (!context.mounted) return;
      await _showResult(context, 'Match annulé.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }
}
