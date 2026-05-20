import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/player_stats.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:arena/data/repositories/referral_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/profile/avatar_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tab "Profil" of the user app (PHASE 9.1).
///
/// Mounted by `MainLayout` under tab index 3, so it has no AppBar of its
/// own — the parent scaffold supplies it. Pulls the authenticated
/// profile from [currentProfileProvider] and the W/L stats from
/// [playerStatsProvider]; both providers refresh on pull-to-refresh.
class PlayerProfilePage extends ConsumerWidget {
  const PlayerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Text(
            'Erreur: $e',
            textAlign: TextAlign.center,
            style: ArenaText.body.copyWith(color: ArenaColors.danger),
          ),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return Center(
            child: Text(
              'Profil indisponible. Reconnecte-toi.',
              style: ArenaText.bodyMuted,
            ),
          );
        }
        return _ProfileBody(profile: profile);
      },
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final Profile profile;

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(currentProfileProvider)
      ..invalidate(playerStatsProvider(profile.id))
      ..invalidate(playerRecentMatchesProvider(profile.id))
      // Le compteur d'invités est un FutureProvider (pas de Realtime sur
      // `profiles`) : sans cette invalidation il reste figé au pull-to-refresh.
      ..invalidate(myReferralCountProvider);
    await ref.read(currentProfileProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatsProvider(profile.id));
    final recentAsync = ref.watch(playerRecentMatchesProvider(profile.id));

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        children: [
          _Header(profile: profile),
          const SizedBox(height: ArenaSpacing.lg),
          const _FriendsSection(),
          const SizedBox(height: ArenaSpacing.lg),
          const _ReferralBadgeCard(),
          const SizedBox(height: ArenaSpacing.lg),
          _StatsCard(stats: statsAsync),
          const SizedBox(height: ArenaSpacing.lg),
          Text('MATCHS RÉCENTS', style: ArenaTypography.labelMedium),
          const SizedBox(height: ArenaSpacing.sm),
          _RecentMatches(playerId: profile.id, asyncMatches: recentAsync),
          const SizedBox(height: ArenaSpacing.xl),
          ArenaButton(
            label: 'PARAMÈTRES',
            icon: Icons.settings_outlined,
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => context.push(UserRoutes.settings),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: 'SE DÉCONNECTER',
            icon: Icons.logout,
            variant: ArenaButtonVariant.ghost,
            fullWidth: true,
            onPressed: () => ref.read(signOutProvider)(),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final color = AvatarPalette.colorFromHex(profile.avatarColor);
    final initial =
        profile.username.isEmpty ? '?' : profile.username[0].toUpperCase();

    return ArenaCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 28,
                  spreadRadius: -2,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: ArenaTypography.headlineLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.username, style: ArenaTypography.headlineMedium),
                const SizedBox(height: 2),
                Text(
                  '${profile.countryCode} • ${profile.email}',
                  style: ArenaTypography.bodySmall.copyWith(
                    color: ArenaColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier',
            onPressed: () => context.push(UserRoutes.profileEdit),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final AsyncValue<PlayerStats> stats;

  @override
  Widget build(BuildContext context) {
    return stats.when(
      loading: () => const ArenaCard(
        child: SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => ArenaCard(
        child: Text(
          'Stats indisponibles ($e)',
          style: ArenaText.body.copyWith(color: ArenaColors.danger),
        ),
      ),
      data: (s) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: ArenaRadius.card,
          boxShadow: [
            BoxShadow(
              color: ArenaColors.primary.withValues(alpha: 0.22),
              blurRadius: 36,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ArenaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STATS', style: ArenaTypography.labelMedium),
              const SizedBox(height: ArenaSpacing.sm),
              Row(
                children: [
                  _StatTile(
                    label: 'V',
                    value: '${s.wins}',
                    color: ArenaColors.success,
                  ),
                  _StatTile(
                    label: 'D',
                    value: '${s.losses}',
                    color: ArenaColors.danger,
                  ),
                  _StatTile(
                    label: 'N',
                    value: '${s.draws}',
                    color: ArenaColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: ArenaSpacing.md),
              _RatioRow(ratio: s.winRatio, totalMatches: s.totalMatches),
              const SizedBox(height: ArenaSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _GoalLine(
                      label: 'Buts marqués',
                      value: s.goalsScored,
                      color: ArenaColors.success,
                    ),
                  ),
                  Expanded(
                    child: _GoalLine(
                      label: 'Buts encaissés',
                      value: s.goalsConceded,
                      color: ArenaColors.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: ArenaTypography.displayMedium.copyWith(color: color),
          ),
          Text(
            label,
            style: ArenaTypography.labelMedium.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatioRow extends StatelessWidget {
  const _RatioRow({required this.ratio, required this.totalMatches});

  final double ratio;
  final int totalMatches;

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Taux de victoire',
              style: ArenaTypography.bodySmall.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
            Text(
              totalMatches == 0 ? '—' : '$pct% ($totalMatches matchs)',
              style: ArenaTypography.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: ArenaColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(ArenaColors.success),
          ),
        ),
      ],
    );
  }
}

class _GoalLine extends StatelessWidget {
  const _GoalLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ArenaTypography.bodySmall.copyWith(
            color: ArenaColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: ArenaTypography.headlineMedium.copyWith(color: color),
        ),
      ],
    );
  }
}

class _RecentMatches extends StatelessWidget {
  const _RecentMatches({
    required this.playerId,
    required this.asyncMatches,
  });

  final String playerId;
  final AsyncValue<List<ArenaMatch>> asyncMatches;

  @override
  Widget build(BuildContext context) {
    return asyncMatches.when(
      loading: () => const ArenaCard(
        child: SizedBox(
          height: 64,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => ArenaCard(
        child: Text(
          'Erreur: $e',
          style: ArenaText.body.copyWith(color: ArenaColors.danger),
        ),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          return ArenaCard(
            child: Text(
              'Aucun match complété pour le moment.',
              style: ArenaTypography.bodyMedium.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final m in matches)
              Padding(
                padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                child: _MatchRow(playerId: playerId, match: m),
              ),
          ],
        );
      },
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.playerId, required this.match});

  final String playerId;
  final ArenaMatch match;

  @override
  Widget build(BuildContext context) {
    final isP1 = match.player1Id == playerId;
    final myScore = isP1 ? match.score1 : match.score2;
    final theirScore = isP1 ? match.score2 : match.score1;

    final result = match.winnerId == null
        ? _Outcome.draw
        : match.winnerId == playerId
            ? _Outcome.win
            : _Outcome.loss;

    return ArenaCard(
      onTap: () => context.push(UserRoutes.matchPath(match.id)),
      padding: const EdgeInsets.symmetric(
        vertical: ArenaSpacing.sm,
        horizontal: ArenaSpacing.md,
      ),
      child: Row(
        children: [
          _ResultBadge(result: result),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Text(
              'Match #${match.id.substring(0, 8)}',
              style: ArenaTypography.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${myScore ?? '-'} : ${theirScore ?? '-'}',
            style: ArenaTypography.labelLarge,
          ),
        ],
      ),
    );
  }
}

/// Phase 13 — Section "Mes amis" dans le tab profil. Affiche un compteur
/// total d'amis acceptés + un badge si demandes pending entrantes ;
/// tap → /friends. Le badge utilise un stream realtime de la table
/// `friendships` pour se mettre à jour sans navigation.
class _FriendsSection extends ConsumerWidget {
  const _FriendsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(incomingFriendRequestsCountProvider);
    final friendsAsync = ref.watch(acceptedFriendsProvider);

    final pending = pendingAsync.maybeWhen(data: (v) => v, orElse: () => 0);
    final friendsCount =
        friendsAsync.maybeWhen(data: (v) => v.length, orElse: () => 0);

    return ArenaCard(
      onTap: () => context.push(UserRoutes.friends),
      padding: const EdgeInsets.symmetric(
        vertical: ArenaSpacing.md,
        horizontal: ArenaSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ArenaColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.people_outline,
              color: ArenaColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Mes amis', style: ArenaTypography.bodyMedium),
                    if (pending > 0) ...[
                      const SizedBox(width: ArenaSpacing.sm),
                      _PendingBadge(count: pending),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  friendsCount == 0
                      ? 'Aucun ami pour le moment'
                      : '$friendsCount ami${friendsCount > 1 ? 's' : ''}',
                  style: ArenaTypography.bodySmall.copyWith(
                    color: ArenaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: ArenaColors.textMuted),
        ],
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ArenaColors.danger,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: ArenaTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum _Outcome { win, loss, draw }

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result});

  final _Outcome result;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (result) {
      _Outcome.win => ('V', ArenaColors.success),
      _Outcome.loss => ('D', ArenaColors.danger),
      _Outcome.draw => ('N', ArenaColors.textMuted),
    };
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: result == _Outcome.draw
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: ArenaTypography.labelLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Item 2 prompt 2026-05-19 — Badge parrainage sur la page Profil.
///
/// Montre : code parrainage (tap to copy) + nombre de filleuls actifs +
/// rappel du perk "accès auto aux compétitions gratuites à récompense
/// conditionnée" pour les users qui atteignent le quota requis par la
/// compétition. La logique de gating elle-même vit côté DB (trigger
/// `enforce_referral_quota_on_registration`) ; ce badge n'est qu'un
/// indicateur informatif.
class _ReferralBadgeCard extends ConsumerWidget {
  const _ReferralBadgeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeAsync = ref.watch(myReferralCodeProvider);
    final countAsync = ref.watch(myReferralCountProvider);

    final code = codeAsync.valueOrNull;
    final count = countAsync.valueOrNull ?? 0;

    return ArenaCard(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.group_add_outlined,
                color: ArenaColors.tierGoldWarm,
                size: 22,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Text(
                  'Mon parrainage',
                  style: ArenaTypography.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ArenaColors.tierGoldWarm.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: ArenaColors.tierGoldWarm.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '$count invité${count > 1 ? 's' : ''}',
                  style: ArenaTypography.labelMedium.copyWith(
                    color: ArenaColors.tierGoldWarm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          if (code != null && code.isNotEmpty)
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code parrainage copié'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.md,
                  vertical: ArenaSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: ArenaColors.void_,
                  borderRadius: BorderRadius.circular(ArenaRadius.md),
                  border: Border.all(color: ArenaColors.tierGoldWarm),
                ),
                child: Row(
                  children: [
                    Text(
                      code,
                      style: ArenaTypography.titleMedium.copyWith(
                        color: ArenaColors.bone,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.copy_outlined,
                      size: 18,
                      color: ArenaColors.tierGoldWarm,
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              'Génération du code en cours…',
              style: ArenaText.bodyMuted,
            ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'Partage ton code pour parrainer des amis. Une fois ton '
            'quota atteint, tu accèdes automatiquement aux compétitions '
            'gratuites avec récompense conditionnée.',
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
        ],
      ),
    );
  }
}
