import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:flutter/material.dart';

/// Arbre KO arborescent — reproduit l'écran #20 de
/// `arena_premium_reference.html` (single-elim 16 players).
///
/// Layout : N colonnes horizontales (1 par round, déterminé par
/// `matches[i].round`), chaque colonne occupe une part équivalente de
/// la hauteur disponible avec `MainAxisAlignment.spaceAround`. Les
/// lignes connectrices entre rounds sont peintes via `_BracketConnectors`
/// (CustomPainter) en arrière-plan : 2 segments horizontaux depuis le
/// bord droit de chaque match du round N + 1 segment vertical joignant
/// leurs centres + 1 segment horizontal entrant dans le successeur en
/// round N+1.
///
/// Wrappé dans un `InteractiveViewer` (pinch-to-zoom 0.5→3.0×, pan
/// permissif via `boundaryMargin: EdgeInsets.all(200)`) pour permettre
/// de naviguer dans un bracket 16 ou 32 joueurs sur écran mobile.
///
/// Styles par round (de l'extérieur vers la finale) :
/// * Round 1 — fond `bone @ 4 %`, texte `silver`, accent neutre.
/// * Rounds intermédiaires — fond `signalBlue @ 10 %`, border
///   `signalBlue`, texte `signalBlue`.
/// * Demi-finales — fond `gold @ 10 %`, border `gold`, texte `gold`.
/// * Finale — gradient `tierGoldWarm → tierGoldDeep`, texte `void_` en
///   Bebas Neue 14 px, glow `gold @ 40 %`.
///
/// Mode read-only par défaut. Pour activer l'interaction : passer
/// `onTapMatch` (déclenché quand le joueur tape une card de match).
class ArenaBracketTree extends StatelessWidget {
  const ArenaBracketTree({
    required this.matches,
    this.onTapMatch,
    this.usernamesByPlayerId = const {},
    this.maxScale = 3,
    super.key,
  });

  /// Liste plate des matches de la compétition (déjà filtrés sur le
  /// format `singleElimination` côté caller). Le tri par round et par
  /// `matchNumber` est fait à l'intérieur.
  final List<ArenaMatch> matches;

  /// Callback de tap sur une card. `null` pour mode read-only (pas
  /// d'`InkWell`, pas de feedback ripple).
  final ValueChanged<ArenaMatch>? onTapMatch;

  /// Resolution `playerId -> username` pour afficher le vrai pseudo
  /// dans les cards. Vide par défaut : fallback sur `P-XXXX` (id
  /// tronqué). Pour résoudre les usernames, le caller doit watcher
  /// `profilesByIdsProvider` et construire cette map.
  final Map<String, String> usernamesByPlayerId;

  /// Plafond du zoom in (`InteractiveViewer.maxScale`). 3× couvre un
  /// bracket 32 joueurs (5 rounds) sur un écran 5".
  final double maxScale;

  // Layout constants — la hauteur dispo est partagée équitablement par
  // les matches du round 1 (qui contient le plus de matches), donc les
  // cards sont compactes pour tenir un bracket 16 sans scroll vertical.
  static const double _columnWidth = 78;
  static const double _columnGap = 18;
  static const double _matchHeight = 42;
  static const double _matchGap = 6;
  static const double _connectorPad = 4;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    final byRound = <int, List<ArenaMatch>>{};
    for (final m in matches) {
      final r = m.round ?? 0;
      if (r <= 0) continue; // matches "hors phase" ignorés dans l'arbre
      (byRound[r] ??= []).add(m);
    }
    if (byRound.isEmpty) return const SizedBox.shrink();

    final rounds = byRound.keys.toList()..sort();
    // Tri stable des matches dans chaque round par `matchNumber` (puis
    // par id en fallback) — garantit que les 2 prédécesseurs en round N
    // (indices 2i / 2i+1) tombent face à leur successeur (index i) en
    // round N+1.
    for (final r in rounds) {
      byRound[r]!.sort((a, b) {
        final an = a.matchNumber ?? 1 << 30;
        final bn = b.matchNumber ?? 1 << 30;
        if (an != bn) return an.compareTo(bn);
        return a.id.compareTo(b.id);
      });
    }

    final firstRoundCount = byRound[rounds.first]!.length;
    final treeHeight = firstRoundCount * (_matchHeight + _matchGap) +
        _matchGap * 2 +
        40; // marge basse pour caption "pince pour zoomer"
    final treeWidth =
        rounds.length * _columnWidth + (rounds.length - 1) * _columnGap;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: maxScale,
      boundaryMargin: const EdgeInsets.all(200),
      child: SizedBox(
        width: treeWidth,
        height: treeHeight,
        child: Stack(
          children: [
            // Connecteurs entre colonnes — peints en background.
            Positioned.fill(
              child: CustomPaint(
                painter: _BracketConnectors(
                  rounds: rounds,
                  byRound: byRound,
                  columnWidth: _columnWidth,
                  columnGap: _columnGap,
                  matchHeight: _matchHeight,
                  treeHeight: treeHeight - 40, // moins caption
                  pad: _connectorPad,
                ),
              ),
            ),
            // Colonnes de cards par round.
            for (var i = 0; i < rounds.length; i++)
              Positioned(
                left: i * (_columnWidth + _columnGap),
                top: 0,
                width: _columnWidth,
                height: treeHeight - 40,
                child: _RoundColumn(
                  matches: byRound[rounds[i]]!,
                  style: _styleForRound(rounds[i], rounds.last),
                  matchHeight: _matchHeight,
                  onTapMatch: onTapMatch,
                  usernamesByPlayerId: usernamesByPlayerId,
                ),
              ),
          ],
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
    required this.onTapMatch,
    required this.usernamesByPlayerId,
  });

  final List<ArenaMatch> matches;
  final _RoundStyle style;
  final double matchHeight;
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
              // Le match de classement arrive dans le même round que la
              // finale ; on le distingue par un style bronze dédié.
              style: m.isThirdPlace ? _RoundStyle.thirdPlace : style,
              onTap: onTapMatch == null ? null : () => onTapMatch!(m),
              usernamesByPlayerId: usernamesByPlayerId,
            ),
          ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.style,
    required this.onTap,
    required this.usernamesByPlayerId,
  });

  final ArenaMatch match;
  final _RoundStyle style;
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

    final card = Container(
      decoration: BoxDecoration(
        gradient: isGradient
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ArenaColors.tierGoldWarm,
                  ArenaColors.tierGoldDeep,
                ],
              )
            : null,
        color: isGradient ? null : bg,
        border: border == null ? null : Border.all(color: border, width: 1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: style == _RoundStyle.finale
            ? const [
                BoxShadow(
                  color: ArenaColors.goldGlow,
                  blurRadius: 14,
                  spreadRadius: -1,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: style == _RoundStyle.finale
          ? _FinaleContent(score1: match.score1, score2: match.score2)
          : style == _RoundStyle.thirdPlace
              ? _ThirdPlaceContent(score1: match.score1, score2: match.score2)
              : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PlayerLine(label: p1, win: p1Win, fg: fg),
                const SizedBox(height: 1),
                _PlayerLine(label: p2, win: p2Win, fg: fg),
              ],
            ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: card,
      ),
    );
  }

  /// Label affiché dans la card du match : prioritise le username réel
  /// (résolu via `usernamesByPlayerId`, alimenté par `profilesByIdsProvider`
  /// côté caller), retombe sur `P-XXXX` (id tronqué) tant que le profil
  /// n'est pas chargé, et `—` quand le slot n'a pas de joueur (le
  /// vainqueur du round précédent n'a pas encore cascadé).
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
  const _PlayerLine({required this.label, required this.win, required this.fg});

  final String label;
  final bool win;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ArenaText.monoSmall.copyWith(
        fontSize: 9,
        color: win ? ArenaColors.bone : fg,
        fontWeight: win ? FontWeight.w800 : FontWeight.w500,
      ),
    );
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
        const Text('🏆', style: TextStyle(fontSize: 12, height: 1)),
        const SizedBox(height: 1),
        Text(
          hasScore ? '$score1 — $score2' : 'FINALE',
          style: ArenaText.h2.copyWith(
            color: ArenaColors.void_,
            fontSize: 11,
            letterSpacing: 1,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Contenu de la card du match de classement (3e place). Style bronze,
/// libellé « 🥉 3e PLACE » tant qu'aucun score n'est saisi.
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
        const Text('🥉', style: TextStyle(fontSize: 12, height: 1)),
        const SizedBox(height: 1),
        Text(
          hasScore ? '$score1 — $score2' : '3e PLACE',
          style: ArenaText.h2.copyWith(
            color: ArenaColors.tierBronze,
            fontSize: 10,
            letterSpacing: 0.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// CustomPainter qui dessine les lignes connectrices entre rounds.
/// Pour chaque round N (sauf le dernier), trace pour chaque paire
/// `(match[2i], match[2i+1])` :
///
/// 1. Un segment horizontal depuis le bord droit de chaque match (les
///    deux à la même longueur, dans la `gap` inter-colonnes).
/// 2. Un segment vertical reliant ces deux extrémités.
/// 3. Un segment horizontal du milieu vertical jusqu'au bord gauche du
///    match successeur en round N+1.
///
/// Trait : `silver @ 35 %` à 1 px (lisible sans surcharger).
class _BracketConnectors extends CustomPainter {
  _BracketConnectors({
    required this.rounds,
    required this.byRound,
    required this.columnWidth,
    required this.columnGap,
    required this.matchHeight,
    required this.treeHeight,
    required this.pad,
  });

  final List<int> rounds;
  final Map<int, List<ArenaMatch>> byRound;
  final double columnWidth;
  final double columnGap;
  final double matchHeight;
  final double treeHeight;
  final double pad;

  static const _stroke = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ArenaColors.silver.withValues(alpha: 0.35)
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < rounds.length - 1; i++) {
      final fromCount = byRound[rounds[i]]!.length;
      final toCount = byRound[rounds[i + 1]]!.length;
      // Si la cardinalité n'est pas exactement le double, on ne dessine
      // rien sur ce gap — évite des connecteurs incohérents (cas de
      // matches manquants / bracket partiel).
      if (toCount * 2 != fromCount) continue;

      final fromSlot = treeHeight / fromCount;
      final toSlot = treeHeight / toCount;
      final colLeftFrom = i * (columnWidth + columnGap);
      final fromRightX = colLeftFrom + columnWidth + pad;
      final colLeftTo = (i + 1) * (columnWidth + columnGap);
      final toLeftX = colLeftTo - pad;
      final midX = (fromRightX + toLeftX) / 2;

      for (var j = 0; j < toCount; j++) {
        final yTop = fromSlot * (2 * j) + fromSlot / 2;
        final yBot = fromSlot * (2 * j + 1) + fromSlot / 2;
        final yMid = toSlot * j + toSlot / 2;

        // Segment 1 : depuis le bord droit des 2 matches du round N
        // jusqu'au mid-X.
        canvas
          ..drawLine(Offset(fromRightX, yTop), Offset(midX, yTop), paint)
          ..drawLine(Offset(fromRightX, yBot), Offset(midX, yBot), paint)
          // Segment 2 : vertical entre les 2 sorties.
          ..drawLine(Offset(midX, yTop), Offset(midX, yBot), paint)
          // Segment 3 : horizontal jusqu'à l'entrée du successeur.
          ..drawLine(Offset(midX, yMid), Offset(toLeftX, yMid), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BracketConnectors old) =>
      old.rounds != rounds ||
      old.byRound != byRound ||
      old.columnWidth != columnWidth ||
      old.columnGap != columnGap ||
      old.matchHeight != matchHeight ||
      old.treeHeight != treeHeight;
}
