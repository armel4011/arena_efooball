import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// État d'un jeu vu par le super-admin.
class GameSetting {
  const GameSetting({
    required this.game,
    required this.isEnabled,
    this.activeCompetitions = 0,
  });

  final GameType game;
  final bool isEnabled;

  /// Compétitions encore actives (ouvertes, fermées, en cours, à
  /// reprogrammer) : elles continuent même si le jeu est désactivé.
  final int activeCompetitions;
}

/// Activation des jeux (table `game_settings`, lecture publique). Un jeu
/// désactivé ne permet plus de créer de compétition (garde serveur) et
/// disparaît des choix côté joueur ; les compétitions existantes continuent.
class GameSettingsRepository {
  const GameSettingsRepository(this._client);

  final SupabaseClient _client;

  /// Jeux désactivés (les jeux sans ligne sont considérés actifs).
  Future<Set<GameType>> fetchDisabledGames() async {
    final rows = await _client
        .from('game_settings')
        .select('game, is_enabled')
        .eq('is_enabled', false);
    return {
      for (final row in rows)
        if (_parse(row['game']) case final game?) game,
    };
  }

  /// État de tous les jeux du catalogue (super-admin), dans l'ordre de
  /// l'enum ; un jeu absent de la table est rendu actif.
  Future<List<GameSetting>> fetchAdminSettings() async {
    final res = await _client.rpc<dynamic>('admin_list_game_settings');
    final byGame = <GameType, GameSetting>{};
    if (res is List) {
      for (final row in res.whereType<Map<dynamic, dynamic>>()) {
        final game = _parse(row['game']);
        if (game == null) continue;
        byGame[game] = GameSetting(
          game: game,
          isEnabled: row['is_enabled'] != false,
          activeCompetitions: (row['active_competitions'] as num?)?.toInt() ?? 0,
        );
      }
    }
    return [
      for (final g in GameType.values)
        byGame[g] ?? GameSetting(game: g, isEnabled: true),
    ];
  }

  /// Active / désactive [game] (super-admin). Refusé par le serveur s'il
  /// s'agit du dernier jeu actif.
  Future<void> setEnabled(GameType game, {required bool enabled}) async {
    await _client.rpc<dynamic>(
      'set_game_enabled',
      params: {'p_game': game.value, 'p_enabled': enabled},
    );
  }

  static GameType? _parse(Object? raw) =>
      GameType.values.where((g) => g.value == raw).firstOrNull;
}

final gameSettingsRepositoryProvider = Provider<GameSettingsRepository>((ref) {
  return GameSettingsRepository(ref.watch(supabaseClientProvider));
});

/// Jeux désactivés par le super-admin. En cas d'échec (hors-ligne…), ensemble
/// VIDE : on n'escamote jamais un jeu par erreur.
final disabledGamesProvider = FutureProvider<Set<GameType>>((ref) async {
  try {
    return await ref.watch(gameSettingsRepositoryProvider).fetchDisabledGames();
  } catch (_) {
    return const <GameType>{};
  }
});

/// Jeux proposés côté joueur / à la création, dans l'ordre de [order]
/// (par défaut l'ordre de l'enum). Pendant le chargement : tous les jeux.
List<GameType> enabledGamesOf(
  WidgetRef ref, {
  List<GameType> order = GameType.values,
}) {
  final disabled =
      ref.watch(disabledGamesProvider).valueOrNull ?? const <GameType>{};
  final games = order.where((g) => !disabled.contains(g)).toList();
  // Garde-fou : le serveur impose au moins un jeu actif ; si l'état local est
  // incohérent, on retombe sur la liste complète plutôt qu'un écran vide.
  return games.isEmpty ? List.of(order) : games;
}
