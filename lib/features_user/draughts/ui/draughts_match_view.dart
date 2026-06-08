// =============================================================================
// ARENA — Jeu de dames : vue de match (Realtime + Edge Function d'autorité).
// =============================================================================
// Branchée dans la match room pour les compétitions `draughts` (Phase 6).
// L'état vient du stream `draughtsActiveGameProvider` (autorité serveur) ; les
// coups partent vers l'Edge Function `draughts-game` (validation dure). Le
// plateau anime localement (optimistic léger), le stream réconcilie.
//
// Horloges affichées en live (décompte local du côté au trait à partir de
// last_move_at) — l'autorité reste serveur ; à 0, on réclame le timeout (EF).
// =============================================================================

import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/draughts_game_row.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/draughts_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:arena/features_user/draughts/ui/draughts_board_view.dart';
import 'package:arena/features_user/draughts/ui/draughts_clock.dart';
import 'package:arena/features_user/match_room/match_room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Salle d'attente draughts : démarrage DIRECT (pas de code de room). Le
/// premier joueur qui lance bascule le match en `in_progress`.
class DraughtsLobbyView extends ConsumerStatefulWidget {
  const DraughtsLobbyView({required this.match, super.key});

  final ArenaMatch match;

  @override
  ConsumerState<DraughtsLobbyView> createState() => _DraughtsLobbyViewState();
}

class _DraughtsLobbyViewState extends ConsumerState<DraughtsLobbyView> {
  bool _starting = false;

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await ref.read(matchRepositoryProvider).markInProgress(widget.match.id);
    } catch (_) {
      if (mounted) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de démarrer la partie')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.grid_on, size: 48, color: ArenaColors.gameDraughts),
          const SizedBox(height: ArenaSpacing.md),
          Text('Partie de dames', style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'Plateau 10×10 · 20 pions · cadence rapide.\n'
            'Lancez quand vous êtes prêts — pas de code à partager.',
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
          const SizedBox(height: ArenaSpacing.lg),
          FilledButton.icon(
            onPressed: _starting ? null : _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(_starting ? 'Démarrage…' : 'Démarrer la partie'),
          ),
        ],
      ),
    );
  }
}

/// Partie en cours : plateau jouable câblé au serveur.
class DraughtsMatchView extends ConsumerStatefulWidget {
  const DraughtsMatchView({
    required this.match,
    required this.selfId,
    this.spectator = false,
    super.key,
  });

  final ArenaMatch match;
  final String? selfId;

  /// Observateur (non-joueur) : plateau en lecture seule, aucune action
  /// (pas de démarrage, pas de coup, pas de réclamation de temps).
  final bool spectator;

  @override
  ConsumerState<DraughtsMatchView> createState() => _DraughtsMatchViewState();
}

class _DraughtsMatchViewState extends ConsumerState<DraughtsMatchView> {
  Timer? _ticker;
  bool _startRequested = false;
  String? _timeoutClaimedForGame;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _ensureStarted(DraughtsGameRow? game) {
    if (widget.spectator || game != null || _startRequested) return;
    _startRequested = true;
    Future<void>.microtask(() async {
      try {
        await ref.read(draughtsRepositoryProvider).start(widget.match.id);
      } catch (_) {
        _startRequested = false; // autorise un nouvel essai
        _snack('Impossible de démarrer la partie');
      }
    });
  }

  Future<void> _onMove(DraughtsMove m) async {
    try {
      await ref.read(draughtsRepositoryProvider).move(widget.match.id, m);
    } on DraughtsActionException catch (e) {
      _snack(_messageFor(e.code));
    } catch (_) {
      _snack('Coup refusé');
    }
  }

  void _maybeClaimTimeout(DraughtsGameRow g) {
    if (widget.spectator || !g.isActive || _timeoutClaimedForGame == g.id) {
      return;
    }
    final ms = _displayMs(g, g.turn);
    if (ms != null && ms <= 0) {
      _timeoutClaimedForGame = g.id;
      Future<void>.microtask(() async {
        try {
          await ref.read(draughtsRepositoryProvider).claimTimeout(widget.match.id);
        } catch (_) {
          _timeoutClaimedForGame = null;
        }
      });
    }
  }

  int? _displayMs(DraughtsGameRow g, Side side) {
    final base = side == Side.white ? g.whiteClockMs : g.blackClockMs;
    if (base == null) return null;
    if (g.isActive && g.turn == side) {
      final elapsed = DateTime.now().difference(g.lastMoveAt).inMilliseconds;
      return (base - elapsed).clamp(0, base);
    }
    return base;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _messageFor(String code) => switch (code) {
        'illegal_move' => 'Coup illégal',
        'not_your_turn' => "Ce n'est pas votre tour",
        'move_conflict' => 'Coup déjà joué',
        'no_active_game' => 'Aucune partie en cours',
        _ => 'Coup refusé',
      };

  String _name(Profile? p) => p?.username ?? 'Joueur';

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(draughtsActiveGameProvider(widget.match.id));
    final players = ref.watch(matchPlayersProvider(widget.match.id));

    return gameAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: ArenaSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: ArenaSpacing.xxl),
        child: Center(child: Text('Partie indisponible')),
      ),
      data: (game) {
        _ensureStarted(game);
        if (game == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: ArenaSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        _maybeClaimTimeout(game);

        final state = game.toState();
        final myColor = game.colorOf(widget.selfId);
        final interactive =
            game.isActive && myColor != null && myColor == game.turn;

        final p1 = players.value?.p1;
        final p2 = players.value?.p2;
        final whiteName =
            game.whiteId == widget.match.player1Id ? _name(p1) : _name(p2);
        final blackName =
            game.blackId == widget.match.player1Id ? _name(p1) : _name(p2);

        return Column(
          children: [
            DraughtsPlayerBar(
              name: blackName,
              isWhite: false,
              active: game.isActive && game.turn == Side.black,
              clockMs: _displayMs(game, Side.black),
              low: (_displayMs(game, Side.black) ?? 99999) <= 30000,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            AspectRatio(
              aspectRatio: 1,
              child: DraughtsBoardView(
                state: state,
                interactive: interactive,
                flip: myColor == Side.black,
                onMove: _onMove,
              ),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            DraughtsPlayerBar(
              name: whiteName,
              isWhite: true,
              active: game.isActive && game.turn == Side.white,
              clockMs: _displayMs(game, Side.white),
              low: (_displayMs(game, Side.white) ?? 99999) <= 30000,
            ),
            if (!interactive && game.isActive)
              Padding(
                padding: const EdgeInsets.only(top: ArenaSpacing.sm),
                child: Text(
                  widget.spectator
                      ? 'Vous regardez la partie'
                      : myColor == null
                          ? 'Partie en cours'
                          : "En attente de l'adversaire…",
                  style: ArenaText.small,
                ),
              ),
          ],
        );
      },
    );
  }
}
