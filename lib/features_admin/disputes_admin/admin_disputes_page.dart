import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';

/// PHASE 11 · A14 — dispute resolution screen.
///
/// Top warning card carries the escalation level + open duration. Below
/// : the disputed scores, the cloud-recorded replay thumbnail, the
/// match-room chat (read-only), three admin verdict CTAs and a
/// mandatory justification text-area for the audit log.
///
/// Maps to screen A14 of `arena_v2.html`.
class AdminDisputesPage extends StatefulWidget {
  const AdminDisputesPage({required this.matchId, super.key});

  final String matchId;

  @override
  State<AdminDisputesPage> createState() => _AdminDisputesPageState();
}

class _AdminDisputesPageState extends State<AdminDisputesPage> {
  final _justificationCtrl = TextEditingController();

  @override
  void dispose() {
    _justificationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Dispute · ${widget.matchId}',
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
            const _DisputeHeader(),
            const SizedBox(height: ArenaSpacing.lg),
            Text('SCORES SAISIS', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            const _ScoresCard(),
            const SizedBox(height: ArenaSpacing.lg),
            Text('PREUVES', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            const _ReplayCard(),
            const SizedBox(height: ArenaSpacing.lg),
            Text('💬 Chat match-room', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            const _ChatPreview(),
            const SizedBox(height: ArenaSpacing.lg),
            Text(
              '⚖ TRANCHER',
              style: ArenaText.inputLabel.copyWith(color: ArenaColors.neonRed),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            ArenaButton(
              label: '✓ VALIDER SCORE 3-1 (AhmedB gagne)',
              fullWidth: true,
              onPressed: () {},
            ),
            const SizedBox(height: ArenaSpacing.xs),
            ArenaButton(
              label: '✓ VALIDER SCORE 2-3 (PaulN gagne)',
              fullWidth: true,
              onPressed: () {},
            ),
            const SizedBox(height: ArenaSpacing.xs),
            ArenaButton(
              label: '🚫 ANNULER MATCH (refund 2× 5000)',
              variant: ArenaButtonVariant.danger,
              fullWidth: true,
              onPressed: () {},
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text('Justification (obligatoire)', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.xs),
            ArenaTextField(
              controller: _justificationCtrl,
              hint: 'Explique ta décision pour audit…',
              minLines: 3,
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
}

class _DisputeHeader extends StatelessWidget {
  const _DisputeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaWarningCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ArenaBadge(
                label: 'ESCALADE NIVEAU 2',
                variant: ArenaBadgeVariant.warn,
              ),
              const Spacer(),
              Text(
                'Ouverte il y a 1h 23min',
                style: ArenaText.bodyMuted,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text('Désaccord persistant sur score', style: ArenaText.h3),
          const SizedBox(height: 2),
          Text(
            '2 votes consécutifs en désaccord',
            style: ArenaText.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _ScoresCard extends StatelessWidget {
  const _ScoresCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          _Row(
            initial: 'A',
            color: ArenaAvatarColor.orange,
            label: 'AhmedB (HOME)',
            score: '3 - 1',
            scoreColor: ArenaColors.gameFifa,
          ),
          const Divider(
            color: ArenaColors.border,
            height: 1,
            thickness: 1,
          ),
          _Row(
            initial: 'P',
            color: ArenaAvatarColor.red,
            label: 'PaulN (AWAY)',
            score: '2 - 3',
            scoreColor: ArenaColors.neonRed,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.initial,
    required this.color,
    required this.label,
    required this.score,
    required this.scoreColor,
  });

  final String initial;
  final ArenaAvatarColor color;
  final String label;
  final String score;
  final Color scoreColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      child: Row(
        children: [
          ArenaAvatar(
            initials: initial,
            color: color,
            size: ArenaAvatarSize.sm,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(child: Text(label, style: ArenaText.body)),
          Text(
            score,
            style: ArenaText.mono.copyWith(
              color: scoreColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayCard extends StatelessWidget {
  const _ReplayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 80,
                decoration: const BoxDecoration(gradient: ArenaColors.bannerFifa),
              ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(ArenaRadius.round),
                  ),
                  child: Text(
                    '🎬 9:42',
                    style: ArenaText.badge.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(ArenaSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recording AhmedB',
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Match auto-recorded · cloud',
                  style: ArenaText.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatPreview extends StatelessWidget {
  const _ChatPreview();

  static const _msgs = <(_BubbleSide, String)>[
    (_BubbleSide.them, 'Code : 8K3-TZ9'),
    (_BubbleSide.me, 'GG, beau match.'),
    (_BubbleSide.them, "Comment tu as compté 1-3 ? J'ai marqué 3 fois."),
    (_BubbleSide.me, 'Non, ton 3e but était hors-jeu.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          for (final (side, text) in _msgs)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Align(
                alignment: side == _BubbleSide.me
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: side == _BubbleSide.me
                        ? ArenaColors.signalBlue
                        : ArenaColors.carbon2,
                    borderRadius: BorderRadius.circular(ArenaRadius.md),
                  ),
                  child: Text(
                    text,
                    style: ArenaText.body.copyWith(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _BubbleSide { me, them }
