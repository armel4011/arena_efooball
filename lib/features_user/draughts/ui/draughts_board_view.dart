// =============================================================================
// ARENA — Plateau de dames : widget interactif (pseudo-3D).
// =============================================================================
// Damier plat (DraughtsBoardPainter) incliné en perspective par un Transform
// (rotateX + perspective). `transformHitTests` (true par défaut) renvoie les
// taps vers les coordonnées plates → hit-testing trivial (col/row = px / cell).
//
// Interaction tap-tap (mobile) : 1er tap = sélection d'une pièce jouable (ses
// cases d'arrivée s'allument), 2e tap = case d'arrivée → animation puis
// `onMove`. Re-tap d'une autre pièce → re-sélection.
// =============================================================================

import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:arena/features_user/draughts/ui/draughts_board_painter.dart';
import 'package:flutter/material.dart';

class DraughtsBoardView extends StatefulWidget {
  const DraughtsBoardView({
    required this.state,
    required this.onMove,
    this.interactive = true,
    this.lastFrom,
    this.lastTo,
    super.key,
  });

  final DraughtsGameState state;
  final ValueChanged<DraughtsMove> onMove;
  final bool interactive;
  final int? lastFrom;
  final int? lastTo;

  @override
  State<DraughtsBoardView> createState() => _DraughtsBoardViewState();
}

class _DraughtsBoardViewState extends State<DraughtsBoardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  int? _selected;
  DraughtsMove? _animatingMove;
  List<Piece>? _animBaseCells;

  @override
  void initState() {
    super.initState();
    _anim
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _animatingMove != null) {
          final move = _animatingMove!;
          _animatingMove = null;
          _animBaseCells = null;
          _anim.reset();
          widget.onMove(move);
        }
      });
  }

  @override
  void didUpdateWidget(covariant DraughtsBoardView old) {
    super.didUpdateWidget(old);
    // Nouvel état (notre coup committé, ou coup adverse) → on repart à zéro.
    if (old.state.toFen() != widget.state.toFen() && _animatingMove == null) {
      _selected = null;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  List<DraughtsMove> get _legal => widget.state.legalMoves();

  void _onTapIndex(int idx) {
    if (!widget.interactive || _animatingMove != null) return;
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
        _startMoveAnimation(move);
        return;
      }
    }

    // (Re)sélection d'une pièce qui a au moins un coup légal.
    final selectable = legal.any((m) => m.from == idx);
    setState(() => _selected = selectable ? idx : null);
  }

  void _startMoveAnimation(DraughtsMove move) {
    setState(() {
      _selected = null;
      _animBaseCells = widget.state.board.mutableCells();
      _animatingMove = move;
    });
    _anim.forward(from: 0);
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
    if (_animatingMove != null) {
      anim = DraughtsMoveAnim(
        path: _animatingMove!.path,
        captured: _animatingMove!.captured,
        movingPiece: (_animBaseCells ?? widget.state.board.cells)[
            _animatingMove!.from],
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
              ..rotateX(0.52), // inclinaison ~30°
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
