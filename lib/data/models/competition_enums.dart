import 'package:freezed_annotation/freezed_annotation.dart';

/// Mirror of Postgres enum `public.competitions.game`. Four games are
/// supported — extending requires both a CHECK update (migration) and a
/// new couleur/emoji sur le client (pas de logo image : emoji + couleur).
enum GameType {
  efootball('efootball', 'eFootball'),
  draughts('draughts', 'Jeu de Dames'),
  eaSportsFc('ea_sports_fc', 'Mobile FC'),
  dreamLeague('dream_league', 'Dream League Soccer');

  const GameType(this.value, this.label);

  final String value;
  final String label;

  static GameType fromValue(String? value) {
    return GameType.values.firstWhere(
      (g) => g.value == value,
      orElse: () => GameType.efootball,
    );
  }

  /// `true` si le jeu se joue DANS Arena (Dames). Les autres jeux se jouent
  /// dans une app EXTERNE (eFootball, Mobile FC, Dream League) — d'où le
  /// dialogue de contrôle d'installation avant inscription.
  bool get isInApp => this == GameType.draughts;

  /// `true` si le jeu requiert une app EXTERNE (tous sauf les Dames).
  bool get isExternal => !isInApp;
}

/// Mirror of Postgres enum `public.competition_status`.
enum CompetitionStatus {
  draft('draft'),
  registrationOpen('registration_open'),
  registrationClosed('registration_closed'),

  /// Échéance atteinte sans quota complet : en attente d'une décision admin
  /// (reprogrammer / démarrer avec les inscrits / annuler). Remplace
  /// l'auto-annulation des compétitions sous-remplies.
  toReprogram('to_reprogram'),
  ongoing('ongoing'),
  completed('completed'),
  cancelled('cancelled');

  const CompetitionStatus(this.value);

  final String value;

  static CompetitionStatus fromValue(String? value) {
    return CompetitionStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => CompetitionStatus.draft,
    );
  }

  bool get isRegistrationOpen => this == CompetitionStatus.registrationOpen;
  bool get isOngoing => this == CompetitionStatus.ongoing;
  bool get isCompleted => this == CompetitionStatus.completed;
  bool get isCancelled => this == CompetitionStatus.cancelled;
  bool get isToReprogram => this == CompetitionStatus.toReprogram;

  /// Regroupe les 7 statuts DB en 3 phases claires pour l'affichage :
  /// À VENIR / EN COURS / TERMINÉ. **Source unique** pour les listes, filtres
  /// et badges (évite les vocabulaires divergents entre écrans).
  ///  * draft / registration_open / registration_closed / to_reprogram → [CompetitionPhase.upcoming]
  ///  * ongoing                                          → [CompetitionPhase.ongoing]
  ///  * completed / cancelled                            → [CompetitionPhase.finished]
  ///
  /// `to_reprogram` est rangé dans « à venir » (le tournoi n'a pas démarré) ;
  /// son libellé/couleur propres sont rendus par `competitionStatusLabel` /
  /// `competitionStatusColor` (cf. competition_phase_ui.dart).
  CompetitionPhase get phase => switch (this) {
        CompetitionStatus.draft ||
        CompetitionStatus.registrationOpen ||
        CompetitionStatus.registrationClosed ||
        CompetitionStatus.toReprogram =>
          CompetitionPhase.upcoming,
        CompetitionStatus.ongoing => CompetitionPhase.ongoing,
        CompetitionStatus.completed ||
        CompetitionStatus.cancelled =>
          CompetitionPhase.finished,
      };
}

/// Phase d'affichage d'une compétition — regroupe les statuts DB en 3
/// catégories claires côté UI (à venir / en cours / terminé).
enum CompetitionPhase { upcoming, ongoing, finished }

/// Mirror of Postgres enum `public.tournament_format`.
enum TournamentFormat {
  singleElimination('single_elimination'),
  groupsThenKnockout('groups_then_knockout'),
  roundRobin('round_robin');

  const TournamentFormat(this.value);

  final String value;

  static TournamentFormat fromValue(String? value) {
    return TournamentFormat.values.firstWhere(
      (f) => f.value == value,
      orElse: () => TournamentFormat.singleElimination,
    );
  }

  bool get hasGroups => this == TournamentFormat.groupsThenKnockout;
  bool get isBracket =>
      this == TournamentFormat.singleElimination ||
      this == TournamentFormat.groupsThenKnockout;
}

class GameTypeConverter implements JsonConverter<GameType, String?> {
  const GameTypeConverter();

  @override
  GameType fromJson(String? value) => GameType.fromValue(value);

  @override
  String toJson(GameType game) => game.value;
}

class CompetitionStatusConverter
    implements JsonConverter<CompetitionStatus, String?> {
  const CompetitionStatusConverter();

  @override
  CompetitionStatus fromJson(String? value) =>
      CompetitionStatus.fromValue(value);

  @override
  String toJson(CompetitionStatus status) => status.value;
}

class TournamentFormatConverter
    implements JsonConverter<TournamentFormat, String?> {
  const TournamentFormatConverter();

  @override
  TournamentFormat fromJson(String? value) => TournamentFormat.fromValue(value);

  @override
  String toJson(TournamentFormat format) => format.value;
}
