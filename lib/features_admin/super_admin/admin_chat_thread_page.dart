import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin_chat_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// F4 — Page admin : fil de messages prives avec UN user. Accessible
/// via `/super/messages/:userId` (ex. depuis super_admin_users).
class AdminChatThreadPage extends ConsumerStatefulWidget {
  const AdminChatThreadPage({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<AdminChatThreadPage> createState() =>
      _AdminChatThreadPageState();
}

class _AdminChatThreadPageState extends ConsumerState<AdminChatThreadPage> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(adminChatRepositoryProvider).send(
            adminId: adminId,
            recipientId: widget.userId,
            text: txt,
          );
      _ctrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec envoi : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminId = ref.watch(currentSessionProvider)?.user.id;
    if (adminId == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      appBar: const ArenaAppBar(title: 'Chat privé'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<AdminChatMessage>>(
                  stream: ref
                      .read(adminChatRepositoryProvider)
                      .watchThread(adminId: adminId, userId: widget.userId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final msgs = snap.data ?? const [];
                    if (msgs.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun message. Sois le premier à écrire.',
                          style: ArenaText.bodyMuted,
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(ArenaSpacing.md),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) =>
                          _MessageBubble(msg: msgs[i], outgoing: true),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(ArenaSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: ArenaTextField(
                          controller: _ctrl,
                          hint: 'Ton message…',
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                        ),
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      ArenaButton(
                        label: _sending ? '…' : 'ENVOYER',
                        onPressed: _sending ? null : _send,
                        isLoading: _sending,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, required this.outgoing});

  final AdminChatMessage msg;
  final bool outgoing;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: ArenaSpacing.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: outgoing
              ? ArenaColors.neonRed.withValues(alpha: 0.18)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(
            color: outgoing ? ArenaColors.neonRed : ArenaColors.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.text, style: ArenaText.body),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fmt.format(msg.sentAt.toLocal()),
                  style: ArenaText.small,
                ),
                if (outgoing) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.readAt == null ? Icons.done : Icons.done_all,
                    size: 12,
                    color: msg.readAt == null
                        ? ArenaColors.silver
                        : ArenaColors.signalBlue,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
