import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Filtre courant (par jeu) appliqué à la liste des compétitions
/// actives sur la home. `null` = "Tous".
final homeGameFilterProvider = StateProvider<GameType?>((_) => null);

/// Section "★ ACTIVE TOURNAMENTS" — chips de filtre par jeu + jusqu'à
/// 3 banners game-themed (gradient eFoot/FIFA/FC) pour les compétitions
/// en `registrationOpen` / `ongoing`. Reproduit `.m-banner-efoot/fifa/fc`
/// de la maquette : gradient corner-to-corner, badge OUVERT/EN COURS/
/// BIENTÔT translucide sur fond couleur, meta blanche en mono.
class ActiveCompetitionsSection extends ConsumerWidget {
  const ActiveCompetitionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeGameFilterProvider);
    final async = ref.watch(competitionsListProvider(filter));
    return Column(
      children: [
        const _GameFilterChips(),
        const SizedBox(height: ArenaSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
          child: async.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              'Erreur : $e',
              style: ArenaText.body.copyWith(color: ArenaColors.danger),
            ),
            data: (all) {
              final active = all
                  .where(
                    (c) =>
                        c.status == CompetitionStatus.registrationOpen ||
                        c.status == CompetitionStatus.ongoing,
                  )
                  .take(3)
                  .toList(growable: false);
              if (active.isEmpty) {
                return Container(
                  decoration: BoxDecoration(
                    color: ArenaColors.carbon,
                    borderRadius: BorderRadius.circular(ArenaRadius.lg),
                    border: Border.all(color: ArenaColors.border),
                  ),
                  padding: const EdgeInsets.all(ArenaSpacing.md),
                  alignment: Alignment.center,
                  child: Text(
                    'Aucune compétition active pour ce filtre.',
                    style: ArenaText.bodyMuted,
                  ),
                );
              }
              return Column(
                children: [
                  for (final c in active) ...[
                    _CompetitionBanner(competition: c),
                    const SizedBox(height: ArenaSpacing.sm),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GameFilterChips extends ConsumerWidget {
  const _GameFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(homeGameFilterProvider);
    final items = <(String, GameType?)>[
      ('Tous', null),
      ('eFoot', GameType.efootball),
      ('FIFA', GameType.fifaMobile),
      ('FC Mobile', GameType.eaSportsFc),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _Chip(
              label: items[i].$1,
              selected: items[i].$2 == current,
              onTap: () =>
                  ref.read(homeGameFilterProvider.notifier).state = items[i].$2,
            ),
            if (i < items.length - 1) const SizedBox(width: ArenaSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: selected ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: selected ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Banner premium d'une compétition active — gradient game-themed
/// (eFoot/FIFA/FC) avec titre Bebas-like en bone, badge statut
/// (OUVERT/EN COURS) translucide à droite, et meta bottom (joueurs · fee ·
/// démarrage) en mono blanc semi-transparent.
class _CompetitionBanner extends StatelessWidget {
  const _CompetitionBanner({required this.competition});
  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final gradient = _gradientFor(c.game);
    final (statusLabel, statusColor) = _statusChip(c.status);
    final daysToStart = c.startDate.difference(DateTime.now()).inDays;
    final startLabel = daysToStart > 0
        ? 'Dans ${daysToStart}j'
        : daysToStart == 0
            ? "Aujourd'hui"
            : 'En cours';
    final fee = c.registrationFee.round();
    final feeLabel = fee == 0 ? 'Gratuit' : '$fee ${c.registrationCurrency}';
    final players = '${c.currentPlayers}/${c.maxPlayers}';

    return InkWell(
      onTap: () => context.push(UserRoutes.competitionPath(c.id)),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
        ),
        padding: const EdgeInsets.all(ArenaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.name,
                    style: ArenaText.h3.copyWith(
                      color: ArenaColors.bone,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: ArenaSpacing.xs),
                _StatusPill(label: statusLabel, accent: statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _MetaText(text: '$players joueurs'),
                const _MetaDot(),
                _MetaText(text: startLabel),
                const Spacer(),
                Text(
                  feeLabel,
                  style: ArenaText.mono.copyWith(
                    color: ArenaColors.bone,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static LinearGradient _gradientFor(GameType game) => switch (game) {
        GameType.efootball => ArenaColors.bannerEfoot,
        GameType.fifaMobile => ArenaColors.bannerFifa,
        GameType.eaSportsFc => ArenaColors.bannerFc,
      };

  static (String, ArenaBadgeVariant) _statusChip(CompetitionStatus s) =>
      switch (s) {
        CompetitionStatus.registrationOpen => (
            'OUVERT',
            ArenaBadgeVariant.success
          ),
        CompetitionStatus.ongoing => ('EN COURS', ArenaBadgeVariant.info),
        _ => ('BIENTÔT', ArenaBadgeVariant.warn),
      };
}

/// Pill statut (OUVERT/EN COURS/BIENTÔT) — fond bone @ 25 % translucide qui marche
/// sur n'importe quel gradient, texte bone bold. `accent` est conservé
/// pour usage futur (border colorée) sans changer le rendu actuel.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.accent});
  final String label;
  final ArenaBadgeVariant accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ArenaColors.bone.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(
          color: ArenaColors.bone,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: ArenaText.small.copyWith(
          color: ArenaColors.bone.withValues(alpha: 0.85),
        ),
      );
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '·',
          style: ArenaText.small.copyWith(
            color: ArenaColors.bone.withValues(alpha: 0.7),
          ),
        ),
      );
}
