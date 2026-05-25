import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// PHASE 4.D — Bracket view for a competition.
///
/// Renders matches grouped by round (Round 1, Round 2, …, Final).
/// Player display names are not joined yet — sub-step 4.E will hydrate
/// them from `profiles`. For now the cards show short id stubs.
///
/// A custom-painter / InteractiveViewer arborescent view is intentionally
/// deferred — a vertical list grouped by round delivers the same value
/// for V1.0 (small brackets, mobile screen) without the test/UX cost.
class BracketView extends ConsumerWidget {
  const BracketView({required this.competitionId, super.key});

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(competitionMatchesProvider(competitionId));

    return ArenaScreenBackground(
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          description: e.toString(),
          onRetry: () =>
              ref.invalidate(competitionMatchesProvider(competitionId)),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return const EmptyState(
              icon: Icons.account_tree_outlined,
              title: 'Bracket pas encore généré',
              description: "Le bracket s'affichera ici dès que l'admin aura"
                  ' clôturé les inscriptions et lancé le tirage.',
            );
          }

          final byRound = <int, List<ArenaMatch>>{};
          for (final m in matches) {
            final r = m.round ?? 0;
            (byRound[r] ??= []).add(m);
          }
          final rounds = byRound.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(competitionMatchesProvider(competitionId));
              await ref.read(competitionMatchesProvider(competitionId).future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              itemCount: rounds.length,
              itemBuilder: (context, i) {
                final round = rounds[i];
                final items = byRound[round]!;
                return _RoundSection(
                  title: _roundLabel(round, rounds.length, items.length),
                  matches: items,
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Human-readable round name. The last round is the Final, the
  /// previous one is the Semi, and so on — we can't always rely on
  /// `round_number == total_rounds` (e.g. third-place matches), so we
  /// fall back to "Round N" for safety.
  static String _roundLabel(int round, int totalRounds, int matchesInRound) {
    if (round <= 0) return 'Hors phase';
    final isLast = round == totalRounds;
    if (isLast && matchesInRound == 1) return 'FINALE';
    if (round == totalRounds - 1 && matchesInRound <= 2) return 'DEMI-FINALES';
    if (round == totalRounds - 2 && matchesInRound <= 4) return 'QUARTS';
    if (round == totalRounds - 3 && matchesInRound <= 8) return 'HUITIÈMES';
    return 'ROUND $round';
  }
}

class _RoundSection extends StatelessWidget {
  const _RoundSection({required this.title, required this.matches});

  final String title;
  final List<ArenaMatch> matches;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ArenaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ArenaTypography.headlineMedium),
          const SizedBox(height: ArenaSpacing.sm),
          for (final m in matches) ...[
            _MatchRow(match: m),
            const SizedBox(height: ArenaSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});

  final ArenaMatch match;

  @override
  Widget build(BuildContext context) {
    final glow = _glowFor(context, match.status);
    final card = ArenaCard(
      onTap: () => context.push(UserRoutes.matchPath(match.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                match.matchNumber == null
                    ? 'MATCH'
                    : 'MATCH #${match.matchNumber}',
                style: ArenaTypography.labelLarge.copyWith(
                  color: ArenaColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              _StatusChip(status: match.status),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _PlayerLine(
            playerId: match.player1Id,
            score: match.score1,
            isWinner: match.hasResult && match.winnerId == match.player1Id,
          ),
          const SizedBox(height: 4),
          Text(
            'vs',
            style: ArenaTypography.bodyMedium.copyWith(
              color: ArenaColors.textFaint,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          _PlayerLine(
            playerId: match.player2Id,
            score: match.score2,
            isWinner: match.hasResult && match.winnerId == match.player2Id,
          ),
        ],
      ),
    );

    if (glow == null) return card;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: ArenaRadius.card,
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.32),
            blurRadius: 26,
            spreadRadius: -3,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: card,
    );
  }

  static Color? _glowFor(BuildContext context, MatchStatus status) {
    return switch (status) {
      MatchStatus.inProgress => ArenaColors.success,
      MatchStatus.ready => Theme.of(context).colorScheme.primary,
      MatchStatus.scorePending ||
      MatchStatus.awaitingValidation =>
        ArenaColors.warning,
      MatchStatus.disputed || MatchStatus.forfeited => ArenaColors.danger,
      MatchStatus.pending ||
      MatchStatus.scheduled ||
      MatchStatus.completed ||
      MatchStatus.cancelled =>
        null,
    };
  }
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({
    required this.playerId,
    required this.score,
    required this.isWinner,
  });

  final String? playerId;
  final int? score;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final pid = playerId;
    final label =
        pid == null ? 'À déterminer' : 'Joueur ${pid.substring(0, 6)}…';

    return Row(
      children: [
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(right: ArenaSpacing.xs),
            child: Icon(
              Icons.emoji_events,
              size: 16,
              color: ArenaColors.warning,
            ),
          ),
        Expanded(
          child: Text(
            label,
            style: ArenaTypography.bodyMedium.copyWith(
              color: playerId == null
                  ? ArenaColors.textMuted
                  : (isWinner ? ArenaColors.warning : ArenaColors.text),
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          score?.toString() ?? '—',
          style: ArenaTypography.headlineMedium.copyWith(
            color: isWinner ? ArenaColors.warning : ArenaColors.text,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MatchStatus.pending => ('À VENIR', ArenaColors.textMuted),
      MatchStatus.scheduled => ('PROGRAMMÉ', ArenaColors.textMuted),
      MatchStatus.ready => ('PRÊT', ArenaColors.primary),
      MatchStatus.inProgress => ('EN COURS', ArenaColors.success),
      MatchStatus.scorePending => ('SCORE EN ATTENTE', ArenaColors.warning),
      MatchStatus.awaitingValidation => ('VALIDATION', ArenaColors.warning),
      MatchStatus.disputed => ('LITIGE', ArenaColors.danger),
      MatchStatus.completed => ('TERMINÉ', ArenaColors.textMuted),
      MatchStatus.cancelled => ('ANNULÉ', ArenaColors.textFaint),
      MatchStatus.forfeited => ('FORFAIT', ArenaColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: ArenaRadius.pill,
      ),
      child: Text(
        label,
        style: ArenaTypography.labelLarge.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }
}
