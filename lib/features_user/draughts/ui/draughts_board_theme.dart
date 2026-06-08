// =============================================================================
// ARENA — Plateau de dames : palette de rendu (jeu).
// =============================================================================
// Teintes/dégradés du damier et des pièces, dérivés d'ArenaColors pour rester
// dans la charte (aucune couleur brute — le garde-fou design l'interdit hors
// lib/core/theme/). Rendu « pseudo-3D premium » : ardoise sombre, jetons
// glossy crème/charbon, accents or (sélection) + bleu signal (cases jouables).
// =============================================================================

import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

class DraughtsBoardTheme {
  DraughtsBoardTheme._();

  // ─── Damier ───────────────────────────────────────────────────────────
  static final Color darkSquare =
      Color.lerp(ArenaColors.void_, ArenaColors.carbon2, 0.55)!;
  static final Color darkSquareLo =
      Color.lerp(ArenaColors.void_, ArenaColors.blackPure, 0.5)!;
  static final Color lightSquare =
      Color.lerp(ArenaColors.graphite, ArenaColors.steel, 0.65)!;
  static final Color lightSquareLo =
      Color.lerp(ArenaColors.graphite, ArenaColors.carbon2, 0.5)!;
  static final Color squareLine = ArenaColors.blackPure.withValues(alpha: 0.45);

  // ─── Cadre / tranche (profondeur) ─────────────────────────────────────
  static final Color frame =
      Color.lerp(ArenaColors.carbon, ArenaColors.blackPure, 0.45)!;
  static final Color frameHi = ArenaColors.steel.withValues(alpha: 0.7);

  // ─── Pièces ───────────────────────────────────────────────────────────
  static const Color whiteTop = ArenaColors.bone;
  static const Color whiteRim = ArenaColors.pearl;
  static final Color whiteShade =
      Color.lerp(ArenaColors.pearl, ArenaColors.silverDim, 0.55)!;
  static final Color darkTop =
      Color.lerp(ArenaColors.steel, ArenaColors.carbon2, 0.35)!;
  static const Color darkRim = ArenaColors.graphite;
  static const Color darkShade = ArenaColors.blackPure;
  static final Color specular = ArenaColors.bone.withValues(alpha: 0.55);

  // ─── Accents ──────────────────────────────────────────────────────────
  static const Color selection = ArenaColors.gold; // pièce sélectionnée
  static const Color legalTarget = ArenaColors.signalBlue; // case jouable
  static const Color lastMove = ArenaColors.gameDraughts; // dernier coup
  static const Color kingMark = ArenaColors.gold; // couronne de dame

  static Color shadow(double alpha) =>
      ArenaColors.blackPure.withValues(alpha: alpha);
}
