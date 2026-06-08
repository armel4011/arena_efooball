// =============================================================================
// ARENA — Plateau de dames : barre joueur + horloge (HUD).
// =============================================================================

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_user/draughts/ui/draughts_board_theme.dart';
import 'package:flutter/material.dart';

String formatClock(int? ms) {
  if (ms == null) return '--:--';
  final total = (ms / 1000).ceil().clamp(0, 59 * 60 + 59);
  final m = (total ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Barre d'un joueur : pastille de couleur, nom, et horloge. Surlignée quand
/// c'est à lui de jouer (`active`).
class DraughtsPlayerBar extends StatelessWidget {
  const DraughtsPlayerBar({
    required this.name,
    required this.isWhite,
    required this.active,
    required this.clockMs,
    this.low = false,
    super.key,
  });

  final String name;
  final bool isWhite;
  final bool active;
  final int? clockMs;
  final bool low; // horloge basse → teinte d'alerte

  @override
  Widget build(BuildContext context) {
    final accent =
        isWhite ? DraughtsBoardTheme.whiteTop : DraughtsBoardTheme.darkTop;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ArenaColors.carbon.withValues(alpha: active ? 0.95 : 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? DraughtsBoardTheme.selection.withValues(alpha: 0.8)
              : ArenaColors.borderHi,
          width: active ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.5),
                colors: [
                  accent,
                  if (isWhite)
                    DraughtsBoardTheme.whiteShade
                  else
                    DraughtsBoardTheme.darkShade,
                ],
              ),
              border: Border.all(
                color: isWhite
                    ? DraughtsBoardTheme.whiteRim
                    : DraughtsBoardTheme.darkRim,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArenaText.body.copyWith(
                color: active ? ArenaColors.bone : ArenaColors.silver,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ArenaColors.void_.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: low
                    ? ArenaColors.neonRed.withValues(alpha: 0.8)
                    : ArenaColors.borderHi,
              ),
            ),
            child: Text(
              formatClock(clockMs),
              style: ArenaText.mono.copyWith(
                color: low ? ArenaColors.neonRed : ArenaColors.bone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
