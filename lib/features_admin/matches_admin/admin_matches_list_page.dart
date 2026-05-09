import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 11 · A10 — global admin matches list with status filters.
///
/// Status chips (Tous / Pending / In progress / Validated / Disputed)
/// drive a card-list of matches with side-coloured borders.
///
/// Maps to screen A10 of `arena_v2.html`.
class AdminMatchesListPage extends StatefulWidget {
  const AdminMatchesListPage({super.key});

  @override
  State<AdminMatchesListPage> createState() => _AdminMatchesListPageState();
}

class _AdminMatchesListPageState extends State<AdminMatchesListPage> {
  String _filter = 'Tous';

  static const _statuses = [
    'Tous',
    'Pending',
    'In progress',
    'Validated',
    'Disputed',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Tous les matchs',
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: ArenaColors.silver),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            Text('STATUS', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in _statuses)
                    Padding(
                      padding:
                          const EdgeInsets.only(right: ArenaSpacing.xs),
                      child: _Chip(
                        label: s,
                        active: s == _filter,
                        onTap: () => setState(() => _filter = s),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: ArenaSpacing.md),
            const _MatchCard(
              borderColor: ArenaColors.neonRed,
              badgeLabel: 'EN COURS',
              badgeVariant: ArenaBadgeVariant.live,
              ref: 'M-4287',
              home: 'KevinM',
              homeInitial: 'K',
              homeColor: ArenaAvatarColor.blue,
              away: 'DianaA',
              awayInitial: 'D',
              awayColor: ArenaAvatarColor.green,
              score: '2 - 1',
              foot: "FIFA Cup · Quart · 42'",
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _MatchCard(
              borderColor: ArenaColors.statusWarn,
              badgeLabel: 'DISPUTED',
              badgeVariant: ArenaBadgeVariant.warn,
              ref: 'M-4282',
              home: 'AhmedB',
              homeInitial: 'A',
              homeColor: ArenaAvatarColor.orange,
              away: 'PaulN',
              awayInitial: 'P',
              awayColor: ArenaAvatarColor.red,
              score: '2 / 3',
              foot: '⚠ Désaccord sur score',
              footColor: ArenaColors.statusWarn,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _MatchCard(
              borderColor: ArenaColors.statusOk,
              badgeLabel: 'VALIDÉ',
              badgeVariant: ArenaBadgeVariant.success,
              ref: 'M-4280',
              home: 'SamuelK',
              homeInitial: 'S',
              homeColor: ArenaAvatarColor.cyan,
              away: 'PaulN',
              awayInitial: 'P',
              awayColor: ArenaAvatarColor.red,
              score: '4 - 2',
              foot: 'il y a 2h · 🎬 Replay dispo',
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _MatchCard(
              borderColor: ArenaColors.border,
              badgeLabel: 'PENDING',
              badgeVariant: ArenaBadgeVariant.info,
              ref: 'M-4292',
              home: 'LindaO',
              homeInitial: 'L',
              homeColor: ArenaAvatarColor.purple,
              away: 'FatimaH',
              awayInitial: 'F',
              awayColor: ArenaAvatarColor.pink,
              score: '— —',
              foot: 'Démarre 15:30',
            ),
          ],
        ),
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

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.borderColor,
    required this.badgeLabel,
    required this.badgeVariant,
    required this.ref,
    required this.home,
    required this.homeInitial,
    required this.homeColor,
    required this.away,
    required this.awayInitial,
    required this.awayColor,
    required this.score,
    required this.foot,
    this.footColor,
  });

  final Color borderColor;
  final String badgeLabel;
  final ArenaBadgeVariant badgeVariant;
  final String ref;
  final String home;
  final String homeInitial;
  final ArenaAvatarColor homeColor;
  final String away;
  final String awayInitial;
  final ArenaAvatarColor awayColor;
  final String score;
  final String foot;
  final Color? footColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border(
          top: const BorderSide(color: ArenaColors.border),
          right: const BorderSide(color: ArenaColors.border),
          bottom: const BorderSide(color: ArenaColors.border),
          left: BorderSide(color: borderColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ArenaBadge(label: badgeLabel, variant: badgeVariant),
              const Spacer(),
              Text(ref, style: ArenaText.monoSmall),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              ArenaAvatar(
                initials: homeInitial,
                color: homeColor,
                size: ArenaAvatarSize.sm,
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Text(home, style: ArenaText.body),
              const Spacer(),
              Text(
                score,
                style: ArenaText.mono.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(away, style: ArenaText.body),
              const SizedBox(width: ArenaSpacing.xs),
              ArenaAvatar(
                initials: awayInitial,
                color: awayColor,
                size: ArenaAvatarSize.sm,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            foot,
            style: ArenaText.bodyMuted.copyWith(color: footColor),
          ),
        ],
      ),
    ).animate().fadeIn(duration: ArenaDurations.medium);
  }
}
