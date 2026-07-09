import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_bracket_repository.dart';

/// Config des poules (format `groupsThenKnockout`). [empty] pour les formats
/// qui n'en ont pas besoin. Partagé par les deux consoles admin (était dupliqué
/// à l'identique dans le wizard bracket mobile et desktop).
class GroupsConfig {
  const GroupsConfig(this.groupCount, this.qualifiers);

  final int groupCount;
  final int qualifiers;

  static const empty = GroupsConfig(0, 0);
}

/// Dispatch la génération du bracket sur la bonne méthode de
/// [AdminBracketRepository] selon le format de [competition]. [groups] n'est lu
/// que pour `groupsThenKnockout`. Les générateurs eux-mêmes (single-elim,
/// round-robin, poules) vivent déjà dans le repo partagé — on ne factorise ici
/// que l'aiguillage, qui était copié mot pour mot entre mobile et desktop.
///
/// La garde « ≥ 2 joueurs », les dialogs de confirmation et le journal d'audit
/// restent côté écran (feedback UI divergent Material/Fluent).
Future<void> generateBracketFor({
  required AdminBracketRepository repo,
  required Competition competition,
  required List<String> playerIds,
  required GroupsConfig groups,
}) async {
  switch (competition.format) {
    case TournamentFormat.singleElimination:
      await repo.generateSingleElim(
        competitionId: competition.id,
        playerIds: playerIds,
        thirdPlace: competition.thirdPlaceMatch,
      );
    case TournamentFormat.roundRobin:
      await repo.generateRoundRobinTournament(
        competitionId: competition.id,
        playerIds: playerIds,
      );
    case TournamentFormat.groupsThenKnockout:
      await repo.generateGroupsKnockoutTournament(
        competitionId: competition.id,
        playerIds: playerIds,
        groupCount: groups.groupCount,
        qualifiersPerGroup: groups.qualifiers,
        thirdPlace: competition.thirdPlaceMatch,
      );
  }
}
