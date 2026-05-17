import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// User dashboard.
///
/// Maps to screen #9 of `arena_v2.html`. Sections (top → bottom):
/// 1. Header — avatar, username + tier badge, search + notif bell.
/// 2. ⚡ Prochains matchs — horizontal scroller (réel : `myActiveMatchesProvider`).
/// 3. 🔴 Lives en cours — `activePublicStreamsProvider` top item ou empty.
/// 4. 🏆 Compétitions actives — filter chips fonctionnels + comp cards.
/// 5. 📊 Tes stats — 3-col grid (matchs / V-D-N / win-rate).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(currentProfileProvider)
          ..invalidate(myActiveMatchesProvider)
          ..invalidate(activePublicStreamsProvider);
        await ref.read(currentProfileProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _Header(profile: profile),
          const _PendingPaymentBanner(),
          const SizedBox(height: ArenaSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.lg,
            ),
            child: Text('⚡ Prochains matchs', style: ArenaText.h3),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          const _UpcomingMatchesScroller(),
          const SizedBox(height: ArenaSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.lg,
            ),
            child: Text('🔴 Lives en cours', style: ArenaText.h3),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
            child: _LiveStreamsSection(),
          ),
          const SizedBox(height: ArenaSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.lg,
            ),
            child: Text('🏆 Compétitions actives', style: ArenaText.h3),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          const _ActiveCompetitionsSection(),
          const SizedBox(height: ArenaSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.lg,
            ),
            child: Text('📊 Tes stats', style: ArenaText.h3),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.lg,
            ),
            child: _StatGrid(profile: profile),
          ),
          const SizedBox(height: ArenaSpacing.xl),
        ],
      ),
    );
  }
}

/// Banner d'alerte affiché en haut de la home quand le joueur a au
/// moins un paiement en `awaiting_admin`. Tap → ré-ouvre P3 sur la
/// transaction la plus récente.
class _PendingPaymentBanner extends ConsumerWidget {
  const _PendingPaymentBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(myPaymentsProvider).valueOrNull ?? const [];
    final pending = payments
        .where((p) => p.status == 'awaiting_admin')
        .toList(growable: false);
    if (pending.isEmpty) return const SizedBox.shrink();
    final p = pending.first;
    final method = PaymentMethod.fromCode(p.payerMethod ?? 'MTN_MOMO');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.sm,
        ArenaSpacing.lg,
        0,
      ),
      child: InkWell(
        onTap: () => context.push(
          UserRoutes.paymentProcessing,
          extra: PaymentProcessingArgs(
            paymentId: p.id,
            method: method,
            amountXaf: p.amountLocal.round(),
            competitionName: 'Compétition',
            maskedPhone: p.payerPhone ?? '+••• •• •• ••',
          ),
        ),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: ArenaColors.signalBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(ArenaRadius.lg),
            border: Border.all(
              color: ArenaColors.signalBlue.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ArenaColors.signalBlue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('⏱', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending.length == 1
                          ? 'Paiement en attente de validation'
                          : '${pending.length} paiements en attente',
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tape pour vérifier le statut',
                      style: ArenaText.small,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: ArenaColors.signalBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = profile?.username ?? 'Joueur';
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();
    final color = _avatarColorFor(profile?.avatarColor);
    final unread = profile == null
        ? 0
        : ref.watch(unreadNotificationCountProvider(profile!.id));

    return Container(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.md,
        ArenaSpacing.lg,
        ArenaSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ArenaColors.border),
        ),
      ),
      child: Row(
        children: [
          ArenaAvatar(initials: initial, color: color),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: ArenaText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                const ArenaBadge(
                  label: '🥉 BRONZE',
                  variant: ArenaBadgeVariant.tierBronze,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.search,
              color: ArenaColors.silver,
              size: 20,
            ),
            tooltip: 'Rechercher un joueur',
            onPressed: () => context.push(UserRoutes.friendsSearch),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: ArenaColors.silver,
                  size: 20,
                ),
                onPressed: () => context.go(UserRoutes.notifications),
              ),
              if (unread > 0)
                Positioned(
                  top: 6,
                  right: 4,
                  child: Container(
                    width: 13,
                    height: 13,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: ArenaColors.neonRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: ArenaText.badge.copyWith(
                        color: ArenaColors.bone,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static ArenaAvatarColor _avatarColorFor(String? hex) {
    if (hex == null) return ArenaAvatarColor.blue;
    final cleaned = hex.replaceAll('#', '').trim().toUpperCase();
    return switch (cleaned) {
      'FF6B6B' || 'E03131' || _ when cleaned.startsWith('FF') &&
              cleaned.endsWith('5F5') =>
        ArenaAvatarColor.red,
      _ => ArenaAvatarColor.blue,
    };
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Prochains matchs
// ──────────────────────────────────────────────────────────────────────────────
class _UpcomingMatchesScroller extends ConsumerWidget {
  const _UpcomingMatchesScroller();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentSessionProvider)?.user.id;
    final matchesAsync = ref.watch(myActiveMatchesProvider);

    return SizedBox(
      height: 110,
      child: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRow(message: 'Erreur : $e'),
        data: (matches) {
          if (matches.isEmpty || me == null) {
            return const _ScrollerEmpty(
              icon: Icons.event_available_outlined,
              label: 'Aucun match programmé',
            );
          }
          // Récupère les opponents en batch (1 round-trip).
          final opponentIds = <String>{
            for (final m in matches)
              if (m.player1Id == me && m.player2Id != null) m.player2Id!
              else if (m.player2Id == me && m.player1Id != null) m.player1Id!
              else if (m.player1Id != null && m.player1Id != me) m.player1Id!
              else if (m.player2Id != null && m.player2Id != me) m.player2Id!,
          };
          final key = (opponentIds.toList()..sort()).join(',');
          final peersAsync = ref.watch(profilesByIdsProvider(key));
          final peers = peersAsync.maybeWhen(
            data: (m) => m,
            orElse: () => const <String, Profile>{},
          );
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
            itemCount: matches.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: ArenaSpacing.sm),
            itemBuilder: (ctx, i) {
              final m = matches[i];
              final opponentId = m.player1Id == me ? m.player2Id : m.player1Id;
              final opponent = opponentId == null ? null : peers[opponentId];
              return _UpcomingMatchCard(match: m, opponent: opponent);
            },
          );
        },
      ),
    );
  }
}

class _UpcomingMatchCard extends StatelessWidget {
  const _UpcomingMatchCard({required this.match, required this.opponent});

  final ArenaMatch match;
  final Profile? opponent;

  @override
  Widget build(BuildContext context) {
    final (badgeLabel, badgeVariant, glow) = _resolveBadge(match);
    final opponentName = opponent?.username ?? 'En attente';
    final opponentInitial =
        opponentName.isEmpty ? '?' : opponentName[0].toUpperCase();
    final opponentColor = opponent == null
        ? ArenaAvatarColor.blue
        : _avatarFromHex(opponent!.avatarColor);
    final phaseLabel = _phaseLabel(match);

    return InkWell(
      onTap: () => context.push(UserRoutes.matchPath(match.id)),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(ArenaSpacing.sm),
        decoration: glow
            ? arenaGlowCardDecoration()
            : BoxDecoration(
                color: ArenaColors.carbon,
                borderRadius: BorderRadius.circular(ArenaRadius.lg),
                border: Border.all(color: ArenaColors.border),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ArenaBadge(label: badgeLabel, variant: badgeVariant),
                const Spacer(),
                if (match.status == MatchStatus.inProgress)
                  Text(
                    'LIVE',
                    style: ArenaText.bodyMuted.copyWith(
                      color: ArenaColors.neonRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Row(
              children: [
                ArenaAvatar(
                  initials: opponentInitial,
                  color: opponentColor,
                  size: ArenaAvatarSize.sm,
                ),
                const SizedBox(width: ArenaSpacing.xs),
                Expanded(
                  child: Text(
                    'vs $opponentName',
                    style: ArenaText.body
                        .copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(phaseLabel, style: ArenaText.bodyMuted),
          ],
        ),
      ),
    );
  }

  static (String, ArenaBadgeVariant, bool) _resolveBadge(ArenaMatch m) {
    if (m.status == MatchStatus.inProgress ||
        m.status == MatchStatus.scorePending) {
      return ('EN COURS', ArenaBadgeVariant.live, true);
    }
    final at = m.scheduledAt;
    if (at == null) {
      return ('À PLANIFIER', ArenaBadgeVariant.warn, false);
    }
    final now = DateTime.now();
    final diff = at.difference(now);
    if (diff.isNegative) {
      return ('PRÊT', ArenaBadgeVariant.info, true);
    }
    if (diff.inHours < 3) return ('DANS ${diff.inHours}H', ArenaBadgeVariant.info, true);
    if (diff.inHours < 24) return ('DANS ${diff.inHours}H', ArenaBadgeVariant.info, false);
    if (diff.inDays < 2) return ('DEMAIN', ArenaBadgeVariant.warn, false);
    return ('DANS ${diff.inDays}J', ArenaBadgeVariant.warn, false);
  }

  static String _phaseLabel(ArenaMatch m) {
    if (m.round == null) return 'Match';
    final r = m.round!;
    return switch (r) {
      1 => 'Finale',
      2 => 'Demi-finale',
      3 => 'Quart de finale',
      4 => '8e de finale',
      5 => '16e de finale',
      _ => 'Round $r',
    };
  }

  static ArenaAvatarColor _avatarFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '').toUpperCase();
    if (cleaned.startsWith('FF')) return ArenaAvatarColor.red;
    if (cleaned.startsWith('69')) return ArenaAvatarColor.green;
    if (cleaned.startsWith('3B') || cleaned.startsWith('15')) {
      return ArenaAvatarColor.cyan;
    }
    if (cleaned.startsWith('F7')) return ArenaAvatarColor.orange;
    if (cleaned.startsWith('97') || cleaned.startsWith('84')) {
      return ArenaAvatarColor.purple;
    }
    return ArenaAvatarColor.blue;
  }
}

class _ScrollerEmpty extends StatelessWidget {
  const _ScrollerEmpty({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: ArenaColors.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.lg,
          vertical: ArenaSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: ArenaColors.silver, size: 22),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Text(label, style: ArenaText.bodyMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      child: Text(message, style: const TextStyle(color: ArenaColors.danger)),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Lives en cours
// ──────────────────────────────────────────────────────────────────────────────
class _LiveStreamsSection extends ConsumerWidget {
  const _LiveStreamsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activePublicStreamsProvider);
    return async.when(
      loading: () => const _LiveLoadingCard(),
      error: (e, _) => _ErrorRow(message: 'Erreur : $e'),
      data: (streams) {
        if (streams.isEmpty) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.lg),
              border: Border.all(color: ArenaColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              'Aucun live en cours.',
              style: ArenaText.bodyMuted,
            ),
          );
        }
        final top = streams.first;
        return _LiveStreamCard(stream: top, allCount: streams.length);
      },
    );
  }
}

class _LiveLoadingCard extends StatelessWidget {
  const _LiveLoadingCard();
  @override
  Widget build(BuildContext context) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: ArenaColors.border),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
}

class _LiveStreamCard extends StatelessWidget {
  const _LiveStreamCard({required this.stream, required this.allCount});

  final MatchStream stream;
  final int allCount;

  @override
  Widget build(BuildContext context) {
    final matchId = stream.matchId;
    return InkWell(
      onTap: () => context.push(UserRoutes.watchStreamPath(matchId)),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        height: 80,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: ArenaColors.bannerFifa,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      ArenaColors.void_.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Row(
                children: [
                  const ArenaBadge(
                    label: 'LIVE',
                    variant: ArenaBadgeVariant.live,
                  ),
                  if (allCount > 1) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ArenaColors.void_.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(ArenaRadius.round),
                      ),
                      child: Text(
                        '+${allCount - 1} autres',
                        style:
                            ArenaText.badge.copyWith(color: ArenaColors.bone),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                'Match #${stream.matchId.substring(0, 8)} • Tape pour regarder',
                style: ArenaText.body.copyWith(
                  color: ArenaColors.bone,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Compétitions actives
// ──────────────────────────────────────────────────────────────────────────────
final _homeGameFilterProvider = StateProvider<GameType?>((_) => null);

class _ActiveCompetitionsSection extends ConsumerWidget {
  const _ActiveCompetitionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_homeGameFilterProvider);
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
              style: const TextStyle(color: ArenaColors.danger),
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
                    _CompetitionCard(competition: c),
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
    final current = ref.watch(_homeGameFilterProvider);
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
              onTap: () => ref
                  .read(_homeGameFilterProvider.notifier)
                  .state = items[i].$2,
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
            color:
                selected ? ArenaColors.signalBlue : ArenaColors.border,
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

class _CompetitionCard extends StatelessWidget {
  const _CompetitionCard({required this.competition});
  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final emoji = switch (c.game) {
      GameType.efootball => '⚽',
      GameType.fifaMobile => '🎮',
      GameType.eaSportsFc => '🎯',
    };
    final daysToStart = c.startDate.difference(DateTime.now()).inDays;
    final startLabel = daysToStart > 0
        ? 'Démarre dans ${daysToStart}j'
        : daysToStart == 0
            ? "Démarre aujourd'hui"
            : 'En cours';
    final fee = c.registrationFee.round();
    final feeLabel =
        fee == 0 ? 'Gratuit' : '$fee ${c.registrationCurrency}';

    return InkWell(
      onTap: () => context.push(UserRoutes.competitionPath(c.id)),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: ArenaColors.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: ArenaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: ArenaText.body
                        .copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${c.currentPlayers}/${c.maxPlayers} • $feeLabel • $startLabel',
                    style: ArenaText.bodyMuted,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ArenaColors.silver),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Stats
// ──────────────────────────────────────────────────────────────────────────────
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final stats = profile?.stats ?? const <String, dynamic>{};
    final wins = _asInt(stats['wins']);
    final losses = _asInt(stats['losses']);
    final draws = _asInt(stats['draws']);
    final played = wins + losses + draws;
    final winRate = played == 0 ? 0 : ((wins / played) * 100).round();
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '$played',
            label: 'Matchs',
          ),
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(
          child: _StatTile(
            value: '$wins/$losses/$draws',
            label: 'V/D/N',
            valueColor: ArenaColors.statusOk,
          ),
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(
          child: _StatTile(
            value: played == 0 ? '—' : '$winRate%',
            label: 'Win rate',
          ),
        ),
      ],
    );
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: ArenaSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: ArenaText.bigNumber.copyWith(
              color: valueColor ?? ArenaColors.bone,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: ArenaText.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
