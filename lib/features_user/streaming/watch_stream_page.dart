import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/core/services/agora_streaming_service.dart';
import 'package:arena/core/services/match_viewers_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full-screen Agora viewer for a public match stream.
///
/// Pulls a token through [AgoraStreamingService.joinAsAudience], then
/// renders the broadcaster's video as soon as a remote uid shows up.
/// Leaving the page (back press) drops the channel cleanly.
///
/// Premium layout : pas d'AppBar Material — la vidéo prend tout l'espace,
/// les contrôles flottent en overlay (back top-left, LIVE badge top-left
/// haut, viewer pill top-right, score zone bottom-left). Le fond
/// est noir pour ne pas perturber la vidéo.
class WatchStreamPage extends ConsumerStatefulWidget {
  const WatchStreamPage({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<WatchStreamPage> createState() => _WatchStreamPageState();
}

class _WatchStreamPageState extends ConsumerState<WatchStreamPage> {
  bool _hasJoined = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  Future<void> _join() async {
    final svc = ref.read(agoraStreamingServiceProvider);
    try {
      await svc.joinAsAudience(matchId: widget.matchId);
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
    // Fire-and-forget — we don't want to block pop on the network leave.
    ref.read(agoraStreamingServiceProvider).leave().catchError(
          (Object e) => debugPrint('WatchStreamPage.leave error: $e'),
        );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agoraStreamingServiceProvider).stateStream;

    return Scaffold(
      backgroundColor: ArenaColors.blackPure,
      body: SafeArea(
        child: Stack(
          children: [
            // === Video layer (or placeholder if not joined yet) ===
            Positioned.fill(
              child: _error != null
                  ? _ErrorLayer(message: _error!)
                  : !_hasJoined
                      ? const _LoadingLayer()
                      : StreamBuilder<AgoraSessionState>(
                          stream: state,
                          initialData:
                              ref.read(agoraStreamingServiceProvider).state,
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

            // === Top scrim (legibility for top badges) ===
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: 120,
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

            // === Back button (top-left) ===
            Positioned(
              top: 8,
              left: 8,
              child: _OverlayIconButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
            ),

            // === LIVE badge (top-center under back button row) ===
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(child: _LiveBadge()),
            ),

            // === Viewer pill (top-right) ===
            Positioned(
              top: 16,
              right: 12,
              child: _ViewerCountBadge(matchId: widget.matchId),
            ),

            // === Bottom scrim (legibility for match caption) ===
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: 140,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xE6050507), // void_ alpha 0.9
                          Color(0x00050507),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // === Match caption (bottom) ===
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MATCH #${widget.matchId.substring(0, 8).toUpperCase()}',
                    style: ArenaText.h2.copyWith(color: ArenaColors.bone),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diffusion en direct',
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.bone.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered loading state — used while we're acquiring the Agora token
/// and joining the channel.
class _LoadingLayer extends StatelessWidget {
  const _LoadingLayer();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ArenaColors.blackPure,
      child: Center(
        child: CircularProgressIndicator(color: ArenaColors.bone),
      ),
    );
  }
}

/// Centered placeholder text — used between "joined" and "remote uid
/// received" states, and when Agora reports a failed session.
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

/// Error state — shown when `joinAsAudience` throws (token fetch,
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

/// LIVE pill identical to the one in LiveStreamsPage — kept duplicated
/// here on purpose so each screen owns its overlay primitives without
/// a coupled internal widget.
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

/// Live presence badge (👁 N) bound to [matchViewerCountProvider]. The
/// caller's own subscription IS counted by the presence channel.
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

/// Translucent circular icon button — used for the floating back arrow.
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
