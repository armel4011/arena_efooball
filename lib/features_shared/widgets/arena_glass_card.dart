import 'dart:ui';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Frosted-glass card with an optional colored halo.
///
/// Renders a [BackdropFilter] over a translucent surface tint plus a
/// hairline border. Needs colored content behind it (e.g. a gradient
/// backdrop) — over a flat dark scaffold the blur has nothing to refract.
class ArenaGlassCard extends StatelessWidget {
  const ArenaGlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(ArenaSpacing.md),
    this.glowColor,
    this.glowAlpha = 0.32,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glowColor;
  final double glowAlpha;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glow = glowColor;

    final card = ClipRRect(
      borderRadius: ArenaRadius.card,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: ArenaColors.surface.withValues(alpha: 0.55),
            borderRadius: ArenaRadius.card,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );

    final framed = glow == null
        ? card
        : DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: ArenaRadius.card,
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: glowAlpha),
                  blurRadius: 28,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: card,
          );

    if (onTap == null) return framed;
    return Material(
      color: Colors.transparent,
      borderRadius: ArenaRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: ArenaRadius.card,
        child: framed,
      ),
    );
  }
}
