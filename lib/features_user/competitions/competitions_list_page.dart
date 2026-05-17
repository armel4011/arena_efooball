import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_shared/widgets/arena_banner.dart' show ArenaBanner;
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/payments/payment_method.dart';
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
  _PricingBucket _pricing = _PricingBucket.all;

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
              const SizedBox(height: ArenaSpacing.sm),
              Text('TARIF', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _PricingChips(
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
                    return _CompetitionListCard(
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

enum _PricingBucket {
  all('Toutes'),
  free('Gratuites'),
  paid('Payantes');

  const _PricingBucket(this.label);
  final String label;

  bool matches(Competition c) => switch (this) {
        _PricingBucket.all => true,
        _PricingBucket.free => c.isFree,
        _PricingBucket.paid => !c.isFree,
      };
}

class _PricingChips extends StatelessWidget {
  const _PricingChips({required this.selected, required this.onChanged});

  final _PricingBucket selected;
  final ValueChanged<_PricingBucket> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _PricingBucket.values.length; i++) ...[
            _Chip(
              label: _PricingBucket.values[i].label,
              active: _PricingBucket.values[i] == selected,
              onTap: () => onChanged(_PricingBucket.values[i]),
            ),
            if (i < _PricingBucket.values.length - 1)
              const SizedBox(width: ArenaSpacing.xs),
          ],
        ],
      ),
    );
  }
}

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

/// Choisit la carte adaptée selon le tarif. Garde la signature unifiée
/// pour la liste, mais le rendu visuel diffère franchement entre les
/// deux modes (cf. design discussion).
class _CompetitionListCard extends StatelessWidget {
  const _CompetitionListCard({
    required this.competition,
    required this.isRegistered,
    required this.hasPendingPayment,
    required this.onTap,
    required this.onRegister,
  });

  final Competition competition;
  final bool isRegistered;

  /// `true` quand un paiement de cet utilisateur sur cette comp est en
  /// `awaiting_admin`. Le bouton CTA passe alors à "VOIR LE STATUT".
  final bool hasPendingPayment;
  final VoidCallback onTap;

  /// `null` quand le joueur est déjà inscrit OU que la comp n'accepte
  /// plus d'inscriptions. Sinon, bouton S'INSCRIRE visible sur la card.
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    return competition.isFree
        ? _FreeCompetitionCard(
            competition: competition,
            isRegistered: isRegistered,
            onTap: onTap,
            onRegister: onRegister,
          )
        : _PaidCompetitionCard(
            competition: competition,
            isRegistered: isRegistered,
            hasPendingPayment: hasPendingPayment,
            onTap: onTap,
            onRegister: onRegister,
          );
  }
}

/// ─── Card "GRATUITE" : layout léger, fond légèrement verdoyant, vibe
/// décontractée. Pas de notion de frais. Aucun élément "trophée".
class _FreeCompetitionCard extends StatelessWidget {
  const _FreeCompetitionCard({
    required this.competition,
    required this.isRegistered,
    required this.onTap,
    required this.onRegister,
  });

  final Competition competition;
  final bool isRegistered;
  final VoidCallback onTap;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final dateLabel =
        DateFormat('d MMM · HH:mm', 'fr').format(c.startDate.toLocal());

    final body = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArenaColors.statusOk.withValues(alpha: 0.10),
              ArenaColors.carbon,
            ],
          ),
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: isRegistered
                ? ArenaColors.statusOk
                : ArenaColors.statusOk.withValues(alpha: 0.35),
            width: isRegistered ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Bloc gauche : badge + emoji
            Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ArenaColors.statusOk.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ArenaColors.statusOk.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _gameEmoji(c.game),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ArenaColors.statusOk.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(ArenaRadius.round),
                  ),
                  child: Text(
                    'GRATUITE',
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.statusOk,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: ArenaSpacing.md),
            // Bloc centre : nom + jeu + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: ArenaText.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.game.label,
                    style: ArenaText.bodyMuted,
                  ),
                  const SizedBox(height: 2),
                  Text('🗓 $dateLabel', style: ArenaText.small),
                  const SizedBox(height: ArenaSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 13, color: ArenaColors.silver,),
                      const SizedBox(width: 3),
                      Text(
                        '${c.currentPlayers}/${c.maxPlayers}',
                        style: ArenaText.small,
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      if (isRegistered)
                        Text(
                          '· ✓ Inscrit',
                          style: ArenaText.small.copyWith(
                            color: ArenaColors.statusOk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: ArenaSpacing.sm),
            const Icon(
              Icons.chevron_right,
              color: ArenaColors.silver,
              size: 22,
            ),
          ],
        ),
      ),
    );

    if (onRegister == null) return body;
    // Card avec bouton S'INSCRIRE en bas — wrap dans Column pour empiler
    // la card cliquable + bouton dédié à l'inscription.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: "✓ M'INSCRIRE GRATUITEMENT",
          fullWidth: true,
          onPressed: onRegister,
        ),
      ],
    );
  }
}

/// ─── Card "PAYANTE" : layout premium avec récompense en or, trophée,
/// glow doré, et footer dédié au prix d'entrée.
class _PaidCompetitionCard extends StatelessWidget {
  const _PaidCompetitionCard({
    required this.competition,
    required this.isRegistered,
    required this.hasPendingPayment,
    required this.onTap,
    required this.onRegister,
  });

  final Competition competition;
  final bool isRegistered;
  final bool hasPendingPayment;
  final VoidCallback onTap;
  final VoidCallback? onRegister;

  static const _gold = Color(0xFFFFC93C);
  static const _goldDeep = Color(0xFFCB9A1F);

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final dateLabel =
        DateFormat('d MMM · HH:mm', 'fr').format(c.startDate.toLocal());
    final prize = _formatPrize(c.prizePoolLocal,
        c.prizePoolCurrency ?? c.registrationCurrency,);

    final body = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          ArenaSpacing.lg,
          ArenaSpacing.md,
          ArenaSpacing.lg,
          ArenaSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x1AFFC93C), // gold tint top
              ArenaColors.carbon, // fades to carbon
            ],
          ),
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: isRegistered
                ? ArenaColors.statusOk
                : _gold.withValues(alpha: 0.4),
            width: isRegistered ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.12),
              blurRadius: 22,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header : emoji + nom + chip PAYANTE ──────────────
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(ArenaRadius.round),
                    border: Border.all(color: _gold.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    'PAYANTE',
                    style: ArenaText.small.copyWith(
                      color: _gold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${c.game.label} · $dateLabel',
              style: ArenaText.bodyMuted,
            ),
            const SizedBox(height: ArenaSpacing.md),

            // ─── Trophée + récompense en gros (gradient or) ──────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_gold, _goldDeep],
                    ),
                    borderRadius:
                        BorderRadius.circular(ArenaRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Text('🏆',
                      style: TextStyle(fontSize: 30),),
                ),
                const SizedBox(width: ArenaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'À GAGNER',
                        style: ArenaText.small.copyWith(
                          color: _gold,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [_gold, _goldDeep],
                        ).createShader(b),
                        child: Text(
                          prize,
                          style: ArenaText.bigNumber.copyWith(
                            fontSize: 30,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ArenaSpacing.md),
            const Divider(height: 1, color: ArenaColors.border),
            const SizedBox(height: ArenaSpacing.sm),

            // ─── Footer : frais + capacité + chip INSCRIT ────────
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 14,
                  color: ArenaColors.silver,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_money(c.registrationFee)} ${c.registrationCurrency}',
                  style: ArenaText.bodyMuted
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: ArenaSpacing.md),
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

    if (onRegister == null) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: hasPendingPayment
              ? '⏱ VOIR LE STATUT DU PAIEMENT'
              : "✓ S'INSCRIRE · "
                  '${_money(c.registrationFee)} ${c.registrationCurrency}',
          variant: hasPendingPayment
              ? ArenaButtonVariant.secondary
              : ArenaButtonVariant.primary,
          fullWidth: true,
          onPressed: onRegister,
        ),
      ],
    );
  }

  static String _formatPrize(double pool, String currency) {
    final formatted = NumberFormat.decimalPattern('fr')
        .format(pool.round())
        .replaceAll(',', ' ');
    return '$formatted $currency';
  }

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
}
