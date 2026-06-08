// =============================================================================
// ARENA — Repository du jeu de dames (Realtime + Edge Function d'autorité).
// =============================================================================
// Lecture : stream Realtime de la partie active (`draughts_games`).
// Écriture : AUCUNE directe (RLS) — tout passe par l'Edge Function
// `draughts-game` (start / move / timeout), qui valide et fait foi.
// =============================================================================

import 'package:arena/data/models/draughts_game_row.dart';
import 'package:arena/data/repositories/profile_repository.dart'
    show supabaseClientProvider;
import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Erreur renvoyée par l'Edge Function (code stable côté serveur).
class DraughtsActionException implements Exception {
  const DraughtsActionException(this.code);
  final String code;
  @override
  String toString() => 'DraughtsActionException($code)';
}

class DraughtsRepository {
  const DraughtsRepository(this._client);

  final SupabaseClient _client;

  /// Stream de la partie ACTIVE d'un match (la plus récente, mort subite
  /// comprise). `null` tant qu'aucune partie n'existe.
  Stream<DraughtsGameRow?> watchActiveGame(String matchId) {
    return _client
        .from('draughts_games')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .map((rows) {
      if (rows.isEmpty) return null;
      final sorted = [...rows]..sort(
          (a, b) =>
              (b['game_number'] as num).compareTo(a['game_number'] as num),
        );
      final active = sorted.firstWhere(
        (r) => r['status'] == 'active',
        orElse: () => sorted.first,
      );
      return DraughtsGameRow.fromMap(active);
    });
  }

  Future<void> start(String matchId) => _invoke('start', matchId);

  Future<Map<String, dynamic>> move(String matchId, DraughtsMove m) =>
      _invoke('move', matchId, move: {
        'from': m.from,
        'to': m.to,
        'captured': m.captured,
      },);

  Future<void> claimTimeout(String matchId) => _invoke('timeout', matchId);

  Future<Map<String, dynamic>> _invoke(
    String action,
    String matchId, {
    Map<String, dynamic>? move,
  }) async {
    final res = await _client.functions.invoke(
      'draughts-game',
      body: {
        'action': action,
        'matchId': matchId,
        if (move != null) 'move': move,
      },
    );
    final data = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    if (res.status != 200) {
      throw DraughtsActionException(
        (data['error'] as String?) ?? 'http_${res.status}',
      );
    }
    return data;
  }
}

final draughtsRepositoryProvider = Provider<DraughtsRepository>((ref) {
  return DraughtsRepository(ref.watch(supabaseClientProvider));
});

/// Partie active d'un match (Realtime). Sans cache offline : une partie de
/// dames se joue en ligne (l'autorité est serveur).
final draughtsActiveGameProvider =
    StreamProvider.family.autoDispose<DraughtsGameRow?, String>((ref, matchId) {
  return ref.watch(draughtsRepositoryProvider).watchActiveGame(matchId);
});
