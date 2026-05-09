import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 9 + PHASE 12.5 — push & in-app notifications feed.
///
/// Backend stream is wired in PHASE 12.5 (Edge Function `dispatch_push`
/// + Supabase `notifications` table). Until then this screen renders a
/// representative sample matching `arena_v2.html` #19 so callers can
/// design layout flows against the final visual.
///
/// Maps to screen #19 of `arena_v2.html`.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final filtered = _samples
        .where((n) => _filter.matches(n.category))
        .toList(growable: false);

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Notifications',
        actions: [
          IconButton(
            tooltip: 'Marquer tout comme lu',
            icon: const Icon(
              Icons.done_all,
              color: ArenaColors.silver,
              size: 18,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ArenaSpacing.lg,
            ArenaSpacing.sm,
            ArenaSpacing.lg,
            ArenaSpacing.lg,
          ),
          children: [
            _FilterChips(
              current: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: ArenaSpacing.md),
            for (var i = 0; i < filtered.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                child: _NotificationCard(notif: filtered[i])
                    .animate(delay: (i * 60).ms)
                    .fadeIn(duration: ArenaDurations.medium)
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _NotificationFilter {
  all('Toutes'),
  match('Matchs'),
  earning('Gains'),
  system('Système');

  const _NotificationFilter(this.label);
  final String label;

  bool matches(_NotificationCategory category) {
    if (this == _NotificationFilter.all) return true;
    return category.name == name;
  }
}

enum _NotificationCategory { match, earning, system }

class _Notification {
  const _Notification({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.emoji,
    required this.color,
    required this.category,
    this.unread = false,
  });

  final String title;
  final String subtitle;
  final String timestamp;
  final String emoji;
  final ArenaAvatarColor color;
  final _NotificationCategory category;
  final bool unread;
}

const _samples = <_Notification>[
  _Notification(
    title: 'Ton match commence dans 5 min !',
    subtitle: 'vs DianaA · FIFA Weekend Cup',
    timestamp: 'Il y a 2 min',
    emoji: '⚽',
    color: ArenaAvatarColor.red,
    category: _NotificationCategory.match,
    unread: true,
  ),
  _Notification(
    title: 'Gain reçu : 25 000 XAF',
    subtitle: 'Top 1 FIFA Cup · Versé sur Orange Money',
    timestamp: 'Il y a 3h',
    emoji: '💰',
    color: ArenaAvatarColor.green,
    category: _NotificationCategory.earning,
  ),
  _Notification(
    title: 'Nouveau tournoi disponible',
    subtitle: 'EA FC Night Battle · 32 places',
    timestamp: 'Hier',
    emoji: '🏆',
    color: ArenaAvatarColor.orange,
    category: _NotificationCategory.system,
  ),
  _Notification(
    title: 'Ta finale va être streamée !',
    subtitle: 'Active la caméra dans la match-room',
    timestamp: 'Hier',
    emoji: '📺',
    color: ArenaAvatarColor.purple,
    category: _NotificationCategory.match,
  ),
  _Notification(
    title: "DianaA t'a envoyé un message",
    subtitle: '"GG, beau match !"',
    timestamp: '2j',
    emoji: '💬',
    color: ArenaAvatarColor.blue,
    category: _NotificationCategory.system,
  ),
];

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.current, required this.onChanged});

  final _NotificationFilter current;
  final ValueChanged<_NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in _NotificationFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: ArenaSpacing.xs),
              child: _Chip(
                label: f.label,
                active: f == current,
                onTap: () => onChanged(f),
              ),
            ),
        ],
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notif});
  final _Notification notif;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: notif.unread
          ? arenaGlowCardDecoration()
          : BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.lg),
              border: Border.all(color: ArenaColors.border),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArenaAvatar(
            initials: notif.emoji,
            color: notif.color,
            size: ArenaAvatarSize.sm,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(notif.subtitle, style: ArenaText.bodyMuted),
                const SizedBox(height: ArenaSpacing.xs),
                Text(
                  notif.timestamp,
                  style: ArenaText.small.copyWith(
                    color: notif.unread
                        ? ArenaColors.signalBlue
                        : ArenaColors.silverDim,
                  ),
                ),
              ],
            ),
          ),
          if (notif.unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                color: ArenaColors.signalBlue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
