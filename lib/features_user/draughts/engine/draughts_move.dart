// =============================================================================
// ARENA — Moteur de dames : représentation d'un coup.
// =============================================================================

import 'package:arena/features_user/draughts/engine/draughts_geometry.dart';
import 'package:meta/meta.dart';

/// Un coup = une case de départ, une case d'arrivée, la liste des pièces
/// capturées (vide pour un simple déplacement) et le chemin parcouru
/// (cases successives départ→…→arrivée, utile pour animer une rafle).
///
/// Toutes les cases sont des index 0-49.
@immutable
class DraughtsMove {
  const DraughtsMove({
    required this.from,
    required this.to,
    required this.captured,
    required this.path,
  });

  /// Construit un simple déplacement (sans prise).
  DraughtsMove.simple(this.from, this.to)
      : captured = const [],
        path = [from, to];

  final int from;
  final int to;
  final List<int> captured;
  final List<int> path;

  bool get isCapture => captured.isNotEmpty;

  /// Notation lisible en numéros de case (1-50) : "32-28" (déplacement) ou
  /// "28x17" (prise simple) / "28x6" (rafle, le nb de × n'est pas détaillé).
  String get notation {
    final sep = isCapture ? 'x' : '-';
    return '${DraughtsGeometry.squareNumber(from)}'
        '$sep${DraughtsGeometry.squareNumber(to)}';
  }

  /// Signature canonique (indépendante de l'ordre des captures) pour comparer
  /// deux coups : départ, arrivée, et ensemble trié des cases capturées.
  String get signature {
    final caps = [...captured]..sort();
    return '$from>$to:${caps.join(",")}';
  }

  @override
  bool operator ==(Object other) =>
      other is DraughtsMove && other.signature == signature;

  @override
  int get hashCode => signature.hashCode;

  @override
  String toString() => 'DraughtsMove($notation, captured=$captured)';
}
