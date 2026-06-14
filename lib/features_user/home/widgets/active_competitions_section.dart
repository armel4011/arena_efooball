import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/home/main_layout.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Section « MES TOURNOIS » — ne liste QUE les compétitions où le joueur
/// courant est **inscrit** (croisement `competitionsListProvider` ×
/// `myRegisteredCompetitionIdsProvider`). Les tournois en cours / inscription
/// ouverte sont remontés en tête, puis le reste, dans la limite de 5 banners.
/// Empty state dédié + CTA vers la liste complète (onglet Compétitions).
class ActiveCompetitionsSection extends ConsumerWidget {
  const ActiveCompetitionsSection({super.key});

  /// Priorité de tri : en cours / inscription ouverte d'abord.
  static int _priority(CompetitionStatus s) => switch (s) {
        CompetitionStatus.ongoing => 0,
        CompetitionStatus.registrationOpen => 1,
        _ => 2,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(competitionsListProvider(null));
    final registeredIds =
        ref.watch(myRegisteredCompetitionIdsProvider).valueOrNull ??
            const <String>{};
    return Padding(
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
          final mine = all
              .where((c) => registeredIds.contains(c.id))
              .toList(growable: false)
            ..sort(
              (a, b) => _priority(a.status).compareTo(_priority(b.status)),
            );
          final shown = mine.take(5).toList(growable: false);
          if (shown.isEmpty) {
            return _EmptyState(
              message: l10n.myTournamentsEmpty,
              ctaLabel: l10n.myTournamentsBrowseCta,
              onCta: () =>
                  ref.read(mainTabRequestProvider.notifier).state = 1,
            );
          }
          return Column(
            children: [
              for (final c in shown) ...[
                _CompetitionBanner(competition: c),
                const SizedBox(height: ArenaSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Empty state de « MES TOURNOIS » : message + CTA vers la liste complète.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.ctaLabel,
    required this.onCta,
  });
  final String message;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      padding: const EdgeInsets.all(ArenaSpacing.md),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 32,
            color: ArenaColors.silver,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaButton(
            label: ctaLabel,
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: onCta,
          ),
        ],
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
/// Le gradient game-themed (eFoot/Dames/FC) reste en arriere-plan pour
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
  /// (eFoot bleu/Dames rouge/FC orange) pour que le tarif soit immediatement
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
                if (c.isPinned) ...[
                  const SizedBox(width: 6),
                  const _TierMiniBadge(
                    label: '📌 À LA UNE',
                    color: ArenaColors.tierGoldWarm,
                  ),
                ],
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
