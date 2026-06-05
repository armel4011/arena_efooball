import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/match_room/widgets/manual_upload_button.dart';
import 'package:arena/features_user/match_room/widgets/match_room_internals.dart';
import 'package:arena/features_user/match_room/widgets/score_edit_dialog.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vues terminales du Match Room : score validé, litige, annulé, forfait.
/// Extraites de `match_room_page.dart` pour alléger le fichier hôte —
/// elles ne consomment que des APIs publiques (helpers shared dans
/// `match_room_internals.dart`).

/// Vue Score validé — affichée quand `MatchStatus == completed`.
class CompletedView extends StatelessWidget {
  const CompletedView({required this.match, required this.selfId, super.key});

  final ArenaMatch match;
  final String? selfId;

  bool get _isPlayer =>
      selfId != null &&
      (selfId == match.player1Id || selfId == match.player2Id);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s1 = match.score1 ?? 0;
    final s2 = match.score2 ?? 0;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.xl),
      decoration: arenaSuccessCardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            color: ArenaColors.statusWarn,
            size: 56,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(l10n.outcomeFinalScore, style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            '$s1 — $s2',
            style: ArenaText.bigNumber.copyWith(fontSize: 48),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            match.winnerId == null
                ? l10n.outcomeDraw
                : l10n.outcomeWinner(match.winnerId!.substring(0, 6)),
            style: ArenaText.bodyMuted,
          ),
          if (_isPlayer) ...[
            const SizedBox(height: ArenaSpacing.lg),
            ManualUploadButton(matchId: match.id, playerId: selfId!),
          ],
        ],
      ),
    );
  }
}

/// Vue Litige — affichée quand `MatchStatus == disputed`. Pour les
/// joueurs : permet de re-soumettre un score corrigé ; pour les
/// observateurs : juste un bandeau d'info.
class DisputedView extends ConsumerStatefulWidget {
  const DisputedView({required this.match, required this.selfId, super.key});

  final ArenaMatch match;
  final String? selfId;

  @override
  ConsumerState<DisputedView> createState() => _DisputedViewState();
}

class _DisputedViewState extends ConsumerState<DisputedView> {
  bool _resolving = false;

  bool get _isPlayer =>
      widget.selfId != null &&
      (widget.selfId == widget.match.player1Id ||
          widget.selfId == widget.match.player2Id);

  bool get _isPlayer1 => widget.selfId == widget.match.player1Id;
  bool get _isKnockout => widget.match.groupId == null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_isPlayer) {
      return _buildBanner();
    }

    final submissionsAsync =
        ref.watch(matchScoreSubmissionsProvider(widget.match.id));
    return submissionsAsync.when(
      loading: _buildBanner,
      error: (_, __) => _buildBanner(),
      data: (submissions) {
        final byPlayer = latestSubmissionPerPlayer(submissions);
        final p1Sub = widget.match.player1Id == null
            ? null
            : byPlayer[widget.match.player1Id];
        final p2Sub = widget.match.player2Id == null
            ? null
            : byPlayer[widget.match.player2Id];

        // If both players already concord on their LATEST submission
        // (e.g. the opponent corrected first and we just landed back on
        // this view), commit silently — resolveSubmissions promotes the
        // match to completed which collapses this view.
        if (p1Sub != null && p2Sub != null && !_resolving) {
          _resolving = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _autoResolve(p1Sub, p2Sub);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBanner(),
            const SizedBox(height: ArenaSpacing.lg),
            _SubmittedScoresGrid(
              match: widget.match,
              p1Sub: p1Sub,
              p2Sub: p2Sub,
              selfIsPlayer1: _isPlayer1,
            ),
            const SizedBox(height: ArenaSpacing.lg),
            ArenaButton(
              label: l10n.outcomeEditMyScore,
              icon: Icons.edit_outlined,
              fullWidth: true,
              onPressed: () => _openEditDialog(
                _isPlayer1 ? p1Sub : p2Sub,
              ),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            ManualUploadButton(
              matchId: widget.match.id,
              playerId: widget.selfId!,
            ),
          ],
        );
      },
    );
  }

  Future<void> _autoResolve(
    Map<String, dynamic> p1Sub,
    Map<String, dynamic> p2Sub,
  ) async {
    await resolveSubmissions(
      match: widget.match,
      p1Submission: p1Sub,
      p2Submission: p2Sub,
      repo: ref.read(matchRepositoryProvider),
      onError: (_) {/* silent — dispute view can retry on next build */},
    );
    if (mounted) _resolving = false;
  }

  Future<void> _openEditDialog(Map<String, dynamic>? mine) async {
    final pl = (mine?['payload'] as Map?)?.cast<String, dynamic>() ?? {};
    final s1 = pl['score1'] as int?;
    final s2 = pl['score2'] as int?;
    final viaPen = pl['via_penalties'] == true;
    final pen1 = pl['penalty1'] as int?;
    final pen2 = pl['penalty2'] as int?;
    final myInitial = (_isPlayer1 ? s1 : s2)?.toString() ?? '';
    final oppInitial = (_isPlayer1 ? s2 : s1)?.toString() ?? '';
    final myPenInitial = viaPen
        ? ((_isPlayer1 ? pen1 : pen2)?.toString() ?? '')
        : '';
    final oppPenInitial = viaPen
        ? ((_isPlayer1 ? pen2 : pen1)?.toString() ?? '')
        : '';

    final updated = await showDialog<EditedScore>(
      context: context,
      builder: (_) => EditScoreDialog(
        myInitial: myInitial,
        oppInitial: oppInitial,
        viaPenaltiesInitial: viaPen,
        myPenInitial: myPenInitial,
        oppPenInitial: oppPenInitial,
        knockout: _isKnockout,
      ),
    );
    if (updated == null || !mounted) return;

    final selfId = widget.selfId;
    if (selfId == null) return;

    final myGoals = updated.my;
    final oppGoals = updated.opp;
    final s1New = _isPlayer1 ? myGoals : oppGoals;
    final s2New = _isPlayer1 ? oppGoals : myGoals;
    final pen1New = updated.viaPenalties
        ? (_isPlayer1 ? updated.myPen : updated.oppPen)
        : null;
    final pen2New = updated.viaPenalties
        ? (_isPlayer1 ? updated.oppPen : updated.myPen)
        : null;

    try {
      await ref.read(matchRepositoryProvider).submitScore(
            matchId: widget.match.id,
            byProfileId: selfId,
            scoreP1: s1New,
            scoreP2: s2New,
            decidedByPenalties: updated.viaPenalties,
            penaltyP1: pen1New,
            penaltyP2: pen2New,
          );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.outcomeResubmitError(e))),
      );
      return;
    }
    // The realtime stream will pick up the new event and trigger
    // _autoResolve on the next build.
    setState(() => _resolving = false);
  }

  Widget _buildBanner() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaDangerCardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.gavel, color: ArenaColors.neonRed, size: 40),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            l10n.outcomeDisputeInProgress,
            style: ArenaText.inputLabel.copyWith(color: ArenaColors.neonRed),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            l10n.outcomeDisputeExplanation,
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _SubmittedScoresGrid extends StatelessWidget {
  const _SubmittedScoresGrid({
    required this.match,
    required this.p1Sub,
    required this.p2Sub,
    required this.selfIsPlayer1,
  });

  final ArenaMatch match;
  final Map<String, dynamic>? p1Sub;
  final Map<String, dynamic>? p2Sub;
  final bool selfIsPlayer1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _ScoreSubmissionCard(
            label: selfIsPlayer1 ? l10n.outcomeScoreCardYou : l10n.outcomeScoreCardPlayer1,
            highlight: selfIsPlayer1,
            payload: (p1Sub?['payload'] as Map?)?.cast<String, dynamic>(),
          ),
        ),
        const SizedBox(width: ArenaSpacing.md),
        Expanded(
          child: _ScoreSubmissionCard(
            label: selfIsPlayer1 ? l10n.outcomeScoreCardPlayer2 : l10n.outcomeScoreCardYou,
            highlight: !selfIsPlayer1,
            payload: (p2Sub?['payload'] as Map?)?.cast<String, dynamic>(),
          ),
        ),
      ],
    );
  }
}

class _ScoreSubmissionCard extends StatelessWidget {
  const _ScoreSubmissionCard({
    required this.label,
    required this.highlight,
    required this.payload,
  });

  final String label;
  final bool highlight;
  final Map<String, dynamic>? payload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s1 = payload?['score1'] as int?;
    final s2 = payload?['score2'] as int?;
    final viaPen = payload?['via_penalties'] == true;
    final pen1 = payload?['penalty1'] as int?;
    final pen2 = payload?['penalty2'] as int?;
    final accent = highlight ? ArenaColors.signalBlue : ArenaColors.silverDim;

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: ArenaText.inputLabel.copyWith(color: accent),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            (s1 == null || s2 == null) ? '— : —' : '$s1 — $s2',
            style: ArenaText.bigNumber.copyWith(fontSize: 32),
          ),
          if (viaPen && pen1 != null && pen2 != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.outcomeScoreShootout(pen1, pen2),
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
          ],
        ],
      ),
    );
  }
}

/// Carte terminale générique (annulé, forfait, etc.). Réutilisable hors
/// match-room — par exemple pour un EmptyState quand un match a été
/// supprimé.
class TerminalCard extends StatelessWidget {
  const TerminalCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.xl),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            title,
            style: ArenaText.inputLabel.copyWith(color: color),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            description,
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
        ],
      ),
    );
  }
}
