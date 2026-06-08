import 'dart:convert';
import 'dart:io';

import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exécute les vecteurs PARTAGÉS (`test/draughts/vectors/engine_cases.json`)
/// contre le moteur Dart. Le futur moteur TypeScript de l'Edge Function devra
/// charger CE MÊME fichier et produire des résultats identiques — toute
/// divergence = bug de parité (cf. décision « validation serveur dure »).
void main() {
  test('vecteurs partagés Dart ↔ (futur) TS', () {
    final file = File('test/draughts/vectors/engine_cases.json');
    expect(file.existsSync(), isTrue, reason: 'vecteurs introuvables');

    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final cases = (json['cases'] as List).cast<Map<String, dynamic>>();
    expect(cases, isNotEmpty);

    for (final c in cases) {
      final name = c['name'] as String;
      final state = DraughtsGameState.fromFen(c['fen'] as String);
      final moves = state.legalMoves();

      expect(
        moves.length,
        c['legalMoveCount'] as int,
        reason: 'legalMoveCount pour "$name"',
      );

      final maxCaptured = moves.fold<int>(
        0,
        (m, mv) => mv.captured.length > m ? mv.captured.length : m,
      );
      expect(
        maxCaptured,
        c['maxCaptured'] as int,
        reason: 'maxCaptured pour "$name"',
      );
    }
  });
}
