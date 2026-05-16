import 'dart:async';

import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/agora_rtm_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/chat_channel.dart';
import 'package:arena/data/models/chat_message.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/chat/messages_inbox_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final opponentAsync = ref.watch(_opponentProvider(widget.matchId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ChatAppBar(
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
    );
  }

  Widget _buildChannelBody(ChatChannel channel) {
    final selfId = ref.watch(currentSessionProvider)?.user.id;
    final messagesAsync = ref.watch(channelMessagesProvider(channel.id));

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
    );
  }
}

/// Resolves the opponent profile for the current match, regardless of
/// whether the seated player sits on the player1 or player2 slot.
final _opponentProvider =
    FutureProvider.family<Profile?, String>((ref, matchId) async {
  final selfId = ref.watch(currentSessionProvider)?.user.id;
  if (selfId == null) return null;
  final match = await ref.watch(matchByIdProvider(matchId).future);
  if (match == null) return null;
  final otherId =
      match.player1Id == selfId ? match.player2Id : match.player1Id;
  if (otherId == null) return null;
  return ref.read(profileRepositoryProvider).getById(otherId);
});

class _ChatAppBar extends StatelessWidget {
  const _ChatAppBar({
    required this.opponent,
    required this.peerTyping,
    required this.peerOnline,
    required this.onBack,
  });

  final Profile? opponent;
  final bool peerTyping;
  final bool peerOnline;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final username = opponent?.username ?? 'Joueur';
    final initials = username.isEmpty ? '?' : username[0].toUpperCase();
    // Hiérarchie : typing > online > offline. Le typing implique online
    // mais on garde le label dédié pour le feedback live.
    final subtitle = peerTyping
        ? 'typing…'
        : peerOnline
            ? 'en ligne'
            : 'hors ligne';
    final subtitleColor = peerOnline
        ? ArenaColors.statusOk
        : ArenaColors.silver;

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
                          style: const TextStyle(
                            color: ArenaColors.bone,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
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
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Les appels arrivent en PHASE 12.5.'),
                duration: Duration(seconds: 2),
              ),
            ),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isSelf});

  final ChatMessage message;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    if (message.type == 'room_code') {
      return _RoomCodeBubble(message: message);
    }
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: ArenaSpacing.md,
            vertical: ArenaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelf ? scheme.primary : ArenaColors.carbon2,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isSelf ? 16 : 4),
              bottomRight: Radius.circular(isSelf ? 4 : 16),
            ),
            boxShadow: isSelf
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.content,
                style: ArenaText.body.copyWith(
                  color: isSelf ? Colors.white : ArenaColors.bone,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTimestamp(message.createdAt, isSelf: isSelf),
                style: ArenaText.small.copyWith(
                  color: isSelf
                      ? Colors.white.withValues(alpha: 0.75)
                      : ArenaColors.silver,
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

class _RoomCodeBubble extends StatelessWidget {
  const _RoomCodeBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: message.content));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code copié'),
              duration: Duration(seconds: 1),
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
                'tap pour copier',
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
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: ArenaSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Emoji',
            icon: const Icon(
              Icons.emoji_emotions_outlined,
              color: ArenaColors.silver,
            ),
            onPressed: sending
                ? null
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Le picker emoji arrive en PHASE 12.5.'),
                        duration: Duration(seconds: 2),
                      ),
                    ),
          ),
          IconButton(
            tooltip: 'Joindre',
            icon: const Icon(
              Icons.attach_file_outlined,
              color: ArenaColors.silver,
            ),
            onPressed: sending
                ? null
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "L'envoi de pièces jointes arrive en PHASE 12.5.",
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    ),
          ),
          Expanded(
            child: ArenaTextField(
              controller: controller,
              hint: 'Message…',
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
                  : [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.55),
                        blurRadius: 20,
                        spreadRadius: -2,
                      ),
                    ],
            ),
            child: IconButton.filled(
              onPressed: sending ? null : onSend,
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
