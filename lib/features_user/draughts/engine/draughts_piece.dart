// =============================================================================
// ARENA — Moteur de dames : pièces et camps.
// =============================================================================

/// Camp d'un joueur. Les Blancs jouent en premier (convention internationale)
/// et se déplacent vers le haut du plateau (rangées décroissantes) ; les Noirs
/// vers le bas (rangées croissantes).
enum Side { white, black }

extension SideX on Side {
  Side get opponent => this == Side.white ? Side.black : Side.white;

  /// Sens d'avance d'un pion de ce camp (deltaRow).
  int get forward => this == Side.white ? -1 : 1;

  /// Rangée de promotion (où un pion devient dame).
  int get promotionRow => this == Side.white ? 0 : 9;
}

/// Contenu d'une case jouable.
enum Piece {
  empty,
  whiteMan,
  blackMan,
  whiteKing,
  blackKing;

  bool get isEmpty => this == Piece.empty;
  bool get isWhite => this == Piece.whiteMan || this == Piece.whiteKing;
  bool get isBlack => this == Piece.blackMan || this == Piece.blackKing;
  bool get isKing => this == Piece.whiteKing || this == Piece.blackKing;
  bool get isMan => this == Piece.whiteMan || this == Piece.blackMan;

  /// Camp de la pièce, ou `null` pour une case vide.
  Side? get side {
    if (isWhite) return Side.white;
    if (isBlack) return Side.black;
    return null;
  }

  /// Le pion du camp donné.
  static Piece manOf(Side side) =>
      side == Side.white ? Piece.whiteMan : Piece.blackMan;

  /// La dame du camp donné.
  static Piece kingOf(Side side) =>
      side == Side.white ? Piece.whiteKing : Piece.blackKing;
}
