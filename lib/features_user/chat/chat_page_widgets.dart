part of 'chat_page.dart';

class _ChatAppBar extends StatelessWidget {
  const _ChatAppBar({
    required this.matchId,
    required this.opponent,
    required this.peerTyping,
    required this.peerOnline,
    required this.onBack,
  });

  final String matchId;
  final Profile? opponent;
  final bool peerTyping;
  final bool peerOnline;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final username = opponent?.username ?? l10n.chatAppBarUsernameFallback;
    final initials = username.isEmpty ? '?' : username[0].toUpperCase();
    // Hiérarchie : typing > online > offline. Le typing implique online
    // mais on garde le label dédié pour le feedback live.
    final subtitle = peerTyping
        ? l10n.chatAppBarTyping
        : peerOnline
            ? l10n.chatAppBarOnline
            : l10n.chatAppBarOffline;
    final subtitleColor =
        peerOnline ? ArenaColors.statusOk : ArenaColors.silver;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      decoration: const BoxDecoration(
        color: ArenaColors.void_,
        border: Border(bottom: BorderSide(color: ArenaColors.border)),
      ),
      child: Row(
        children: [
          _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
          const SizedBox(width: 10),
          // Phase 13 — tap sur l'identité du peer ouvre son profil public.
          Expanded(
            child: InkWell(
              onTap: opponent == null
                  ? null
                  : () => context.push(
                        UserRoutes.publicProfilePath(opponent!.username),
                      ),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ArenaAvatar(
                        initials: initials,
                        color: inboxAvatarFor(username),
                        size: ArenaAvatarSize.sm,
                      ),
                      if (peerOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: ArenaColors.statusOk,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ArenaColors.void_,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
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
                          subtitle,
                          style: ArenaText.small.copyWith(
                            color: subtitleColor,
                            fontStyle: peerTyping
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _CircleIconButton(
            icon: Icons.call_outlined,
            onTap: () {
              final peer = opponent;
              if (peer == null) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CallScreen(
                    scope: 'match',
                    id: matchId,
                    calleeId: peer.id,
                    peerName: peer.username,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: ArenaColors.carbon,
        ),
        child: Icon(icon, size: 16, color: ArenaColors.bone),
      ),
    );
  }
}

/// Bubble unitaire d'un message — partagée entre [ChatPage] (match) et
/// `FriendChatPage`. Long-press déclenche [onLongPress] (typiquement
/// "supprimer mon message").
class ChatBubble extends ConsumerWidget {
  const ChatBubble({
    required this.message,
    required this.isSelf,
    this.onLongPress,
    super.key,
  });

  final ChatMessage message;
  final bool isSelf;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (message.type == 'room_code') {
      return _RoomCodeBubble(message: message);
    }

    final isDeleted = message.deletedAt != null;
    final hasMedia = !isDeleted && message.mediaUrl != null;

    return GestureDetector(
      onLongPress: isDeleted ? null : onLongPress,
      child: Align(
        alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: hasMedia
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.md,
                    vertical: ArenaSpacing.sm,
                  ),
            decoration: BoxDecoration(
              // Reproduit la maquette #16 :
              // * self → gradient signalBlue → signalBlueDark + shadow
              //   signalBlueGlow, coin bottom-right "queue" (4 px).
              // * peer → bone @ 6 % translucide, coin bottom-left "queue".
              gradient: isSelf
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ArenaColors.signalBlue,
                        ArenaColors.signalBlueDark,
                      ],
                    )
                  : null,
              color: isSelf ? null : ArenaColors.bone.withValues(alpha: 0.06),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isSelf ? 16 : 4),
                bottomRight: Radius.circular(isSelf ? 4 : 16),
              ),
              boxShadow: isSelf && !hasMedia
                  ? const [
                      BoxShadow(
                        color: ArenaColors.signalBlueGlow,
                        blurRadius: 18,
                        spreadRadius: -2,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isDeleted)
                  Text(
                    l10n.chatMessageDeleted,
                    style: ArenaText.body.copyWith(
                      color: isSelf
                          ? ArenaColors.bone.withValues(alpha: 0.7)
                          : ArenaColors.silver,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else ...[
                  if (hasMedia)
                    _MediaPreview(
                      pathInBucket: message.mediaUrl!,
                      mediaType: message.mediaType,
                    ),
                  if (message.content.isNotEmpty)
                    Padding(
                      padding: hasMedia
                          ? const EdgeInsets.fromLTRB(
                              ArenaSpacing.sm,
                              ArenaSpacing.xs,
                              ArenaSpacing.sm,
                              0,
                            )
                          : EdgeInsets.zero,
                      child: Text(
                        message.content,
                        style: ArenaText.body.copyWith(
                          color: ArenaColors.bone,
                        ),
                      ),
                    ),
                ],
                Padding(
                  padding: hasMedia
                      ? const EdgeInsets.symmetric(
                          horizontal: ArenaSpacing.sm,
                          vertical: 2,
                        )
                      : const EdgeInsets.only(top: 2),
                  child: Text(
                    _formatTimestamp(message.createdAt, isSelf: isSelf),
                    style: ArenaText.small.copyWith(
                      color: isSelf
                          ? ArenaColors.bone.withValues(alpha: 0.75)
                          : ArenaColors.silver,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Charge l'image media via signed URL Storage (expire 1h). Le
/// `FutureBuilder` est keyé sur le path pour ne pas re-fetcher quand
/// la bubble est juste re-rendue.
class _MediaPreview extends ConsumerWidget {
  const _MediaPreview({required this.pathInBucket, required this.mediaType});

  final String pathInBucket;
  final String? mediaType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (mediaType != null && mediaType != 'image') {
      // V1: seules les images sont rendues. Video/audio en V1.5.
      return Container(
        height: 80,
        width: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${l10n.chatMediaUnsupported}$mediaType (V1.5)',
          style: ArenaText.small,
        ),
      );
    }
    return FutureBuilder<String>(
      key: ValueKey('media_$pathInBucket'),
      future: ref.read(chatRepositoryProvider).signedMediaUrl(pathInBucket),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            width: 220,
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Container(
            width: 220,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.broken_image_outlined,
              color: ArenaColors.silver,
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: snap.data!,
            fit: BoxFit.cover,
            width: 240,
            errorWidget: (_, __, ___) => Container(
              width: 220,
              height: 80,
              alignment: Alignment.center,
              color: ArenaColors.carbon,
              child: const Icon(
                Icons.broken_image_outlined,
                color: ArenaColors.silver,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoomCodeBubble extends StatelessWidget {
  const _RoomCodeBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: message.content));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.chatRoomCodeCopied),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(
            horizontal: ArenaSpacing.md,
            vertical: ArenaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: ArenaColors.gameEfoot.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ArenaColors.gameEfoot),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.copy_outlined,
                    size: 14,
                    color: ArenaColors.gameEfoot,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.content,
                    style: ArenaText.body.copyWith(
                      color: ArenaColors.bone,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                l10n.chatRoomCodeTapToCopy,
                style: ArenaText.small.copyWith(
                  color: ArenaColors.gameEfoot,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTimestamp(DateTime? created, {required bool isSelf}) {
  if (created == null) return isSelf ? '✓✓' : '';
  final h = created.hour.toString().padLeft(2, '0');
  final m = created.minute.toString().padLeft(2, '0');
  return isSelf ? '$h:$m ✓✓' : '$h:$m';
}

/// Composer du chat (input texte + emoji + attach). Partagé entre
/// [ChatPage] (match) et `FriendChatPage`.
class ChatMessageInput extends StatelessWidget {
  const ChatMessageInput({
    required this.controller,
    required this.sending,
    required this.emojiActive,
    required this.onSend,
    required this.onToggleEmoji,
    required this.onAttach,
    super.key,
  });

  final TextEditingController controller;
  final bool sending;
  final bool emojiActive;
  final VoidCallback onSend;
  final VoidCallback onToggleEmoji;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: ArenaSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: emojiActive
                ? l10n.chatInputTooltipKeyboard
                : l10n.chatInputTooltipEmoji,
            icon: Icon(
              emojiActive
                  ? Icons.keyboard_outlined
                  : Icons.emoji_emotions_outlined,
              color: emojiActive ? ArenaColors.signalBlue : ArenaColors.silver,
            ),
            onPressed: sending ? null : onToggleEmoji,
          ),
          IconButton(
            tooltip: l10n.chatInputTooltipAttach,
            icon: const Icon(
              Icons.attach_file_outlined,
              color: ArenaColors.silver,
            ),
            onPressed: sending ? null : onAttach,
          ),
          Expanded(
            child: ArenaTextField(
              controller: controller,
              hint: l10n.chatInputHint,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: sending
                  ? null
                  : const [
                      BoxShadow(
                        color: ArenaColors.signalBlueGlow,
                        blurRadius: 20,
                        spreadRadius: -2,
                      ),
                    ],
            ),
            child: IconButton.filled(
              onPressed: sending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: ArenaColors.signalBlue,
                foregroundColor: ArenaColors.bone,
              ),
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}
