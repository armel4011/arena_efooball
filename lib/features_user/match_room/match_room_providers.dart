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
  (ref, matchId) => null,
);

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
  // On ne dépend que du `competitionId` (stable pendant tout le match) via
  // `selectAsync` : sinon ce provider se relancerait à CHAQUE réémission du
  // stream realtime `matchByIdProvider` (nouvel objet `ArenaMatch` à chaque
  // tick/heartbeat Supabase), repassant en `AsyncLoading` et faisant clignoter
  // le spinner de la room (bug « écran qui tremble »).
  final competitionId = await ref
      .watch(matchByIdProvider(matchId).selectAsync((m) => m?.competitionId));
  if (competitionId == null) return GameType.efootball;
  final comp = await ref.watch(competitionByIdProvider(competitionId).future);
  return comp?.game ?? GameType.efootball;
});

/// Loads the two players' profiles in parallel for the match header.
final matchPlayersProvider = FutureProvider.family
    .autoDispose<MatchPlayers, String>((ref, matchId) async {
  // On ne re-fetch les profils QUE si la paire de joueurs change, via
  // `selectAsync` sur `(player1Id, player2Id)` : sans ça, chaque tick realtime
  // de `matchByIdProvider` relancerait deux appels réseau profils inutiles.
  final (p1Id, p2Id) = await ref.watch(
    matchByIdProvider(matchId).selectAsync((m) => (m?.player1Id, m?.player2Id)),
  );
  final repo = ref.watch(profileRepositoryProvider);
  // Profils PUBLICS (adversaire ou soi) : on n'a besoin que de pseudo +
  // avatar, et la table est restreinte à self+admin (fix C-1 résiduel).
  final p1 = p1Id == null ? null : await repo.getPublicById(p1Id);
  final p2 = p2Id == null ? null : await repo.getPublicById(p2Id);
  return MatchPlayers(p1: p1, p2: p2);
});
