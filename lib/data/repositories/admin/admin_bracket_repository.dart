import 'package:arena/core/utils/bracket_generators/bracket_generator.dart';
import 'package:arena/core/utils/bracket_generators/groups_then_knockout_generator.dart';
import 'package:arena/core/utils/bracket_generators/round_robin_generator.dart';
import 'package:arena/core/utils/bracket_generators/single_elimination_generator.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the bracket plan produced by the generators (PHASE 11).
///
/// Insert order matters:
///   1. `phases` (one row per phase: groups, KO, …)
///   2. `groups` (only when format = groups+KO)
///   3. `matches` — index → UUID map kept in memory
///   4. `bracket_nodes` — link `match_id` and `next_node_id` against
///      the in-memory map
///
/// The DB trigger `cascade_match_winner` takes over from there.
class AdminBracketRepository {
  const AdminBracketRepository(this._client);

  final SupabaseClient _client;

  /// Returns the player IDs confirmed in [competitionId] in
  /// registration order. Used by the bracket admin page to seed the
  /// generators.
  Future<List<String>> listConfirmedRegistrations(String competitionId) async {
    final rows = await _client
        .from('competition_registrations')
        .select('player_id')
        .eq('competition_id', competitionId)
        .eq('status', 'confirmed')
        .order('registered_at');
    return [
      for (final row in rows as List<dynamic>)
        (row as Map<String, dynamic>)['player_id'] as String,
    ];
  }

  /// Generates + persists a single-elimination bracket.
  Future<void> generateSingleElim({
    required String competitionId,
    required List<String> playerIds,
    bool thirdPlace = false,
    int? seed,
  }) async {
    final plan = generateSingleElimination(
      playerIds: playerIds,
      thirdPlace: thirdPlace,
      seed: seed,
    );
    final phaseId = await _insertPhase(
      competitionId: competitionId,
      type: 'knockout',
      order: 1,
    );
    await _persistPlan(
      plan: plan,
      competitionId: competitionId,
      phaseId: phaseId,
    );
  }

  /// Generates + persists a round-robin (no bracket_nodes).
  Future<void> generateRoundRobinTournament({
    required String competitionId,
    required List<String> playerIds,
  }) async {
    final plan = generateRoundRobin(playerIds: playerIds);
    final phaseId = await _insertPhase(
      competitionId: competitionId,
      type: 'round_robin',
      order: 1,
    );
    for (final match in plan.matches) {
      await _client.from('matches').insert(
            match.toRow(competitionId: competitionId, phaseId: phaseId),
          );
    }
  }

  /// Generates + persists a groups-then-knockout tournament. Inserts
  /// 2 phases (`groups` + `knockout`), the groups themselves, the
  /// group matches with `group_id` resolved, and the empty KO bracket.
  Future<void> generateGroupsKnockoutTournament({
    required String competitionId,
    required List<String> playerIds,
    required int groupCount,
    required int qualifiersPerGroup,
    bool thirdPlace = false,
    int? seed,
  }) async {
    final plan = generateGroupsThenKnockout(
      playerIds: playerIds,
      groupCount: groupCount,
      qualifiersPerGroup: qualifiersPerGroup,
      thirdPlace: thirdPlace,
      seed: seed,
    );

    final groupPhaseId = await _insertPhase(
      competitionId: competitionId,
      type: 'groups',
      order: 1,
    );
    final koPhaseId = await _insertPhase(
      competitionId: competitionId,
      type: 'knockout',
      order: 2,
    );

    // Groups
    final groupIds = <String>[];
    for (var i = 0; i < plan.groups.length; i++) {
      final row = await _client.from('groups').insert({
        'competition_id': competitionId,
        'phase_id': groupPhaseId,
        'name': 'Groupe ${plan.groups[i]}',
        'group_number': i + 1,
      }).select('id').single();
      groupIds.add(row['id'] as String);
    }

    // Group matches
    for (var i = 0; i < plan.groupMatches.length; i++) {
      for (final match in plan.groupMatches[i]) {
        final row = match.toRow(
          competitionId: competitionId,
          phaseId: groupPhaseId,
        );
        row['group_id'] = groupIds[i];
        await _client.from('matches').insert(row);
      }
    }

    // KO bracket
    await _persistPlan(
      plan: plan.knockoutPlan,
      competitionId: competitionId,
      phaseId: koPhaseId,
    );
  }

  /// Danger zone — wipes every match + bracket_node + phase for the
  /// competition. Hooked behind the long-press "Reset bracket" gesture
  /// in the admin UI.
  Future<void> resetBracket(String competitionId) async {
    await _client
        .from('bracket_nodes')
        .delete()
        .eq('competition_id', competitionId);
    await _client.from('matches').delete().eq('competition_id', competitionId);
    await _client.from('phases').delete().eq('competition_id', competitionId);
  }

  Future<String> _insertPhase({
    required String competitionId,
    required String type,
    required int order,
  }) async {
    final row = await _client.from('phases').insert({
      'competition_id': competitionId,
      'phase_order': order,
      'type': type,
      'status': 'pending',
    }).select('id').single();
    return row['id'] as String;
  }

  Future<void> _persistPlan({
    required BracketPlan plan,
    required String competitionId,
    required String phaseId,
  }) async {
    // Insert matches in order, keep an index→UUID map.
    final matchIds = <String>[];
    for (final match in plan.matches) {
      final row = await _client
          .from('matches')
          .insert(match.toRow(competitionId: competitionId, phaseId: phaseId))
          .select('id')
          .single();
      matchIds.add(row['id'] as String);
    }

    // Insert nodes referencing the match UUIDs we just learned. We do
    // it in two passes so `next_node_id` can self-reference within
    // the same set: first pass without next_node_id, second pass
    // patches it.
    final nodeIds = <String>[];
    for (final node in plan.nodes) {
      final matchId = node.matchIndex >= 0 ? matchIds[node.matchIndex] : null;
      final row = await _client.from('bracket_nodes').insert({
        'competition_id': competitionId,
        'phase_id': phaseId,
        'round_number': node.roundNumber,
        'position_in_round': node.positionInRound,
        'total_rounds': node.totalRounds,
        if (matchId != null) 'match_id': matchId,
        'is_grand_final': node.isGrandFinal,
        'is_third_place_match': node.isThirdPlaceMatch,
        'is_bye': node.isBye,
        if (node.byePlayerId != null) 'bye_player_id': node.byePlayerId,
      }).select('id').single();
      nodeIds.add(row['id'] as String);
    }

    for (var i = 0; i < plan.nodes.length; i++) {
      final node = plan.nodes[i];
      final nextIndex = node.nextNodeIndex;
      if (nextIndex == null) continue;
      await _client.from('bracket_nodes').update({
        'next_node_id': nodeIds[nextIndex],
        if (node.nextPosition != null) 'next_position': node.nextPosition,
      }).eq('id', nodeIds[i]);
    }

    // Câblage du PERDANT vers le match de classement (3e place). Même
    // pattern que `next_node_id` : sur chaque demi-finale, on pointe le
    // nœud du match 3e place + le slot du perdant. Le trigger
    // `cascade_match_winner` route alors automatiquement le perdant.
    for (var i = 0; i < plan.nodes.length; i++) {
      final node = plan.nodes[i];
      final loserIndex = node.loserNextNodeIndex;
      if (loserIndex == null) continue;
      await _client.from('bracket_nodes').update({
        'loser_next_node_id': nodeIds[loserIndex],
        if (node.loserNextPosition != null)
          'loser_next_position': node.loserNextPosition,
      }).eq('id', nodeIds[i]);
    }

    // Résout les byes : on marque le match du bye `forfeited` avec le joueur
    // présent comme vainqueur. Le trigger `cascade_match_winner` (qui gère
    // désormais `forfeited` et dérive le match suivant via bracket_nodes)
    // l'avance alors automatiquement au round suivant — parité avec le
    // générateur SQL `generate_single_elim_bracket`. À faire APRÈS le câblage
    // des `next_node_id` pour que la cascade trouve le lien.
    for (final node in plan.nodes) {
      if (!node.isBye || node.byePlayerId == null || node.matchIndex < 0) {
        continue;
      }
      await _client.from('matches').update({
        'status': 'forfeited',
        'winner_id': node.byePlayerId,
        'score1': 0,
        'score2': 0,
      }).eq('id', matchIds[node.matchIndex]);
    }
  }
}

final adminBracketRepositoryProvider =
    Provider<AdminBracketRepository>((ref) {
  return AdminBracketRepository(ref.watch(supabaseClientProvider));
});
