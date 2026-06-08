// =============================================================================
// ARENA — Moteur de dames internationales 10×10 : point d'entrée (barrel).
// =============================================================================
// Dart pur, sans dépendance Flutter/Supabase : exécutable à l'identique côté
// client (UI : surbrillance des coups légaux, optimistic) et porté en TS côté
// Edge Function (autorité serveur). La parité est verrouillée par les vecteurs
// de test JSON partagés (test/draughts/vectors/).
// =============================================================================

export 'package:arena/features_user/draughts/engine/draughts_board.dart';
export 'package:arena/features_user/draughts/engine/draughts_fen.dart';
export 'package:arena/features_user/draughts/engine/draughts_game_state.dart';
export 'package:arena/features_user/draughts/engine/draughts_geometry.dart';
export 'package:arena/features_user/draughts/engine/draughts_move.dart';
export 'package:arena/features_user/draughts/engine/draughts_piece.dart';
export 'package:arena/features_user/draughts/engine/draughts_rules.dart';
