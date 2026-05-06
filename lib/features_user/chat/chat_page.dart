import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/data/models/chat_channel.dart';
import 'package:arena/data/models/chat_message.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// PHASE 6 — 1-on-1 match chat. Hands the matchId to
/// [matchChannelProvider] which fetches or auto-creates the
/// `type = 'match'` channel, then streams messages from
/// [channelMessagesProvider]. Presence/typing is intentionally absent
/// in V1.0 — Agora RTM lands in PHASE 12.5.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String channelId) async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final selfId = ref.read(currentSessionProvider)?.user.id;
    if (selfId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            channelId: channelId,
            senderId: selfId,
            content: text,
          );
      _inputCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text("Impossible d'envoyer : $e")),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelAsync = ref.watch(matchChannelProvider(widget.matchId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHAT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(UserRoutes.home);
            }
          },
        ),
      ),
      body: channelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          description: e.toString(),
          onRetry: () =>
              ref.invalidate(matchChannelProvider(widget.matchId)),
        ),
        data: _buildChannelBody,
      ),
    );
  }

  Widget _buildChannelBody(ChatChannel channel) {
    final selfId = ref.watch(currentSessionProvider)?.user.id;
    final messagesAsync = ref.watch(channelMessagesProvider(channel.id));

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                description: e.toString(),
                onRetry: () => ref.invalidate(
                  channelMessagesProvider(channel.id),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Pas encore de message',
                    description: 'Sois le premier à écrire ici.',
                  );
                }
                return ListView.builder(
                  reverse: true,
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(ArenaSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    // Stream is oldest → newest. Reverse the indexing so
                    // the newest message sits at the bottom of the
                    // (reversed) ListView.
                    final msg = messages[messages.length - 1 - i];
                    return _Bubble(
                      message: msg,
                      isSelf: msg.senderId == selfId,
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1, color: ArenaColors.border),
          _MessageInput(
            controller: _inputCtrl,
            sending: _sending,
            onSend: () => _send(channel.id),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isSelf});

  final ChatMessage message;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(
            horizontal: ArenaSpacing.md,
            vertical: ArenaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelf ? scheme.primary : ArenaColors.surfaceLight,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isSelf ? 16 : 4),
              bottomRight: Radius.circular(isSelf ? 4 : 16),
            ),
          ),
          child: Text(
            message.content,
            style: ArenaTypography.bodyMedium.copyWith(
              color: isSelf ? Colors.white : ArenaColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              enabled: !sending,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Écris un message…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                isDense: true,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
