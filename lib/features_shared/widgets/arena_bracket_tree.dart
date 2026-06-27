import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:flutter/material.dart';

/// Arbre KO en **double arborescence** (mirror) : la moitié gauche du
/// bracket pousse de l'extérieur vers le centre (round 1 tout à gauche →
/// demi-finale près du centre), la moitié droite est son miroir (round 1
/// tout à droite → demi-finale près du centre), et la **finale + trophée
/// 🏆** trône au milieu. Les scores des matchs joués sont affichés.
///
/// Layout : `2·(R-1) + 1` colonnes (R = nombre de rounds). Chaque colonne
/// répartit ses matchs équitablement en hauteur (`spaceAround`). Les
/// connecteurs (gauche → centre, droite → centre, demi-finales → finale)
/// sont peints par [_BracketConnectors].
///
/// Wrappé dans un `InteractiveViewer` (pinch-to-zoom 0.5→3×) pour naviguer
/// un grand bracket sur mobile.
///
/// Styles par round : R1 neutre, intermédiaires bleu, demi-finales or,
/// finale gradient or + glow, match 3e place bronze.
class ArenaBracketTree extends StatelessWidget {
  const ArenaBracketTree({
    required this.matches,
    this.onTapMatch,
    this.usernamesByPlayerId = const {},
    this.maxScale = 3,
    super.key,
  });

  /// Liste plate des matches (déjà filtrés `singleElimination` côté caller).
  final List<ArenaMatch> matches;

  /// Tap sur une card. `null` = read-only.
  final ValueChanged<ArenaMatch>? onTapMatch;

  /// Résolution `playerId -> username` (fallback `P-XXXX`).
  final Map<String, String> usernamesByPlayerId;

  /// Plafond du zoom in.
  final double maxScale;

  // Layout constants — légèrement agrandis pour une meilleure lisibilité.
  static const double _columnWidth = 96;
  static const double _columnGap = 24;
  static const double _matchHeight = 54;
  static const double _matchGap = 8;
  static const double _connectorPad = 4;
  static const double _bottomMargin = 40;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    final byRound = <int, List<ArenaMatch>>{};
    for (final m in matches) {
      final r = m.round ?? 0;
      if (r <= 0) continue;
      (byRound[r] ??= []).add(m);
    }
    if (byRound.isEmpty) return const SizedBox.shrink();

    final rounds = byRound.keys.toList()..sort();
    for (final r in rounds) {
      byRound[r]!.sort((a, b) {
        final an = a.matchNumber ?? 1 << 30;
        final bn = b.matchNumber ?? 1 << 30;
        if (an != bn) return an.compareTo(bn);
        return a.id.compareTo(b.id);
      });
    }

    // Finale (dernier round) + éventuel match 3e place (même round).
    final finalRound = rounds.last;
    final finalList = byRound[finalRound]!;
    final finalMatch =
        finalList.where((m) => !m.isThirdPlace).cast<ArenaMatch?>().firstWhere(
              (m) => true,
              orElse: () => finalList.isNotEmpty ? finalList.first : null,
            );
    ArenaMatch? thirdPlace;
    for (final m in finalList) {
      if (m.isThirdPlace) thirdPlace = m;
    }

    final nonFinal = rounds.sublist(0, rounds.length - 1);

    // Cas dégénéré : pas de rounds avant la finale → finale seule, centrée.
    if (nonFinal.isEmpty) {
      return _soloFinale(context, finalMatch, thirdPlace);
    }

    // Scinde chaque round non-final en moitié gauche / droite.
    final leftByRound = <int, List<ArenaMatch>>{};
    final rightByRound = <int, List<ArenaMatch>>{};
    for (final r in nonFinal) {
      final list = byRound[r]!;
      final leftCount = list.length - list.length ~/ 2; // gauche = ceil
      leftByRound[r] = list.sublist(0, leftCount);
      rightByRound[r] = list.sublist(leftCount);
    }

    final k = nonFinal.length;
    final totalCols = 2 * k + 1;
    final leftR1Count = leftByRound[nonFinal.first]!.length;
    final treeHeight =
        leftR1Count * (_matchHeight + _matchGap) + _matchGap * 2;
    final fullHeight = treeHeight + _bottomMargin;
    final treeWidth =
        totalCols * _columnWidth + (totalCols - 1) * _columnGap;

    double colX(int col) => col * (_columnWidth + _columnGap);

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: maxScale,
      boundaryMargin: const EdgeInsets.all(200),
      child: SizedBox(
        width: treeWidth,
        height: fullHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BracketConnectors(
                  nonFinal: nonFinal,
                  leftByRound: leftByRound,
                  rightByRound: rightByRound,
                  k: k,
                  columnWidth: _columnWidth,
                  columnGap: _columnGap,
                  treeHeight: treeHeight,
                  pad: _connectorPad,
                ),
              ),
            ),
            // ── Colonnes GAUCHE : R1 (col 0) → demi (col k-1) ──
            for (var i = 0; i < k; i++)
              Positioned(
                left: colX(i),
                top: 0,
                width: _columnWidth,
                height: treeHeight,
                child: _RoundColumn(
                  matches: leftByRound[nonFinal[i]]!,
                  style: _styleForRound(nonFinal[i], finalRound),
                  matchHeight: _matchHeight,
                  mirrored: false,
                  onTapMatch: onTapMatch,
                  usernamesByPlayerId: usernamesByPlayerId,
                ),
              ),
            // ── Colonne CENTRE : finale (+ 3e place) ──
            Positioned(
              left: colX(k),
              top: 0,
              width: _columnWidth,
              height: treeHeight,
              child: _CenterColumn(
                finalMatch: finalMatch,
                thirdPlace: thirdPlace,
                onTapMatch: onTapMatch,
                usernamesByPlayerId: usernamesByPlayerId,
              ),
            ),
            // ── Colonnes DROITE (miroir) : demi (col k+1) → R1 (col 2k) ──
            for (var i = 0; i < k; i++)
              Positioned(
                left: colX(2 * k - i),
                top: 0,
                width: _columnWidth,
                height: treeHeight,
                child: _RoundColumn(
                  matches: rightByRound[nonFinal[i]]!,
                  style: _styleForRound(nonFinal[i], finalRound),
                  matchHeight: _matchHeight,
                  mirrored: true,
                  onTapMatch: onTapMatch,
                  usernamesByPlayerId: usernamesByPlayerId,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _soloFinale(
    BuildContext context,
    ArenaMatch? finalMatch,
    ArenaMatch? thirdPlace,
  ) {
    return Center(
      child: SizedBox(
        width: _columnWidth + 40,
        child: _CenterColumn(
          finalMatch: finalMatch,
          thirdPlace: thirdPlace,
          onTapMatch: onTapMatch,
          usernamesByPlayerId: usernamesByPlayerId,
        ),
      ),
    );
  }

  static _RoundStyle _styleForRound(int round, int finalRound) {
    if (round == finalRound) return _RoundStyle.finale;
    if (round == finalRound - 1) return _RoundStyle.demi;
    if (round == 1) return _RoundStyle.round1;
    return _RoundStyle.intermediate;
  }
}

enum _RoundStyle { round1, intermediate, demi, finale, thirdPlace }

class _RoundColumn extends StatelessWidget {
  const _RoundColumn({
    required this.matches,
    required this.style,
    required this.matchHeight,
    required this.mirrored,
    required this.onTapMatch,
    required this.usernamesByPlayerId,
  });

  final List<ArenaMatch> matches;
  final _RoundStyle style;
  final double matchHeight;
  final bool mirrored;
  final ValueChanged<ArenaMatch>? onTapMatch;
  final Map<String, String> usernamesByPlayerId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final m in matches)
          SizedBox(
            height: matchHeight,
            child: _MatchCard(
              match: m,
              style: m.isThirdPlace ? _RoundStyle.thirdPlace : style,
              mirrored: mirrored,
              onTap: onTapMatch == null ? null : () => onTapMatch!(m),
              usernamesByPlayerId: usernamesByPlayerId,
            ),
          ),
      ],
    );
  }
}

/// Colonne centrale : la finale (avec trophée) et, si présent, le match de
/// la 3e place, empilés et centrés verticalement.
class _CenterColumn extends StatelessWidget {
  const _CenterColumn({
    required this.finalMatch,
    required this.thirdPlace,
    required this.onTapMatch,
    required this.usernamesByPlayerId,
  });

  final ArenaMatch? finalMatch;
  final ArenaMatch? thirdPlace;
  final ValueChanged<ArenaMatch>? onTapMatch;
  final Map<String, String> usernamesByPlayerId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (finalMatch != null)
          SizedBox(
            height: 64,
            child: _MatchCard(
              match: finalMatch!,
              style: _RoundStyle.finale,
              mirrored: false,
              onTap:
                  onTapMatch == null ? null : () => onTapMatch!(finalMatch!),
              usernamesByPlayerId: usernamesByPlayerId,
            ),
          ),
        if (thirdPlace != null) ...[
          const SizedBox(height: ArenaSpacing.md),
          SizedBox(
            height: 50,
            child: _MatchCard(
              match: thirdPlace!,
              style: _RoundStyle.thirdPlace,
              mirrored: false,
              onTap:
                  onTapMatch == null ? null : () => onTapMatch!(thirdPlace!),
              usernamesByPlayerId: usernamesByPlayerId,
            ),
          ),
        ],
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.style,
    required this.mirrored,
    required this.onTap,
    required this.usernamesByPlayerId,
  });

  final ArenaMatch match;
  final _RoundStyle style;
  final bool mirrored;
  final VoidCallback? onTap;
  final Map<String, String> usernamesByPlayerId;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, isGradient) = _palette(style);
    final p1 = _label(match.player1Id, usernamesByPlayerId);
    final p2 = _label(match.player2Id, usernamesByPlayerId);
    final winner = match.winnerId;
    final p1Win = winner != null && winner == match.player1Id;
    final p2Win = winner != null && winner == match.player2Id;
    final hasScore = match.score1 != null && match.score2 != null;

    final card = Container(
      decoration: BoxDecoration(
        gradient: isGradient
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ArenaColors.tierGoldWarm, ArenaColors.tierGoldDeep],
              )
            : null,
        color: isGradient ? null : bg,
        border: border == null ? null : Border.all(color: border, width: 1),
        borderRadius: BorderRadius.circular(6),
        boxShadow: style == _RoundStyle.finale
            ? const [
                BoxShadow(
                  color: ArenaColors.goldGlow,
                  blurRadius: 16,
                  spreadRadius: -1,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: style == _RoundStyle.finale
          ? _FinaleContent(score1: match.score1, score2: match.score2)
          : style == _RoundStyle.thirdPlace
              ? _ThirdPlaceContent(score1: match.score1, score2: match.score2)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PlayerLine(
                      label: p1,
                      score: hasScore ? match.score1 : null,
                      win: p1Win,
                      fg: fg,
                      mirrored: mirrored,
                    ),
                    const SizedBox(height: 2),
                    _PlayerLine(
                      label: p2,
                      score: hasScore ? match.score2 : null,
                      win: p2Win,
                      fg: fg,
                      mirrored: mirrored,
                    ),
                  ],
                ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: card,
      ),
    );
  }

  static String _label(
    String? playerId,
    Map<String, String> usernamesByPlayerId,
  ) {
    if (playerId == null || playerId.isEmpty) return '—';
    final username = usernamesByPlayerId[playerId];
    if (username != null && username.isNotEmpty) return username;
    final short = playerId.length > 4 ? playerId.substring(0, 4) : playerId;
    return 'P-${short.toUpperCase()}';
  }

  static (Color, Color?, Color, bool) _palette(_RoundStyle s) => switch (s) {
        _RoundStyle.round1 => (
            ArenaColors.bone.withValues(alpha: 0.04),
            ArenaColors.bone.withValues(alpha: 0.08),
            ArenaColors.silver,
            false,
          ),
        _RoundStyle.intermediate => (
            ArenaColors.signalBlue.withValues(alpha: 0.10),
            ArenaColors.signalBlue,
            ArenaColors.signalBlue,
            false,
          ),
        _RoundStyle.demi => (
            ArenaColors.tierGoldWarm.withValues(alpha: 0.10),
            ArenaColors.tierGoldWarm,
            ArenaColors.tierGoldWarm,
            false,
          ),
        _RoundStyle.finale => (
            ArenaColors.tierGoldWarm,
            null,
            ArenaColors.void_,
            true,
          ),
        _RoundStyle.thirdPlace => (
            ArenaColors.tierBronze.withValues(alpha: 0.12),
            ArenaColors.tierBronze,
            ArenaColors.tierBronze,
            false,
          ),
      };
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({
    required this.label,
    required this.score,
    required this.win,
    required this.fg,
    required this.mirrored,
  });

  final String label;
  final int? score;
  final bool win;
  final Color fg;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final name = Expanded(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: mirrored ? TextAlign.right : TextAlign.left,
        style: ArenaText.monoSmall.copyWith(
          fontSize: 11,
          color: win ? ArenaColors.bone : fg,
          fontWeight: win ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
    final scoreWidget = score == null
        ? const SizedBox.shrink()
        : Padding(
            padding: EdgeInsets.only(
              left: mirrored ? 0 : 6,
              right: mirrored ? 6 : 0,
            ),
            child: Text(
              '$score',
              style: ArenaText.monoSmall.copyWith(
                fontSize: 11,
                color: win ? ArenaColors.bone : fg,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
    // Miroir : score à gauche, nom à droite.
    final children =
        mirrored ? [scoreWidget, name] : [name, scoreWidget];
    return Row(children: children);
  }
}

class _FinaleContent extends StatelessWidget {
  const _FinaleContent({required this.score1, required this.score2});

  final int? score1;
  final int? score2;

  @override
  Widget build(BuildContext context) {
    final hasScore = score1 != null && score2 != null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🏆', style: TextStyle(fontSize: 18, height: 1)),
        const SizedBox(height: 2),
        Text(
          hasScore ? '$score1 — $score2' : 'FINALE',
          style: ArenaText.h2.copyWith(
            color: ArenaColors.void_,
            fontSize: 14,
            letterSpacing: 1,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _ThirdPlaceContent extends StatelessWidget {
  const _ThirdPlaceContent({required this.score1, required this.score2});

  final int? score1;
  final int? score2;

  @override
  Widget build(BuildContext context) {
    final hasScore = score1 != null && score2 != null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🥉', style: TextStyle(fontSize: 14, height: 1)),
        const SizedBox(height: 1),
        Text(
          hasScore ? '$score1 — $score2' : '3e PLACE',
          style: ArenaText.h2.copyWith(
            color: ArenaColors.tierBronze,
            fontSize: 12,
            letterSpacing: 0.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Peint les connecteurs de la double arborescence :
///  * Gauche : R1 (extérieur) → demi-finale (centre), flux vers la droite.
///  * Droite : miroir, flux vers la gauche.
///  * Centre : les deux demi-finales rejoignent la finale.
///
/// Trait `silver @ 35 %`.
class _BracketConnectors extends CustomPainter {
  _BracketConnectors({
    required this.nonFinal,
    required this.leftByRound,
    required this.rightByRound,
    required this.k,
    required this.columnWidth,
    required this.columnGap,
    required this.treeHeight,
    required this.pad,
  });

  final List<int> nonFinal;
  final Map<int, List<ArenaMatch>> leftByRound;
  final Map<int, List<ArenaMatch>> rightByRound;
  final int k;
  final double columnWidth;
  final double columnGap;
  final double treeHeight;
  final double pad;

  static const _stroke = 1.2;

  double _colX(int col) => col * (columnWidth + columnGap);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ArenaColors.silver.withValues(alpha: 0.35)
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke;

    // ── GAUCHE : colonnes 0..k-1, flux vers la droite ──
    for (var i = 0; i < k - 1; i++) {
      final fromCount = leftByRound[nonFinal[i]]!.length;
      final toCount = leftByRound[nonFinal[i + 1]]!.length;
      if (toCount == 0 || toCount * 2 != fromCount) continue;
      final fromSlot = treeHeight / fromCount;
      final toSlot = treeHeight / toCount;
      final fromRightX = _colX(i) + columnWidth + pad;
      final toLeftX = _colX(i + 1) - pad;
      final midX = (fromRightX + toLeftX) / 2;
      for (var j = 0; j < toCount; j++) {
        final yTop = fromSlot * (2 * j) + fromSlot / 2;
        final yBot = fromSlot * (2 * j + 1) + fromSlot / 2;
        final yMid = toSlot * j + toSlot / 2;
        canvas
          ..drawLine(Offset(fromRightX, yTop), Offset(midX, yTop), paint)
          ..drawLine(Offset(fromRightX, yBot), Offset(midX, yBot), paint)
          ..drawLine(Offset(midX, yTop), Offset(midX, yBot), paint)
          ..drawLine(Offset(midX, yMid), Offset(toLeftX, yMid), paint);
      }
    }

    // ── DROITE : R1 en col 2k → demi en col k+1, flux vers la gauche ──
    for (var i = 0; i < k - 1; i++) {
      final fromCount = rightByRound[nonFinal[i]]!.length;
      final toCount = rightByRound[nonFinal[i + 1]]!.length;
      if (toCount == 0 || toCount * 2 != fromCount) continue;
      final fromSlot = treeHeight / fromCount;
      final toSlot = treeHeight / toCount;
      final cFrom = 2 * k - i;
      final cTo = 2 * k - i - 1;
      final fromLeftX = _colX(cFrom) - pad;
      final toRightX = _colX(cTo) + columnWidth + pad;
      final midX = (fromLeftX + toRightX) / 2;
      for (var j = 0; j < toCount; j++) {
        final yTop = fromSlot * (2 * j) + fromSlot / 2;
        final yBot = fromSlot * (2 * j + 1) + fromSlot / 2;
        final yMid = toSlot * j + toSlot / 2;
        canvas
          ..drawLine(Offset(fromLeftX, yTop), Offset(midX, yTop), paint)
          ..drawLine(Offset(fromLeftX, yBot), Offset(midX, yBot), paint)
          ..drawLine(Offset(midX, yTop), Offset(midX, yBot), paint)
          ..drawLine(Offset(midX, yMid), Offset(toRightX, yMid), paint);
      }
    }

    // ── CENTRE : demi-finales (col k-1 gauche, col k+1 droite) → finale ──
    final finalY = treeHeight / 2;
    final leftSemi = leftByRound[nonFinal.last]!;
    final rightSemi = rightByRound[nonFinal.last]!;
    final finalLeftX = _colX(k) - pad;
    final finalRightX = _colX(k) + columnWidth + pad;
    if (leftSemi.isNotEmpty) {
      final rightEdge = _colX(k - 1) + columnWidth + pad;
      canvas.drawLine(
        Offset(rightEdge, finalY),
        Offset(finalLeftX, finalY),
        paint,
      );
    }
    if (rightSemi.isNotEmpty) {
      final leftEdge = _colX(k + 1) - pad;
      canvas.drawLine(
        Offset(leftEdge, finalY),
        Offset(finalRightX, finalY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BracketConnectors old) =>
      old.nonFinal != nonFinal ||
      old.leftByRound != leftByRound ||
      old.rightByRound != rightByRound ||
      old.k != k ||
      old.columnWidth != columnWidth ||
      old.columnGap != columnGap ||
      old.treeHeight != treeHeight;
}
