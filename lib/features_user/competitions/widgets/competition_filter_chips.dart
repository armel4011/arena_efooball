import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/l10n/generated/app_localizations.dart';

/// Lot C.1 — Les widgets `GameChips` / `StatusChips` / `PricingChips`
/// ont été remplacés par un `ArenaFilterMenu` dans `competitions_list_page`.
/// Ce fichier ne conserve plus que les enums utilisés par la logique
/// de filtrage côté client (`StatusBucket.matches` / `PricingBucket.matches`).

/// Tarif filter — gratuit / payant / tous.
enum PricingBucket {
  all,
  free,
  paid;

  String labelOf(AppLocalizations l10n) => switch (this) {
        PricingBucket.all => l10n.filterAll,
        PricingBucket.free => l10n.filterFree,
        PricingBucket.paid => l10n.filterPaid,
      };

  bool matches(Competition c) => switch (this) {
        PricingBucket.all => true,
        PricingBucket.free => c.isFree,
        PricingBucket.paid => !c.isFree,
      };
}

/// Status filter — bucket regroupant plusieurs `CompetitionStatus`.
enum StatusBucket {
  all,
  upcoming,
  toReprogram,
  ongoing,
  completed;

  String labelOf(AppLocalizations l10n) => switch (this) {
        StatusBucket.all => l10n.filterAll,
        StatusBucket.upcoming => l10n.filterUpcoming,
        StatusBucket.toReprogram => l10n.statusToReprogram,
        StatusBucket.ongoing => l10n.filterOngoing,
        StatusBucket.completed => l10n.filterCompleted,
      };

  // Délègue au mapping centralisé `CompetitionStatus.phase` (source unique).
  // `toReprogram` a son propre bucket et est exclu de « à venir » pour que les
  // filtres restent mutuellement exclusifs.
  bool matches(CompetitionStatus status) => switch (this) {
        StatusBucket.all => true,
        StatusBucket.upcoming => status.phase == CompetitionPhase.upcoming &&
            status != CompetitionStatus.toReprogram,
        StatusBucket.toReprogram => status == CompetitionStatus.toReprogram,
        StatusBucket.ongoing => status.phase == CompetitionPhase.ongoing,
        StatusBucket.completed => status.phase == CompetitionPhase.finished,
      };
}
