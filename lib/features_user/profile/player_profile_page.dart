import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/player_stats.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:arena/data/repositories/referral_repository.dart';
import 'package:arena/features_shared/avatar_palette.dart';
import 'package:arena/features_shared/player_tier.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/home/widgets/tutorial_video_section.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'player_profile_social.dart';
part 'player_profile_widgets.dart';

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

    return ArenaScreenBackground(
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: Text(
              AppLocalizations.of(context).playerProfileError(e),
              textAlign: TextAlign.center,
              style: ArenaText.body.copyWith(color: ArenaColors.danger),
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                AppLocalizations.of(context).playerProfileUnavailable,
                style: ArenaText.bodyMuted,
              ),
            );
          }
          return _ProfileBody(profile: profile);
        },
      ),
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
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(playerStatsProvider(profile.id));
    final recentAsync = ref.watch(playerRecentMatchesProvider(profile.id));

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        children: [
          const TutorialBannerSection(page: TutorialPage.profile),
          _Header(
            profile: profile,
            wins: statsAsync.valueOrNull?.wins ?? 0,
          ),
          const SizedBox(height: ArenaSpacing.lg),
          _StatsRow(stats: statsAsync),
          const SizedBox(height: ArenaSpacing.lg),
          Text(
            l10n.playerProfileSuccessHeader,
            style: ArenaText.monoSmall.copyWith(
              color: ArenaColors.silver,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _AchievementsRow(stats: statsAsync),
          const SizedBox(height: ArenaSpacing.lg),
          const _FriendsSection(),
          const SizedBox(height: ArenaSpacing.lg),
          const _ReferralBadgeCard(),
          const SizedBox(height: ArenaSpacing.lg),
          Text(
            l10n.playerProfileRecentMatchesHeader,
            style: ArenaText.monoSmall.copyWith(
              color: ArenaColors.silver,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _RecentMatches(playerId: profile.id, asyncMatches: recentAsync),
          const SizedBox(height: ArenaSpacing.xl),
          // Accès à la page Paiements & gains : l'utilisateur y voit ses
          // versements et RÉCLAME ses gains (onglet GAINS → « À réclamer »).
          ArenaButton(
            label: l10n.playerProfilePaymentsButton,
            icon: Icons.payments_outlined,
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => context.push(UserRoutes.paymentHistory),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: l10n.playerProfileSettingsButton,
            icon: Icons.settings_outlined,
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => context.push(UserRoutes.settings),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: l10n.playerProfileSignOutButton,
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
