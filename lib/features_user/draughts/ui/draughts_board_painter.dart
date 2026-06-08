// =============================================================================
// ARENA — Plateau de dames : peintre (rendu plat, incliné ensuite en 3D).
// =============================================================================
// Dessine un damier 10×10 vu de dessus ; l'inclinaison « pseudo-3D » est
// appliquée par un Transform en perspective côté widget (DraughtsBoardView).
// Le hit-testing se fait donc en coordonnées plates → trivial.
//
// Rendu : cases dégradées + lignes d'ombre, jetons glossy (dégradé radial +
// reflet spéculaire + ombre portée), dames couronnées, glow sur les cases
// jouables, surbrillance de la sélection et du dernier coup, animation de
// glisse/rafle (pièce mobile interpolée + captures qui s'estompent).
// =============================================================================

import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:arena/features_user/draughts/ui/draughts_board_theme.dart';
import 'package:flutter/material.dart';

/// État d'animation d'un coup (glisse + rafle).
class DraughtsMoveAnim {
  const DraughtsMoveAnim({
    required this.path,
    required this.captured,
    required this.movingPiece,
    required this.t,
  });

  final List<int> path; // cases traversées (index 0-49), départ→arrivée
  final List<int> captured; // index capturés (s'estompent)
  final Piece movingPiece;
  final double t; // progression 0→1
}

class DraughtsBoardPainter extends CustomPainter {
  DraughtsBoardPainter({
    required this.cells,
    required this.selected,
    required this.legalTargets,
    required this.lastFrom,
    required this.lastTo,
    required this.anim,
  });

  final List<Piece> cells;
  final int? selected;
  final Set<int> legalTargets;
  final int? lastFrom;
  final int? lastTo;
  final DraughtsMoveAnim? anim;

  static const int _n = DraughtsGeometry.boardSize; // 10

  @override
  void paint(Canvas canvas, Size size) {
    final boardSize = size.shortestSide;
    final cell = boardSize / _n;
    final origin = Offset(
      (size.width - boardSize) / 2,
      (size.height - boardSize) / 2,
    );

    _paintFrame(canvas, origin, boardSize);
    _paintSquares(canvas, origin, cell);
    _paintHighlights(canvas, origin, cell);
    _paintPieces(canvas, origin, cell);
  }

  Offset _centerOf(Offset origin, double cell, int index) {
    final row = DraughtsGeometry.rowOf(index);
    final col = DraughtsGeometry.colOf(index);
    return origin + Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }

  void _paintFrame(Canvas canvas, Offset origin, double boardSize) {
    final pad = boardSize * 0.035;
    final outer = Rect.fromLTWH(
      origin.dx - pad,
      origin.dy - pad,
      boardSize + 2 * pad,
      boardSize + 2 * pad,
    );
    final rrect = RRect.fromRectAndRadius(outer, Radius.circular(boardSize * 0.04));
    canvas
      ..drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [DraughtsBoardTheme.frameHi, DraughtsBoardTheme.frame],
          ).createShader(outer),
      )
      ..drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = DraughtsBoardTheme.frameHi,
      );
  }

  void _paintSquares(Canvas canvas, Offset origin, double cell) {
    for (var row = 0; row < _n; row++) {
      for (var col = 0; col < _n; col++) {
        final rect = Rect.fromLTWH(
          origin.dx + col * cell,
          origin.dy + row * cell,
          cell,
          cell,
        );
        final isDark = DraughtsGeometry.indexAt(row, col) >= 0;
        final hi = isDark
            ? DraughtsBoardTheme.darkSquare
            : DraughtsBoardTheme.lightSquare;
        final lo = isDark
            ? DraughtsBoardTheme.darkSquareLo
            : DraughtsBoardTheme.lightSquareLo;
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [hi, lo],
            ).createShader(rect),
        );
      }
    }
    // Lignes d'ombre subtiles (profondeur du quadrillage).
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = DraughtsBoardTheme.squareLine;
    for (var i = 0; i <= _n; i++) {
      canvas
        ..drawLine(
          origin + Offset(i * cell, 0),
          origin + Offset(i * cell, _n * cell),
          line,
        )
        ..drawLine(
          origin + Offset(0, i * cell),
          origin + Offset(_n * cell, i * cell),
          line,
        );
    }
  }

  void _paintHighlights(Canvas canvas, Offset origin, double cell) {
    void tintSquare(int index, Color color, double alpha) {
      final row = DraughtsGeometry.rowOf(index);
      final col = DraughtsGeometry.colOf(index);
      final rect = Rect.fromLTWH(
        origin.dx + col * cell,
        origin.dy + row * cell,
        cell,
        cell,
      );
      canvas
        ..drawRect(rect, Paint()..color = color.withValues(alpha: alpha))
        ..drawRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = color.withValues(alpha: alpha + 0.25),
      );
    }

    if (lastFrom != null) tintSquare(lastFrom!, DraughtsBoardTheme.lastMove, 0.16);
    if (lastTo != null) tintSquare(lastTo!, DraughtsBoardTheme.lastMove, 0.22);
    if (selected != null) {
      tintSquare(selected!, DraughtsBoardTheme.selection, 0.22);
    }

    // Cases jouables : pastille + halo bleu signal.
    for (final t in legalTargets) {
      final c = _centerOf(origin, cell, t);
      final occupied = !cells[t].isEmpty;
      final r = occupied ? cell * 0.44 : cell * 0.15;
      if (occupied) {
        // Cible de capture / atterrissage occupé : anneau.
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.07
            ..color = DraughtsBoardTheme.legalTarget.withValues(alpha: 0.85),
        );
      } else {
        canvas
          ..drawCircle(
            c,
            r * 2.1,
            Paint()
              ..color = DraughtsBoardTheme.legalTarget.withValues(alpha: 0.18)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          )
          ..drawCircle(
            c,
            r,
            Paint()..color =
                DraughtsBoardTheme.legalTarget.withValues(alpha: 0.9),
        );
      }
    }
  }

  void _paintPieces(Canvas canvas, Offset origin, double cell) {
    final animating = anim != null;
    final capturedSet = animating ? anim!.captured.toSet() : const <int>{};
    final movingFrom = animating ? anim!.path.first : -1;

    for (var i = 0; i < cells.length; i++) {
      final piece = cells[i];
      if (piece.isEmpty) continue;
      if (animating && i == movingFrom) continue; // dessinée en mouvement
      var alpha = 1.0;
      if (animating && capturedSet.contains(i)) {
        alpha = (1.0 - anim!.t).clamp(0.0, 1.0); // capture qui s'estompe
        if (alpha <= 0.02) continue;
      }
      final lifted = !animating && selected == i;
      _drawPiece(canvas, _centerOf(origin, cell, i), cell, piece, alpha, lifted);
    }

    if (animating) {
      _drawPiece(
        canvas,
        _animPosition(origin, cell),
        cell,
        anim!.movingPiece,
        1,
        true,
      );
    }
  }

  Offset _animPosition(Offset origin, double cell) {
    final path = anim!.path;
    final segs = path.length - 1;
    if (segs <= 0) return _centerOf(origin, cell, path.first);
    final scaled = (anim!.t * segs).clamp(0.0, segs.toDouble());
    final seg = scaled.floor().clamp(0, segs - 1);
    final local = scaled - seg;
    final a = _centerOf(origin, cell, path[seg]);
    final b = _centerOf(origin, cell, path[seg + 1]);
    return Offset.lerp(a, b, local)!;
  }

  void _drawPiece(
    Canvas canvas,
    Offset center,
    double cell,
    Piece piece,
    double alpha,
    bool lifted,
  ) {
    final r = cell * (lifted ? 0.40 : 0.37);
    final isWhite = piece.isWhite;

    // Ombre portée (plus marquée si la pièce est « soulevée »).
    final shadowOffset = lifted ? cell * 0.16 : cell * 0.08;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(shadowOffset * 0.4, shadowOffset),
        width: r * 2.05,
        height: r * 1.7,
      ),
      Paint()
        ..color = DraughtsBoardTheme.shadow(lifted ? 0.55 : 0.42 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, lifted ? 8 : 4),
    );

    // Corps : dégradé radial (lumière en haut-gauche).
    final top = isWhite ? DraughtsBoardTheme.whiteTop : DraughtsBoardTheme.darkTop;
    final shade =
        isWhite ? DraughtsBoardTheme.whiteShade : DraughtsBoardTheme.darkShade;
    final bodyRect = Rect.fromCircle(center: center, radius: r);
    final rimColor =
        (isWhite ? DraughtsBoardTheme.whiteRim : DraughtsBoardTheme.darkRim)
            .withValues(alpha: alpha);
    canvas
      ..drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.1,
            colors: [
              top.withValues(alpha: alpha),
              shade.withValues(alpha: alpha),
            ],
          ).createShader(bodyRect),
      )
      // Rim (anneau d'épaisseur du jeton).
      ..drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.035
          ..color = rimColor,
      )
      // Reflet spéculaire (petit ovale clair en haut-gauche).
      ..drawOval(
        Rect.fromCenter(
          center: center + Offset(-r * 0.32, -r * 0.40),
          width: r * 0.8,
          height: r * 0.5,
        ),
        Paint()
          ..color = DraughtsBoardTheme.specular.withValues(alpha: alpha * 0.7),
      );

    // Dame : couronne (double anneau or + point central).
    if (piece.isKing) {
      canvas
        ..drawCircle(
          center,
          r * 0.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.04
            ..color = DraughtsBoardTheme.kingMark.withValues(alpha: alpha),
        )
        ..drawCircle(
          center,
          r * 0.16,
          Paint()..color = DraughtsBoardTheme.kingMark.withValues(alpha: alpha),
        );
    }
  }

  @override
  bool shouldRepaint(covariant DraughtsBoardPainter old) =>
      old.cells != cells ||
      old.selected != selected ||
      old.legalTargets != legalTargets ||
      old.lastFrom != lastFrom ||
      old.lastTo != lastTo ||
      old.anim?.t != anim?.t;
}
