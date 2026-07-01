part of 'admin_disputes_page.dart';

/// Section « Preuves » : miniatures des captures (tap → visionneuse plein
/// écran) et tuiles vidéo (bouton → lecteur externe via url_launcher).
class _ProofsSection extends ConsumerWidget {
  const _ProofsSection({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proofs = ref.watch(adminDisputeProofsProvider(matchId));
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
          return Text('Aucune preuve soumise', style: ArenaText.bodyMuted);
        }
        return Wrap(
          spacing: ArenaSpacing.sm,
          runSpacing: ArenaSpacing.sm,
          children: [
            for (final p in list) _ProofTile(proof: p),
          ],
        );
      },
    );
  }
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({required this.proof});

  final SignedDisputeProof proof;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    if (proof.isVideo) {
      return InkWell(
        onTap: () => _openVideo(context),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            borderRadius: BorderRadius.circular(ArenaRadius.md),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_outline,
                color: ArenaColors.neonRed,
                size: 32,
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Text('Vidéo', style: ArenaText.bodyMuted),
            ],
          ),
        ),
      );
    }
    return InkWell(
      onTap: () => ArenaImageViewer.show(context, imageUrl: proof.url),
      borderRadius: BorderRadius.circular(ArenaRadius.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        child: CachedNetworkImage(
          imageUrl: proof.url,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: _size,
            height: _size,
            color: ArenaColors.carbon,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, __, ___) => Container(
            width: _size,
            height: _size,
            color: ArenaColors.carbon,
            child: const Icon(
              Icons.broken_image_outlined,
              color: ArenaColors.silverDim,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.tryParse(proof.url);
    var ok = false;
    if (uri != null) {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir la vidéo.')),
      );
    }
  }
}

/// Bandeau « Plan anti-triche » (tiering P4) : pour le match, indique s'il a été
/// couvert par un egress LiveKit serveur (et POURQUOI : cagnotte / surveillance
/// / litige / aléa) ou par le seul commitment hash. Null = aucun plan assigné
/// (provider natif). Aide l'admin à savoir si une preuve serveur doit exister.
class _AnticheatPlanSection extends ConsumerWidget {
  const _AnticheatPlanSection({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(adminMatchAnticheatPlanProvider(matchId));
    return plan.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(ArenaSpacing.sm),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Erreur de chargement du plan : ${arenaErrorMessage(e)}',
        style: ArenaText.bodyMuted,
      ),
      data: (p) {
        if (p == null) {
          return Text(
            'Aucun plan serveur assigné (provider natif ou match hors tiering).',
            style: ArenaText.bodyMuted,
          );
        }
        final livekit = p.isLivekit;
        final color = livekit ? ArenaColors.signalBlue : ArenaColors.silver;
        final who = p.recordedPlayerId;
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
                  Icon(
                    livekit ? Icons.cloud_done_outlined : Icons.fingerprint,
                    color: color,
                    size: 18,
                  ),
                  const SizedBox(width: ArenaSpacing.sm),
                  Expanded(
                    child: Text(
                      p.tier.label,
                      style:
                          ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Raison : ${anticheatReasonLabel(p.reason)}',
                style: ArenaText.small.copyWith(color: ArenaColors.silver),
              ),
              if (livekit && who != null && who.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Joueur egressé : '
                  '${who.substring(0, who.length < 6 ? who.length : 6).toUpperCase()}',
                  style: ArenaText.small.copyWith(color: ArenaColors.silver),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Section « Enregistrements auto » : preuves anti-triche captées
/// automatiquement (recorder natif ou LiveKit Track Egress). Chaque tuile
/// ouvre la vidéo dans le lecteur externe via une URL signée 1h.
class _RecordingsSection extends ConsumerWidget {
  const _RecordingsSection({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordings = ref.watch(adminMatchRecordingsProvider(matchId));
    return recordings.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(ArenaSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Erreur de chargement des enregistrements : ${arenaErrorMessage(e)}',
        style: ArenaText.bodyMuted,
      ),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            'Aucun enregistrement automatique',
            style: ArenaText.bodyMuted,
          );
        }
        return Wrap(
          spacing: ArenaSpacing.sm,
          runSpacing: ArenaSpacing.sm,
          children: [
            for (final r in list) _RecordingTile(recording: r),
          ],
        );
      },
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({required this.recording});

  final SignedMatchRecording recording;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openVideo(context),
      borderRadius: BorderRadius.circular(ArenaRadius.md),
      child: Container(
        width: _size,
        height: _size,
        padding: const EdgeInsets.all(ArenaSpacing.xs),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(color: ArenaColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              color: ArenaColors.neonRed,
              size: 30,
            ),
            const SizedBox(height: ArenaSpacing.xs),
            Text(
              recording.isLiveKit ? 'LiveKit' : 'Natif',
              style: ArenaText.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.tryParse(recording.url);
    var ok = false;
    if (uri != null) {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir la vidéo.')),
      );
    }
  }
}
