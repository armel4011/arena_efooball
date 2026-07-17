import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Règles d'un jeu (une ligne par jeu). Miroir léger de `public.game_rules` —
/// pas de freezed : la table est minuscule et lue/écrite telle quelle.
class GameRules {
  const GameRules({
    required this.game,
    required this.rulesText,
    this.updatedBy,
    this.updatedAt,
  });

  final GameType game;
  final String rulesText;
  final String? updatedBy;
  final DateTime? updatedAt;

  /// `null` si la ligne ne porte pas de jeu connu (colonne libre côté DB).
  static GameRules? fromJson(Map<String, dynamic> json) {
    final raw = json['game'] as String?;
    if (raw == null) return null;
    final game = GameType.values.where((g) => g.value == raw).firstOrNull;
    if (game == null) return null;
    final updatedAt = json['updated_at'] as String?;
    return GameRules(
      game: game,
      rulesText: (json['rules_text'] as String?) ?? '',
      updatedBy: json['updated_by'] as String?,
      updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt),
    );
  }
}

/// Lecture/écriture des règles par jeu. Lecture publique, écriture admin (RLS).
class GameRulesRepository {
  const GameRulesRepository(this._client);

  static const _table = 'game_rules';

  final SupabaseClient _client;

  /// Toutes les règles (pour l'éditeur admin), triées par jeu.
  Future<List<GameRules>> fetchAll() async {
    final rows = await _client.from(_table).select();
    return (rows as List)
        .map((r) => GameRules.fromJson(r as Map<String, dynamic>))
        .whereType<GameRules>()
        .toList();
  }

  /// Le texte des règles d'un jeu, ou `null` si aucune règle n'a été saisie.
  Future<String?> fetchForGame(GameType game) async {
    final rows = await _client
        .from(_table)
        .select('rules_text')
        .eq('game', game.value)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    final text = (list.first as Map<String, dynamic>)['rules_text'] as String?;
    return (text == null || text.trim().isEmpty) ? null : text;
  }

  /// Crée ou remplace les règles d'un jeu (upsert sur la PK `game`).
  Future<void> upsert({
    required GameType game,
    required String rulesText,
    String? updatedBy,
  }) async {
    await _client.from(_table).upsert({
      'game': game.value,
      'rules_text': rulesText,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (updatedBy != null) 'updated_by': updatedBy,
    });
  }
}

final gameRulesRepositoryProvider = Provider<GameRulesRepository>((ref) {
  return GameRulesRepository(ref.watch(supabaseClientProvider));
});

/// Règles d'un jeu pour l'écran de verrouillage — `null` si non saisies.
/// `FutureProvider` (pas de canal Realtime) : l'écran est transitoire et les
/// règles changent rarement.
final gameRulesProvider =
    FutureProvider.family.autoDispose<String?, GameType>((ref, game) {
  return ref.watch(gameRulesRepositoryProvider).fetchForGame(game);
});

/// Toutes les règles saisies, pour l'éditeur admin (rafraîchi à chaque save via
/// `ref.invalidate`).
final allGameRulesProvider =
    FutureProvider.autoDispose<List<GameRules>>((ref) {
  return ref.watch(gameRulesRepositoryProvider).fetchAll();
});
