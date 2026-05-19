import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_shared/widgets/arena_filter_menu.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/competitions/widgets/competition_filter_chips.dart';
import 'package:arena/features_user/competitions/widgets/competition_list_card.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// PHASE 4 — list of competitions, filterable by game + status + tarif.
///
/// Maps to screen #10 of `arena_v2.html`. Lot C.1 : les trois rangées
/// de chips ont été consolidées dans un seul `ArenaFilterMenu` qui ouvre
/// une bottom-sheet — preserve la même UX (jeu + statut + tarif) en
/// libérant l'en-tête de la page.
///
/// Le rendu des cards et la logique des filtres (enums `StatusBucket` /
/// `PricingBucket`) sont extraits dans `widgets/`.
class CompetitionsListPage extends ConsumerStatefulWidget {
  const CompetitionsListPage({super.key});

  @override
  ConsumerState<CompetitionsListPage> createState() =>
      _CompetitionsListPageState();
}

class _CompetitionsListPageState extends ConsumerState<CompetitionsListPage> {
  GameType? _game;
  StatusBucket _bucket = StatusBucket.upcoming;
  PricingBucket _pricing = PricingBucket.all;

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
            ArenaSpacing.sm,
          ),
          child: Row(
            children: [
              ArenaFilterMenu(
                activeCount: _activeFilterCount(),
                sections: _buildSections(),
                initialSelection: _selectionSnapshot(),
                onApply: _applySelection,
              ),
              const Spacer(),
              if (_activeFilterCount() > 0)
                TextButton(
                  onPressed: _resetAll,
                  child: Text(
                    'Réinitialiser',
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.signalBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: ArenaColors.border),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              description: e.toString(),
              onRetry: () => ref.invalidate(competitionsListProvider(_game)),
            ),
            data: (items) {
              final filtered = items
                  .where((c) => _bucket.matches(c.status))
                  .where((c) => _pricing.matches(c))
                  .toList();
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
              final pendingByComp =
                  ref.watch(myPendingPaymentByCompetitionProvider);
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
                    final isReg = registeredIds.contains(c.id);
                    final pending = pendingByComp[c.id];
                    return CompetitionListCard(
                      competition: c,
                      isRegistered: isReg,
                      hasPendingPayment: pending != null,
                      onTap: () => _onCardTap(
                        context,
                        c,
                        registeredIds,
                        pending,
                      ),
                      onRegister: !isReg && c.canRegister
                          ? () => _onRegisterTap(context, c, pending)
                          : null,
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

  // ─── Filter helpers (mapping page state ↔ ArenaFilterMenu) ──────────

  List<ArenaFilterSection> _buildSections() {
    return [
      ArenaFilterSection(
        id: 'game',
        title: 'Jeu',
        mode: ArenaFilterMode.radio,
        options: [
          for (final g in GameType.values)
            ArenaFilterOption(id: g.name, label: g.label),
        ],
      ),
      ArenaFilterSection(
        id: 'status',
        title: 'Statut',
        mode: ArenaFilterMode.radio,
        options: [
          for (final b in StatusBucket.values)
            ArenaFilterOption(id: b.name, label: b.label),
        ],
      ),
      ArenaFilterSection(
        id: 'pricing',
        title: 'Tarif',
        mode: ArenaFilterMode.radio,
        options: [
          for (final p in PricingBucket.values)
            ArenaFilterOption(id: p.name, label: p.label),
        ],
      ),
    ];
  }

  Map<String, List<String>> _selectionSnapshot() {
    return {
      'game': _game == null ? const [] : [_game!.name],
      'status': [_bucket.name],
      'pricing': _pricing == PricingBucket.all ? const [] : [_pricing.name],
    };
  }

  void _applySelection(Map<String, List<String>> selection) {
    setState(() {
      final gameId = selection['game']?.firstOrNull;
      _game = gameId == null
          ? null
          : GameType.values.firstWhere((g) => g.name == gameId);

      final statusId = selection['status']?.firstOrNull;
      // Status n'a pas d'option "toutes" — fallback sur upcoming si vide.
      _bucket = statusId == null
          ? StatusBucket.upcoming
          : StatusBucket.values.firstWhere((b) => b.name == statusId);

      final pricingId = selection['pricing']?.firstOrNull;
      _pricing = pricingId == null
          ? PricingBucket.all
          : PricingBucket.values.firstWhere((p) => p.name == pricingId);
    });
  }

  int _activeFilterCount() {
    var n = 0;
    if (_game != null) n++;
    if (_bucket != StatusBucket.upcoming) n++;
    if (_pricing != PricingBucket.all) n++;
    return n;
  }

  void _resetAll() {
    setState(() {
      _game = null;
      _bucket = StatusBucket.upcoming;
      _pricing = PricingBucket.all;
    });
  }
}

void _onCardTap(
  BuildContext context,
  Competition c,
  Set<String> registeredIds,
  PaymentRecord? pending,
) {
  // Si déjà inscrit → accès direct au détail (bracket / matches / etc).
  if (registeredIds.contains(c.id)) {
    context.push(UserRoutes.competitionPath(c.id));
    return;
  }
  // Si la comp n'accepte plus d'inscription (annulée/terminée/etc.) →
  // on ouvre la vue gated du détail qui explique pourquoi, plutôt que
  // de pousser inutilement vers la confirmation d'inscription.
  if (!c.canRegister) {
    context.push(UserRoutes.competitionPath(c.id));
    return;
  }
  // Sinon, s'il y a un paiement en attente, on saute la confirmation
  // et P1/P2 et on ré-ouvre P3 directement.
  _onRegisterTap(context, c, pending);
}

void _onRegisterTap(
  BuildContext context,
  Competition c,
  PaymentRecord? pending,
) {
  if (pending != null) {
    _resumeProcessing(context, c, pending);
    return;
  }
  _openInscriptionFlow(context, c);
}

void _resumeProcessing(
  BuildContext context,
  Competition c,
  PaymentRecord pending,
) {
  context.push(
    UserRoutes.paymentProcessing,
    extra: PaymentProcessingArgs(
      paymentId: pending.id,
      method: PaymentMethod.fromCode(pending.payerMethod ?? 'MTN_MOMO'),
      amountXaf: pending.amountLocal.round(),
      competitionName: c.name,
      maskedPhone: pending.payerPhone ?? '+••• •• •• ••',
    ),
  );
}

void _openInscriptionFlow(BuildContext context, Competition c) {
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
      prizeDistribution: c.prizeDistribution,
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
