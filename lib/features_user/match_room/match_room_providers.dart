import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Optimistic state pour la soumission de score — survit aux remounts
/// (back-to-bracket-and-return). Le widget tree ne le porte pas.
final pendingScoreSubmissionProvider =
    StateProvider.family<Map<String, dynamic>?, String>(
        (ref, matchId) => null,);

/// Optimistic state pour le partage du code room (HOME) — survit aussi
/// aux remounts. Permet d'afficher l'interstitial "code partagé" même
/// si la sync DB tarde.
final pendingRoomCodeProvider =
    StateProvider.family<String?, String>((ref, matchId) => null);

/// Snapshot des deux profils players d'un match. Chargé en parallèle
/// pour alimenter le header.
class MatchPlayers {
  const MatchPlayers({required this.p1, required this.p2});
  final Profile? p1;
  final Profile? p2;
}

/// Type de jeu du match (porté par la compétition, pas par le match). Sert à
/// router les compétitions `draughts` vers le plateau in-app (cf. StepBody).
/// `efootball` par défaut tant que le chargement n'est pas résolu.
final matchGameTypeProvider =
    FutureProvider.family.autoDispose<GameType, String>((ref, matchId) async {
  final match = await ref.watch(matchByIdProvider(matchId).future);
  if (match == null) return GameType.efootball;
  final comp =
      await ref.watch(competitionByIdProvider(match.competitionId).future);
  return comp?.game ?? GameType.efootball;
});

/// Loads the two players' profiles in parallel for the match header.
final matchPlayersProvider =
    FutureProvider.family.autoDispose<MatchPlayers, String>((ref, matchId) async {
  final match = await ref.watch(matchByIdProvider(matchId).future);
  if (match == null) return const MatchPlayers(p1: null, p2: null);
  final repo = ref.watch(profileRepositoryProvider);
  // Profils PUBLICS (adversaire ou soi) : on n'a besoin que de pseudo +
  // avatar, et la table est restreinte à self+admin (fix C-1 résiduel).
  final p1 = match.player1Id == null
      ? null
      : await repo.getPublicById(match.player1Id!);
  final p2 = match.player2Id == null
      ? null
      : await repo.getPublicById(match.player2Id!);
  return MatchPlayers(p1: p1, p2: p2);
});
