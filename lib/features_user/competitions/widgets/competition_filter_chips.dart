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

/// Status filter — bucket sur les 3 phases (`CompetitionStatus.phase`).
/// Pas d'option « Toutes » : l'absence de sélection (gérée côté page) = tous.
enum StatusBucket {
  upcoming,
  ongoing,
  completed;

  String labelOf(AppLocalizations l10n) => switch (this) {
        StatusBucket.upcoming => l10n.filterUpcoming,
        StatusBucket.ongoing => l10n.filterOngoing,
        StatusBucket.completed => l10n.filterCompleted,
      };

  // Délègue au mapping centralisé `CompetitionStatus.phase` (source unique).
  bool matches(CompetitionStatus status) => switch (this) {
        StatusBucket.upcoming => status.phase == CompetitionPhase.upcoming,
        StatusBucket.ongoing => status.phase == CompetitionPhase.ongoing,
        StatusBucket.completed => status.phase == CompetitionPhase.finished,
      };
}
