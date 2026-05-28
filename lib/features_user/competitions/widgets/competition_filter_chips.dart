import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';

/// Lot C.1 — Les widgets `GameChips` / `StatusChips` / `PricingChips`
/// ont été remplacés par un `ArenaFilterMenu` dans `competitions_list_page`.
/// Ce fichier ne conserve plus que les enums utilisés par la logique
/// de filtrage côté client (`StatusBucket.matches` / `PricingBucket.matches`).

/// Tarif filter — gratuit / payant / tous.
enum PricingBucket {
  all('Toutes'),
  free('Gratuites'),
  paid('Payantes');

  const PricingBucket(this.label);
  final String label;

  bool matches(Competition c) => switch (this) {
        PricingBucket.all => true,
        PricingBucket.free => c.isFree,
        PricingBucket.paid => !c.isFree,
      };
}

/// Status filter — bucket regroupant plusieurs `CompetitionStatus`.
enum StatusBucket {
  all('Toutes'),
  upcoming('À venir'),
  ongoing('En cours'),
  completed('Terminés');

  const StatusBucket(this.label);
  final String label;

  bool matches(CompetitionStatus status) => switch (this) {
        StatusBucket.all => true,
        StatusBucket.upcoming => status == CompetitionStatus.draft ||
            status == CompetitionStatus.registrationOpen ||
            status == CompetitionStatus.registrationClosed,
        StatusBucket.ongoing => status == CompetitionStatus.ongoing,
        StatusBucket.completed => status == CompetitionStatus.completed ||
            status == CompetitionStatus.cancelled,
      };
}
