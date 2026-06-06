import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/match_viewers_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lists every match an admin has flagged as a live Agora stream.
///
/// Streams appear automatically when the admin flips `is_public = true`
/// on the HOME's recording row, and disappear when they flip it back
/// or when the broadcaster ends the session. Backed by
/// [activePublicStreamsProvider] which uses Supabase realtime, so
/// the list updates live.
class LiveStreamsPage extends ConsumerWidget {
  const LiveStreamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final streamsAsync = ref.watch(activePublicStreamsProvider);

    return Scaffold(
      backgroundColor: ArenaColors.void_,
      appBar: ArenaAppBar(title: l10n.liveStreamsAppBarTitle),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: streamsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: ArenaColors.neonRed),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              child: Text(
                '${l10n.liveStreamsErrorPrefixV2}$e',
                style: ArenaText.body.copyWith(color: ArenaColors.danger),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (streams) {
            if (streams.isEmpty) {
              return EmptyState(
                title: l10n.liveStreamsEmptyTitle,
                description: l10n.liveStreamsEmptyDescription,
                icon: Icons.live_tv_outlined,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                ArenaSpacing.md,
                ArenaSpacing.md,
                ArenaSpacing.md,
                ArenaSpacing.xl,
              ),
              itemCount: streams.length + 1,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: ArenaSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: ArenaSpacing.xs),
                    child: _LiveCounter(count: streams.length),
                  );
                }
                final stream = streams[index - 1];
                return _LiveStreamCard(
                  stream: stream,
                  hero: index == 1,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Pulsing red dot + "N STREAMS LIVE" caption — mirrors the magazine-
/// sport mockup header ("● 3 STREAMS LIVE").
class _LiveCounter extends StatelessWidget {
  const _LiveCounter({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _PulsingDot(color: ArenaColors.neonRed),
        const SizedBox(width: 8),
        Text(
          '$count STREAM${count > 1 ? 'S' : ''} LIVE',
          style: ArenaText.monoSmall.copyWith(
            color: ArenaColors.neonRed,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Hero stream card. The first one in the list gets `hero: true` for
/// a taller "lead story" feel; the rest are compact.
///
/// Watches [matchViewerCountProvider] for this match — counts are
/// streamed live from the Supabase presence channel, so they animate
/// without a refresh.
class _LiveStreamCard extends ConsumerWidget {
  const _LiveStreamCard({required this.stream, this.hero = false});
  final MatchStream stream;
  final bool hero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Deterministic gradient per matchId hash — gives each stream its
    // own colour identity in the absence of game-type metadata.
    final palette = _palettes[stream.matchId.hashCode.abs() % _palettes.length];
    final viewerAsync = ref.watch(matchViewerCountProvider(stream.matchId));
    final viewers = viewerAsync.maybeWhen(data: (n) => n, orElse: () => 0);

    return GestureDetector(
      onTap: () => context.push(UserRoutes.watchStreamPath(stream.matchId)),
      child: Container(
        constraints: BoxConstraints(minHeight: hero ? 180 : 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.last.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dark overlay at bottom for text legibility on bright gradients
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      ArenaColors.void_.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            // LIVE badge — top-left, pulsating
            const Positioned(top: 10, left: 10, child: _LiveBadge()),
            // Viewers pill — top-right
            Positioned(
              top: 10,
              right: 10,
              child: _ViewerPill(count: viewers),
            ),
            // Match title + broadcaster — bottom
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MATCH #${stream.matchId.substring(0, 8).toUpperCase()}',
                    style: (hero ? ArenaText.h2 : ArenaText.h3).copyWith(
                      color: ArenaColors.bone,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.liveStreamsBroadcastByPrefix}'
                    '${stream.playerId.substring(0, 8)}…',
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.bone.withValues(alpha: 0.85),
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

  // 4 deterministic gradients (eFootball green, draughts red,
  // FC Mobile violet, signal blue) cycled by matchId hash — keeps
  // visual variety without needing a `game` field on MatchStream.
  static const _palettes = <List<Color>>[
    [Color(0xFF0A4D2C), Color(0xFF0D6E3F)], // eFootball green
    [Color(0xFF4A2A1A), Color(0xFF6E3F0D)], // draughts mock
    [Color(0xFF2A1A4D), Color(0xFF3F0D6E)], // FC Mobile violet
    [Color(0xFF1A2A4D), Color(0xFF0D3F6E)], // signal blue
  ];
}

/// LIVE pill — white dot + "LIVE" caption, red background, glow.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ArenaColors.neonRed,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: ArenaColors.neonRed.withValues(alpha: 0.5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: ArenaColors.bone,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
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

/// Eye icon + viewer count — translucent black pill, mono digits.
class _ViewerPill extends StatelessWidget {
  const _ViewerPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ArenaColors.void_.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.remove_red_eye_outlined,
            size: 12,
            color: ArenaColors.bone,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: ArenaText.monoSmall.copyWith(color: ArenaColors.bone),
          ),
        ],
      ),
    );
  }
}

/// Single-ticker pulsing dot — opacity 0.85↔1.0 over 1.5s with glow.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.85, end: 1).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: widget.color, blurRadius: _anim.value * 8),
            ],
          ),
        ),
      ),
    );
  }
}
