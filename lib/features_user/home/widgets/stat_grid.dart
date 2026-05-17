import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/profile.dart';
import 'package:flutter/material.dart';

/// Grille 3-colonnes "Tes stats" affichée en bas de la home :
/// Matchs joués · V/D/N · Win rate. Source : `profile.stats` (jsonb,
/// autoritaire pour leaderboards, recalculé par `recalculate_player_stats`).
class StatGrid extends StatelessWidget {
  const StatGrid({required this.profile, super.key});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final stats = profile?.stats ?? const <String, dynamic>{};
    final wins = _asInt(stats['wins']);
    final losses = _asInt(stats['losses']);
    final draws = _asInt(stats['draws']);
    final played = wins + losses + draws;
    final winRate = played == 0 ? 0 : ((wins / played) * 100).round();
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '$played',
            label: 'Matchs',
          ),
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(
          child: _StatTile(
            value: '$wins/$losses/$draws',
            label: 'V/D/N',
            valueColor: ArenaColors.statusOk,
          ),
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(
          child: _StatTile(
            value: played == 0 ? '—' : '$winRate%',
            label: 'Win rate',
          ),
        ),
      ],
    );
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: ArenaSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: ArenaText.bigNumber.copyWith(
              color: valueColor ?? ArenaColors.bone,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: ArenaText.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
