import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_banner.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User dashboard.
///
/// Maps to screen #9 of `arena_v2.html`. Sections (top → bottom):
/// 1. Header — avatar, username + tier badge, search + notif bell.
/// 2. ⚡ Prochains matchs — horizontal-scrolling card list (PHASE 5).
/// 3. 🔴 Lives en cours — full-bleed banner (PHASE 8).
/// 4. 🏆 Compétitions actives — game-filter chips + game banner card
///    (PHASE 4).
/// 5. 📊 Tes stats — 3-col grid (matchs / W-D-L / win-rate).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentProfileProvider);
        await ref.read(currentProfileProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _Header(profile: profile),
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
            child: _LiveStreamCard(),
          ),
          const SizedBox(height: ArenaSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.lg,
            ),
            child: Text('🏆 Compétitions actives', style: ArenaText.h3),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          const _GameFilterChips(),
          const SizedBox(height: ArenaSpacing.sm),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
            child: ArenaBanner(
              game: ArenaBannerGame.fifa,
              title: 'FIFA WEEKEND CUP',
              subtitle: '12/16 · 60 000 XAF · Démarre dans 2j',
            ),
          ),
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

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final username = profile?.username ?? 'Joueur';
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();
    final color = _avatarColorFor(profile?.avatarColor);

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
            onPressed: () {},
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications push : PHASE 12.5 (FCM).'),
                    ),
                  );
                },
              ),
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
                    '3',
                    style: ArenaText.badge.copyWith(
                      color: Colors.white,
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
    // Round-trip the persisted hex to the closest enum entry. We compare
    // against the gradient's first stop colour (the brightest one).
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

class _UpcomingMatchesScroller extends StatelessWidget {
  const _UpcomingMatchesScroller();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
        children: const [
          _UpcomingMatchCard(
            badgeLabel: 'DANS 2H',
            badgeVariant: ArenaBadgeVariant.info,
            game: '⚽ FIFA',
            opponent: 'DianaA',
            opponentInitial: 'D',
            opponentColor: ArenaAvatarColor.green,
            phase: 'Quart de finale',
            glow: true,
          ),
          SizedBox(width: ArenaSpacing.sm),
          _UpcomingMatchCard(
            badgeLabel: 'DEMAIN',
            badgeVariant: ArenaBadgeVariant.warn,
            game: '🎯 EA FC',
            opponent: 'SamuelK',
            opponentInitial: 'S',
            opponentColor: ArenaAvatarColor.cyan,
            phase: '8e de finale',
          ),
        ],
      ),
    );
  }
}

class _UpcomingMatchCard extends StatelessWidget {
  const _UpcomingMatchCard({
    required this.badgeLabel,
    required this.badgeVariant,
    required this.game,
    required this.opponent,
    required this.opponentInitial,
    required this.opponentColor,
    required this.phase,
    this.glow = false,
  });

  final String badgeLabel;
  final ArenaBadgeVariant badgeVariant;
  final String game;
  final String opponent;
  final String opponentInitial;
  final ArenaAvatarColor opponentColor;
  final String phase;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text(game, style: ArenaText.bodyMuted),
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
                  'vs $opponent',
                  style: ArenaText.body
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(phase, style: ArenaText.bodyMuted),
        ],
      ),
    );
  }
}

class _LiveStreamCard extends StatelessWidget {
  const _LiveStreamCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
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
                    Colors.black.withValues(alpha: 0.55),
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
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(ArenaRadius.round),
                  ),
                  child: Text(
                    '👁 1 247',
                    style: ArenaText.badge.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Text(
              'FINALE FIFA WEEKEND CUP',
              style: ArenaText.body.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameFilterChips extends StatelessWidget {
  const _GameFilterChips();

  static const _labels = ['Tous', 'eFoot', 'FIFA', 'FC Mobile'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: i == 0
                    ? ArenaColors.signalBlue.withValues(alpha: 0.15)
                    : ArenaColors.carbon,
                borderRadius:
                    BorderRadius.circular(ArenaRadius.round),
                border: Border.all(
                  color:
                      i == 0 ? ArenaColors.signalBlue : ArenaColors.border,
                ),
              ),
              child: Text(
                _labels[i],
                style: ArenaText.body.copyWith(
                  color: i == 0
                      ? ArenaColors.signalBlue
                      : ArenaColors.silver,
                  fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (i < _labels.length - 1) const SizedBox(width: ArenaSpacing.xs),
          ],
        ],
      ),
    );
  }
}

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
