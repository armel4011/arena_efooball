import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin_chat_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// F4 — Inbox user des messages recus de l'admin. Listes en ordre
/// anti-chrono. Au mount on marque les non-lus comme lus.
class AdminMessagesPage extends ConsumerWidget {
  const AdminMessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentSessionProvider)?.user.id;
    if (userId == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final repo = ref.read(adminChatRepositoryProvider);
    return Scaffold(
      appBar: const ArenaAppBar(title: 'Messages ARENA'),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: StreamBuilder<List<AdminChatMessage>>(
            stream: repo.watchInbox(userId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final msgs = snap.data ?? const [];
              if (msgs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(ArenaSpacing.xl),
                    child: Text(
                      "Aucun message de la part d'ARENA.",
                      style: ArenaText.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              // Mark all unread as read (fire & forget).
              for (final m in msgs) {
                if (m.isUnread) repo.markRead(m.id);
              }
              return ListView.separated(
                padding: const EdgeInsets.all(ArenaSpacing.md),
                itemCount: msgs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: ArenaSpacing.sm),
                itemBuilder: (_, i) => _MessageCard(msg: msgs[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.msg});
  final AdminChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM HH:mm');
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(
          color: msg.isUnread ? ArenaColors.signalBlue : ArenaColors.border,
        ),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 14,
                color: ArenaColors.neonRed,
              ),
              const SizedBox(width: 4),
              Text(
                'ARENA · ${fmt.format(msg.sentAt.toLocal())}',
                style: ArenaText.monoSmall,
              ),
              if (msg.isUnread) ...[
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ArenaColors.signalBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(msg.text, style: ArenaText.body),
        ],
      ),
    );
  }
}
