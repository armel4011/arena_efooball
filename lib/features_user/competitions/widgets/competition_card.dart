import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Visual card for a single competition in the list.
class CompetitionCard extends StatelessWidget {
  const CompetitionCard({
    required this.competition,
    required this.onTap,
    super.key,
  });

  final Competition competition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glow = _glowFor(context, competition.status);
    final card = ArenaCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  competition.name.toUpperCase(),
                  style: ArenaTypography.headlineMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              if (competition.isFree) ...[
                const _FreeBadge(),
                const SizedBox(width: ArenaSpacing.xs),
              ],
              _StatusBadge(status: competition.status),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            '${competition.game.label} · ${_formatLabel(competition.format, l10n)}',
            style: ArenaTypography.bodyMedium.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
          const SizedBox(height: ArenaSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: 16,
                color: ArenaColors.textMuted,
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Text(
                _formatDate(competition.startDate),
                style: ArenaTypography.bodyMedium,
              ),
              const SizedBox(width: ArenaSpacing.md),
              const Icon(
                Icons.people_outline,
                size: 16,
                color: ArenaColors.textMuted,
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Text(
                '${competition.currentPlayers} / ${competition.maxPlayers}',
                style: ArenaTypography.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: competition.fillRatio,
              minHeight: 4,
              backgroundColor: ArenaColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(
                competition.fillRatio >= 1
                    ? ArenaColors.danger
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: ArenaSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 16,
                color: ArenaColors.textMuted,
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Text(
                competition.registrationFee == 0
                    ? 'Gratuit'
                    : '${_formatMoney(competition.registrationFee)}'
                        ' ${competition.registrationCurrency}',
                style: ArenaTypography.bodyMedium,
              ),
              const Spacer(),
              if (competition.prizePoolLocal > 0) ...[
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 16,
                  color: ArenaColors.warning,
                ),
                const SizedBox(width: ArenaSpacing.xs),
                Text(
                  '${_formatMoney(competition.prizePoolLocal)}'
                  ' ${competition.prizePoolCurrency ?? competition.registrationCurrency}',
                  style: ArenaTypography.bodyMedium.copyWith(
                    color: ArenaColors.warning,
                  ),
                ),
              ],
            ],
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
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: card,
    );
  }

  static Color? _glowFor(BuildContext context, CompetitionStatus status) {
    return switch (status) {
      CompetitionStatus.registrationOpen =>
        Theme.of(context).colorScheme.primary,
      CompetitionStatus.ongoing => ArenaColors.success,
      CompetitionStatus.registrationClosed => ArenaColors.warning,
      CompetitionStatus.draft ||
      CompetitionStatus.completed ||
      CompetitionStatus.cancelled =>
        null,
    };
  }

  static String _formatDate(DateTime d) {
    return DateFormat('d MMM y', 'fr').format(d.toLocal());
  }

  static String _formatMoney(double v) {
    return NumberFormat.decimalPattern('fr').format(v);
  }

  static String _formatLabel(TournamentFormat f, AppLocalizations l10n) =>
      switch (f) {
        TournamentFormat.singleElimination => l10n.compFormatSingleElim,
        TournamentFormat.groupsThenKnockout => l10n.compFormatGroupsKnockout,
        TournamentFormat.roundRobin => l10n.compFormatRoundRobin,
      };
}

class _FreeBadge extends StatelessWidget {
  const _FreeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.success.withValues(alpha: 0.16),
        borderRadius: ArenaRadius.pill,
        border: Border.all(
          color: ArenaColors.success.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        'GRATUIT',
        style: ArenaTypography.labelLarge.copyWith(
          color: ArenaColors.success,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CompetitionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: ArenaRadius.pill,
      ),
      child: Text(
        label,
        style: ArenaTypography.labelLarge.copyWith(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }

  static (String, Color) _styleFor(CompetitionStatus status) => switch (status) {
        CompetitionStatus.draft => ('BROUILLON', ArenaColors.textMuted),
        CompetitionStatus.registrationOpen =>
          ('INSCRIPTIONS', ArenaColors.success),
        CompetitionStatus.registrationClosed =>
          ('INSCRIPTIONS CLOSES', ArenaColors.warning),
        CompetitionStatus.ongoing => ('EN COURS', ArenaColors.success),
        CompetitionStatus.completed => ('TERMINÉ', ArenaColors.textMuted),
        CompetitionStatus.cancelled => ('ANNULÉ', ArenaColors.danger),
      };
}
