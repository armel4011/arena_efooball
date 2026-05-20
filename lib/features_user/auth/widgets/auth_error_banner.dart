import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Bandeau d'erreur d'authentification — sobre et discret.
///
/// Remplace les anciens `_ErrorBanner` rouge vif dupliqués dans chaque
/// écran d'auth user. Surface neutre, accent ambre léger, texte lisible
/// mais non alarmant : l'erreur reste visible sans dramatiser l'écran.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  /// Message déjà localisé, prêt à afficher (cf. `authFailureToMessage`).
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.surfaceLight,
        borderRadius: ArenaRadius.button,
        border: Border.all(color: ArenaColors.borderHi),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: ArenaColors.statusWarn,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: ArenaText.small.copyWith(color: ArenaColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
