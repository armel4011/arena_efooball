import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/match_room/match_room_providers.dart';
import 'package:arena/features_user/match_room/widgets/match_players_header.dart';
import 'package:arena/features_user/match_room/widgets/match_recording_lifecycle.dart';
import 'package:arena/features_user/match_room/widgets/match_step_body.dart';
import 'package:arena/features_user/match_room/widgets/match_step_indicator.dart';
import 'package:arena/features_user/streaming/start_streaming_banner.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Where the current user stands relative to the match.
enum MatchRole {
  player1,
  player2,
  observer;

  bool isHomeOf(ArenaMatch m) {
    final selfMap = switch (this) {
      MatchRole.player1 => m.player1Id,
      MatchRole.player2 => m.player2Id,
      MatchRole.observer => null,
    };
    return selfMap != null && selfMap == m.homePlayerId;
  }

  static MatchRole resolve({required ArenaMatch match, String? selfId}) {
    if (selfId == null) return MatchRole.observer;
    if (selfId == match.player1Id) return MatchRole.player1;
    if (selfId == match.player2Id) return MatchRole.player2;
    return MatchRole.observer;
  }
}

/// PHASE 5 + v2 redesign — Match Room shell.
///
/// Layout per `docs/arena_v2.html` #11 : ArenaAppBar → 4-step progress →
/// player avatars (HOME/AWAY) → step-specific body. The scoring,
/// recording-lifecycle and streaming-banner wiring from v1 stays intact ;
/// only the chrome and the share-code / room-ready surfaces are restyled
/// to match the v2 mockup.
///
/// Tous les widgets (header, steps, score flow, ...) sont extraits dans
/// `widgets/` (PR 2026-05-17, refacto P1 audit followup) pour garder
/// cette page sous la barre des 150 lignes.
class MatchRoomPage extends ConsumerWidget {
  const MatchRoomPage({required this.matchId, super.key});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final l10n = AppLocalizations.of(context);
    final async = widgetRef.watch(matchByIdProvider(matchId));
    final selfId = widgetRef.watch(currentSessionProvider)?.user.id;
    final loadedMatch = async.value;
    final isPlayer = loadedMatch != null &&
        MatchRole.resolve(match: loadedMatch, selfId: selfId) !=
            MatchRole.observer;

    return PopScope(
      // The bracket reads `competitionMatchesProvider` as a Future ;
      // refresh it on every exit so a status change here shows up
      // without a manual pull-to-refresh.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widgetRef.invalidate(competitionMatchesProvider);
      },
      child: Scaffold(
        appBar: ArenaAppBar(
          title: switch (async.value?.matchNumber) {
            null => l10n.matchRoomTitleDefault,
            final n => 'MATCH #$n',
          },
          onBack: () {
            widgetRef.invalidate(competitionMatchesProvider);
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(UserRoutes.home);
            }
          },
          actions: [
            if (isPlayer)
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: ArenaColors.gameEfoot,
                ),
                tooltip: l10n.matchRoomChatTooltip,
                onPressed: () =>
                    context.push(UserRoutes.matchChatPath(matchId)),
              ),
          ],
        ),
        body: ArenaScreenBackground(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              description: e.toString(),
              onRetry: () => widgetRef.invalidate(matchByIdProvider(matchId)),
            ),
            data: (m) {
              if (m == null) {
                return EmptyState(
                  icon: Icons.search_off_outlined,
                  title: l10n.matchRoomNotFoundTitle,
                  description: l10n.matchRoomNotFoundDescription,
                );
              }
              final role = MatchRole.resolve(match: m, selfId: selfId);
              return _MatchRoomBody(match: m, role: role, selfId: selfId);
            },
          ),
        ),
      ),
    );
  }
}

class _MatchRoomBody extends ConsumerWidget {
  const _MatchRoomBody({
    required this.match,
    required this.role,
    required this.selfId,
  });

  final ArenaMatch match;
  final MatchRole role;
  final String? selfId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(matchPlayersProvider(match.id));
    final step = MatchStep.fromStatus(match.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.md,
        ArenaSpacing.lg,
        ArenaSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepIndicator(step: step),
          const SizedBox(height: ArenaSpacing.sm),
          StepLabel(step: step),
          const SizedBox(height: ArenaSpacing.lg),
          PlayersHeader(
            match: match,
            role: role,
            p1: players.value?.p1,
            p2: players.value?.p2,
          ),
          // Anti-cheat recording banner (Android-only, no-op elsewhere).
          MatchRecordingLifecycle(match: match, selfId: selfId),
          if (role != MatchRole.observer)
            StartStreamingBanner(matchId: match.id),
          const SizedBox(height: ArenaSpacing.lg),
          StepBody(match: match, role: role, selfId: selfId),
        ],
      ),
    );
  }
}
