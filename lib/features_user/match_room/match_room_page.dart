import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/match_room/match_room_providers.dart';
import 'package:arena/features_user/match_room/widgets/match_locked_view.dart';
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

/// Politique d'accès « T-5 min » à la salle de match : on n'entre qu'à partir
/// de 5 minutes avant `scheduledAt`. Retourne `null` si l'accès est ouvert,
/// sinon un record dont `opensAt` est l'heure d'ouverture (`null` = match pas
/// encore programmé → verrouillé sans rebours). Un match déjà actif ou terminé
/// n'est jamais verrouillé (on n'enferme pas un match en cours / clôturé).
({DateTime? opensAt})? matchAccessLock(ArenaMatch m) {
  const openOnceReached = {
    MatchStatus.inProgress,
    MatchStatus.scorePending,
    MatchStatus.awaitingValidation,
    MatchStatus.disputed,
    MatchStatus.completed,
    MatchStatus.forfeited,
    MatchStatus.cancelled,
  };
  if (openOnceReached.contains(m.status)) return null;
  final at = m.scheduledAt;
  if (at == null) return (opensAt: null);
  final opensAt = at.subtract(const Duration(minutes: 5));
  if (DateTime.now().isBefore(opensAt)) return (opensAt: opensAt);
  return null;
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
            final n => l10n.matchRoomTitleNumbered(n),
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
              // Verrou d'accès : la salle n'ouvre qu'à T-5 min avant le coup
              // d'envoi planifié. L'app user n'héberge aucun admin
              // (enforceRoleForFlavor) → ce verrou s'applique à tous ses
              // utilisateurs (joueurs + observateurs) ; les admins gèrent les
              // matchs via l'app admin, non verrouillée.
              final lock = matchAccessLock(m);
              if (lock != null) {
                return MatchLockedView(
                  matchId: matchId,
                  scheduledAt: m.scheduledAt,
                  opensAt: lock.opensAt,
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
    final gameTypeAsync = ref.watch(matchGameTypeProvider(match.id));

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
          // Le type de jeu décide tout le bas de la room (plateau de dames
          // in-app vs flux déclaratif code + preuve). On ATTEND sa résolution :
          // un défaut « non-dames » afficherait le formulaire de preuve sur une
          // room de dames pendant le chargement (flash de demande de preuve).
          gameTypeAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: ArenaSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.xxl),
              child: ErrorState(
                description: e.toString(),
                onRetry: () =>
                    ref.invalidate(matchGameTypeProvider(match.id)),
              ),
            ),
            data: (gameType) {
              final isDraughts = gameType == GameType.draughts;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Anti-cheat recording banner (Android-only, no-op ailleurs).
                  // Inutile pour les dames : la partie est jouée in-app, le
                  // serveur tient l'historique des coups (pas d'écran tiers à
                  // filmer).
                  if (!isDraughts)
                    MatchRecordingLifecycle(match: match, selfId: selfId),
                  if (role != MatchRole.observer)
                    StartStreamingBanner(matchId: match.id),
                  const SizedBox(height: ArenaSpacing.lg),
                  StepBody(
                    match: match,
                    role: role,
                    selfId: selfId,
                    isDraughts: isDraughts,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
