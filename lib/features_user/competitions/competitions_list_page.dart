import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_shared/widgets/arena_filter_menu.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/competitions/widgets/competition_filter_chips.dart';
import 'package:arena/features_user/competitions/widgets/competition_list_card.dart';
import 'package:arena/features_user/home/widgets/tutorial_video_section.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// PHASE 4 — list of competitions, organised by game in a [TabBar].
///
/// Maps to screen #10 of `arena_v2.html`. Lot C.1 avait consolidé les chips
/// dans un `ArenaFilterMenu`. Évolution : il n'y a plus d'onglet « Tous » —
/// **un onglet par jeu** ([GameType]), chacun ne montrant que ses compétitions
/// (filtrage serveur via `competitionsListProvider(game)`). Chaque onglet
/// conserve son **propre** filtrage statut + tarif, indépendant des autres
/// (état préservé d'un onglet à l'autre via [AutomaticKeepAliveClientMixin]).
///
/// Le rendu des cards et la logique des filtres (enums `StatusBucket` /
/// `PricingBucket`) sont extraits dans `widgets/`.
class CompetitionsListPage extends StatefulWidget {
  const CompetitionsListPage({super.key});

  @override
  State<CompetitionsListPage> createState() => _CompetitionsListPageState();
}

class _CompetitionsListPageState extends State<CompetitionsListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: GameType.values.length, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArenaScreenBackground(
      child: Column(
        children: [
          const TutorialBannerSection(page: TutorialPage.competitions),
          TabBar(
            controller: _tab,
            indicatorColor: ArenaColors.signalBlue,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: ArenaColors.border,
            labelColor: ArenaColors.bone,
            unselectedLabelColor: ArenaColors.textMuted,
            labelStyle: ArenaText.button,
            unselectedLabelStyle: ArenaText.button,
            tabs: [
              for (final g in GameType.values) Tab(text: _tabLabel(g)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                for (final g in GameType.values)
                  _CompetitionTab(key: ValueKey(g), game: g),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Libellé court (avec emoji) pour l'onglet d'un jeu — `GameType.label` est
/// trop long pour 3 onglets fixes (« EA SPORTS FC Mobile »).
String _tabLabel(GameType g) => switch (g) {
      GameType.efootball => '⚽  eFootball',
      GameType.draughts => '🔴  Dames',
      GameType.eaSportsFc => '🎮  EA FC',
    };

/// Onglet d'un jeu : la liste filtrée d'un seul [GameType], avec son propre
/// état de filtres (statut + tarif) maintenu indépendamment des autres onglets.
class _CompetitionTab extends ConsumerStatefulWidget {
  const _CompetitionTab({required this.game, super.key});

  final GameType game;

  @override
  ConsumerState<_CompetitionTab> createState() => _CompetitionTabState();
}

class _CompetitionTabState extends ConsumerState<_CompetitionTab>
    with AutomaticKeepAliveClientMixin {
  // null = aucun filtre de statut (= toutes les phases). Plus d'option « Toutes ».
  StatusBucket? _bucket;
  PricingBucket _pricing = PricingBucket.all;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // requis par AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(competitionsListProvider(widget.game));

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
                sections: _buildSections(l10n),
                initialSelection: _selectionSnapshot(),
                onApply: _applySelection,
              ),
              const Spacer(),
              if (_activeFilterCount() > 0)
                TextButton(
                  onPressed: _resetAll,
                  child: Text(
                    l10n.compListReset,
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
              onRetry: () =>
                  ref.invalidate(competitionsListProvider(widget.game)),
            ),
            data: (items) {
              final filtered = items
                  .where((c) => _bucket?.matches(c.status) ?? true)
                  .where((c) => _pricing.matches(c))
                  .toList();
              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.sports_esports_outlined,
                  title: '${l10n.compListEmptyTitleGamePrefix}'
                      '${widget.game.label}',
                  description: l10n.compListEmptyDesc,
                );
              }
              final registeredIds =
                  ref.watch(myRegisteredCompetitionIdsProvider).valueOrNull ??
                      const <String>{};
              final pendingByComp =
                  ref.watch(myPendingPaymentByCompetitionProvider);
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(competitionsListProvider(widget.game));
                  await ref.read(competitionsListProvider(widget.game).future);
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

  // ─── Filter helpers (mapping tab state ↔ ArenaFilterMenu) ───────────
  // La section « jeu » a disparu : le jeu est porté par l'onglet courant.

  List<ArenaFilterSection> _buildSections(AppLocalizations l10n) {
    return [
      ArenaFilterSection(
        id: 'status',
        title: l10n.compListFilterStatus,
        mode: ArenaFilterMode.radio,
        options: [
          for (final b in StatusBucket.values)
            ArenaFilterOption(id: b.name, label: b.labelOf(l10n)),
        ],
      ),
      ArenaFilterSection(
        id: 'pricing',
        title: l10n.compListFilterPricing,
        mode: ArenaFilterMode.radio,
        options: [
          for (final p in PricingBucket.values)
            ArenaFilterOption(id: p.name, label: p.labelOf(l10n)),
        ],
      ),
    ];
  }

  Map<String, List<String>> _selectionSnapshot() {
    return {
      'status': _bucket == null ? const [] : [_bucket!.name],
      'pricing': _pricing == PricingBucket.all ? const [] : [_pricing.name],
    };
  }

  void _applySelection(Map<String, List<String>> selection) {
    setState(() {
      final statusId = selection['status']?.firstOrNull;
      _bucket = statusId == null
          ? null
          : StatusBucket.values.firstWhere((b) => b.name == statusId);

      final pricingId = selection['pricing']?.firstOrNull;
      _pricing = pricingId == null
          ? PricingBucket.all
          : PricingBucket.values.firstWhere((p) => p.name == pricingId);
    });
  }

  int _activeFilterCount() {
    var n = 0;
    if (_bucket != null) n++;
    if (_pricing != PricingBucket.all) n++;
    return n;
  }

  void _resetAll() {
    setState(() {
      _bucket = null;
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
  final l10n = AppLocalizations.of(context);
  final dateLabel =
      DateFormat('dd MMM yyyy · HH:mm', 'fr').format(c.startDate.toLocal());
  context.push(
    UserRoutes.registrationConfirmPath(c.id),
    extra: RegistrationConfirmArgs(
      competitionName: c.name,
      gameLabel: c.game.label,
      gameEmoji: _gameEmoji(c.game),
      dateLabel: dateLabel,
      formatLabel: _formatLabel(l10n, c.format),
      entryFeeXaf: c.registrationFee.round(),
      totalPrizeXaf: c.prizePoolLocal.round(),
      prizeDistribution: c.prizeDistribution,
      androidStoreUrl: c.androidStoreUrl,
      iosStoreUrl: c.iosStoreUrl,
    ),
  );
}

String _gameEmoji(GameType g) => switch (g) {
      GameType.efootball => '⚽',
      GameType.draughts => '🔴',
      GameType.eaSportsFc => '🎮',
    };

String _formatLabel(AppLocalizations l10n, TournamentFormat f) => switch (f) {
      TournamentFormat.singleElimination => l10n.compListFormatSingleElim,
      TournamentFormat.groupsThenKnockout => l10n.compListFormatGroupsKnockout,
      TournamentFormat.roundRobin => l10n.compListFormatRoundRobin,
    };
