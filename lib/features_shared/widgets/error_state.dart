import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';

/// Error placeholder with retry CTA.
///
/// Show in place of content when a network call or query fails. The
/// caller controls retry behavior via [onRetry].
class ErrorState extends StatelessWidget {
  const ErrorState({
    this.title = 'Une erreur est survenue',
    this.description,
    this.retryLabel = 'Réessayer',
    this.onRetry,
    super.key,
  });

  final String title;
  final String? description;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: ArenaColors.danger,
            ),
            const SizedBox(height: ArenaSpacing.md),
            Text(
              title,
              style: ArenaTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                description!,
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: ArenaSpacing.lg),
              ArenaButton(
                label: retryLabel,
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
