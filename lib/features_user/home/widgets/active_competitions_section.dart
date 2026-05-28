import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
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

/// Banner premium d'une compétition active sur la home.
///
/// **Trois couleurs d'accent par tier** (border + glow + badge mini), comme
/// sur la page liste — pour que le joueur identifie au scroll les tournois
/// payants / gratuits-avec-gain / gratuits-purs :
///  - Payant         → OR (`tierGoldWarm`) + badge `★`
///  - Gratuit + gain → TURQUOISE (`iceCyan`) + badge `🎁`
///  - Gratuit pur    → VERT (`statusOk`) + badge ASCII libre
///
/// Le gradient game-themed (eFoot/FIFA/FC) reste en arriere-plan pour
/// conserver l'identite jeu (bleu/vert/orange).
class _CompetitionBanner extends StatelessWidget {
  const _CompetitionBanner({required this.competition});
  final Competition competition;

  bool get _isPaid => !competition.isFree;
  bool get _hasPrize => competition.prizePoolLocal > 0;

  /// Couleur d'accent par tier — partagee avec `CompetitionListCard`.
  Color get _accent {
    if (_isPaid) return ArenaColors.tierGoldWarm;
    if (_hasPrize) return ArenaColors.iceCyan;
    return ArenaColors.statusOk;
  }

  /// Glow assorti a l'accent (jamais sur le gradient game).
  Color get _glow {
    if (_isPaid) return ArenaColors.tierGoldWarm.withValues(alpha: 0.32);
    if (_hasPrize) return ArenaColors.iceCyanGlow;
    return ArenaColors.statusOk.withValues(alpha: 0.22);
  }

  /// Mini badge tier en haut-gauche (compact pour la home).
  (String, Color) get _tierBadge {
    if (_isPaid) return ('★ PREMIUM', ArenaColors.tierGoldWarm);
    if (_hasPrize) return ('🎁 + GAINS', ArenaColors.iceCyan);
    return ('GRATUIT', ArenaColors.statusOk);
  }

  /// Gradient de fond par tier — remplace l'ancien gradient game-themed
  /// (eFoot bleu/FIFA vert/FC orange) pour que le tarif soit immediatement
  /// lisible au scroll.
  LinearGradient get _tierGradient {
    if (_isPaid) return ArenaColors.compTierPaid;
    if (_hasPrize) return ArenaColors.compTierFreePrize;
    return ArenaColors.compTierFreePure;
  }

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final gradient = _tierGradient;
    final statusLabel = _statusLabel(c.status);
    final daysToStart = c.startDate.difference(DateTime.now()).inDays;
    final startLabel = daysToStart > 0
        ? 'Dans ${daysToStart}j'
        : daysToStart == 0
            ? "Aujourd'hui"
            : 'En cours';
    final fee = c.registrationFee.round();
    final feeLabel = fee == 0 ? 'Gratuit' : '$fee ${c.registrationCurrency}';
    final players = '${c.currentPlayers}/${c.maxPlayers}';
    final accent = _accent;
    final (tierLabel, tierColor) = _tierBadge;

    return InkWell(
      onTap: () => context.push(UserRoutes.competitionPath(c.id)),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: accent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _glow,
              blurRadius: 18,
              spreadRadius: -6,
            ),
          ],
        ),
        padding: const EdgeInsets.all(ArenaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TierMiniBadge(label: tierLabel, color: tierColor),
                const Spacer(),
                _StatusPill(label: statusLabel),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c.name,
              style: ArenaText.h3.copyWith(
                color: ArenaColors.bone,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
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
                    color: _isPaid ? accent : ArenaColors.bone,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(CompetitionStatus s) => switch (s) {
        CompetitionStatus.registrationOpen => 'OUVERT',
        CompetitionStatus.ongoing => 'EN COURS',
        _ => 'BIENTÔT',
      };
}

/// Badge mini en haut-gauche : « ★ PREMIUM » / « 🎁 + GAINS » / « GRATUIT ».
/// **Fond noir + bordure + texte coloré** — necessaire depuis que le
/// gradient de fond du banner est aussi celui du tier (sinon badge fond
/// clair sur fond clair = invisible). Look "etiquette premium" qui tranche
/// net sur n'importe quel gradient.
class _TierMiniBadge extends StatelessWidget {
  const _TierMiniBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: ArenaColors.void_,
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        border: Border.all(color: color, width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 6,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Pill statut (OUVERT/EN COURS/BIENTÔT) — fond bone @ 25 % translucide qui
/// marche sur n'importe quel gradient game, texte bone bold.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

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
