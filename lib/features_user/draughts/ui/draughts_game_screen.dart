// =============================================================================
// ARENA — Plateau de dames : écran de partie (pseudo-3D).
// =============================================================================
// Phase 5 : écran jouable en local (pass-and-play) — sert de démo et de base
// à l'intégration match room (Phase 6, où l'état viendra du Realtime et les
// coups passeront par l'Edge Function d'autorité `draughts-game`).
//
// Les horloges décomptées ici sont LOCALES (démo) ; l'autorité d'horloge est
// côté serveur (EF) en match réel.
// =============================================================================

import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:arena/features_user/draughts/ui/draughts_board_theme.dart';
import 'package:arena/features_user/draughts/ui/draughts_board_view.dart';
import 'package:arena/features_user/draughts/ui/draughts_clock.dart';
import 'package:flutter/material.dart';

class DraughtsGameScreen extends StatefulWidget {
  const DraughtsGameScreen({
    this.initialState,
    this.whiteName = 'Joueur · Blancs',
    this.blackName = 'Joueur · Noirs',
    this.clockMs = 10 * 60 * 1000,
    super.key,
  });

  final DraughtsGameState? initialState;
  final String whiteName;
  final String blackName;
  final int clockMs;

  @override
  State<DraughtsGameScreen> createState() => _DraughtsGameScreenState();
}

class _DraughtsGameScreenState extends State<DraughtsGameScreen> {
  late DraughtsGameState _state;
  late int _whiteMs;
  late int _blackMs;
  int? _lastFrom;
  int? _lastTo;
  Timer? _ticker;
  DraughtsOutcome _forcedOutcome = DraughtsOutcome.ongoing;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      _state = widget.initialState ?? DraughtsGameState.initial();
      _whiteMs = widget.clockMs;
      _blackMs = widget.clockMs;
      _lastFrom = null;
      _lastTo = null;
      _forcedOutcome = DraughtsOutcome.ongoing;
    });
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isOver) {
        _ticker?.cancel();
        return;
      }
      setState(() {
        if (_state.turn == Side.white) {
          _whiteMs = (_whiteMs - 1000).clamp(0, widget.clockMs);
          if (_whiteMs == 0) _forcedOutcome = DraughtsOutcome.blackWins;
        } else {
          _blackMs = (_blackMs - 1000).clamp(0, widget.clockMs);
          if (_blackMs == 0) _forcedOutcome = DraughtsOutcome.whiteWins;
        }
      });
    });
  }

  bool get _isOver =>
      _forcedOutcome != DraughtsOutcome.ongoing ||
      _state.outcome() != DraughtsOutcome.ongoing;

  DraughtsOutcome get _outcome => _forcedOutcome != DraughtsOutcome.ongoing
      ? _forcedOutcome
      : _state.outcome();

  void _onMove(DraughtsMove move) {
    setState(() {
      _lastFrom = move.from;
      _lastTo = move.to;
      _state = _state.apply(move);
    });
    if (_isOver) _ticker?.cancel();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turn = _state.turn;
    return Scaffold(
      appBar: const ArenaAppBar(title: 'Jeu de Dames'),
      body: ArenaScreenBackground(
        accent: DraughtsBoardTheme.lastMove,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                DraughtsPlayerBar(
                  name: widget.blackName,
                  isWhite: false,
                  active: turn == Side.black && !_isOver,
                  clockMs: _blackMs,
                  low: _blackMs <= 30 * 1000,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: DraughtsBoardView(
                          state: _state,
                          interactive: !_isOver,
                          lastFrom: _lastFrom,
                          lastTo: _lastTo,
                          onMove: _onMove,
                        ),
                      ),
                      if (_isOver) _OutcomeBanner(outcome: _outcome, onReplay: _reset),
                    ],
                  ),
                ),
                DraughtsPlayerBar(
                  name: widget.whiteName,
                  isWhite: true,
                  active: turn == Side.white && !_isOver,
                  clockMs: _whiteMs,
                  low: _whiteMs <= 30 * 1000,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutcomeBanner extends StatelessWidget {
  const _OutcomeBanner({required this.outcome, required this.onReplay});

  final DraughtsOutcome outcome;
  final VoidCallback onReplay;

  String get _label => switch (outcome) {
        DraughtsOutcome.whiteWins => 'Victoire des Blancs',
        DraughtsOutcome.blackWins => 'Victoire des Noirs',
        DraughtsOutcome.draw => 'Partie nulle',
        DraughtsOutcome.ongoing => '',
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: ArenaColors.carbon.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DraughtsBoardTheme.selection.withValues(alpha: 0.7)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_label, style: ArenaText.h2.copyWith(color: ArenaColors.bone)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onReplay,
              child: const Text('Rejouer'),
            ),
          ],
        ),
      ),
    );
  }
}
