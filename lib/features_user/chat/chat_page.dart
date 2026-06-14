import 'dart:async';
import 'dart:io';

import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/agora_rtm_service.dart';
import 'package:arena/core/services/sync_queue_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/chat_channel.dart';
import 'package:arena/data/models/chat_message.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/chat/call_screen.dart';
import 'package:arena/features_user/chat/messages_inbox_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

part 'chat_page_widgets.dart';

/// PHASE 6 — 1-on-1 match chat. Hands the matchId to
/// [matchChannelProvider] which fetches or auto-creates the
/// `type = 'match'` channel, then streams messages from
/// [channelMessagesProvider]. Header pulls the opponent profile via
/// [_opponentProvider] so the avatar + username match the seated
/// players. Presence/typing is intentionally cosmetic in V1.0 — Agora
/// RTM lands in PHASE 12.5.
///
/// Maps to screen #16 of `arena_v2.html`.
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

  /// Tracks the last time we published a typing hint to throttle the
  /// RTM publish to ~one per 3s while the user is actively keying.
  DateTime _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);
  static const _typingThrottle = Duration(seconds: 3);

  StreamSubscription<TypingEvent>? _typingSub;
  StreamSubscription<PresenceUpdate>? _presenceSub;
  Timer? _typingClearTimer;

  /// `true` while the peer's typing hint is still fresh (< 5 s old).
  bool _peerTyping = false;

  /// `true` once we've seen `remoteJoinChannel` from the opponent.
  bool _peerOnline = false;

  /// Toggle de l'overlay emoji picker — visible quand l'utilisateur
  /// tape sur le bouton smiley.
  bool _showEmojiPanel = false;

  /// `true` pendant l'upload d'un media (caméra/galerie). Bloque les
  /// boutons send/attach/emoji pour éviter les doubles posts.
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapRtm());
    _inputCtrl.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _inputCtrl
      ..removeListener(_onInputChanged)
      ..dispose();
    _scrollCtrl.dispose();
    _typingClearTimer?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    // Best-effort leave — RTM est entièrement cosmétique, donc on
    // swallow toute erreur (test sans Supabase, provider non override).
    try {
      final svc = ref.read(agoraRtmServiceProvider);
      if (svc.isConnected) {
        svc.leaveMatchChannel(widget.matchId);
      }
    } catch (_) {/* RTM non initialisé — rien à libérer */}
    super.dispose();
  }

  Future<void> _bootstrapRtm() async {
    // RTM est cosmétique : si la connexion échoue (config Agora pas
    // prête, réseau, environnement de test sans Supabase, etc.), on
    // garde la chat fonctionnelle sans typing/presence. Pas de snackbar.
    AgoraRtmService svc;
    try {
      svc = ref.read(agoraRtmServiceProvider);
      if (!svc.isConnected) {
        await svc.connect();
      }
      await svc.joinMatchChannel(widget.matchId);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    _typingSub = svc.typingEvents
        .where((e) => e.matchId == widget.matchId)
        .listen(_onPeerTyping);
    _presenceSub = svc.presenceEvents
        .where((e) => e.matchId == widget.matchId)
        .listen(_onPeerPresence);
  }

  void _onInputChanged() {
    final now = DateTime.now();
    if (now.difference(_lastTypingSent) < _typingThrottle) return;
    if (_inputCtrl.text.isEmpty) return;
    _lastTypingSent = now;
    try {
      final svc = ref.read(agoraRtmServiceProvider);
      if (svc.isConnected) {
        svc.sendTyping(widget.matchId);
      }
    } catch (_) {/* RTM non initialisé — no-op */}
  }

  void _onPeerTyping(TypingEvent _) {
    if (!mounted) return;
    setState(() => _peerTyping = true);
    _typingClearTimer?.cancel();
    // Le SDK envoie 1 event par publish ; on garde l'indicator allumé
    // 5 s puis on l'éteint si plus rien n'arrive.
    _typingClearTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _peerTyping = false);
    });
  }

  void _onPeerPresence(PresenceUpdate event) {
    if (!mounted) return;
    setState(() => _peerOnline = event.isOnline);
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
      final queued = await ref.read(offlineAwareActionsProvider).sendChatMessage(
            channelId: channelId,
            senderId: selfId,
            content: text,
          );
      _inputCtrl.clear();
      if (queued && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.chatOfflineQueued),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.chatSendFailed}$e')),
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
    final file = File(picked.path);
    debugPrint('[chat] upload media start :'
        ' path=${picked.path}'
        ' size=${await file.length()} bytes'
        ' channel=$channelId');
    try {
      await ref.read(chatRepositoryProvider).sendMediaMessage(
            channelId: channelId,
            senderId: selfId,
            file: file,
            mediaType: 'image',
          );
      debugPrint('[chat] upload media OK');
    } catch (e, st) {
      debugPrint('[chat] upload media FAILED: $e\n$st');
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
    final newText = text.replaceRange(start, end, emoji.emoji);
    _inputCtrl
      ..text = newText
      ..selection = TextSelection.collapsed(offset: start + emoji.emoji.length);
  }

  Future<void> _confirmAndDeleteMessage(ChatMessage msg) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text(l10n.chatDeleteDialogTitle),
        content: Text(l10n.chatDeleteDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.chatDeleteDialogCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ArenaColors.neonRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.chatDeleteDialogConfirm),
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
        SnackBar(content: Text('${l10n.chatGenericFailure}${arenaErrorMessage(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelAsync = ref.watch(matchChannelProvider(widget.matchId));
    final opponentAsync = ref.watch(_opponentProvider(widget.matchId));

    return Scaffold(
      body: ArenaScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              _ChatAppBar(
                matchId: widget.matchId,
                opponent: opponentAsync.valueOrNull,
                peerTyping: _peerTyping,
                peerOnline: _peerOnline,
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
                    onRetry: () =>
                        ref.invalidate(matchChannelProvider(widget.matchId)),
                  ),
                  data: _buildChannelBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelBody(ChatChannel channel) {
    final l10n = AppLocalizations.of(context);
    final selfId = ref.watch(currentSessionProvider)?.user.id;
    final messagesAsync = ref.watch(channelMessagesProvider(channel.id));
    final clearedAt =
        ref.watch(myChatClearedAtProvider(channel.id)).valueOrNull;

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              description: e.toString(),
              onRetry: () => ref.invalidate(
                channelMessagesProvider(channel.id),
              ),
            ),
            data: (rawMessages) {
              // Filtre client-side : messages avant cleared_at sont
              // masqués pour moi (le peer voit tout — sémantique
              // WhatsApp "Supprimer pour moi").
              final messages = clearedAt == null
                  ? rawMessages
                  : [
                      for (final m in rawMessages)
                        if (m.createdAt == null ||
                            m.createdAt!.isAfter(clearedAt))
                          m,
                    ];
              if (messages.isEmpty) {
                return EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: l10n.chatEmptyTitle,
                  description: l10n.chatEmptyDescription,
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
                  // Stream is oldest → newest. Reverse the indexing so
                  // the newest message sits at the bottom of the
                  // (reversed) ListView.
                  final msg = messages[messages.length - 1 - i];
                  final isSelf = msg.senderId == selfId;
                  return ChatBubble(
                    message: msg,
                    isSelf: isSelf,
                    onLongPress:
                        isSelf ? () => _confirmAndDeleteMessage(msg) : null,
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
          onToggleEmoji: _toggleEmojiPanel,
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

/// Resolves the opponent profile for the current match, regardless of
/// whether the seated player sits on the player1 or player2 slot.
final _opponentProvider =
    FutureProvider.family.autoDispose<Profile?, String>((ref, matchId) async {
  final selfId = ref.watch(currentSessionProvider)?.user.id;
  if (selfId == null) return null;
  final match = await ref.watch(matchByIdProvider(matchId).future);
  if (match == null) return null;
  final otherId = match.player1Id == selfId ? match.player2Id : match.player1Id;
  if (otherId == null) return null;
  return ref.read(profileRepositoryProvider).getPublicById(otherId);
});
