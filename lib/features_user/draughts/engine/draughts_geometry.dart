// =============================================================================
// ARENA — Moteur de dames internationales 10×10 : géométrie du damier.
// =============================================================================
// 50 cases sombres jouables, numérotées 1→50 (convention FMJD / PDN) :
//   rangée 0 (haut) = cases 1-5 … rangée 9 (bas) = cases 46-50.
// En interne on indexe 0→49 (numéro de case = index + 1).
//
// Disposition des cases sombres :
//   - rangées paires (0,2,4,6,8) : colonnes impaires (1,3,5,7,9)
//   - rangées impaires (1,3,5,7,9) : colonnes paires (0,2,4,6,8)
//
// Dart pur (aucun import Flutter/Supabase) : ce moteur tourne à l'identique
// côté client (UI) et sera porté en TypeScript côté Edge Function (autorité).
// La parité des deux implémentations est garantie par les vecteurs de test
// JSON partagés (cf. test/draughts/vectors/).
// =============================================================================

class DraughtsGeometry {
  DraughtsGeometry._();

  /// Nombre de cases jouables (sombres).
  static const int squares = 50;

  /// Côté du damier (10×10).
  static const int boardSize = 10;

  /// Les 4 directions diagonales, en (deltaRow, deltaCol).
  static const List<List<int>> diagonals = [
    [-1, -1],
    [-1, 1],
    [1, -1],
    [1, 1],
  ];

  /// Rangée (0 = haut, 9 = bas) de l'index 0-49.
  static int rowOf(int index) => index ~/ 5;

  /// Colonne (0-9) de l'index 0-49.
  static int colOf(int index) {
    final row = index ~/ 5;
    final pos = index % 5;
    return row.isEven ? 2 * pos + 1 : 2 * pos;
  }

  /// Index 0-49 de la case (row, col), ou -1 si hors plateau ou case claire.
  static int indexAt(int row, int col) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) return -1;
    final isDark = row.isEven ? col.isOdd : col.isEven;
    if (!isDark) return -1;
    final pos = row.isEven ? (col - 1) ~/ 2 : col ~/ 2;
    return row * 5 + pos;
  }

  /// Numéro de case 1-50 (affichage / FEN).
  static int squareNumber(int index) => index + 1;

  /// Index 0-49 depuis un numéro de case 1-50.
  static int indexFromSquare(int square) => square - 1;
}
