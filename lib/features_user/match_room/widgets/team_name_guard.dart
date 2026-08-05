import 'package:arena/data/models/arena_match.dart';

/// Règle : les DEUX joueurs d'un match ne peuvent pas utiliser la même équipe.
///
/// `true` si [entered] correspond (casse et espaces de bord ignorés) à l'équipe
/// déjà choisie par l'ADVERSAIRE dans ce match. Utilisé pour un contrôle client
/// immédiat ; le trigger serveur `guard_distinct_team_names` reste le filet
/// infalsifiable (course, client modifié).
bool sameTeamAsOpponent(
  ArenaMatch match,
  String entered, {
  required bool isPlayer1,
}) {
  final opp =
      (isPlayer1 ? match.player2TeamName : match.player1TeamName)?.trim();
  if (opp == null || opp.isEmpty) return false;
  return opp.toLowerCase() == entered.trim().toLowerCase();
}

/// Reconnaît l'erreur levée par le garde serveur `guard_distinct_team_names`
/// (course : les deux joueurs valident le même nom quasi simultanément).
bool isSameTeamError(Object e) =>
    e.toString().toLowerCase().contains('même équipe');
