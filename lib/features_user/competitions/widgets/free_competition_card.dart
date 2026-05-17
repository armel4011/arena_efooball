import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card "GRATUITE" : layout léger, fond légèrement verdoyant, vibe
/// décontractée. Pas de notion de frais. Aucun élément "trophée".
class FreeCompetitionCard extends StatelessWidget {
  const FreeCompetitionCard({
    required this.competition,
    required this.isRegistered,
    required this.onTap,
    required this.onRegister,
    super.key,
  });

  final Competition competition;
  final bool isRegistered;
  final VoidCallback onTap;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final dateLabel =
        DateFormat('d MMM · HH:mm', 'fr').format(c.startDate.toLocal());

    final body = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArenaColors.statusOk.withValues(alpha: 0.10),
              ArenaColors.carbon,
            ],
          ),
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: isRegistered
                ? ArenaColors.statusOk
                : ArenaColors.statusOk.withValues(alpha: 0.35),
            width: isRegistered ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Bloc gauche : badge + emoji
            Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ArenaColors.statusOk.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ArenaColors.statusOk.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _gameEmoji(c.game),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ArenaColors.statusOk.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(ArenaRadius.round),
                  ),
                  child: Text(
                    'GRATUITE',
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.statusOk,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: ArenaSpacing.md),
            // Bloc centre : nom + jeu + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: ArenaText.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.game.label,
                    style: ArenaText.bodyMuted,
                  ),
                  const SizedBox(height: 2),
                  Text('🗓 $dateLabel', style: ArenaText.small),
                  const SizedBox(height: ArenaSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 13, color: ArenaColors.silver,),
                      const SizedBox(width: 3),
                      Text(
                        '${c.currentPlayers}/${c.maxPlayers}',
                        style: ArenaText.small,
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      if (isRegistered)
                        Text(
                          '· ✓ Inscrit',
                          style: ArenaText.small.copyWith(
                            color: ArenaColors.statusOk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: ArenaSpacing.sm),
            const Icon(
              Icons.chevron_right,
              color: ArenaColors.silver,
              size: 22,
            ),
          ],
        ),
      ),
    );

    if (onRegister == null) return body;
    // Card avec bouton S'INSCRIRE en bas — wrap dans Column pour empiler
    // la card cliquable + bouton dédié à l'inscription.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: "✓ M'INSCRIRE GRATUITEMENT",
          fullWidth: true,
          onPressed: onRegister,
        ),
      ],
    );
  }

  static String _gameEmoji(GameType g) => switch (g) {
        GameType.efootball => '⚽',
        GameType.fifaMobile => '🏆',
        GameType.eaSportsFc => '🎮',
      };
}
