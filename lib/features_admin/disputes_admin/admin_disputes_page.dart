import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/anticheat_plan.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/dispute.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/models/proof_status.dart';
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

part 'admin_disputes_proof_widgets.dart';
part 'admin_disputes_commitment_widgets.dart';

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
    // Scores DÉCLARÉS par chaque joueur (matches.score1/2 sont NULL en litige).
    final submissions =
        ref.watch(matchSubmittedScoresProvider(widget.matchId));

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
              Text('PLAN ANTI-TRICHE', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _AnticheatPlanSection(matchId: widget.matchId),
              const SizedBox(height: ArenaSpacing.lg),
              Text('ENREGISTREMENTS AUTO', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _RecordingsSection(matchId: widget.matchId),
              const SizedBox(height: ArenaSpacing.lg),
              Text('PREUVES ENGAGÉES', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _ProofCommitmentsSection(matchId: widget.matchId),
              const SizedBox(height: ArenaSpacing.lg),
              Text('SCORES SAISIS', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              match.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erreur : $e', style: ArenaText.bodyMuted),
                data: (m) => m == null
                    ? Text('Match introuvable.', style: ArenaText.bodyMuted)
                    : _ScoresCard(
                        match: m,
                        submissions: submissions.valueOrNull ?? const {},
                      ),
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
  const _ScoresCard({required this.match, this.submissions = const {}});
  final ArenaMatch match;

  /// Scoreline déclaré par chaque joueur (`player_id → SubmittedScore`).
  final Map<String, SubmittedScore> submissions;

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
            label: 'Joueur 1 (HOME) · a déclaré',
            teamName: match.player1TeamName,
            score: _declaredFor(match.player1Id, fallback: match.score1),
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
            label: 'Joueur 2 (AWAY) · a déclaré',
            teamName: match.player2TeamName,
            score: _declaredFor(match.player2Id, fallback: match.score2),
            scoreColor: ArenaColors.neonRed,
          ),
        ],
      ),
    );
  }

  /// Scoreline complet « s1-s2 » déclaré par [playerId] (source de vérité en
  /// litige) ; repli sur le score final agréé [fallback] ; « — » si aucun.
  String _declaredFor(String? playerId, {int? fallback}) {
    final sub = playerId == null ? null : submissions[playerId];
    if (sub != null) return sub.label;
    if (fallback != null) return '$fallback';
    return '—';
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
