import 'package:arena/data/models/competition_enums.dart';

// Libellés FR (admin) des enums de compétition, partagés par les consoles
// mobile et desktop. NB : côté USER, les libellés sont LOCALISÉS (l10n) — ne
// pas confondre ; ce fichier est la source des libellés admin non localisés.

/// Libellé FR du format de tournoi. Source unique des consoles admin —
/// résorbe 4 copies divergentes (l'une affichait « Poules + KO » là où les
/// autres affichaient « Poules puis KO »).
String competitionFormatLabel(TournamentFormat format) {
  switch (format) {
    case TournamentFormat.singleElimination:
      return 'Élimination directe';
    case TournamentFormat.groupsThenKnockout:
      return 'Poules puis KO';
    case TournamentFormat.roundRobin:
      return 'Round robin';
  }
}
