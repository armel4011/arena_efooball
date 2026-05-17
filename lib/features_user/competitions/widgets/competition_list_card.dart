import 'package:arena/data/models/competition.dart';
import 'package:arena/features_user/competitions/widgets/free_competition_card.dart';
import 'package:arena/features_user/competitions/widgets/paid_competition_card.dart';
import 'package:flutter/material.dart';

/// Choisit la carte adaptée selon le tarif. Garde la signature unifiée
/// pour la liste, mais le rendu visuel diffère franchement entre les
/// deux modes (cf. design discussion).
class CompetitionListCard extends StatelessWidget {
  const CompetitionListCard({
    required this.competition,
    required this.isRegistered,
    required this.hasPendingPayment,
    required this.onTap,
    required this.onRegister,
    super.key,
  });

  final Competition competition;
  final bool isRegistered;

  /// `true` quand un paiement de cet utilisateur sur cette comp est en
  /// `awaiting_admin`. Le bouton CTA passe alors à "VOIR LE STATUT".
  final bool hasPendingPayment;
  final VoidCallback onTap;

  /// `null` quand le joueur est déjà inscrit OU que la comp n'accepte
  /// plus d'inscriptions. Sinon, bouton S'INSCRIRE visible sur la card.
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    return competition.isFree
        ? FreeCompetitionCard(
            competition: competition,
            isRegistered: isRegistered,
            onTap: onTap,
            onRegister: onRegister,
          )
        : PaidCompetitionCard(
            competition: competition,
            isRegistered: isRegistered,
            hasPendingPayment: hasPendingPayment,
            onTap: onTap,
            onRegister: onRegister,
          );
  }
}
