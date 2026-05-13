import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// PHASE 4 — list of competitions, filterable by game + status.
///
/// Maps to screen #10 of `arena_v2.html`. Two chip rows on top (jeu /
/// statut), then full-bleed [ArenaBanner] cards per competition with a
/// trailing OPEN badge + capacity counter.
class CompetitionsListPage extends ConsumerStatefulWidget {
  const CompetitionsListPage({super.key});

  @override
  ConsumerState<CompetitionsListPage> createState() =>
      _CompetitionsListPageState();
}

class _CompetitionsListPageState extends ConsumerState<CompetitionsListPage> {
  GameType? _game;
  _StatusBucket _bucket = _StatusBucket.upcoming;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(competitionsListProvider(_game));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ArenaSpacing.lg,
            ArenaSpacing.md,
            ArenaSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JEU', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _GameChips(
                selected: _game,
                onChanged: (g) => setState(() => _game = g),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text('STATUS', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _StatusChips(
                selected: _bucket,
                onChanged: (b) => setState(() => _bucket = b),
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        const Divider(height: 1, thickness: 1, color: ArenaColors.border),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              description: e.toString(),
              onRetry: () => ref.invalidate(competitionsListProvider(_game)),
            ),
            data: (items) {
              final filtered =
                  items.where((c) => _bucket.matches(c.status)).toList();
              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.sports_esports_outlined,
                  title: _game == null
                      ? 'Aucune compétition'
                      : 'Aucune compétition sur ${_game!.label}',
                  description: 'De nouveaux tournois sont publiés chaque'
                      ' semaine. Reviens bientôt !',
                );
              }
              final registeredIds =
                  ref.watch(myRegisteredCompetitionIdsProvider).valueOrNull ??
                      const <String>{};
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(competitionsListProvider(_game));
                  await ref
                      .read(competitionsListProvider(_game).future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: ArenaSpacing.md),
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    return _CompetitionListCard(
                      competition: c,
                      isRegistered: registeredIds.contains(c.id),
                      onTap: () => _onCardTap(context, c, registeredIds),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

void _onCardTap(
  BuildContext context,
  Competition c,
  Set<String> registeredIds,
) {
  // Si déjà inscrit → accès direct au détail (bracket / matches / etc).
  if (registeredIds.contains(c.id)) {
    context.push(UserRoutes.competitionPath(c.id));
    return;
  }
  // Pas inscrit → on saute le détail et on envoie directement vers la
  // page de confirmation d'inscription (gate).
  final dateLabel =
      DateFormat('dd MMM yyyy · HH:mm', 'fr').format(c.startDate.toLocal());
  context.push(
    UserRoutes.registrationConfirmPath(c.id),
    extra: RegistrationConfirmArgs(
      competitionName: c.name,
      gameLabel: c.game.label,
      gameEmoji: _gameEmoji(c.game),
      dateLabel: dateLabel,
      formatLabel: _formatLabel(c.format),
      entryFeeXaf: c.registrationFee.round(),
      totalPrizeXaf: c.prizePoolLocal.round(),
    ),
  );
}

String _gameEmoji(GameType g) => switch (g) {
      GameType.efootball => '⚽',
      GameType.fifaMobile => '🏆',
      GameType.eaSportsFc => '🎮',
    };

String _formatLabel(TournamentFormat f) => switch (f) {
      TournamentFormat.singleElimination => 'Élimination directe',
      TournamentFormat.groupsThenKnockout => 'Poules + élimination',
      TournamentFormat.roundRobin => 'Round robin',
    };

enum _StatusBucket {
  upcoming('À venir'),
  ongoing('En cours'),
  completed('Terminés');

  const _StatusBucket(this.label);
  final String label;

  bool matches(CompetitionStatus status) => switch (this) {
        _StatusBucket.upcoming => status == CompetitionStatus.draft ||
            status == CompetitionStatus.registrationOpen ||
            status == CompetitionStatus.registrationClosed,
        _StatusBucket.ongoing => status == CompetitionStatus.ongoing,
        _StatusBucket.completed => status == CompetitionStatus.completed ||
            status == CompetitionStatus.cancelled,
      };
}

class _GameChips extends StatelessWidget {
  const _GameChips({required this.selected, required this.onChanged});

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

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.selected, required this.onChanged});

  final _StatusBucket selected;
  final ValueChanged<_StatusBucket> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _StatusBucket.values.length; i++) ...[
            _Chip(
              label: _StatusBucket.values[i].label,
              active: _StatusBucket.values[i] == selected,
              onTap: () => onChanged(_StatusBucket.values[i]),
            ),
            if (i < _StatusBucket.values.length - 1)
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

/// Carte compétition simplifiée — affiche les infos clés pour
/// décider de s'inscrire : nom, badge GRATUITE/PAYANTE, récompense en
/// gros caractères pour les compétitions payantes (ou "GRATUIT" pour
/// les gratuites), et une ligne footer avec date + frais + capacité.
///
/// Le détail complet (bracket, matches, chat) reste gated derrière
/// l'inscription — d'où le minimalisme volontaire ici.
class _CompetitionListCard extends StatelessWidget {
  const _CompetitionListCard({
    required this.competition,
    required this.isRegistered,
    required this.onTap,
  });

  final Competition competition;
  final bool isRegistered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final isFree = c.isFree;
    final accent = isFree ? ArenaColors.statusOk : ArenaColors.signalBlue;
    final dateLabel = DateFormat('d MMM · HH:mm', 'fr').format(
      c.startDate.toLocal(),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: isRegistered
                ? ArenaColors.statusOk.withValues(alpha: 0.5)
                : ArenaColors.border,
            width: isRegistered ? 1.5 : 1,
          ),
          boxShadow: isRegistered
              ? [
                  BoxShadow(
                    color: ArenaColors.statusOk.withValues(alpha: 0.15),
                    blurRadius: 18,
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header : emoji + nom + badge tarif ─────────────────
            Row(
              children: [
                Text(
                  _gameEmoji(c.game),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: ArenaSpacing.sm),
                Expanded(
                  child: Text(
                    c.name,
                    style: ArenaText.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: ArenaSpacing.xs),
                _PricingChip(isFree: isFree),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${c.game.label} · $dateLabel',
              style: ArenaText.bodyMuted,
            ),
            const SizedBox(height: ArenaSpacing.md),

            // ─── Récompense en gros (ou GRATUIT) ────────────────────
            Center(
              child: Column(
                children: [
                  if (isFree)
                    Text(
                      'GRATUIT',
                      style: ArenaText.bigNumber.copyWith(
                        color: accent,
                        fontSize: 36,
                        letterSpacing: 2,
                      ),
                    )
                  else
                    Text(
                      _formatPrize(c.prizePoolLocal, c.prizePoolCurrency,
                          c.registrationCurrency),
                      style: ArenaText.bigNumber.copyWith(
                        color: accent,
                        fontSize: 32,
                        letterSpacing: 1,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    isFree ? 'Inscription libre' : 'À gagner',
                    style: ArenaText.bodyMuted.copyWith(letterSpacing: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ArenaSpacing.md),
            const Divider(height: 1, color: ArenaColors.border),
            const SizedBox(height: ArenaSpacing.sm),

            // ─── Footer : frais (si payante) + capacité + état inscr. ─
            Row(
              children: [
                if (!isFree) ...[
                  const Icon(
                    Icons.payments_outlined,
                    size: 14,
                    color: ArenaColors.silver,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_money(c.registrationFee)} ${c.registrationCurrency}',
                    style: ArenaText.bodyMuted,
                  ),
                  const SizedBox(width: ArenaSpacing.md),
                ],
                const Icon(
                  Icons.people_outline,
                  size: 14,
                  color: ArenaColors.silver,
                ),
                const SizedBox(width: 4),
                Text(
                  '${c.currentPlayers}/${c.maxPlayers}',
                  style: ArenaText.bodyMuted,
                ),
                const Spacer(),
                if (isRegistered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ArenaColors.statusOk.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(ArenaRadius.round),
                      border: Border.all(
                        color: ArenaColors.statusOk.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '✓ INSCRIT',
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.statusOk,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrize(double pool, String? poolCurrency, String fee) {
    final formatted = NumberFormat.decimalPattern('fr')
        .format(pool.round())
        .replaceAll(',', ' ');
    final currency = poolCurrency ?? fee;
    return '$formatted $currency';
  }

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
}

class _PricingChip extends StatelessWidget {
  const _PricingChip({required this.isFree});
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    final color = isFree ? ArenaColors.statusOk : ArenaColors.signalBlue;
    final label = isFree ? 'GRATUITE' : 'PAYANTE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: ArenaText.small.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          fontSize: 10,
        ),
      ),
    );
  }
}
