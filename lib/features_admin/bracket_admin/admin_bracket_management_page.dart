import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';

/// PHASE 11 · A11 — admin bracket management.
///
/// Per-match admin actions (activer streaming / valider score / marquer
/// dispute / annuler match) wrapped in a glow card. Greyed-out future
/// rounds (semi-finals + final) reuse the same visual but disable
/// interactions until prerequisite matches finish.
///
/// Maps to screen A11 of `arena_v2.html`.
class AdminBracketManagementPage extends StatelessWidget {
  const AdminBracketManagementPage({
    required this.competitionId,
    super.key,
  });

  final String competitionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Gestion bracket',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: ArenaColors.silver),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            Text(
              'FIFA Weekend Cup · Quarts de finale',
              style: ArenaText.bodyMuted,
            ),
            const SizedBox(height: ArenaSpacing.md),
            _LiveMatchCard(
              ref: 'M-4287 · 42\'',
              home: 'KevinM_237',
              homeInitial: 'K',
              homeColor: ArenaAvatarColor.blue,
              homeScore: '2',
              away: 'DianaA',
              awayInitial: 'D',
              awayColor: ArenaAvatarColor.green,
              awayScore: '1',
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _UpcomingMatchCard(
              ref: 'M-4288',
              startsAt: '15:30',
              home: 'SamuelK',
              homeInitial: 'S',
              homeColor: ArenaAvatarColor.cyan,
              away: 'FatimaH',
              awayInitial: 'F',
              awayColor: ArenaAvatarColor.pink,
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text('DEMI-FINALES', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            const _DimMatch(
              opacity: 0.6,
              top: 'Vainqueur QF1',
              bottom: 'Vainqueur QF2',
              footnote: '📺 Streaming auto activé (semis)',
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text('FINALE', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            const _DimMatch(
              opacity: 0.4,
              top: 'Vainqueur SF1',
              bottom: 'Vainqueur SF2',
              footnote: '📺 Streaming OBLIGATOIRE',
              footnoteColor: ArenaColors.neonRed,
              dashed: true,
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Container(
              padding: const EdgeInsets.all(ArenaSpacing.md),
              decoration: arenaWarningCardDecoration(),
              child: Text(
                '⚠ Toutes les actions sont auditées (admin_audit_log).',
                style: ArenaText.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveMatchCard extends StatelessWidget {
  const _LiveMatchCard({
    required this.ref,
    required this.home,
    required this.homeInitial,
    required this.homeColor,
    required this.homeScore,
    required this.away,
    required this.awayInitial,
    required this.awayColor,
    required this.awayScore,
  });

  final String ref;
  final String home;
  final String homeInitial;
  final ArenaAvatarColor homeColor;
  final String homeScore;
  final String away;
  final String awayInitial;
  final ArenaAvatarColor awayColor;
  final String awayScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.neonRed),
        boxShadow: [
          BoxShadow(
            color: ArenaColors.neonRed.withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ArenaBadge(
                label: 'EN COURS',
                variant: ArenaBadgeVariant.live,
              ),
              const Spacer(),
              Text(ref, style: ArenaText.monoSmall),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _ScoreLine(
            name: home,
            initial: homeInitial,
            color: homeColor,
            score: homeScore,
          ),
          const SizedBox(height: 4),
          _ScoreLine(
            name: away,
            initial: awayInitial,
            color: awayColor,
            score: awayScore,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _SmallActionButton(label: '📺 ACTIVER STREAMING', onTap: () {}),
              _SmallActionButton(label: '✅ VALIDER SCORE', onTap: () {}),
              _SmallActionButton(
                label: '⚠ MARQUER DISPUTE',
                onTap: () {},
                accent: ArenaColors.statusWarn,
              ),
              _SmallActionButton(
                label: '🚫 ANNULER MATCH',
                onTap: () {},
                danger: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingMatchCard extends StatelessWidget {
  const _UpcomingMatchCard({
    required this.ref,
    required this.startsAt,
    required this.home,
    required this.homeInitial,
    required this.homeColor,
    required this.away,
    required this.awayInitial,
    required this.awayColor,
  });

  final String ref;
  final String startsAt;
  final String home;
  final String homeInitial;
  final ArenaAvatarColor homeColor;
  final String away;
  final String awayInitial;
  final ArenaAvatarColor awayColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ArenaBadge(
                label: 'À VENIR · $startsAt',
                variant: ArenaBadgeVariant.info,
              ),
              const Spacer(),
              Text(ref, style: ArenaText.monoSmall),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _ScoreLine(
            name: home,
            initial: homeInitial,
            color: homeColor,
            score: '—',
            muted: true,
          ),
          const SizedBox(height: 4),
          _ScoreLine(
            name: away,
            initial: awayInitial,
            color: awayColor,
            score: '—',
            muted: true,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: '📺 STREAMING',
                  variant: ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ArenaButton(
                  label: '⏰ DÉCALER',
                  variant: ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DimMatch extends StatelessWidget {
  const _DimMatch({
    required this.opacity,
    required this.top,
    required this.bottom,
    required this.footnote,
    this.footnoteColor,
    this.dashed = false,
  });

  final double opacity;
  final String top;
  final String bottom;
  final String footnote;
  final Color? footnoteColor;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: ArenaColors.border,
            style: dashed ? BorderStyle.solid : BorderStyle.solid,
            width: dashed ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(top, style: ArenaText.bodyMuted)),
                Text('—', style: ArenaText.body),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text(bottom, style: ArenaText.bodyMuted)),
                Text('—', style: ArenaText.body),
              ],
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              footnote,
              textAlign: TextAlign.center,
              style: ArenaText.bodyMuted.copyWith(color: footnoteColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({
    required this.name,
    required this.initial,
    required this.color,
    required this.score,
    this.muted = false,
  });

  final String name;
  final String initial;
  final ArenaAvatarColor color;
  final String score;
  final bool muted;

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
        Expanded(
          child: Text(
            name,
            style: muted ? ArenaText.bodyMuted : ArenaText.body,
          ),
        ),
        Text(score, style: ArenaText.bigNumber.copyWith(fontSize: 18)),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.onTap,
    this.danger = false,
    this.accent,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: danger
              ? ArenaColors.neonRed
              : (accent != null
                  ? accent!.withValues(alpha: 0.12)
                  : ArenaColors.carbon),
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(
            color: danger
                ? Colors.transparent
                : (accent ?? ArenaColors.borderHi),
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: danger
                ? Colors.white
                : (accent ?? ArenaColors.bone),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
