import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Branded surface container.
///
/// Use as the building block for competition cards, match cards, settings
/// rows, etc. Tappable when [onTap] is provided (ripple respects radius).
class ArenaCard extends StatelessWidget {
  const ArenaCard({
    required this.child,
    this.padding = const EdgeInsets.all(ArenaSpacing.md),
    this.color,
    this.borderColor,
    this.onTap,
    this.elevated = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  /// When `true`, uses [ArenaColors.surfaceLight] (slightly higher) instead
  /// of [ArenaColors.surface]. Useful for nested cards or modals.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (elevated ? ArenaColors.surfaceLight : ArenaColors.surface);

    final card = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: ArenaRadius.card,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!),
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: ArenaRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: ArenaRadius.card,
        child: card,
      ),
    );
  }
}
