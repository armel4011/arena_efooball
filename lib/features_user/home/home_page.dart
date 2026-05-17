import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/home/widgets/active_competitions_section.dart';
import 'package:arena/features_user/home/widgets/home_header.dart';
import 'package:arena/features_user/home/widgets/live_streams_section.dart';
import 'package:arena/features_user/home/widgets/pending_payment_banner.dart';
import 'package:arena/features_user/home/widgets/stat_grid.dart';
import 'package:arena/features_user/home/widgets/upcoming_matches_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User dashboard.
///
/// Maps to screen #9 of `arena_v2.html`. Sections (top → bottom) :
/// 1. Header — avatar, username + tier badge, search + notif bell.
/// 2. ⚡ Prochains matchs — horizontal scroller (réel : `myActiveMatchesProvider`).
/// 3. 🔴 Lives en cours — `activePublicStreamsProvider` top item ou empty.
/// 4. 🏆 Compétitions actives — filter chips fonctionnels + comp cards.
/// 5. 📊 Tes stats — 3-col grid (matchs / V-D-N / win-rate).
///
/// Chaque section a été extraite dans `widgets/` (PR 2026-05-17,
/// refacto P1 audit followup) pour garder ce fichier sous la barre
/// des 200 lignes.
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
          HomeHeader(profile: profile),
          const PendingPaymentBanner(),
          const SizedBox(height: ArenaSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.lg,
            ),
            child: Text('⚡ Prochains matchs', style: ArenaText.h3),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          const UpcomingMatchesScroller(),
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
            child: LiveStreamsSection(),
          ),
          const SizedBox(height: ArenaSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.lg,
            ),
            child: Text('🏆 Compétitions actives', style: ArenaText.h3),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          const ActiveCompetitionsSection(),
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
            child: StatGrid(profile: profile),
          ),
          const SizedBox(height: ArenaSpacing.xl),
        ],
      ),
    );
  }
}
