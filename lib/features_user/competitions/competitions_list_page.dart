import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/payment_repository.dart';
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
/// Maps to screen #10 of `arena_v2.html`. Trois rangées de chips sur le
/// haut (jeu / statut / tarif), puis cards plein-largeur par compétition.
///
/// Le rendu des cards et la logique des filtres sont extraits dans
/// `widgets/` (PR 2026-05-17, refacto P1 audit followup) pour garder
/// cette page sous la barre des 250 lignes.
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
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JEU', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              GameChips(
                selected: _game,
                onChanged: (g) => setState(() => _game = g),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text('STATUS', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              StatusChips(
                selected: _bucket,
                onChanged: (b) => setState(() => _bucket = b),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text('TARIF', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              PricingChips(
                selected: _pricing,
                onChanged: (p) => setState(() => _pricing = p),
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
