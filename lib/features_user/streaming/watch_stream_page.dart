import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/core/services/agora_streaming_service.dart';
import 'package:arena/core/services/match_viewers_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen Agora viewer for a public match stream.
///
/// Pulls a token through [AgoraStreamingService.joinAsAudience], then
/// renders the broadcaster's video as soon as a remote uid shows up.
/// Leaving the page (back press) drops the channel cleanly.
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
    ref.read(agoraStreamingServiceProvider).leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agoraStreamingServiceProvider).stateStream;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: ArenaAppBar(
        title: 'Match #${widget.matchId.substring(0, 8)}',
        actions: [
          _ViewerCountBadge(matchId: widget.matchId),
          const SizedBox(width: ArenaSpacing.md),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(ArenaSpacing.lg),
                child: Text(
                  _error!,
                  style: ArenaText.body.copyWith(color: ArenaColors.neonRed),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : !_hasJoined
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : StreamBuilder<AgoraSessionState>(
                  stream: state,
                  initialData:
                      ref.read(agoraStreamingServiceProvider).state,
                  builder: (context, snap) {
                    final s = snap.data;
                    if (s is AgoraJoined && s.remoteUid != null) {
                      final engine =
                          ref.read(agoraStreamingServiceProvider).engine;
                      if (engine == null) {
                        return const _PlaceholderText('Connexion en cours…');
                      }
                      return AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: engine,
                          canvas: VideoCanvas(uid: s.remoteUid),
                          connection:
                              RtcConnection(channelId: s.channel),
                        ),
                      );
                    }
                    if (s is AgoraFailed) {
                      return _PlaceholderText('Échec : ${s.reason}');
                    }
                    return const _PlaceholderText(
                      'En attente du diffuseur…',
                    );
                  },
                ),
    );
  }
}

class _PlaceholderText extends StatelessWidget {
  const _PlaceholderText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70),
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
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.remove_red_eye_outlined,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
