import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:flutter/material.dart';

/// Tarif filter — gratuit / payant / tous.
enum PricingBucket {
  all('Toutes'),
  free('Gratuites'),
  paid('Payantes');

  const PricingBucket(this.label);
  final String label;

  bool matches(Competition c) => switch (this) {
        PricingBucket.all => true,
        PricingBucket.free => c.isFree,
        PricingBucket.paid => !c.isFree,
      };
}

/// Status filter — bucket regroupant plusieurs `CompetitionStatus`.
enum StatusBucket {
  upcoming('À venir'),
  ongoing('En cours'),
  completed('Terminés');

  const StatusBucket(this.label);
  final String label;

  bool matches(CompetitionStatus status) => switch (this) {
        StatusBucket.upcoming => status == CompetitionStatus.draft ||
            status == CompetitionStatus.registrationOpen ||
            status == CompetitionStatus.registrationClosed,
        StatusBucket.ongoing => status == CompetitionStatus.ongoing,
        StatusBucket.completed => status == CompetitionStatus.completed ||
            status == CompetitionStatus.cancelled,
      };
}

class GameChips extends StatelessWidget {
  const GameChips({required this.selected, required this.onChanged, super.key});

  final GameType? selected;
  final ValueChanged<GameType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'Tous',
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final g in GameType.values) ...[
            const SizedBox(width: ArenaSpacing.xs),
            _Chip(
              label: g.label,
              active: selected == g,
              onTap: () => onChanged(g),
            ),
          ],
        ],
      ),
    );
  }
}

class StatusChips extends StatelessWidget {
  const StatusChips(
      {required this.selected, required this.onChanged, super.key,});

  final StatusBucket selected;
  final ValueChanged<StatusBucket> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < StatusBucket.values.length; i++) ...[
            _Chip(
              label: StatusBucket.values[i].label,
              active: StatusBucket.values[i] == selected,
              onTap: () => onChanged(StatusBucket.values[i]),
            ),
            if (i < StatusBucket.values.length - 1)
              const SizedBox(width: ArenaSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class PricingChips extends StatelessWidget {
  const PricingChips(
      {required this.selected, required this.onChanged, super.key,});

  final PricingBucket selected;
  final ValueChanged<PricingBucket> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < PricingBucket.values.length; i++) ...[
            _Chip(
              label: PricingBucket.values[i].label,
              active: PricingBucket.values[i] == selected,
              onTap: () => onChanged(PricingBucket.values[i]),
            ),
            if (i < PricingBucket.values.length - 1)
              const SizedBox(width: ArenaSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: active ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
