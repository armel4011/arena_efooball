import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';

/// PHASE 11 · A9 — admin competition detail with 6 tabs.
///
/// Tabs (admin variant): Infos / Particip. / Bracket / Matchs / Disputes
/// / Payouts. Header is full-bleed with the game gradient. Bracket tab
/// ships first because it carries the admin actions surface (validate
/// score / mark dispute / cancel match) used most often during ops.
///
/// Maps to screen A9 of `arena_v2.html`.
class AdminCompetitionDetailPage extends StatelessWidget {
  const AdminCompetitionDetailPage({
    required this.competitionId,
    this.competitionName = 'FIFA WEEKEND CUP',
    super.key,
  });

  final String competitionId;
  final String competitionName;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      initialIndex: 2,
      child: Scaffold(
        appBar: ArenaAppBar(
          title: competitionName,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz, color: ArenaColors.silver),
              onPressed: () {},
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(name: competitionName, ref: '#$competitionId'),
              const _AdminTabs(),
              const Expanded(child: _BracketTab()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.ref});

  final String name;
  final String ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: const BoxDecoration(gradient: ArenaColors.bannerFifa),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ArenaBadge(
                label: 'LIVE — QUARTS',
                variant: ArenaBadgeVariant.live,
              ),
              const Spacer(),
              Text(
                ref,
                style: ArenaText.monoSmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(name, style: ArenaText.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            '12/16 inscrits · Récompense 60 000 XAF',
            style: ArenaText.bodyMuted.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTabs extends StatelessWidget {
  const _AdminTabs();

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      labelStyle: ArenaText.button,
      unselectedLabelStyle: ArenaText.button,
      labelColor: ArenaColors.bone,
      unselectedLabelColor: ArenaColors.silver,
      indicatorColor: ArenaColors.signalBlue,
      indicatorWeight: 2,
      tabs: const [
        Tab(text: 'INFOS'),
        Tab(text: 'PARTICIP.'),
        Tab(text: 'BRACKET'),
        Tab(text: 'MATCHS'),
        Tab(text: 'DISPUTES'),
        Tab(text: 'PAYOUTS'),
      ],
    );
  }
}

class _BracketTab extends StatelessWidget {
  const _BracketTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      children: [
        Text('QUARTS DE FINALE', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.sm),
        const _MatchRow(
          status: ArenaBadgeVariant.live,
          statusLabel: 'EN COURS',
          ref: 'M-4287',
          home: 'KevinM',
          homeColor: ArenaAvatarColor.blue,
          homeScore: '2',
          away: 'DianaA',
          awayColor: ArenaAvatarColor.green,
          awayScore: '1',
          showActions: true,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        const _MatchRow(
          status: ArenaBadgeVariant.info,
          statusLabel: 'À VENIR',
          ref: '15:30',
          home: 'SamuelK',
          homeColor: ArenaAvatarColor.cyan,
          homeScore: '—',
          away: 'FatimaH',
          awayColor: ArenaAvatarColor.pink,
          awayScore: '—',
        ),
        const SizedBox(height: ArenaSpacing.lg),
        Text(
          '⚡ ACTIONS ADMIN',
          style: ArenaText.inputLabel.copyWith(color: ArenaColors.neonRed),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: '✏ MODIFIER COMPÉTITION',
          variant: ArenaButtonVariant.secondary,
          fullWidth: true,
          onPressed: () {},
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaButton(
          label: '▶ FORCER DÉMARRAGE',
          variant: ArenaButtonVariant.secondary,
          fullWidth: true,
          onPressed: () {},
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaButton(
          label: '🚫 ANNULER (refund all)',
          variant: ArenaButtonVariant.danger,
          fullWidth: true,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.status,
    required this.statusLabel,
    required this.ref,
    required this.home,
    required this.homeColor,
    required this.homeScore,
    required this.away,
    required this.awayColor,
    required this.awayScore,
    this.showActions = false,
  });

  final ArenaBadgeVariant status;
  final String statusLabel;
  final String ref;
  final String home;
  final ArenaAvatarColor homeColor;
  final String homeScore;
  final String away;
  final ArenaAvatarColor awayColor;
  final String awayScore;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: status == ArenaBadgeVariant.live
              ? ArenaColors.signalBlue
              : ArenaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ArenaBadge(label: statusLabel, variant: status),
              const Spacer(),
              Text(ref, style: ArenaText.monoSmall),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _PlayerRow(
            name: home,
            color: homeColor,
            score: homeScore,
            initial: home[0],
          ),
          const SizedBox(height: 4),
          _PlayerRow(
            name: away,
            color: awayColor,
            score: awayScore,
            initial: away[0],
          ),
          if (showActions) ...[
            const SizedBox(height: ArenaSpacing.sm),
            ArenaButton(
              label: '⚙ ACTIONS ADMIN',
              variant: ArenaButtonVariant.secondary,
              fullWidth: true,
              onPressed: () {},
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.name,
    required this.color,
    required this.score,
    required this.initial,
  });

  final String name;
  final ArenaAvatarColor color;
  final String score;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ArenaAvatar(
          initials: initial,
          color: color,
          size: ArenaAvatarSize.sm,
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(child: Text(name, style: ArenaText.body)),
        Text(score, style: ArenaText.bigNumber.copyWith(fontSize: 18)),
      ],
    );
  }
}
