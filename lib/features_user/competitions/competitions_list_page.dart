import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/payment_repository.dart';
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

/// Ordre d'affichage des onglets — **Dames en 1er**, eFootball en 2e, EA FC
/// en 3e. Liste LOCALE (l'enum [GameType] garde son ordre natif pour ne pas
/// casser les effets de bord ailleurs) : on mappe systématiquement l'index
/// d'onglet → jeu via cette liste.
const _orderedGames = <GameType>[
  GameType.draughts,
  GameType.efootball,
  GameType.eaSportsFc,
];

/// Couleur d'accent par jeu (indicateur + label actif de l'onglet).
Color _gameAccent(GameType g) => switch (g) {
      GameType.draughts => ArenaColors.gameDraughts,
      GameType.efootball => ArenaColors.gameEfoot,
      GameType.eaSportsFc => ArenaColors.gameFc,
    };

class _CompetitionsListPageState extends State<CompetitionsListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: _orderedGames.length, vsync: this);

  @override
  void initState() {
    super.initState();
    // Recalcule l'accent (indicateur + label actif) à chaque changement
    // d'onglet — y compris pendant le swipe (index courant suivi).
    _tab.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tab
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGame = _orderedGames[_tab.index];
    final accent = _gameAccent(currentGame);
    return ArenaScreenBackground(
      child: Column(
        children: [
          const TutorialBannerSection(page: TutorialPage.competitions),
          TabBar(
            controller: _tab,
            indicatorColor: accent,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: ArenaColors.border,
            labelColor: accent,
            unselectedLabelColor: ArenaColors.textMuted,
            labelStyle: ArenaText.button,
            unselectedLabelStyle: ArenaText.button,
            tabs: [
              for (var i = 0; i < _orderedGames.length; i++)
                Tab(
                  child: Text(
                    _tabLabel(_orderedGames[i]),
                    style: ArenaText.button.copyWith(
                      color: _tab.index == i
                          ? accent
                          : ArenaColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                for (final g in _orderedGames)
                  _CompetitionTab(key: ValueKey(g), game: g),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Libellé court et pro (sans emoji) pour l'onglet d'un jeu — `GameType.label`
/// est trop long pour 3 onglets fixes (« EA SPORTS FC Mobile »).
String _tabLabel(GameType g) => switch (g) {
      GameType.draughts => 'Dames',
      GameType.efootball => 'eFootball',
      GameType.eaSportsFc => 'EA FC',
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
  // L'onglet démarre sur « À venir » (plus de menu de filtres groupé : les
  // statuts sont exposés directement en chips ci-dessous). Pas d'option
  // « Toutes » côté user, cf. #168.
  StatusBucket _bucket = StatusBucket.upcoming;
  // Filtre tarif : « Toutes » par défaut (gratuites + payantes).
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusChips(
                current: _bucket,
                onChanged: (b) => setState(() => _bucket = b),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _PricingChips(
                current: _pricing,
                onChanged: (p) => setState(() => _pricing = p),
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
                  .where((c) => _bucket.matches(c.status))
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

}

/// Chips de filtre de statut — remplacent l'ancien menu groupé
/// `ArenaFilterMenu`. Pas d'option « Toutes » (cf. #168) ; trois statuts :
/// à venir / en cours / terminé. L'onglet démarre sur « À venir ».
class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.current, required this.onChanged});

  final StatusBucket current;
  final ValueChanged<StatusBucket> onChanged;

  static const _options = <(StatusBucket, Color)>[
    (StatusBucket.upcoming, ArenaColors.signalBlue),
    (StatusBucket.toReprogram, ArenaColors.statusWarn),
    (StatusBucket.ongoing, ArenaColors.statusWarn),
    (StatusBucket.completed, ArenaColors.silver),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (b, accent) in _options) ...[
            _FilterPill(
              label: b.labelOf(l10n),
              accent: accent,
              active: b == current,
              onTap: () => onChanged(b),
            ),
            const SizedBox(width: ArenaSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Chips de filtre tarif (Toutes / Gratuites / Payantes). « Toutes » par
/// défaut afin d'afficher gratuites + payantes.
class _PricingChips extends StatelessWidget {
  const _PricingChips({required this.current, required this.onChanged});

  final PricingBucket current;
  final ValueChanged<PricingBucket> onChanged;

  static const _options = <(PricingBucket, Color)>[
    (PricingBucket.all, ArenaColors.signalBlue),
    (PricingBucket.free, ArenaColors.statusOk),
    (PricingBucket.paid, ArenaColors.tierGoldWarm),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (p, accent) in _options) ...[
            _FilterPill(
              label: p.labelOf(l10n),
              accent: accent,
              active: p == current,
              onTap: () => onChanged(p),
            ),
            const SizedBox(width: ArenaSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Pastille de filtre générique (statut ou tarif). Active : fond
/// `accent @ 18 %` + border accent, sinon carbon neutre — même style que les
/// chips de l'historique de matchs.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.accent,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.18) : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(color: active ? accent : ArenaColors.border),
        ),
        child: Text(
          label,
          style: ArenaText.button.copyWith(
            color: active ? accent : ArenaColors.silver,
            fontSize: 12,
          ),
        ),
      ),
    );
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
