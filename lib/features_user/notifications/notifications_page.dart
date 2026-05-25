import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_notification.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// PHASE 10 — push & in-app notifications feed.
///
/// Reads `public.notifications` via [userNotificationsProvider] (Supabase
/// realtime). FCM dispatch lives in PHASE 12.5 — the rows themselves are
/// already inserted today by the Edge Functions that close matches /
/// validate scores, so the in-app feed lights up even without push.
///
/// Maps to screen #19 of `arena_v2.html`.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final userId = profile?.id;

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
            onPressed: userId == null ? null : () => _markAllRead(userId),
          ),
        ],
      ),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: userId == null
              ? const _SignedOutPlaceholder()
              : _NotificationsList(
                  userId: userId,
                  filter: _filter,
                  onFilterChanged: (v) => setState(() => _filter = v),
                  onTap: _onTap,
                ),
        ),
      ),
    );
  }

  Future<void> _markAllRead(String userId) async {
    final repo = ref.read(notificationRepositoryProvider);
    try {
      await repo.markAllRead(userId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de tout marquer comme lu.')),
      );
    }
  }

  Future<void> _onTap(ArenaNotification notif) async {
    final repo = ref.read(notificationRepositoryProvider);
    if (notif.isUnread) {
      unawaited(
        repo.markRead(notif.id).catchError(
              (Object e) => debugPrint('markRead failed for ${notif.id}: $e'),
            ),
      );
    }
    final route = notif.route;
    if (!mounted) return;
    if (route != null) {
      context.go(route);
    }
  }
}

class _NotificationsList extends ConsumerWidget {
  const _NotificationsList({
    required this.userId,
    required this.filter,
    required this.onFilterChanged,
    required this.onTap,
  });

  final String userId;
  final _NotificationFilter filter;
  final ValueChanged<_NotificationFilter> onFilterChanged;
  final ValueChanged<ArenaNotification> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(userNotificationsProvider(userId));

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Text(
            'Erreur de chargement.\n$e',
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
        ),
      ),
      data: (rows) {
        final filtered = rows
            .where((n) => filter.matches(_categorize(n)))
            .toList(growable: false);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            ArenaSpacing.lg,
            ArenaSpacing.sm,
            ArenaSpacing.lg,
            ArenaSpacing.lg,
          ),
          children: [
            _FilterChips(current: filter, onChanged: onFilterChanged),
            const SizedBox(height: ArenaSpacing.md),
            if (filtered.isEmpty)
              const _EmptyState()
            else
              for (var i = 0; i < filtered.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                  child: _NotificationCard(
                    notif: filtered[i],
                    onTap: () => onTap(filtered[i]),
                  )
                      .animate(delay: (i * 60).ms)
                      .fadeIn(duration: ArenaDurations.medium)
                      .slideY(
                        begin: 0.05,
                        end: 0,
                        curve: Curves.easeOutCubic,
                      ),
                ),
          ],
        );
      },
    );
  }
}

class _SignedOutPlaceholder extends StatelessWidget {
  const _SignedOutPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Text(
          'Connecte-toi pour voir tes notifications.',
          textAlign: TextAlign.center,
          style: ArenaText.bodyMuted,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.xxl),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: ArenaColors.silverDim,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            'Aucune notification pour le moment.',
            style: ArenaText.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ],
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

/// Routes a row's `type` string to one of the three feed buckets shown
/// in the filter chips. Unknown types fall into `system`.
_NotificationCategory _categorize(ArenaNotification n) {
  switch (n.type) {
    case 'match_starting':
    case 'match_score_to_validate':
    case 'match_finished':
    case 'stream_live':
      return _NotificationCategory.match;
    case 'payout_received':
    case 'payment_completed':
      return _NotificationCategory.earning;
    default:
      return _NotificationCategory.system;
  }
}

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
  const _NotificationCard({required this.notif, required this.onTap});

  final ArenaNotification notif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(notif);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: notif.isUnread
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
              initials: visual.emoji,
              color: visual.color,
              size: ArenaAvatarSize.sm,
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: ArenaText.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((notif.body ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(notif.body!, style: ArenaText.bodyMuted),
                  ],
                  const SizedBox(height: ArenaSpacing.xs),
                  Text(
                    _formatTimestamp(notif.createdAt),
                    style: ArenaText.small.copyWith(
                      color: notif.isUnread
                          ? ArenaColors.signalBlue
                          : ArenaColors.silverDim,
                    ),
                  ),
                ],
              ),
            ),
            if (notif.isUnread)
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
      ),
    );
  }
}

class _NotifVisual {
  const _NotifVisual({required this.emoji, required this.color});
  final String emoji;
  final ArenaAvatarColor color;
}

_NotifVisual _visualFor(ArenaNotification n) {
  switch (n.type) {
    case 'match_starting':
      return const _NotifVisual(emoji: '⚽', color: ArenaAvatarColor.red);
    case 'match_score_to_validate':
    case 'match_finished':
      return const _NotifVisual(emoji: '✅', color: ArenaAvatarColor.green);
    case 'stream_live':
      return const _NotifVisual(emoji: '📺', color: ArenaAvatarColor.purple);
    case 'competition_starting':
      return const _NotifVisual(emoji: '🏆', color: ArenaAvatarColor.orange);
    case 'payout_received':
    case 'payment_completed':
      return const _NotifVisual(emoji: '💰', color: ArenaAvatarColor.green);
    case 'dispute_opened':
      return const _NotifVisual(emoji: '⚠️', color: ArenaAvatarColor.orange);
    case 'chat_message':
      return const _NotifVisual(emoji: '💬', color: ArenaAvatarColor.blue);
    default:
      return const _NotifVisual(emoji: '🔔', color: ArenaAvatarColor.blue);
  }
}

/// French relative timestamp ("Il y a 5 min", "Hier", "3j"). Kept inline
/// because no other screen needs this exact format — every other clock
/// in the app shows absolute times.
String _formatTimestamp(DateTime? at) {
  if (at == null) return '';
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'Hier';
  if (diff.inDays < 7) return '${diff.inDays}j';
  return '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}';
}
