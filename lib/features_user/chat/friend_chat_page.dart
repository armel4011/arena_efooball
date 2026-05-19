import 'dart:io';

import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/chat_channel.dart';
import 'package:arena/data/models/chat_message.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/chat/call_screen.dart';
import 'package:arena/features_user/chat/chat_page.dart';
import 'package:arena/features_user/chat/messages_inbox_page.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Chat 1v1 entre amis (Phase 13 extension).
///
/// Le channel `type='friend'` est créé/réutilisé via la RPC
/// `ensure_friend_channel`. Pas d'Agora RTM en V1 (présence/typing
/// reportés à V2).
class FriendChatPage extends ConsumerStatefulWidget {
  const FriendChatPage({required this.friendshipId, super.key});

  final String friendshipId;

  @override
  ConsumerState<FriendChatPage> createState() => _FriendChatPageState();
}

class _FriendChatPageState extends ConsumerState<FriendChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _uploading = false;
  bool _showEmojiPanel = false;

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
        SnackBar(content: Text('Impossible : ${arenaErrorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage(String channelId, ImageSource source) async {
    if (_uploading) return;
    final selfId = ref.read(currentSessionProvider)?.user.id;
    if (selfId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Picker : ${arenaErrorMessage(e)}')),
      );
      return;
    }
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await ref.read(chatRepositoryProvider).sendMediaMessage(
            channelId: channelId,
            senderId: selfId,
            file: File(picked.path),
            mediaType: 'image',
          );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _showAttachSheet(String channelId) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ArenaColors.carbon,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: ArenaColors.signalBlue,
              ),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: ArenaColors.signalBlue,
              ),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: ArenaSpacing.sm),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickAndSendImage(channelId, source);
  }

  void _toggleEmoji() {
    setState(() => _showEmojiPanel = !_showEmojiPanel);
    if (_showEmojiPanel) FocusScope.of(context).unfocus();
  }

  void _onEmojiSelected(Category? _, Emoji emoji) {
    final selection = _inputCtrl.selection;
    final text = _inputCtrl.text;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final newText = text.replaceRange(start, end, emoji.emoji);
    _inputCtrl
      ..text = newText
      ..selection =
          TextSelection.collapsed(offset: start + emoji.emoji.length);
  }

  Future<void> _confirmAndDelete(ChatMessage msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: const Text('Supprimer ce message ?'),
        content: const Text(
          'Ton ami verra «Message supprimé» à la place.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ArenaColors.neonRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(chatRepositoryProvider).softDeleteMessage(msg.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelAsync = ref.watch(_friendChannelProvider(widget.friendshipId));
    final peerAsync = ref.watch(_friendPeerProvider(widget.friendshipId));
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _FriendChatAppBar(
              friendshipId: widget.friendshipId,
              peer: peerAsync.valueOrNull,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(UserRoutes.home);
                }
              },
            ),
            Expanded(
              child: channelAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorState(
                  description: e.toString(),
                  onRetry: () => ref.invalidate(
                    _friendChannelProvider(widget.friendshipId),
                  ),
                ),
                data: _buildBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ChatChannel channel) {
    final selfId = ref.watch(currentSessionProvider)?.user.id;
    final msgsAsync = ref.watch(channelMessagesProvider(channel.id));
    final clearedAt =
        ref.watch(myChatClearedAtProvider(channel.id)).valueOrNull;
    return Column(
      children: [
        Expanded(
          child: msgsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              description: e.toString(),
              onRetry: () =>
                  ref.invalidate(channelMessagesProvider(channel.id)),
            ),
            data: (rawMessages) {
              final messages = clearedAt == null
                  ? rawMessages
                  : [
                      for (final m in rawMessages)
                        if (m.createdAt == null ||
                            m.createdAt!.isAfter(clearedAt))
                          m,
                    ];
              if (messages.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'Démarre la conversation',
                  description: 'Envoie un premier message à ton ami.',
                );
              }
              return ListView.builder(
                reverse: true,
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: ArenaSpacing.md,
                ),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[messages.length - 1 - i];
                  final isSelf = msg.senderId == selfId;
                  return ChatBubble(
                    message: msg,
                    isSelf: isSelf,
                    onLongPress:
                        isSelf ? () => _confirmAndDelete(msg) : null,
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1, color: ArenaColors.border),
        ChatMessageInput(
          controller: _inputCtrl,
          sending: _sending || _uploading,
          emojiActive: _showEmojiPanel,
          onSend: () => _send(channel.id),
          onToggleEmoji: _toggleEmoji,
          onAttach: () => _showAttachSheet(channel.id),
        ),
        if (_showEmojiPanel)
          SizedBox(
            height: 260,
            child: EmojiPicker(
              onEmojiSelected: _onEmojiSelected,
              textEditingController: _inputCtrl,
              config: const Config(
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor: ArenaColors.void_,
                  columns: 8,
                ),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: ArenaColors.carbon,
                  iconColor: ArenaColors.silver,
                  iconColorSelected: ArenaColors.signalBlue,
                  indicatorColor: ArenaColors.signalBlue,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: ArenaColors.carbon,
                  buttonColor: ArenaColors.carbon,
                  buttonIconColor: ArenaColors.silver,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Resolve (or create) le `chat_channel` type=friend pour la friendship.
/// Au passage, un-hide pour moi (sémantique WhatsApp : rouvrir une
/// conv "supprimée pour moi" la fait ré-apparaître dans l'inbox) +
/// invalide l'inbox provider pour qu'il pick up le changement.
final _friendChannelProvider =
    FutureProvider.family.autoDispose<ChatChannel, String>(
        (ref, friendshipId) async {
  final repo = ref.read(chatRepositoryProvider);
  final channel = await repo.ensureFriendChannel(friendshipId);
  await repo.unhideChannelForMe(channel.id);
  ref.invalidate(myFriendChannelsProvider);
  return channel;
});

/// Resolve le profil de l'ami à partir de la friendship.
final _friendPeerProvider =
    FutureProvider.family.autoDispose<Profile?, String>(
        (ref, friendshipId) async {
  final selfId = ref.watch(currentSessionProvider)?.user.id;
  if (selfId == null) return null;
  final friendship = await ref
      .read(friendsRepositoryProvider)
      .getById(friendshipId);
  if (friendship == null) return null;
  final peerId = friendship.requesterId == selfId
      ? friendship.addresseeId
      : friendship.requesterId;
  return ref.read(profileRepositoryProvider).getById(peerId);
});

class _FriendChatAppBar extends StatelessWidget {
  const _FriendChatAppBar({
    required this.friendshipId,
    required this.peer,
    required this.onBack,
  });

  final String friendshipId;
  final Profile? peer;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final username = peer?.username ?? 'Ami';
    final initials = username.isEmpty ? '?' : username[0].toUpperCase();
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      decoration: const BoxDecoration(
        color: ArenaColors.void_,
        border: Border(bottom: BorderSide(color: ArenaColors.border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ArenaColors.carbon,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 16,
                color: ArenaColors.bone,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: peer == null
                  ? null
                  : () => context.push(
                        UserRoutes.publicProfilePath(peer!.username),
                      ),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  ArenaAvatar(
                    initials: initials,
                    color: inboxAvatarFor(username),
                    size: ArenaAvatarSize.sm,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: ArenaText.small.copyWith(
                            color: ArenaColors.bone,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Ami',
                          style: ArenaText.small.copyWith(
                            color: ArenaColors.silver,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CallScreen(
                  scope: 'friend',
                  id: friendshipId,
                  peerName: peer?.username ?? 'Ami',
                ),
                fullscreenDialog: true,
              ),
            ),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ArenaColors.carbon,
              ),
              child: const Icon(
                Icons.call_outlined,
                size: 16,
                color: ArenaColors.bone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
