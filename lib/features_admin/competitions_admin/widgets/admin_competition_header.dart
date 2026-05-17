import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Bannière haut de la page admin compétition : badge de statut, ID court,
/// nom + capacité + cagnotte. Gradient par jeu (eFoot / FIFA / FC).
class AdminCompetitionHeader extends StatelessWidget {
  const AdminCompetitionHeader({required this.competition, super.key});
  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientFor(competition.game);
    final fmt = NumberFormat('#,###', 'fr_FR');
    final pool = fmt
        .format(competition.prizePoolLocal.round())
        .replaceAll(',', ' ');

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(gradient: gradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ArenaBadge(
                label: _statusLabel(competition.status),
                variant: _statusBadgeVariant(competition.status),
              ),
              const Spacer(),
              Text(
                '#${competition.id.substring(0, 8).toUpperCase()}',
                style: ArenaText.monoSmall
                    .copyWith(color: ArenaColors.bone.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            competition.name.toUpperCase(),
            style: ArenaText.h2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            '${competition.currentPlayers}/${competition.maxPlayers} inscrits'
            '${competition.prizePoolLocal > 0 ? " · Cagnotte $pool ${competition.prizePoolCurrency ?? competition.registrationCurrency}" : ""}',
            style: ArenaText.bodyMuted.copyWith(
              color: ArenaColors.bone.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(CompetitionStatus s) {
    switch (s) {
      case CompetitionStatus.ongoing:
        return 'LIVE';
      case CompetitionStatus.registrationOpen:
        return 'INSCRIPTIONS';
      case CompetitionStatus.registrationClosed:
        return 'COMPLET';
      case CompetitionStatus.draft:
        return 'DRAFT';
      case CompetitionStatus.completed:
        return 'TERMINÉ';
      case CompetitionStatus.cancelled:
        return 'ANNULÉ';
    }
  }

  static ArenaBadgeVariant _statusBadgeVariant(CompetitionStatus s) {
    switch (s) {
      case CompetitionStatus.ongoing:
        return ArenaBadgeVariant.live;
      case CompetitionStatus.registrationOpen:
        return ArenaBadgeVariant.info;
      case CompetitionStatus.completed:
        return ArenaBadgeVariant.success;
      case CompetitionStatus.cancelled:
        return ArenaBadgeVariant.danger;
      case CompetitionStatus.draft:
      case CompetitionStatus.registrationClosed:
        return ArenaBadgeVariant.warn;
    }
  }

  static LinearGradient _gradientFor(GameType g) {
    switch (g) {
      case GameType.fifaMobile:
        return ArenaColors.bannerFifa;
      case GameType.eaSportsFc:
        return ArenaColors.bannerFc;
      case GameType.efootball:
        return ArenaColors.bannerEfoot;
    }
  }
}
