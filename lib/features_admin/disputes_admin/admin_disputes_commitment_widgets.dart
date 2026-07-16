part of 'admin_disputes_page.dart';

/// Section « Preuves engagées » (anti-triche Phase 3) : lignes `streams`
/// portant un commitment hash. Pour chacune, un badge de statut et — tant que
/// la vidéo n'a pas été livrée — un bouton « Réclamer la vidéo » qui notifie le
/// joueur de l'uploader. Une fois livrée, badge « hash vérifié / falsifié ».
class _ProofCommitmentsSection extends ConsumerWidget {
  const _ProofCommitmentsSection({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proofs = ref.watch(adminMatchProofCommitmentsProvider(matchId));
    return proofs.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(ArenaSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Erreur de chargement des preuves : ${arenaErrorMessage(e)}',
        style: ArenaText.bodyMuted,
      ),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            'Aucune preuve engagée pour ce match',
            style: ArenaText.bodyMuted,
          );
        }
        final match = ref.watch(matchByIdProvider(matchId)).valueOrNull;
        return Column(
          children: [
            for (final s in list)
              Padding(
                padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
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
        ProofStatus.verified => (ArenaColors.success, Icons.verified_outlined),
        ProofStatus.mismatch => (ArenaColors.danger, Icons.gpp_bad_outlined),
        ProofStatus.claimed => (ArenaColors.warning, Icons.hourglass_top),
        ProofStatus.uploaded => (ArenaColors.warning, Icons.cloud_sync_outlined),
        _ => (ArenaColors.silver, Icons.fingerprint),
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

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Text(
                  who,
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                status.label,
                style: ArenaText.small.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (s.canClaimProof) ...[
            const SizedBox(height: ArenaSpacing.sm),
            ArenaButton(
              label: status == ProofStatus.claimed
                  ? 'Relancer la demande'
                  : 'Réclamer la vidéo',
              variant: ArenaButtonVariant.secondary,
              fullWidth: true,
              isLoading: _claiming,
              onPressed: _claiming ? null : _claim,
            ),
          ],
          if (s.proofVideoAvailable) ...[
            const SizedBox(height: ArenaSpacing.sm),
            ArenaButton(
              label: 'Voir la vidéo',
              variant: ArenaButtonVariant.secondary,
              fullWidth: true,
              isLoading: _loadingVideo,
              onPressed: _loadingVideo ? null : _openVideo,
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      final signed = await ref
          .read(adminDisputesRepositoryProvider)
          .signedRecordingUrl(path);
      final uri = Uri.tryParse(signed);
      final ok = uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir la vidéo.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _loadingVideo = false);
    }
  }

  Future<void> _claim() async {
    setState(() => _claiming = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(adminDisputesRepositoryProvider)
          .claimProof(widget.stream.id);
      ref.invalidate(adminMatchProofCommitmentsProvider(widget.matchId));
      messenger.showSnackBar(
        const SnackBar(content: Text('Demande envoyée au joueur.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
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
    // Verrou serveur (audit 2026-07-07, guard_matches_protected_columns) :
    // re-arbitrer un match à cagnotte déjà décidé est réservé au super-admin.
    // On désactive les CTA verdict pour un admin simple — PARITÉ avec la
    // console desktop (le serveur rejette en 42501, mais l'UI doit le refléter ;
    // c'était une divergence mobile/desktop relevée par l'audit 2026-07-13).
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
      children: [
        if (verdictLocked) ...[
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: ArenaColors.silver,
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Expanded(
                child: Text(superAdminOnlyHint, style: ArenaText.small),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
        ],
        ArenaButton(
          label: '🏳️ J1 GAGNE 3-0 (tapis vert)',
          fullWidth: true,
          onPressed: verdictLocked || match.player1Id == null
              ? null
              : () => _commit(context, ref, winnerId: match.player1Id),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaButton(
          label: '🏳️ J2 GAGNE 3-0 (tapis vert)',
          fullWidth: true,
          onPressed: verdictLocked || match.player2Id == null
              ? null
              : () => _commit(context, ref, winnerId: match.player2Id),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        // 3e issue : quand les preuves ne départagent PAS, le tapis vert punit
        // peut-être un innocent et l'annulation efface un match qui a eu lieu.
        // On remet les deux joueurs sur le terrain, sans coupable.
        // Sans litige ouvert, pas de rejeu : le serveur refuse, l'UI doit le
        // refléter plutôt que de laisser tenter.
        ArenaButton(
          label: '🔄 FAIRE REJOUER',
          variant: ArenaButtonVariant.secondary,
          fullWidth: true,
          onPressed: verdictLocked || dispute == null
              ? null
              : () => _replay(context, ref),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaButton(
          label: '🚫 ANNULER MATCH',
          variant: ArenaButtonVariant.danger,
          fullWidth: true,
          onPressed: () => _cancelMatch(context, ref),
        ),
      ],
    );
  }

  /// Remet le match en jeu à un nouveau créneau (RPC `replay_match`). Le
  /// serveur annule le résultat précédent (stats, bracket, classement) et
  /// clôture le litige SANS désigner de coupable.
  Future<void> _replay(BuildContext context, WidgetRef ref) async {
    final disputeId = dispute?.id;
    if (disputeId == null) return;
    final justification = justificationController.text.trim();
    if (justification.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Justification obligatoire.')),
      );
      return;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null || !context.mounted) return;
    final scheduledAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Litige · faire rejouer le match',
    );
    if (!totpOk || !context.mounted) return;

    try {
      await ref.read(adminDisputesRepositoryProvider).replayMatch(
            matchId: match.id,
            disputeId: disputeId,
            justification: justification,
            scheduledAt: scheduledAt,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match remis en jeu — les joueurs sont prévenus.'),
        ),
      );
      await Navigator.of(context).maybePop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  Future<void> _commit(
    BuildContext context,
    WidgetRef ref, {
    required String? winnerId,
  }) async {
    final justification = justificationController.text.trim();
    if (justification.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Justification obligatoire.')),
      );
      return;
    }
    // TAPIS VERT : le favorisé gagne 3-0 (le serveur force ce score, cf.
    // resolve_dispute). Score orienté via le helper PARTAGÉ (parité desktop).
    final score = disputeWalkoverScore(
      winnerId: winnerId,
      player1Id: match.player1Id,
    );
    final scoreP1 = score.scoreP1;
    final scoreP2 = score.scoreP2;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Résoudre dispute · tapis vert $scoreP1-$scoreP2',
    );
    if (!totpOk) return;
    if (!context.mounted) return;

    try {
      // Verdict + résolution du litige + audit, ATOMIQUEMENT (une transaction).
      await ref.read(adminDisputesRepositoryProvider).resolveAtomic(
            matchId: match.id,
            disputeId: dispute?.id,
            justification: justification,
            winnerId: winnerId,
            scoreP1: scoreP1,
            scoreP2: scoreP2,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verdict enregistré.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  Future<void> _cancelMatch(BuildContext context, WidgetRef ref) async {
    final justification = justificationController.text.trim();
    if (justification.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Justification obligatoire.')),
      );
      return;
    }
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Annuler le match (dispute)',
    );
    if (!totpOk) return;
    if (!context.mounted) return;

    try {
      // Annulation du match + résolution du litige + audit, ATOMIQUEMENT.
      await ref.read(adminDisputesRepositoryProvider).resolveAtomic(
            matchId: match.id,
            disputeId: dispute?.id,
            justification: justification,
            cancel: true,
          );
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }
}
