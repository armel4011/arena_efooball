import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Branded spinner with optional label below.
class ArenaLoadingIndicator extends StatelessWidget {
  const ArenaLoadingIndicator({
    this.label,
    this.size = 32,
    super.key,
  });

  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          width: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(primary),
            backgroundColor: ArenaColors.surfaceLight,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: ArenaSpacing.md),
          Text(
            label!,
            style: ArenaTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
