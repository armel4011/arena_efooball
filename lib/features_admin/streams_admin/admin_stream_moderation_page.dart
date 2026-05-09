import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:flutter/material.dart';

/// PHASE 11 · A12 — multi-stream moderation grid.
///
/// 2x2 (or larger) grid of mini Agora subscribers, capped at 6 active
/// streams per moderator session. Each tile carries a kill-switch that
/// disconnects the broadcaster + a chat shortcut. Bottom card shows the
/// global chat aggregated across streams.
///
/// Maps to screen A12 of `arena_v2.html`.
class AdminStreamModerationPage extends StatelessWidget {
  const AdminStreamModerationPage({super.key});

  static const _streams = <_Stream>[
    _Stream(
      label: 'FIFA · Finale',
      players: 'KevinM vs DianaA',
      viewers: 1247,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A3A6C), Color(0xFF2C0A1F)],
      ),
      flagged: true,
    ),
    _Stream(
      label: 'eFoot · Demi',
      players: 'SamuelK vs LindaO',
      viewers: 432,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A3A1A), Color(0xFF0A1A0A)],
      ),
    ),
    _Stream(
      label: 'EA FC · Quart',
      players: 'PaulN vs FatimaH',
      viewers: 218,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3A2200), Color(0xFF1A0A00)],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Modération streams',
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
            const _SummaryCard(),
            const SizedBox(height: ArenaSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 0.95,
              crossAxisSpacing: ArenaSpacing.xs,
              mainAxisSpacing: ArenaSpacing.xs,
              children: [
                for (final s in _streams) _StreamTile(stream: s),
                const _EmptySlot(used: 3, total: 6),
              ],
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text(
              'CHAT GLOBAL — TOUS STREAMS',
              style: ArenaText.inputLabel,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _ChatRow(
              initial: 'L',
              color: ArenaAvatarColor.purple,
              user: 'LindaO',
              streamRef: 'stream FIFA',
              message: 'Allez Diana 🔥',
            ),
            const SizedBox(height: ArenaSpacing.md),
            Container(
              padding: const EdgeInsets.all(ArenaSpacing.md),
              decoration: arenaWarningCardDecoration(),
              child: Text(
                '⚠ Couper un stream est journalisé dans admin_audit_log '
                'avec ton ID admin.',
                style: ArenaText.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stream {
  const _Stream({
    required this.label,
    required this.players,
    required this.viewers,
    required this.gradient,
    this.flagged = false,
  });

  final String label;
  final String players;
  final int viewers;
  final LinearGradient gradient;
  final bool flagged;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: arenaGlowCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3 streams actifs', style: ArenaText.h3),
                const SizedBox(height: 2),
                Text('Sur 6 max simultanés', style: ArenaText.bodyMuted),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const ArenaBadge(
                label: 'LIVE',
                variant: ArenaBadgeVariant.live,
              ),
              const SizedBox(height: 4),
              Text(
                '1 897 👁',
                style: ArenaText.mono.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreamTile extends StatelessWidget {
  const _StreamTile({required this.stream});

  final _Stream stream;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: stream.flagged ? ArenaColors.neonRed : ArenaColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(gradient: stream.gradient),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: const ArenaBadge(
                  label: 'LIVE',
                  variant: ArenaBadgeVariant.live,
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
                    borderRadius:
                        BorderRadius.circular(ArenaRadius.round),
                  ),
                  child: Text(
                    '👁 ${stream.viewers}',
                    style: ArenaText.badge.copyWith(color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                child: Text(
                  stream.label,
                  style: ArenaText.body.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  stream.players,
                  style: ArenaText.body.copyWith(fontSize: 9),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _MiniButton(
                        label: '🔇 COUPER',
                        onTap: () {},
                        danger: true,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _MiniButton(label: '💬', onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.used, required this.total});

  final int used;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: ArenaColors.silverDim,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+',
              style: ArenaText.bigNumber.copyWith(
                color: ArenaColors.silverDim,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text('Slot libre', style: ArenaText.bodyMuted),
            const SizedBox(height: 2),
            Text(
              '$used/$total utilisés',
              style: ArenaText.small,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: danger ? ArenaColors.neonRed : ArenaColors.carbon2,
          borderRadius: BorderRadius.circular(ArenaRadius.sm),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: ArenaText.badge.copyWith(
            color: Colors.white,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.initial,
    required this.color,
    required this.user,
    required this.streamRef,
    required this.message,
  });

  final String initial;
  final ArenaAvatarColor color;
  final String user;
  final String streamRef;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArenaAvatar(
            initials: initial,
            color: color,
            size: ArenaAvatarSize.sm,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: ArenaText.bodyMuted,
                    children: [
                      TextSpan(
                        text: user,
                        style: ArenaText.body.copyWith(
                          color: ArenaColors.neonRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' · $streamRef'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(message, style: ArenaText.body),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Bannir',
            iconSize: 18,
            color: ArenaColors.neonRed,
            icon: const Icon(Icons.block),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
