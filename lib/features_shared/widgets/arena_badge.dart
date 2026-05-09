import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Pill-shaped status badge.
///
/// Maps to `.badge` in `arena_v2.html` with variants `b-live` / `b-success` /
/// `b-info` / `b-warn` / `b-danger` / `b-tier-bronze`. The `live` variant
/// renders a pulsing white dot prefix (1500 ms loop).
enum ArenaBadgeVariant { live, success, info, warn, danger, tierBronze, neutral }

class ArenaBadge extends StatelessWidget {
  const ArenaBadge({
    required this.label,
    this.variant = ArenaBadgeVariant.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final ArenaBadgeVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(variant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(ArenaRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (variant == ArenaBadgeVariant.live)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: ArenaPulseDot(color: Colors.white, size: 5),
            )
          else if (icon != null) ...[
            Icon(icon, size: 10, color: spec.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: ArenaText.badge.copyWith(color: spec.foreground),
          ),
        ],
      ),
    );
  }

  static ({Color background, Color foreground}) _spec(ArenaBadgeVariant v) =>
      switch (v) {
        ArenaBadgeVariant.live => (
            background: ArenaColors.neonRed,
            foreground: Colors.white,
          ),
        ArenaBadgeVariant.success => (
            background: ArenaColors.statusOk.withValues(alpha: 0.15),
            foreground: ArenaColors.statusOk,
          ),
        ArenaBadgeVariant.info => (
            background: ArenaColors.signalBlue.withValues(alpha: 0.15),
            foreground: ArenaColors.signalBlue,
          ),
        ArenaBadgeVariant.warn => (
            background: ArenaColors.statusWarn.withValues(alpha: 0.15),
            foreground: ArenaColors.statusWarn,
          ),
        ArenaBadgeVariant.danger => (
            background: ArenaColors.neonRed.withValues(alpha: 0.15),
            foreground: ArenaColors.neonRed,
          ),
        ArenaBadgeVariant.tierBronze => (
            background: ArenaColors.tierBronze.withValues(alpha: 0.15),
            foreground: ArenaColors.tierBronze,
          ),
        ArenaBadgeVariant.neutral => (
            background: ArenaColors.borderHi,
            foreground: ArenaColors.silver,
          ),
      };
}
