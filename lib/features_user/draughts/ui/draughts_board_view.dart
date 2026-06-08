// =============================================================================
// ARENA — Plateau de dames : widget interactif (pseudo-3D).
// =============================================================================
// Damier plat (DraughtsBoardPainter) incliné en perspective par un Transform
// (rotateX + perspective ; rotateZ pour le joueur Noir). `transformHitTests`
// renvoie les taps vers les coordonnées plates → hit-testing trivial.
//
// Animation pilotée par l'ÉTAT AUTORITAIRE : à chaque changement de `state`
// (mon coup confirmé OU coup adverse reçu par le stream), le coup est dérivé
// par diff ancien→nouveau plateau et animé. Le tap envoie `onMove` puis attend
// le nouvel état (pas d'optimistic divergent — l'autorité est serveur).
// =============================================================================

import 'dart:math' as math;

import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:arena/features_user/draughts/ui/draughts_board_painter.dart';
import 'package:flutter/material.dart';

class DraughtsBoardView extends StatefulWidget {
  const DraughtsBoardView({
    required this.state,
    required this.onMove,
    this.interactive = true,
    this.flip = false,
    this.lastFrom,
    this.lastTo,
    super.key,
  });

  final DraughtsGameState state;
  final ValueChanged<DraughtsMove> onMove;
  final bool interactive;

  /// Oriente le plateau côté Noirs (le joueur voit ses pions en bas).
  final bool flip;
  final int? lastFrom;
  final int? lastTo;

  @override
  State<DraughtsBoardView> createState() => _DraughtsBoardViewState();
}

class _DraughtsBoardViewState extends State<DraughtsBoardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  int? _selected;

  // Animation du dernier coup (mien ou adverse), dérivée du diff d'état.
  DraughtsMove? _animatingMove;
  List<Piece>? _animBaseCells;

  // Anti-double-soumission : vrai entre l'envoi d'un coup et l'arrivée du
  // nouvel état (aller-retour Edge Function).
  bool _awaitingState = false;

  @override
  void initState() {
    super.initState();
    _anim
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _animatingMove = null;
            _animBaseCells = null;
          });
          _anim.reset();
        }
      });
  }

  @override
  void didUpdateWidget(covariant DraughtsBoardView old) {
    super.didUpdateWidget(old);
    if (old.state.toFen() == widget.state.toFen()) return;

    _selected = null;
    _awaitingState = false;

    // Anime le coup qui a transformé l'ancien état en le nouveau (dérivé par
    // diff). Si non dérivable (ex. mort subite → plateau réinitialisé), snap.
    final move = DraughtsRules.deriveMove(
      old.state.board.cells,
      widget.state.board.cells,
    );
    if (move != null) {
      _animBaseCells = old.state.board.mutableCells();
      _animatingMove = move;
      _anim.forward(from: 0);
    } else {
      _animatingMove = null;
      _animBaseCells = null;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  List<DraughtsMove> get _legal => widget.state.legalMoves();

  void _onTapIndex(int idx) {
    if (!widget.interactive || _animatingMove != null || _awaitingState) {
      return;
    }
    final legal = _legal;

    if (_selected != null) {
      final move = legal
          .where((m) => m.from == _selected && m.to == idx)
          .fold<DraughtsMove?>(
            null,
            (best, m) =>
                best == null || m.captured.length > best.captured.length
                    ? m
                    : best,
          );
      if (move != null) {
        setState(() {
          _selected = null;
          _awaitingState = true; // attend le nouvel état autoritaire
        });
        widget.onMove(move);
        return;
      }
    }

    final selectable = legal.any((m) => m.from == idx);
    setState(() => _selected = selectable ? idx : null);
  }

  void _handleTap(Offset local, double boardSize) {
    final cell = boardSize / DraughtsGeometry.boardSize;
    final col = (local.dx / cell).floor();
    final row = (local.dy / cell).floor();
    final idx = DraughtsGeometry.indexAt(row, col);
    if (idx >= 0) _onTapIndex(idx);
  }

  @override
  Widget build(BuildContext context) {
    final cells = _animBaseCells ?? widget.state.board.cells;
    final targets = _selected == null
        ? const <int>{}
        : _legal
            .where((m) => m.from == _selected)
            .map((m) => m.to)
            .toSet();

    DraughtsMoveAnim? anim;
    if (_animatingMove != null && _animBaseCells != null) {
      anim = DraughtsMoveAnim(
        path: _animatingMove!.path,
        captured: _animatingMove!.captured,
        movingPiece: _animBaseCells![_animatingMove!.from],
        t: _anim.value,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide;
        return Center(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0011) // force de la perspective
              ..rotateX(0.52) // inclinaison ~30°
              ..rotateZ(widget.flip ? math.pi : 0), // orientation Noirs
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _handleTap(d.localPosition, boardSize),
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: CustomPaint(
                  painter: DraughtsBoardPainter(
                    cells: cells,
                    selected: _selected,
                    legalTargets: targets,
                    lastFrom: widget.lastFrom,
                    lastTo: widget.lastTo,
                    anim: anim,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
