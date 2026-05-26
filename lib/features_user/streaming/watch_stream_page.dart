import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/core/services/agora_streaming_service.dart';
import 'package:arena/core/services/match_viewers_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/models/stream_comment.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/data/repositories/stream_comment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full-screen Agora viewer for a public match stream.
///
/// Pulls a token through [AgoraStreamingService.joinAsAudience], then
/// renders the broadcaster's video as soon as a remote uid shows up.
/// Leaving the page (back press) drops the channel cleanly.
///
/// Premium layout : pas d'AppBar Material — la vidéo prend les 60%
/// supérieurs, les contrôles flottent en overlay (back top-left,
/// LIVE badge centre haut, viewer pill top-right) et un panneau chat
/// spectateurs prend les 40% inférieurs avec scrim translucide.
class WatchStreamPage extends ConsumerStatefulWidget {
  const WatchStreamPage({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<WatchStreamPage> createState() => _WatchStreamPageState();
}

class _WatchStreamPageState extends ConsumerState<WatchStreamPage> {
  bool _hasJoined = false;
  String? _error;
  // Capturé en initState pour pouvoir appeler leave() dans dispose() —
  // `ref.read` est interdit pendant la phase unmount (Riverpod 2.6+).
  AgoraStreamingService? _service;

  @override
  void initState() {
    super.initState();
    _service = ref.read(agoraStreamingServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  Future<void> _join() async {
    try {
      await _service!.joinAsAudience(matchId: widget.matchId);
      if (mounted) {
        setState(() => _hasJoined = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  void dispose() {
    // Fire-and-forget — pop ne doit pas attendre le network leave.
    _service?.leave().catchError(
          (Object e) => debugPrint('WatchStreamPage.leave error: $e'),
        );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agoraStreamingServiceProvider).stateStream;

    return Scaffold(
      backgroundColor: ArenaColors.blackPure,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // === Top half : video + overlays ===
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _error != null
                        ? _ErrorLayer(message: _error!)
                        : !_hasJoined
                            ? const _LoadingLayer()
                            : StreamBuilder<AgoraSessionState>(
                                stream: state,
                                initialData: ref
                                    .read(agoraStreamingServiceProvider)
                                    .state,
                                builder: (context, snap) {
                                  final s = snap.data;
                                  if (s is AgoraJoined && s.remoteUid != null) {
                                    final engine = ref
                                        .read(agoraStreamingServiceProvider)
                                        .engine;
                                    if (engine == null) {
                                      return const _PlaceholderLayer(
                                        text: 'Connexion en cours…',
                                      );
                                    }
                                    return AgoraVideoView(
                                      controller: VideoViewController.remote(
                                        rtcEngine: engine,
                                        canvas: VideoCanvas(uid: s.remoteUid),
                                        connection: RtcConnection(
                                          channelId: s.channel,
                                        ),
                                      ),
                                    );
                                  }
                                  if (s is AgoraFailed) {
                                    return _PlaceholderLayer(
                                      text: 'Échec : ${s.reason}',
                                    );
                                  }
                                  return const _PlaceholderLayer(
                                    text: 'En attente du diffuseur…',
                                  );
                                },
                              ),
                  ),
                  // Top scrim — lisibilité des badges du dessus.
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: SizedBox(
                        height: 110,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xCC050507), // void_ alpha 0.8
                                Color(0x00050507),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Back button — top-left.
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _OverlayIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => context.pop(),
                    ),
                  ),
                  // LIVE badge — centre haut.
                  const Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(child: _LiveBadge()),
                  ),
                  // Viewer pill — top-right.
                  Positioned(
                    top: 16,
                    right: 12,
                    child: _ViewerCountBadge(matchId: widget.matchId),
                  ),
                  // Match caption — bottom (au-dessus du chat).
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Text(
                      'MATCH #${widget.matchId.substring(0, 8).toUpperCase()}',
                      style: ArenaText.h3.copyWith(
                        color: ArenaColors.bone,
                        shadows: const [
                          Shadow(blurRadius: 12, color: ArenaColors.blackPure),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // === Bottom half : chat spectateur ===
            Expanded(
              flex: 4,
              child: _SpectatorChat(matchId: widget.matchId),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panneau chat spectateurs — caption "SPECTATOR CHAT · N watching" +
/// liste scrollable des messages + input pour envoyer. Backed by
/// [streamCommentsProvider] qui combine fetch initial + realtime
/// INSERT, et [StreamCommentRepository.post] pour l'envoi.
class _SpectatorChat extends ConsumerStatefulWidget {
  const _SpectatorChat({required this.matchId});
  final String matchId;

  @override
  ConsumerState<_SpectatorChat> createState() => _SpectatorChatState();
}

class _SpectatorChatState extends ConsumerState<_SpectatorChat> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _ctrl.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(streamCommentRepositoryProvider)
          .post(matchId: widget.matchId, content: content);
      _ctrl.clear();
      // Petit délai pour laisser le realtime arriver avant scroll.
      Future<void>.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur envoi : $e', style: ArenaText.small),
            backgroundColor: ArenaColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(streamCommentsProvider(widget.matchId));
    final viewersAsync = ref.watch(matchViewerCountProvider(widget.matchId));
    final viewers = viewersAsync.maybeWhen(data: (n) => n, orElse: () => 0);

    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.blackPure.withValues(alpha: 0.65),
        border: Border(
          top: BorderSide(color: ArenaColors.bone.withValues(alpha: 0.06)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header chat.
            Row(
              children: [
                Text(
                  'SPECTATOR CHAT',
                  style: ArenaText.monoSmall.copyWith(
                    color: ArenaColors.silver,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '·',
                  style: ArenaText.monoSmall.copyWith(
                    color: ArenaColors.silver,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$viewers watching',
                  style: ArenaText.monoSmall.copyWith(
                    color: ArenaColors.silver,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Liste des messages.
            Expanded(
              child: commentsAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ArenaColors.bone,
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Chat indisponible',
                    style: ArenaText.small.copyWith(color: ArenaColors.silver),
                  ),
                ),
                data: (comments) {
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        'Sois le premier à commenter !',
                        style: ArenaText.small.copyWith(
                          color: ArenaColors.silver,
                        ),
                      ),
                    );
                  }
                  // Auto-scroll en bas quand de nouveaux messages arrivent.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );
                  // Charge les profils des auteurs pour afficher le vrai
                  // pseudo (au lieu de l'id tronqué). joinedIds = clé
                  // stable Riverpod, cache automatique le temps que la
                  // liste de comments soit inchangée.
                  final ids = {
                    for (final c in comments)
                      if (c.authorId != null) c.authorId!,
                  };
                  final joinedIds = (ids.toList()..sort()).join(',');
                  final profilesAsync = ref.watch(
                    profilesByIdsProvider(joinedIds),
                  );
                  final profiles = profilesAsync.maybeWhen(
                    data: (m) => m,
                    orElse: () => const <String, Profile>{},
                  );
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: EdgeInsets.zero,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: _CommentRow(
                          comment: c,
                          authorProfile:
                              c.authorId == null ? null : profiles[c.authorId!],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Input + bouton envoyer.
            _ChatInput(
              controller: _ctrl,
              sending: _sending,
              onSubmit: _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne d'un message — préfixe `username:` coloré (couleur déterministe
/// par hash de l'authorId) + corps en `pearl`. Le username vient de
/// [profilesByIdsProvider] joiné par le parent ; on retombe sur l'id
/// tronqué (`Fan_XXXX`) si le profil n'est pas encore chargé, et sur
/// `anon` si l'auteur a été soft-deleted (author_id null).
class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment, this.authorProfile});
  final StreamComment comment;
  final Profile? authorProfile;

  @override
  Widget build(BuildContext context) {
    final authorId = comment.authorId;
    final username = authorProfile?.username;
    // Couleur basée sur authorId (stable même si username arrive async).
    final color = authorId == null
        ? ArenaColors.silver
        : _palette[authorId.hashCode.abs() % _palette.length];
    final tag = username ??
        (authorId == null
            ? 'anon'
            : 'Fan_${authorId.substring(0, authorId.length > 4 ? 4 : authorId.length)}');
    return RichText(
      text: TextSpan(
        style: ArenaText.small.copyWith(color: ArenaColors.pearl),
        children: [
          TextSpan(
            text: '$tag: ',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: comment.content),
        ],
      ),
    );
  }

  // 5 couleurs pour distinguer les auteurs — mirror de la maquette
  // (signal-blue, status-ok, gold, hot-coral, ice-cyan).
  static const _palette = <Color>[
    ArenaColors.signalBlue,
    ArenaColors.statusOk,
    ArenaColors.gold,
    ArenaColors.hotCoral,
    ArenaColors.iceCyan,
  ];
}

/// Input message — pill translucide + bouton rond ↑ signalBlue. Disable
/// pendant l'envoi pour éviter les doublons.
class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: ArenaColors.bone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              style: ArenaText.body.copyWith(color: ArenaColors.bone),
              decoration: InputDecoration(
                hintText: 'Envoie un message…',
                hintStyle: ArenaText.body.copyWith(color: ArenaColors.silver),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              maxLength: 500,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                maxLength,
              }) =>
                  null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          GestureDetector(
            onTap: sending ? null : onSubmit,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: sending ? ArenaColors.steel : ArenaColors.signalBlue,
                shape: BoxShape.circle,
                boxShadow: sending
                    ? null
                    : [
                        BoxShadow(
                          color: ArenaColors.signalBlue.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ArenaColors.bone,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward,
                      size: 18,
                      color: ArenaColors.bone,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading state — centered spinner sur fond blackPure.
class _LoadingLayer extends StatelessWidget {
  const _LoadingLayer();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ArenaColors.blackPure,
      child: Center(child: CircularProgressIndicator(color: ArenaColors.bone)),
    );
  }
}

/// Placeholder text avec icône — utilisé entre "joined" et "remote uid
/// received", et quand Agora reporte un échec de session.
class _PlaceholderLayer extends StatelessWidget {
  const _PlaceholderLayer({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ArenaColors.blackPure,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                size: 48,
                color: ArenaColors.bone.withValues(alpha: 0.4),
              ),
              const SizedBox(height: ArenaSpacing.md),
              Text(
                text,
                style: ArenaText.body.copyWith(
                  color: ArenaColors.bone.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state — affiché quand `joinAsAudience` throws (token fetch,
/// channel ban, network down, etc.).
class _ErrorLayer extends StatelessWidget {
  const _ErrorLayer({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ArenaColors.blackPure,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: ArenaColors.neonRed,
              ),
              const SizedBox(height: ArenaSpacing.md),
              Text(
                message,
                style: ArenaText.body.copyWith(color: ArenaColors.danger),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// LIVE pill — dot blanc + "LIVE", bg rouge, glow neonRed.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ArenaColors.neonRed,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: ArenaColors.neonRed.withValues(alpha: 0.5),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: ArenaColors.bone,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'LIVE',
            style: ArenaText.monoSmall.copyWith(
              color: ArenaColors.bone,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live presence badge (👁 N) bound to [matchViewerCountProvider]. Le
/// subscriber courant EST compté par le channel de presence.
class _ViewerCountBadge extends ConsumerWidget {
  const _ViewerCountBadge({required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(matchViewerCountProvider(matchId));
    final count = countAsync.maybeWhen(data: (c) => c, orElse: () => 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ArenaColors.void_.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.remove_red_eye_outlined,
            size: 14,
            color: ArenaColors.bone,
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: ArenaText.monoSmall.copyWith(
              color: ArenaColors.bone,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent circular icon button — back arrow flottant.
class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ArenaColors.void_.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: ArenaColors.bone, size: 22),
        ),
      ),
    );
  }
}
