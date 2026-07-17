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

class _VerdictButtons extends ConsumerStatefulWidget {
  const _VerdictButtons({
    required this.match,
    required this.dispute,
    required this.justificationController,
  });

  final ArenaMatch match;
  final Dispute? dispute;
  final TextEditingController justificationController;

  @override
  ConsumerState<_VerdictButtons> createState() => _VerdictButtonsState();
}

class _VerdictButtonsState extends ConsumerState<_VerdictButtons> {
  /// Coupable désigné — `null` = personne (le défaut). Indépendant du
  /// vainqueur : un litige peut se trancher sans triche. Parité mobile.
  String? _guiltyPartyId;

  ArenaMatch get match => widget.match;
  Dispute? get dispute => widget.dispute;
  TextEditingController get justificationController =>
      widget.justificationController;

  @override
  Widget build(BuildContext context) {
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
        // Strike réservé au super-admin (exigence serveur) et à un litige réel.
        if (isSuperAdmin && dispute != null) ...[
          _GuiltySelector(
            match: match,
            guiltyPartyId: _guiltyPartyId,
            onChanged: (id) => setState(() => _guiltyPartyId = id),
          ),
          const SizedBox(height: 8),
        ],
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
              : () => _commit(context, ref, winnerId: match.player1Id),
          child: const Text('J1 gagne 3-0 (tapis vert)'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: verdictLocked || match.player2Id == null
              ? null
              : () => _commit(context, ref, winnerId: match.player2Id),
          child: const Text('J2 gagne 3-0 (tapis vert)'),
        ),
        const SizedBox(height: 8),
        // 3e issue : quand les preuves ne départagent PAS, le tapis vert punit
        // peut-être un innocent et l'annulation efface un match qui a eu lieu.
        // On remet les deux joueurs sur le terrain, sans coupable.
        // Sans litige ouvert, pas de rejeu : le serveur refuse, l'UI doit le
        // refléter plutôt que de laisser tenter.
        Button(
          onPressed: verdictLocked || dispute == null
              ? null
              : () => _replay(context, ref),
          child: const Text('Faire rejouer'),
        ),
        const SizedBox(height: 8),
        Button(
          onPressed: () => _cancelMatch(context, ref),
          child: const Text('Annuler le match'),
        ),
      ],
    );
  }

  /// Remet le match en jeu à un nouveau créneau (RPC `replay_match`). Le
  /// serveur annule le résultat précédent (stats, bracket, classement) et
  /// clôture le litige SANS désigner de coupable. Parité avec le mobile.
  Future<void> _replay(BuildContext context, WidgetRef ref) async {
    final disputeId = dispute?.id;
    if (disputeId == null) return;
    final justification = justificationController.text.trim();
    if (justification.isEmpty) {
      await _showResult(context, 'Justification obligatoire.', isError: true);
      return;
    }
    final slot = await _askReplaySlot(context);
    if (slot == null || !context.mounted) return;

    final totpOk = await showDesktopTotpGate(
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
            scheduledAt: slot,
          );
      if (!context.mounted) return;
      await _showResult(
        context,
        'Match remis en jeu — les joueurs sont prévenus.',
        isError: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  /// Demande le créneau de la nouvelle manche (Fluent n'a pas de
  /// `showDateTimePicker` : on compose DatePicker + TimePicker).
  Future<DateTime?> _askReplaySlot(BuildContext context) {
    var slot = DateTime.now().add(const Duration(days: 1));
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => ContentDialog(
          title: const Text('Nouveau créneau'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'À quelle date les deux joueurs rejouent-ils ce match ?',
              ),
              const SizedBox(height: 12),
              DatePicker(
                selected: slot,
                onChanged: (d) => setLocal(
                  () => slot =
                      DateTime(d.year, d.month, d.day, slot.hour, slot.minute),
                ),
              ),
              const SizedBox(height: 8),
              TimePicker(
                selected: slot,
                onChanged: (t) => setLocal(
                  () => slot = DateTime(
                    slot.year,
                    slot.month,
                    slot.day,
                    t.hour,
                    t.minute,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Button(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(slot),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _commit(
    BuildContext context,
    WidgetRef ref, {
    required String? winnerId,
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
    // TAPIS VERT : le favorisé gagne 3-0 (helper PARTAGÉ / resolve_dispute).
    final score = disputeWalkoverScore(
      winnerId: winnerId,
      player1Id: match.player1Id,
    );
    final scoreP1 = score.scoreP1;
    final scoreP2 = score.scoreP2;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Résoudre le litige · tapis vert $scoreP1-$scoreP2',
    );
    if (!totpOk || !context.mounted) return;
    try {
      // Verdict + résolution du litige + audit, ATOMIQUEMENT (resolve_dispute).
      // Le serveur force le tapis vert 3-0 ; les deux écritures séparées de
      // l'ancienne version laissaient le match `completed` avec un litige
      // resté `open` en cas d'échec de la seconde. Parité avec le mobile.
      await ref.read(adminDisputesRepositoryProvider).resolveAtomic(
            matchId: match.id,
            disputeId: dispute?.id,
            justification: justification,
            winnerId: winnerId,
            scoreP1: scoreP1,
            scoreP2: scoreP2,
            guiltyPartyId: _guiltyPartyId,
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
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Annuler le match (litige)',
    );
    if (!totpOk || !context.mounted) return;
    try {
      // Annulation du match + résolution du litige + audit, ATOMIQUEMENT.
      await ref.read(adminDisputesRepositoryProvider).resolveAtomic(
            matchId: match.id,
            disputeId: dispute?.id,
            justification: justification,
            cancel: true,
          );
      if (!context.mounted) return;
      await _showResult(context, 'Match annulé.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }
}

/// Sélecteur du coupable de triche (verdict « 3 strikes »), console desktop.
///
/// Miroir Fluent du sélecteur mobile : mêmes trois choix, même défaut « Aucun »,
/// mêmes libellés (source unique dans `dispute_resolution.dart`) — les deux
/// consoles doivent énoncer identiquement une conséquence aussi lourde qu'un
/// bannissement à vie.
class _GuiltySelector extends StatelessWidget {
  const _GuiltySelector({
    required this.match,
    required this.guiltyPartyId,
    required this.onChanged,
  });

  final ArenaMatch match;
  final String? guiltyPartyId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(disputeGuiltyLabel, style: FluentTheme.of(context).typography.body),
        const SizedBox(height: 4),
        ComboBox<String?>(
          value: guiltyPartyId,
          placeholder: const Text(disputeGuiltyNoneLabel),
          items: [
            const ComboBoxItem<String?>(
              value: null,
              child: Text(disputeGuiltyNoneLabel),
            ),
            if (match.player1Id != null)
              ComboBoxItem<String?>(
                value: match.player1Id,
                child: const Text('J1 a triché'),
              ),
            if (match.player2Id != null)
              ComboBoxItem<String?>(
                value: match.player2Id,
                child: const Text('J2 a triché'),
              ),
          ],
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Text(
          disputeGuiltyHint,
          style: FluentTheme.of(context).typography.caption,
        ),
      ],
    );
  }
}
