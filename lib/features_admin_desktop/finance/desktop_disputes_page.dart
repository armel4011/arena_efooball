import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/anticheat_plan.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/dispute.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/models/proof_status.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_disputes_repository.dart';
import 'package:arena/data/repositories/admin/admin_matches_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_admin_desktop/shared/desktop_totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_image_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Finance · Litige (desktop) — détail d'un litige sur un match donné +
/// résolution (verdict J1 / J2 / annulation), protégée par le step-up
/// TOTP.
///
/// Réutilise [adminDisputeByMatchProvider], [matchByIdProvider],
/// [adminMatchesRepositoryProvider], [adminDisputesRepositoryProvider]
/// et [adminAuditLogRepositoryProvider] (mêmes providers que le mobile).
class DesktopDisputesPage extends ConsumerStatefulWidget {
  const DesktopDisputesPage({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<DesktopDisputesPage> createState() =>
      _DesktopDisputesPageState();
}

class _DesktopDisputesPageState extends ConsumerState<DesktopDisputesPage> {
  final _justificationController = TextEditingController();

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disputeAsync =
        ref.watch(adminDisputeByMatchProvider(widget.matchId));
    final matchAsync = ref.watch(matchByIdProvider(widget.matchId));

    return ScaffoldPage(
      header: PageHeader(
        title: Text(
          'LITIGE · M-${_shortId(widget.matchId)}',
        ),
      ),
      content: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          disputeAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: ProgressRing()),
            ),
            error: (e, _) => InfoBar(
              title: const Text('Impossible de charger le litige'),
              content: Text('$e'),
              severity: InfoBarSeverity.error,
            ),
            data: (dispute) => dispute == null
                ? const InfoBar(
                    title: Text('Aucun litige'),
                    content: Text('Aucun litige ouvert pour ce match.'),
                  )
                : _DisputeHeader(dispute: dispute),
          ),
          const SizedBox(height: 24),
          Text(
            'PREUVES',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          _ProofsSection(matchId: widget.matchId),
          const SizedBox(height: 24),
          Text(
            'PLAN ANTI-TRICHE',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          _AnticheatPlanSection(matchId: widget.matchId),
          const SizedBox(height: 24),
          Text(
            'ENREGISTREMENTS AUTO',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          _RecordingsSection(matchId: widget.matchId),
          const SizedBox(height: 24),
          Text(
            'PREUVES ENGAGÉES',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          _ProofCommitmentsSection(matchId: widget.matchId),
          const SizedBox(height: 24),
          Text(
            'SCORES SAISIS',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          matchAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: ProgressRing()),
            ),
            error: (e, _) => InfoBar(
              title: const Text('Impossible de charger le match'),
              content: Text('$e'),
              severity: InfoBarSeverity.error,
            ),
            data: (match) => match == null
                ? const InfoBar(
                    title: Text('Match introuvable'),
                    content: Text('Ce match n’existe pas ou plus.'),
                  )
                : _ScoresCard(match: match),
          ),
          const SizedBox(height: 24),
          Text(
            'TRANCHER',
            style: _sectionStyle.copyWith(color: ArenaColors.neonRed),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: 'Justification (obligatoire)',
            child: TextBox(
              controller: _justificationController,
              placeholder: 'Expliquez votre décision pour audit…',
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 12),
          matchAsync.maybeWhen(
            data: (match) => match == null
                ? const SizedBox.shrink()
                : _VerdictButtons(
                    match: match,
                    dispute: disputeAsync.valueOrNull,
                    justificationController: _justificationController,
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DisputeHeader extends StatelessWidget {
  const _DisputeHeader({required this.dispute});

  final Dispute dispute;

  @override
  Widget build(BuildContext context) {
    final since = dispute.createdAt;
    final ageLabel = since == null
        ? ''
        : 'Ouvert depuis ${_humanDuration(DateTime.now().difference(since))}';
    return Card(
      backgroundColor: ArenaColors.carbon,
      borderColor: ArenaColors.statusWarn.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ArenaColors.statusWarn.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: ArenaColors.statusWarn.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'ESCALADE NIVEAU ${dispute.escalationLevel}',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.statusWarn,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                ageLabel,
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.silver,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dispute.reason ?? 'Désaccord sur le score',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (dispute.evidence['note'] is String) ...[
            const SizedBox(height: 4),
            Text(
              dispute.evidence['note'] as String,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _humanDuration(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes - h * 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}

class _ScoresCard extends StatelessWidget {
  const _ScoresCard({required this.match});

  final ArenaMatch match;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _scoreRow(
            label: 'Joueur 1 (HOME)',
            score: '${match.score1 ?? '?'}',
            color: ArenaColors.gameDraughts,
            border: true,
          ),
          _scoreRow(
            label: 'Joueur 2 (AWAY)',
            score: '${match.score2 ?? '?'}',
            color: ArenaColors.neonRed,
            border: false,
          ),
        ],
      ),
    );
  }

  Widget _scoreRow({
    required String label,
    required String score,
    required Color color,
    required bool border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: border
            ? const Border(bottom: BorderSide(color: ArenaColors.border))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.bone,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            score,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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
        return Wrap(
          spacing: 12,
          runSpacing: 12,
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

  static const double _size = 110;

  @override
  Widget build(BuildContext context) {
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
        return Wrap(
          spacing: 12,
          runSpacing: 12,
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

  static const double _size = 110;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.tryParse(recording.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

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
        return Column(
          children: [
            for (final s in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ProofCommitmentTile(matchId: matchId, stream: s),
              ),
          ],
        );
      },
    );
  }
}

class _ProofCommitmentTile extends ConsumerStatefulWidget {
  const _ProofCommitmentTile({required this.matchId, required this.stream});

  final String matchId;
  final MatchStream stream;

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
    final pid = s.playerId;
    final who = pid.isEmpty
        ? '?'
        : pid.substring(0, pid.length < 6 ? pid.length : 6).toUpperCase();

    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Joueur $who',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: match.player1Id == null
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
          onPressed: match.player2Id == null
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

final TextStyle _sectionStyle = GoogleFonts.bebasNeue(
  color: ArenaColors.silver,
  fontSize: 16,
  letterSpacing: 1.5,
);

Future<void> _showResult(
  BuildContext context,
  String message, {
  required bool isError,
}) async {
  await displayInfoBar(
    context,
    builder: (ctx, close) => InfoBar(
      title: Text(isError ? 'Échec' : 'Succès'),
      content: Text(message),
      severity: isError ? InfoBarSeverity.error : InfoBarSeverity.success,
      onClose: close,
    ),
  );
}

String _shortId(String id) =>
    id.length <= 6 ? id.toUpperCase() : id.substring(0, 6).toUpperCase();
