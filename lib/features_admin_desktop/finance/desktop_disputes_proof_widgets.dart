part of 'desktop_disputes_page.dart';

/// Section « Preuves » (desktop, Fluent UI) : miniatures images + tuiles
/// vidéo ouvrant le clip dans le lecteur système (url_launcher).
class _ProofsSection extends ConsumerWidget {
  const _ProofsSection({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proofs = ref.watch(adminDisputeProofsProvider(matchId));
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
            'Aucune preuve soumise',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 13,
            ),
          );
        }
        final match = ref.watch(matchByIdProvider(matchId)).valueOrNull;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final p in list)
              _ProofTile(
                proof: p,
                homeId: match?.player1Id,
                awayId: match?.player2Id,
              ),
          ],
        );
      },
    );
  }
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({required this.proof, this.homeId, this.awayId});

  final SignedDisputeProof proof;
  final String? homeId;
  final String? awayId;

  static const double _size = 110;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _thumb(context),
        const SizedBox(height: 4),
        SizedBox(
          width: _size,
          child: Text(
            _disputePlayerRoleShort(
              proof.playerId,
              homeId: homeId,
              awayId: awayId,
            ),
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _thumb(BuildContext context) {
    if (proof.isVideo) {
      return SizedBox(
        width: _size,
        height: _size,
        child: Button(
          onPressed: () => _openVideo(context),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FluentIcons.play, size: 24),
              SizedBox(height: 6),
              Text('Vidéo'),
            ],
          ),
        ),
      );
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => ArenaImageViewer.show(context, imageUrl: proof.url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: proof.url,
            width: _size,
            height: _size,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: _size,
              height: _size,
              color: ArenaColors.carbon,
              child: const Center(child: ProgressRing()),
            ),
            errorWidget: (_, __, ___) => Container(
              width: _size,
              height: _size,
              color: ArenaColors.carbon,
              child: const Icon(FluentIcons.photo_error),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.tryParse(proof.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Bandeau « Plan anti-triche » (tiering P4, desktop) : tier (natif seul /
/// egress LiveKit) + raison de la décision serveur + joueur egressé. Null =
/// aucun plan assigné (provider natif).
class _AnticheatPlanSection extends ConsumerWidget {
  const _AnticheatPlanSection({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(adminMatchAnticheatPlanProvider(matchId));
    return plan.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Text(
        'Erreur de chargement du plan : ${arenaErrorMessage(e)}',
        style: GoogleFonts.spaceGrotesk(color: ArenaColors.silver),
      ),
      data: (p) {
        if (p == null) {
          return Text(
            'Aucun plan serveur assigné (provider natif ou match hors tiering).',
            style: GoogleFonts.spaceGrotesk(color: ArenaColors.silver),
          );
        }
        final livekit = p.isLivekit;
        final color = livekit ? ArenaColors.signalBlue : ArenaColors.silver;
        final who = p.recordedPlayerId;
        return Card(
          backgroundColor: ArenaColors.carbon,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    livekit ? FluentIcons.cloud : FluentIcons.fingerprint,
                    color: color,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    p.tier.label,
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.bone,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Raison : ${anticheatReasonLabel(p.reason)}',
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.silver,
                  fontSize: 12,
                ),
              ),
              if (livekit && who != null && who.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Joueur egressé : '
                  '${who.substring(0, who.length < 6 ? who.length : 6).toUpperCase()}',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.silver,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Section « Enregistrements auto » (desktop) : preuves anti-triche captées
/// automatiquement (recorder natif ou LiveKit Track Egress), ouvertes dans le
/// lecteur système via URL signée.
class _RecordingsSection extends ConsumerWidget {
  const _RecordingsSection({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordings = ref.watch(adminMatchRecordingsProvider(matchId));
    return recordings.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: ProgressRing()),
      ),
      error: (e, _) => InfoBar(
        title: const Text('Enregistrements indisponibles'),
        content: Text('$e'),
        severity: InfoBarSeverity.error,
      ),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            'Aucun enregistrement automatique',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 13,
            ),
          );
        }
        final match = ref.watch(matchByIdProvider(matchId)).valueOrNull;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final r in list)
              _RecordingTile(
                recording: r,
                homeId: match?.player1Id,
                awayId: match?.player2Id,
              ),
          ],
        );
      },
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({required this.recording, this.homeId, this.awayId});

  final SignedMatchRecording recording;
  final String? homeId;
  final String? awayId;

  static const double _size = 110;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _size,
          height: _size,
          child: Button(
            onPressed: () => _openVideo(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FluentIcons.play, size: 24),
                const SizedBox(height: 6),
                Text(recording.isLiveKit ? 'LiveKit' : 'Natif'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: _size,
          child: Text(
            _disputePlayerRoleShort(
              recording.playerId,
              homeId: homeId,
              awayId: awayId,
            ),
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.tryParse(recording.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
