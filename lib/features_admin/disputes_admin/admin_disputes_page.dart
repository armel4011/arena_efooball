import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/dispute.dart';
import 'package:arena/data/repositories/admin/admin_disputes_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_image_viewer.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// PHASE 11 · A14 — dispute resolution screen.
///
/// Reads the dispute + match via providers; the admin picks a verdict
/// for player 1, player 2, or cancels the match outright. Each path
/// stamps the verdict on `matches`, marks the dispute `resolved` with
/// the admin's written justification, and appends an audit log row.
///
/// Maps to screen A14 of `arena_v2.html`.
class AdminDisputesPage extends ConsumerStatefulWidget {
  const AdminDisputesPage({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<AdminDisputesPage> createState() => _AdminDisputesPageState();
}

class _AdminDisputesPageState extends ConsumerState<AdminDisputesPage> {
  final _justificationCtrl = TextEditingController();

  @override
  void dispose() {
    _justificationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dispute = ref.watch(adminDisputeByMatchProvider(widget.matchId));
    final match = ref.watch(matchByIdProvider(widget.matchId));

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'LITIGE · M-${widget.matchId.substring(0, 6).toUpperCase()}',
      ),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              dispute.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erreur : $e', style: ArenaText.bodyMuted),
                data: (d) => d == null
                    ? Text(
                        'Aucune dispute ouverte pour ce match.',
                        style: ArenaText.bodyMuted,
                      )
                    : _DisputeHeader(dispute: d),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text('PREUVES', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _ProofsSection(matchId: widget.matchId),
              const SizedBox(height: ArenaSpacing.lg),
              Text('SCORES SAISIS', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              match.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erreur : $e', style: ArenaText.bodyMuted),
                data: (m) => m == null
                    ? Text('Match introuvable.', style: ArenaText.bodyMuted)
                    : _ScoresCard(match: m),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                '⚖ TRANCHER',
                style:
                    ArenaText.inputLabel.copyWith(color: ArenaColors.neonRed),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              match.maybeWhen(
                data: (m) => m == null
                    ? const SizedBox.shrink()
                    : _VerdictButtons(
                        match: m,
                        dispute: dispute.valueOrNull,
                        justificationController: _justificationCtrl,
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text('Justification (obligatoire)', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.xs),
              ArenaTextField(
                controller: _justificationCtrl,
                hint: 'Explique ta décision pour audit…',
                minLines: 3,
                maxLines: 5,
              ),
            ],
          ),
        ),
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
        : 'Ouverte depuis ${_humanDuration(DateTime.now().difference(since))}';

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaWarningCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ArenaBadge(
                label: 'ESCALADE NIVEAU ${dispute.escalationLevel}',
                variant: ArenaBadgeVariant.warn,
              ),
              const Spacer(),
              Text(ageLabel, style: ArenaText.bodyMuted),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            dispute.reason ?? 'Désaccord sur score',
            style: ArenaText.h3,
          ),
          if (dispute.evidence['note'] is String) ...[
            const SizedBox(height: 2),
            Text(
              dispute.evidence['note'] as String,
              style: ArenaText.bodyMuted,
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
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          _Row(
            initial: _initialFor(match.player1Id),
            color: ArenaAvatarColor.orange,
            label: 'Joueur 1 (HOME)',
            teamName: match.player1TeamName,
            score: '${match.score1 ?? '?'}',
            scoreColor: ArenaColors.gameDraughts,
          ),
          const Divider(
            color: ArenaColors.border,
            height: 1,
            thickness: 1,
          ),
          _Row(
            initial: _initialFor(match.player2Id),
            color: ArenaAvatarColor.red,
            label: 'Joueur 2 (AWAY)',
            teamName: match.player2TeamName,
            score: '${match.score2 ?? '?'}',
            scoreColor: ArenaColors.neonRed,
          ),
        ],
      ),
    );
  }

  static String _initialFor(String? id) =>
      (id == null || id.isEmpty) ? '?' : id[0].toUpperCase();
}

class _Row extends StatelessWidget {
  const _Row({
    required this.initial,
    required this.color,
    required this.label,
    required this.teamName,
    required this.score,
    required this.scoreColor,
  });

  final String initial;
  final ArenaAvatarColor color;
  final String label;
  final String? teamName;
  final String score;
  final Color scoreColor;

  @override
  Widget build(BuildContext context) {
    final team = teamName?.trim();
    return Padding(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      child: Row(
        children: [
          ArenaAvatar(
            initials: initial,
            color: color,
            size: ArenaAvatarSize.sm,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ArenaText.body),
                const SizedBox(height: 2),
                Text(
                  (team == null || team.isEmpty)
                      ? '⚽ Équipe non renseignée'
                      : '⚽ $team',
                  style: ArenaText.bodyMuted.copyWith(
                    color: (team == null || team.isEmpty)
                        ? ArenaColors.silverDim
                        : ArenaColors.silver,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score,
            style: ArenaText.mono.copyWith(
              color: scoreColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final p1Score = match.score1 ?? 0;
    final p2Score = match.score2 ?? 0;

    return Column(
      children: [
        ArenaButton(
          label: '✓ VALIDER $p1Score-$p2Score (J1 gagne)',
          fullWidth: true,
          onPressed: match.player1Id == null
              ? null
              : () => _commit(
                    context,
                    ref,
                    winnerId: match.player1Id,
                    scoreP1: p1Score,
                    scoreP2: p2Score,
                  ),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaButton(
          label: '✓ VALIDER $p2Score-$p1Score (J2 gagne)',
          fullWidth: true,
          onPressed: match.player2Id == null
              ? null
              : () => _commit(
                    context,
                    ref,
                    winnerId: match.player2Id,
                    scoreP1: p2Score,
                    scoreP2: p1Score,
                  ),
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

  Future<void> _commit(
    BuildContext context,
    WidgetRef ref, {
    required String? winnerId,
    required int scoreP1,
    required int scoreP2,
  }) async {
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
      reason: 'Résoudre dispute · verdict $scoreP1-$scoreP2',
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
