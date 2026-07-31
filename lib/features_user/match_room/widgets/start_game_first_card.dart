import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_user/match_room/match_room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carte d'AVERTISSEMENT affichée à l'étape « Activer l'enregistrement »
/// (avant le démarrage) : rappelle au joueur de LANCER D'ABORD son jeu
/// (jusqu'au menu principal) AVANT de démarrer l'enregistrement, car il ne
/// dispose que de 25 minutes pour jouer le match une fois l'enregistrement
/// lancé.
///
/// Une fois l'enregistrement démarré, le déroulé passe à l'étape suivante et
/// cette carte laisse place au COMPTE À REBOURS (RecordingCountdownCard).
class StartGameFirstCard extends ConsumerWidget {
  const StartGameFirstCard({required this.matchId, super.key});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(matchGameTypeProvider(matchId)).valueOrNull;
    final label = game?.label ?? 'ton jeu';
    const accent = ArenaColors.statusWarn;

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: accent, size: 22),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lance D'ABORD $label",
                  style: ArenaText.body.copyWith(
                    color: ArenaColors.bone,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Ouvre $label jusqu'au menu principal AVANT de démarrer "
                  "l'enregistrement. Tu n'auras que 25 minutes pour jouer le "
                  "match une fois l'enregistrement lancé.",
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
