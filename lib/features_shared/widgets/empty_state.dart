import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';

/// Friendly empty placeholder — used when a list/section has no data yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: ArenaColors.textFaint),
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: ArenaSpacing.lg),
              ArenaButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: ArenaButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
