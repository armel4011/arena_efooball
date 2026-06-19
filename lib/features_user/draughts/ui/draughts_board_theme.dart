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

  // ─── Damier (palette « Bleu ARENA » : cases jouables bleu signal,
  // cases inertes crème) ─────────────────────────────────────────────────
  // Les cases sombres sont les cases JOUABLES (les pièces s'y posent) ; on
  // les passe en bleu signal avec un compagnon plus profond pour le dégradé.
  static const Color darkSquare = ArenaColors.signalBlue;
  static final Color darkSquareLo =
      Color.lerp(ArenaColors.signalBlue, ArenaColors.signalBlueDark, 0.6)!;
  // Cases claires (non jouables) : crème, léger dégradé vers le perle.
  static final Color lightSquare =
      Color.lerp(ArenaColors.bone, ArenaColors.pearl, 0.12)!;
  static final Color lightSquareLo =
      Color.lerp(ArenaColors.bone, ArenaColors.pearl, 0.35)!;
  static final Color squareLine = ArenaColors.blackPure.withValues(alpha: 0.25);

  // ─── Cadre / tranche (profondeur) ─────────────────────────────────────
  static final Color frame =
      Color.lerp(ArenaColors.carbon, ArenaColors.blackPure, 0.45)!;
  static final Color frameHi = ArenaColors.steel.withValues(alpha: 0.7);

  // ─── Pièces ───────────────────────────────────────────────────────────
  static const Color whiteTop = ArenaColors.bone;
  static const Color whiteRim = ArenaColors.pearl;
  static final Color whiteShade =
      Color.lerp(ArenaColors.pearl, ArenaColors.silverDim, 0.55)!;
  // Pions « noirs » : graphite à reflet clair + liseré argenté pour rester
  // lisibles sur les cases sombres (sinon ils se fondent dans le damier).
  static final Color darkTop =
      Color.lerp(ArenaColors.steel, ArenaColors.silver, 0.45)!;
  static final Color darkRim =
      Color.lerp(ArenaColors.silver, ArenaColors.pearl, 0.4)!;
  static const Color darkShade = ArenaColors.blackPure;
  static final Color specular = ArenaColors.bone.withValues(alpha: 0.55);

  // ─── Accents ──────────────────────────────────────────────────────────
  static const Color selection = ArenaColors.gold; // pièce sélectionnée
  // Cases sombres désormais bleues → le marqueur « jouable » passe en vert
  // acide pour rester visible (le signalBlue se fondrait dans la case).
  static const Color legalTarget = ArenaColors.acidGreen; // case jouable
  static const Color lastMove = ArenaColors.gameDraughts; // dernier coup
  static const Color kingMark = ArenaColors.gold; // couronne de dame

  static Color shadow(double alpha) =>
      ArenaColors.blackPure.withValues(alpha: alpha);
}
