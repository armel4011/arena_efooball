import 'dart:io';

import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/chat/chat_page.dart' show ChatBubble, ChatMessageInput;
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Écran « Contact / Aide » — fil de support conversationnel user ↔ admin.
///
/// Réutilise l'infra de chat générique : [supportChannelProvider] résout
/// (ou crée) le canal `type='admin_user'` du user via la RPC
/// `ensure_support_channel`, puis les messages sont streamés par
/// [channelMessagesProvider] et rendus avec [ChatBubble] / le composer
/// [ChatMessageInput] — exactement comme le chat de match, sans la couche
/// RTM (présence/typing) qui n'a pas de sens pour un fil de support.
class SupportChatPage extends ConsumerStatefulWidget {
  const SupportChatPage({super.key});

  @override
  ConsumerState<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends ConsumerState<SupportChatPage> {
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

    final l10n = AppLocalizations.of(context);
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
        SnackBar(content: Text('${l10n.chatSendFailed}${arenaErrorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage(String channelId, ImageSource source) async {
    if (_uploading) return;
    final selfId = ref.read(currentSessionProvider)?.user.id;
    if (selfId == null) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.chatPickerUnavailable}${arenaErrorMessage(e)}'),
        ),
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
        SnackBar(content: Text('${l10n.chatUploadFailed}${arenaErrorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _showAttachSheet(String channelId) async {
    if (_uploading) return;
    final l10n = AppLocalizations.of(context);
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
              title: Text(l10n.chatAttachGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: ArenaColors.signalBlue,
              ),
              title: Text(l10n.chatAttachCamera),
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

  void _toggleEmojiPanel() {
    setState(() => _showEmojiPanel = !_showEmojiPanel);
    if (_showEmojiPanel) FocusScope.of(context).unfocus();
  }

  void _onEmojiSelected(Category? _, Emoji emoji) {
    final selection = _inputCtrl.selection;
    final text = _inputCtrl.text;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    _inputCtrl
      ..text = text.replaceRange(start, end, emoji.emoji)
      ..selection =
          TextSelection.collapsed(offset: start + emoji.emoji.length);
  }

  @override
  Widget build(BuildContext context) {
    final channelAsync = ref.watch(supportChannelProvider);

    return Scaffold(
      body: ArenaScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              _SupportAppBar(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(UserRoutes.settings);
                  }
                },
              ),
              Expanded(
                child: channelAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorState(
                    description: e.toString(),
                    onRetry: () => ref.invalidate(supportChannelProvider),
                  ),
                  data: _buildBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(String channelId) {
    final l10n = AppLocalizations.of(context);
    final selfId = ref.watch(currentSessionProvider)?.user.id;
    final messagesAsync = ref.watch(channelMessagesProvider(channelId));

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              description: e.toString(),
              onRetry: () =>
                  ref.invalidate(channelMessagesProvider(channelId)),
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return EmptyState(
                  icon: Icons.support_agent_outlined,
                  title: l10n.supportChatEmptyTitle,
                  description: l10n.supportChatEmptyDescription,
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
                  return ChatBubble(
                    message: msg,
                    isSelf: msg.senderId == selfId,
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
          onSend: () => _send(channelId),
          onToggleEmoji: _toggleEmojiPanel,
          onAttach: () => _showAttachSheet(channelId),
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

/// Pastille ARENA en tête du fil de support.
class _ArenaSupportBadge extends StatelessWidget {
  const _ArenaSupportBadge();

  @override
  Widget build(BuildContext context) {
    return const ArenaAvatar(
      initials: 'A',
      size: ArenaAvatarSize.sm,
    );
  }
}

/// En-tête du fil de support — badge ARENA + titre, pas de présence/appel
/// (≠ chat de match).
class _SupportAppBar extends StatelessWidget {
  const _SupportAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          const _ArenaSupportBadge(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.supportChatTitle,
                  style: ArenaText.small.copyWith(
                    color: ArenaColors.bone,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.supportChatHeaderSubtitle,
                  style: ArenaText.small.copyWith(color: ArenaColors.silver),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
