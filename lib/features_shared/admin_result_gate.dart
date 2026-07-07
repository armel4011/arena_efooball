import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/match_status.dart';

/// Miroir Dart des gardes serveur (audit 2026-07-07, migration
/// `20260707120000_p1_admin_privilege_escalation`). Un admin **SIMPLE** ne peut
/// pas, sur une compétition **À PRIX** :
///   - inverser / ré-arbitrer le résultat d'un match déjà décidé
///     (`guard_matches_protected_columns`) ;
///   - écraser le classement final d'une compétition **clôturée**
///     (`guard_registrations_final_rank`).
///
/// Ces helpers permettent de **désactiver côté UI** les contrôles correspondants
/// pour un admin simple, plutôt que de le laisser tenter une action qui échouera
/// côté serveur (42501). La **1re saisie** (match non décidé / compétition non
/// clôturée) reste permise, exactement comme côté serveur. Source de vérité
/// unique : ce fichier reflète les conditions SQL — à garder synchronisé si le
/// guard évolue.

/// La compétition a un enjeu financier (miroir de `public.competition_has_prize` :
/// cagnotte déclarée OU au moins une part de distribution > 0).
bool competitionHasPrize(Competition c) =>
    c.prizePoolLocal > 0 || c.prizeDistribution.any((p) => p > 0);

/// `true` si un admin SIMPLE ne peut PAS (re)poser le résultat de [match] :
/// compétition à prix, acteur non super-admin, ET match déjà décidé (vainqueur
/// posé ou état terminal). La 1re saisie d'un match non décidé reste permise.
bool matchResultLockedForAdmin({
  required bool isSuperAdmin,
  required Competition competition,
  required ArenaMatch match,
}) {
  if (isSuperAdmin || !competitionHasPrize(competition)) return false;
  return match.winnerId != null ||
      match.status == MatchStatus.completed ||
      match.status == MatchStatus.forfeited;
}

/// `true` si un admin SIMPLE ne peut PAS modifier le classement final : la
/// compétition à prix est déjà clôturée (`completed`). Avant clôture, la saisie
/// manuelle reste permise (le classement auto l'écrasera à la clôture).
bool finalRankLockedForAdmin({
  required bool isSuperAdmin,
  required Competition competition,
}) {
  if (isSuperAdmin || !competitionHasPrize(competition)) return false;
  return competition.status.isCompleted;
}

/// Message d'indice affiché à côté d'un contrôle verrouillé.
const String superAdminOnlyHint =
    'Réservé au super-admin (compétition à cagnotte).';
