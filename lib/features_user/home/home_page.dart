import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/home/widgets/active_competitions_section.dart';
import 'package:arena/features_user/home/widgets/home_header.dart';
import 'package:arena/features_user/home/widgets/live_streams_section.dart';
import 'package:arena/features_user/home/widgets/pending_payment_banner.dart';
import 'package:arena/features_user/home/widgets/promo_banner_section.dart';
import 'package:arena/features_user/home/widgets/stat_grid.dart';
import 'package:arena/features_user/home/widgets/tutorial_video_section.dart';
import 'package:arena/features_user/home/widgets/upcoming_matches_section.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// User dashboard — écran #9 de `arena_premium_reference.html`.
///
/// Sections (top→bottom) :
/// 1. `HomeHeader` — avatar, username + tier, search + notif bell.
/// 2. ⚡ NEXT MATCH — scroller horizontal (`myActiveMatchesProvider`),
///    1er match en hero card glow.
/// 3. ● LIVE NOW (caption rouge pulsante + lien View all) —
///    `activePublicStreamsProvider` top item, gradient game-themed.
/// 4. ★ ACTIVE TOURNAMENTS (caption gold) — filter chips + 3 banners
///    game-themed (eFoot / Dames / FC).
/// 5. 📊 YOUR STATS — grille 3-col (`profile.stats`).
///
/// Captions stylisées : `_SectionCaption` reproduit `m-text-caption`
/// de la maquette (uppercase, mono small, color marker) + dot pulsant
/// optionnel pour le marqueur LIVE.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return ArenaScreenBackground(
      child: RefreshIndicator(
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
            const PromoBannerSection(),
            const TutorialBannerSection(page: TutorialPage.home),
            const SizedBox(height: ArenaSpacing.lg),
            _SectionCaption(
              label: l10n.homeSectionNextMatch,
              color: ArenaColors.signalBlue,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const UpcomingMatchesScroller(),
            const SizedBox(height: ArenaSpacing.xl),
            _SectionCaption(
              label: l10n.homeSectionLive,
              color: ArenaColors.neonRed,
              showDot: true,
              trailing: _ViewAllLink(
                onTap: () => context.push(UserRoutes.liveStreams),
              ),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
              child: LiveStreamsSection(),
            ),
            const SizedBox(height: ArenaSpacing.xl),
            _SectionCaption(
              label: l10n.homeSectionActiveTournaments,
              color: ArenaColors.gold,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const ActiveCompetitionsSection(),
            const SizedBox(height: ArenaSpacing.xl),
            _SectionCaption(
              label: l10n.homeSectionYourStats,
              color: ArenaColors.silver,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
              child: StatGrid(profile: profile),
            ),
            const SizedBox(height: ArenaSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Caption uppercase coloré qui démarque chaque section de la home.
/// Reproduit `.m-text-caption` de la maquette : mono small, letter-spacing
/// 1.5, color marker (signalBlue / neonRed / gold / silver). `showDot`
/// active un point pulsant 1.5s (utilisé uniquement pour le marqueur LIVE
/// rouge), `trailing` accueille typiquement un `_ViewAllLink`.
class _SectionCaption extends StatelessWidget {
  const _SectionCaption({
    required this.label,
    required this.color,
    this.showDot = false,
    this.trailing,
  });
  final String label;
  final Color color;
  final bool showDot;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      child: Row(
        children: [
          if (showDot) ...[
            _PulsingDot(color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: ArenaText.monoSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

/// Point pulsant 1.5s — opacity 0.5→1.0 avec glow proportionnel. Sert
/// d'indicateur LIVE animé en tête de la caption "LIVE NOW".
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = 0.5 + 0.5 * _ctrl.value;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: t),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: t * 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lien "View all →" en fin de caption — mono small silver pour rester
/// discret, tap déclenche la nav vers la liste complète.
class _ViewAllLink extends StatelessWidget {
  const _ViewAllLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.homeViewAllLink,
              style: ArenaText.monoSmall.copyWith(
                color: ArenaColors.silver,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.arrow_forward,
              size: 11,
              color: ArenaColors.silver,
            ),
          ],
        ),
      ),
    );
  }
}
