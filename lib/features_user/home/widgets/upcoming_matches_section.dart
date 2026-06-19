import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/home/widgets/home_error_row.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Scroller horizontal des matchs actifs du joueur connecté.
/// Source : `myActiveMatchesProvider` + batch des profils opponents
/// via `profilesByIdsProvider`.
class UpcomingMatchesScroller extends ConsumerWidget {
  const UpcomingMatchesScroller({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentSessionProvider)?.user.id;
    final matchesAsync = ref.watch(myActiveMatchesProvider);

    return SizedBox(
      height: 110,
      child: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => HomeErrorRow(message: l10n.upcomingMatchesError(e)),
        data: (matches) {
          if (matches.isEmpty || me == null) {
            return _ScrollerEmpty(
              icon: Icons.event_available_outlined,
              label: l10n.upcomingMatchesEmpty,
            );
          }
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
    final l10n = AppLocalizations.of(context);
    final (badgeLabel, badgeVariant, glow) = _resolveBadge(match, l10n);
    final opponentName = opponent?.username ?? l10n.upcomingMatchOpponentWaiting;
    final opponentInitial =
        opponentName.isEmpty ? '?' : opponentName[0].toUpperCase();
    final opponentColor = opponent == null
        ? ArenaAvatarColor.blue
        : _avatarFromHex(opponent!.avatarColor);
    final phaseLabel = _phaseLabel(match, l10n);

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
                    l10n.upcomingMatchLive,
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
                  imageUrl: opponent?.avatarUrl,
                ),
                const SizedBox(width: ArenaSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.upcomingMatchVsOpponent(opponentName),
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

  static (String, ArenaBadgeVariant, bool) _resolveBadge(
    ArenaMatch m,
    AppLocalizations l10n,
  ) {
    if (m.status == MatchStatus.inProgress ||
        m.status == MatchStatus.scorePending) {
      return (l10n.upcomingBadgeInProgress, ArenaBadgeVariant.live, true);
    }
    final at = m.scheduledAt;
    if (at == null) {
      return (l10n.upcomingBadgeToSchedule, ArenaBadgeVariant.warn, false);
    }
    final now = DateTime.now();
    final diff = at.difference(now);
    if (diff.isNegative) {
      return (l10n.upcomingBadgeReady, ArenaBadgeVariant.info, true);
    }
    if (diff.inHours < 3) return (l10n.upcomingBadgeInHours(diff.inHours), ArenaBadgeVariant.info, true);
    if (diff.inHours < 24) return (l10n.upcomingBadgeInHours(diff.inHours), ArenaBadgeVariant.info, false);
    if (diff.inDays < 2) return (l10n.upcomingBadgeTomorrow, ArenaBadgeVariant.warn, false);
    return (l10n.upcomingBadgeInDays(diff.inDays), ArenaBadgeVariant.warn, false);
  }

  static String _phaseLabel(ArenaMatch m, AppLocalizations l10n) {
    if (m.round == null) return l10n.upcomingPhaseMatch;
    final r = m.round!;
    return switch (r) {
      1 => l10n.upcomingPhaseFinal,
      2 => l10n.upcomingPhaseSemiFinal,
      3 => l10n.upcomingPhaseQuarterFinal,
      4 => l10n.upcomingPhaseRoundOf16,
      5 => l10n.upcomingPhaseRoundOf32,
      _ => l10n.upcomingPhaseRound(r),
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
