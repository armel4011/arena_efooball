import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Boîte de support (super-admin) — liste des fils de support entrants
/// (canaux `chat_channels.type='admin_user'`). Tap → fil de discussion.
///
/// Réutilise l'infra de chat générique : [adminSupportThreadsProvider]
/// agrège les canaux + dernier message, [adminSupportUnreadProvider] les
/// compteurs non-lus de l'admin courant.
class SuperAdminSupportInbox extends ConsumerWidget {
  const SuperAdminSupportInbox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(adminSupportThreadsProvider);
    final unread = ref.watch(adminSupportUnreadProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Support'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: threadsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              description: e.toString(),
              onRetry: () => ref.invalidate(adminSupportThreadsProvider),
            ),
            data: (threads) {
              if (threads.isEmpty) {
                return const EmptyState(
                  icon: Icons.support_agent_outlined,
                  title: 'Aucune demande de support',
                  description:
                      'Les messages envoyés par les utilisateurs depuis '
                      '« Contact / Aide » apparaîtront ici.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref
                    ..invalidate(adminSupportThreadsProvider)
                    ..invalidate(adminSupportUnreadProvider);
                  await ref.read(adminSupportThreadsProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(ArenaSpacing.md),
                  itemCount: threads.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: ArenaSpacing.sm),
                  itemBuilder: (context, i) {
                    final t = threads[i];
                    return _SupportThreadCard(
                      thread: t,
                      unreadCount: unread[t.channelId] ?? 0,
                      onTap: () async {
                        await context.push(
                          AdminRoutes.superSupportThreadPath(t.channelId),
                          extra: t.username,
                        );
                        ref
                          ..invalidate(adminSupportThreadsProvider)
                          ..invalidate(adminSupportUnreadProvider);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SupportThreadCard extends StatelessWidget {
  const _SupportThreadCard({
    required this.thread,
    required this.unreadCount,
    required this.onTap,
  });

  final SupportThreadSummary thread;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials =
        thread.username.isEmpty ? '?' : thread.username[0].toUpperCase();
    return ArenaCard(
      onTap: onTap,
      child: Row(
        children: [
          ArenaAvatar(
            initials: initials,
            size: ArenaAvatarSize.md,
            imageUrl: thread.avatarUrl,
          ),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        thread.username,
                        style: ArenaText.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (thread.lastSentAt != null)
                      Text(
                        DateFormat('dd/MM HH:mm')
                            .format(thread.lastSentAt!.toLocal()),
                        style: ArenaText.small,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        thread.lastMessage.isEmpty
                            ? 'Nouvelle conversation'
                            : thread.lastMessage,
                        style: ArenaText.bodyMuted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: ArenaSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: ArenaColors.neonRed,
                          shape: BoxShape.rectangle,
                          borderRadius:
                              BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: ArenaText.small.copyWith(
                            color: ArenaColors.bone,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
