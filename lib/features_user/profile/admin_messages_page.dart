import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin_chat_repository.dart';
import 'package:arena/features_admin/super_admin/admin_chat_thread_page.dart'
    show AdminChatBubble;
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// F4 — Inbox user des messages recus de l'admin. Listes en ordre
/// anti-chrono. Au mount on marque les non-lus comme lus.
///
/// Supporte texte / image / image+caption (style WhatsApp). Tap sur
/// l'image -> viewer plein ecran avec pinch-to-zoom.
class AdminMessagesPage extends ConsumerWidget {
  const AdminMessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentSessionProvider)?.user.id;
    if (userId == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final async = ref.watch(userAdminMessagesProvider);
    final repo = ref.read(adminChatRepositoryProvider);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: ArenaAppBar(title: l10n.adminMessagesAppBarTitle),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                l10n.adminMessagesError(e),
                style: ArenaText.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ),
            data: (msgs) {
              if (msgs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(ArenaSpacing.xl),
                    child: Text(
                      l10n.adminMessagesEmpty,
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
                itemBuilder: (_, i) => _UserMessageEntry(msg: msgs[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Un message recu : badge ARENA + dot unread + bulle (texte/image/caption).
class _UserMessageEntry extends StatelessWidget {
  const _UserMessageEntry({required this.msg});
  final AdminChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM HH:mm');
    return Column(
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
        const SizedBox(height: ArenaSpacing.xs),
        AdminChatBubble(msg: msg, outgoing: false),
      ],
    );
  }
}
