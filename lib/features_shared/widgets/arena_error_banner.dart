import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Encart d'erreur **inline** — à distinguer de `ErrorState` (placeholder plein
/// écran avec CTA de réessai). Affiche un message dans un cartouche rouge
/// discret, typiquement au-dessus d'un formulaire ou d'une section.
///
/// [dense] réduit la typographie ([ArenaText.small] au lieu de [ArenaText.body])
/// pour les contextes compacts (ex. le `TotpGate`).
class ArenaErrorBanner extends StatelessWidget {
  const ArenaErrorBanner({
    required this.message,
    this.dense = false,
    super.key,
  });

  final String message;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.danger.withValues(alpha: 0.12),
        borderRadius: ArenaRadius.button,
        border: Border.all(color: ArenaColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: ArenaColors.danger,
            size: 20,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: (dense ? ArenaText.small : ArenaText.body).copyWith(
                color: ArenaColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
