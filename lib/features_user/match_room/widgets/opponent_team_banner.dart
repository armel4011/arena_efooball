import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:flutter/material.dart';

/// Affiche le nom d'équipe DÉJÀ choisi par l'adversaire, pour que le joueur
/// évite de reprendre la même (règle « pas la même équipe »). Ne s'affiche que
/// si l'adversaire a déjà validé son équipe ; se met à jour en temps réel via
/// le rebuild du match parent.
class OpponentTeamBanner extends StatelessWidget {
  const OpponentTeamBanner({
    required this.match,
    required this.isPlayer1,
    super.key,
  });

  final ArenaMatch match;
  final bool isPlayer1;

  @override
  Widget build(BuildContext context) {
    final opp =
        (isPlayer1 ? match.player2TeamName : match.player1TeamName)?.trim();
    if (opp == null || opp.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: ArenaSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.iceCyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(
          color: ArenaColors.iceCyan.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 20,
            color: ArenaColors.iceCyan,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Équipe de l'adversaire",
                  style: ArenaText.small.copyWith(color: ArenaColors.silver),
                ),
                const SizedBox(height: 2),
                Text(
                  opp,
                  style: ArenaText.inputLabel.copyWith(
                    color: ArenaColors.iceCyan,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choisis une équipe différente.',
                  style: ArenaText.small.copyWith(color: ArenaColors.silver),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
