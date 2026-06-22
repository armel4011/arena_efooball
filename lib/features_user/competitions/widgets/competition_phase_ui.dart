import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Présentation unifiée des 3 phases de compétition (À VENIR / EN COURS /
/// TERMINÉ). Source d'affichage unique partagée par la liste, le badge de
/// card et le détail — pour éviter les vocabulaires divergents.
///
/// Réutilise les libellés l10n du filtre (`filterUpcoming` = « À venir »,
/// `filterOngoing` = « En cours », `filterCompleted` = « Terminés ») déjà
/// traduits FR/EN/AR.
String competitionPhaseLabel(CompetitionPhase phase, AppLocalizations l10n) =>
    switch (phase) {
      CompetitionPhase.upcoming => l10n.filterUpcoming,
      CompetitionPhase.ongoing => l10n.filterOngoing,
      CompetitionPhase.finished => l10n.filterCompleted,
    };

/// Couleur d'accent de la phase : à venir = bleu (neutre/à venir),
/// en cours = vert (actif), terminé = gris (clos).
Color competitionPhaseColor(CompetitionPhase phase) => switch (phase) {
      CompetitionPhase.upcoming => ArenaColors.signalBlue,
      CompetitionPhase.ongoing => ArenaColors.statusOk,
      CompetitionPhase.finished => ArenaColors.silver,
    };

/// Libellé d'affichage d'un [CompetitionStatus] en tenant compte du cas
/// spécial `to_reprogram` (échéance atteinte, quota incomplet — en attente de
/// décision admin), qui n'a pas de phase propre mais mérite un libellé
/// distinct. Sinon, délègue au libellé de phase (source unique).
String competitionStatusLabel(
  CompetitionStatus status,
  AppLocalizations l10n,
) =>
    status == CompetitionStatus.toReprogram
        ? l10n.statusToReprogram
        : competitionPhaseLabel(status.phase, l10n);

/// Couleur d'accent d'un [CompetitionStatus] : `to_reprogram` = orange
/// (attention/action requise), sinon couleur de phase.
Color competitionStatusColor(CompetitionStatus status) =>
    status == CompetitionStatus.toReprogram
        ? ArenaColors.statusWarn
        : competitionPhaseColor(status.phase);
