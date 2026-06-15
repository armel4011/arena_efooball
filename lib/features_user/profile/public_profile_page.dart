import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/friendship.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/avatar_palette.dart';
import 'package:arena/features_shared/player_tier.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Phase 13 — Profil public d'un autre joueur (`/profile/u/:username`).
///
/// Affiche : avatar + username + pays + stats (depuis profiles.stats jsonb,
/// alimenté par `recalculate_player_stats`) + 10 derniers matchs +
/// bouton ajouter/accepter/retirer/bloquer/débloquer selon l'état de
/// l'amitié entre `me` et le profil consulté.
class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({required this.username, super.key});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(publicProfileByUsernameProvider(username));
    return Scaffold(
      backgroundColor: ArenaColors.void_,
      appBar: ArenaAppBar(title: l10n.publicProfileAppBarTitle),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: l10n.publicProfileError(e)),
        data: (profile) {
          if (profile == null) {
            return _ErrorState(message: l10n.publicProfilePlayerNotFound);
          }
          return _PublicProfileBody(profile: profile);
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: ArenaText.body.copyWith(color: ArenaColors.danger),
        ),
      ),
    );
  }
}

class _PublicProfileBody extends ConsumerWidget {
  const _PublicProfileBody({required this.profile});

  final Profile profile;

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(publicProfileByUsernameProvider(profile.username))
      ..invalidate(friendshipBetweenProvider(profile.id))
      ..invalidate(playerRecentMatchesProvider(profile.id));
    await ref.read(publicProfileByUsernameProvider(profile.username).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentSessionProvider)?.user.id;
    final friendshipAsync = me == null
        ? const AsyncValue<Friendship?>.data(null)
        : ref.watch(friendshipBetweenProvider(profile.id));
    final recentAsync = ref.watch(playerRecent10MatchesProvider(profile.id));
    final isSelf = me == profile.id;

    final ctaState = isSelf
        ? null
        : friendshipAsync.maybeWhen(
            data: (f) => f.ctaStateFor(me!),
            orElse: () => FriendCtaState.none,
          );

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        children: [
          _Header(profile: profile),
          const SizedBox(height: ArenaSpacing.lg),
          if (!isSelf && ctaState != null)
            _FriendCtaSection(
              profile: profile,
              state: ctaState,
              friendshipAsync: friendshipAsync,
            ),
          if (!isSelf) const SizedBox(height: ArenaSpacing.lg),
          _StatsCard(stats: profile.stats),
          const SizedBox(height: ArenaSpacing.lg),
          Text(
            l10n.publicProfileRecentMatchesHeader,
            style: ArenaTypography.labelMedium,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _RecentMatches(playerId: profile.id, asyncMatches: recentAsync),
          const SizedBox(height: ArenaSpacing.xl),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final Profile profile;

  int _wins() {
    final v = profile.stats['wins'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = AvatarPalette.colorFromHex(profile.avatarColor);
    final initial =
        profile.username.isEmpty ? '?' : profile.username[0].toUpperCase();
    final tier = tierFor(_wins());

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
                  profile.countryCode,
                  style: ArenaTypography.bodySmall.copyWith(
                    color: ArenaColors.textMuted,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                _TierBadge(
                  label: _publicTierLabel(l10n, tier),
                  gradient: tier.gradient,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Traduit un [PlayerTier] en libellé localisé pour le badge public.
String _publicTierLabel(AppLocalizations l10n, PlayerTier tier) =>
    switch (tier) {
      PlayerTier.bronze => l10n.playerProfileTierBronze,
      PlayerTier.silver => l10n.playerProfileTierSilver,
      PlayerTier.gold => l10n.playerProfileTierGold,
      PlayerTier.elite => l10n.playerProfileTierElite,
    };

/// Tier badge — variante profil public, couleur dérivée du palier réel.
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.label, required this.gradient});

  final String label;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(
          color: ArenaColors.bone,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _FriendCtaSection extends ConsumerStatefulWidget {
  const _FriendCtaSection({
    required this.profile,
    required this.state,
    required this.friendshipAsync,
  });

  final Profile profile;
  final FriendCtaState state;
  final AsyncValue<Friendship?> friendshipAsync;

  @override
  ConsumerState<_FriendCtaSection> createState() => _FriendCtaSectionState();
}

class _FriendCtaSectionState extends ConsumerState<_FriendCtaSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() op, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await op();
      if (success != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success)),
        );
      }
      ref
        ..invalidate(friendshipBetweenProvider(widget.profile.id))
        ..invalidate(acceptedFriendsProvider)
        ..invalidate(incomingFriendRequestsProvider)
        ..invalidate(outgoingFriendRequestsProvider)
        ..invalidate(blockedByMeProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: ArenaColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(friendsRepositoryProvider);
    final p = widget.profile;

    switch (widget.state) {
      case FriendCtaState.none:
        return ArenaButton(
          label: l10n.publicProfileCtaAddFriend,
          icon: Icons.person_add_alt_1_outlined,
          variant: ArenaButtonVariant.primary,
          fullWidth: true,
          isLoading: _busy,
          onPressed: () => _run(
            () => repo.sendRequest(p.id),
            success: l10n.publicProfileRequestSent(p.username),
          ),
        );
      case FriendCtaState.outgoingPending:
        final fid = widget.friendshipAsync.value?.id;
        return Column(
          children: [
            ArenaButton(
              label: l10n.publicProfileCtaRequestSent,
              icon: Icons.schedule,
              variant: ArenaButtonVariant.secondary,
              fullWidth: true,
              onPressed: null,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            ArenaButton(
              label: l10n.publicProfileCtaCancel,
              icon: Icons.close,
              variant: ArenaButtonVariant.ghost,
              fullWidth: true,
              isLoading: _busy,
              onPressed: fid == null
                  ? null
                  : () => _run(
                        () => repo.decline(fid),
                        success: l10n.publicProfileRequestCancelled,
                      ),
            ),
          ],
        );
      case FriendCtaState.incomingPending:
        final fid = widget.friendshipAsync.value?.id;
        return Row(
          children: [
            Expanded(
              child: ArenaButton(
                label: l10n.publicProfileCtaAccept,
                icon: Icons.check,
                variant: ArenaButtonVariant.primary,
                isLoading: _busy,
                onPressed: fid == null
                    ? null
                    : () => _run(
                          () => repo.accept(fid),
                          success: l10n.publicProfileNowFriend(p.username),
                        ),
              ),
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: ArenaButton(
                label: l10n.publicProfileCtaDecline,
                icon: Icons.close,
                variant: ArenaButtonVariant.ghost,
                isLoading: _busy,
                onPressed: fid == null
                    ? null
                    : () => _run(
                          () => repo.decline(fid),
                          success: l10n.publicProfileRequestDeclined,
                        ),
              ),
            ),
          ],
        );
      case FriendCtaState.friends:
        return Column(
          children: [
            ArenaButton(
              label: l10n.publicProfileCtaFriend,
              icon: Icons.check_circle_outline,
              variant: ArenaButtonVariant.secondary,
              fullWidth: true,
              onPressed: null,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ArenaButton(
                    label: l10n.publicProfileCtaRemove,
                    icon: Icons.person_remove_outlined,
                    variant: ArenaButtonVariant.ghost,
                    isLoading: _busy,
                    onPressed: () => _confirmAndRun(
                      title: l10n.publicProfileRemoveConfirmTitle(p.username),
                      action: () => repo.remove(p.id),
                      successMsg: l10n.publicProfileFriendRemoved,
                    ),
                  ),
                ),
                const SizedBox(width: ArenaSpacing.sm),
                Expanded(
                  child: ArenaButton(
                    label: l10n.publicProfileCtaBlock,
                    icon: Icons.block,
                    variant: ArenaButtonVariant.danger,
                    isLoading: _busy,
                    onPressed: () => _confirmAndRun(
                      title: l10n.publicProfileBlockConfirmTitle(p.username),
                      detail: l10n.publicProfileBlockConfirmDetail,
                      action: () => repo.block(p.id),
                      successMsg: l10n.publicProfilePlayerBlocked,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case FriendCtaState.blockedByMe:
        return ArenaButton(
          label: l10n.publicProfileCtaUnblock,
          icon: Icons.lock_open,
          variant: ArenaButtonVariant.secondary,
          fullWidth: true,
          isLoading: _busy,
          onPressed: () => _run(
            () => repo.unblock(p.id),
            success: l10n.publicProfilePlayerUnblocked,
          ),
        );
      case FriendCtaState.blockedByThem:
        return ArenaButton(
          label: l10n.publicProfileCtaUnavailable,
          icon: Icons.block,
          variant: ArenaButtonVariant.ghost,
          fullWidth: true,
          onPressed: null,
        );
    }
  }

  Future<void> _confirmAndRun({
    required String title,
    required Future<void> Function() action,
    required String successMsg,
    String? detail,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.surface,
        title: Text(title, style: ArenaTypography.titleMedium),
        content:
            detail == null ? null : Text(detail, style: ArenaTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.publicProfileDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.publicProfileDialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(action, success: successMsg);
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final Map<String, dynamic> stats;

  int _read(String key) {
    final v = stats[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final wins = _read('wins');
    final losses = _read('losses');
    final draws = _read('draws');
    final goalsScored = _read('goals_scored');
    final goalsConceded = _read('goals_conceded');
    final total = wins + losses + draws;
    final ratio = total == 0 ? 0.0 : wins / total;
    final pct = (ratio * 100).round();
    final l10n = AppLocalizations.of(context);

    return ArenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.publicProfileStatsHeader, style: ArenaTypography.labelMedium),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              _StatTile(
                label: l10n.publicProfileStatWin,
                value: '$wins',
                color: ArenaColors.success,
              ),
              _StatTile(
                label: l10n.publicProfileStatLoss,
                value: '$losses',
                color: ArenaColors.danger,
              ),
              _StatTile(
                label: l10n.publicProfileStatDraw,
                value: '$draws',
                color: ArenaColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.publicProfileWinRateLabel,
                style: ArenaTypography.bodySmall.copyWith(
                  color: ArenaColors.textMuted,
                ),
              ),
              Text(
                total == 0 ? '—' : l10n.publicProfileWinRateValue(pct, total),
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
              valueColor:
                  const AlwaysStoppedAnimation(ArenaColors.success),
            ),
          ),
          const SizedBox(height: ArenaSpacing.md),
          Row(
            children: [
              Expanded(
                child: _GoalLine(
                  label: l10n.publicProfileGoalsScored,
                  value: goalsScored,
                  color: ArenaColors.success,
                ),
              ),
              Expanded(
                child: _GoalLine(
                  label: l10n.publicProfileGoalsConceded,
                  value: goalsConceded,
                  color: ArenaColors.danger,
                ),
              ),
            ],
          ),
        ],
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
    final l10n = AppLocalizations.of(context);
    return asyncMatches.when(
      loading: () => const ArenaCard(
        child: SizedBox(
          height: 64,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => ArenaCard(
        child: Text(
          l10n.publicProfileMatchRowError(e),
          style: ArenaText.body.copyWith(color: ArenaColors.danger),
        ),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          return ArenaCard(
            child: Text(
              l10n.publicProfileNoCompletedMatches,
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

enum _Outcome { win, loss, draw }

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result});
  final _Outcome result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (result) {
      _Outcome.win => (l10n.publicProfileResultWin, ArenaColors.success),
      _Outcome.loss => (l10n.publicProfileResultLoss, ArenaColors.danger),
      _Outcome.draw => (l10n.publicProfileResultDraw, ArenaColors.textMuted),
    };
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
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
