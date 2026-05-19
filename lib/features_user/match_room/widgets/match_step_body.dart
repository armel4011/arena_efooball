import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_user/match_room/match_room_page.dart'
    show MatchRole;
import 'package:arena/features_user/match_room/widgets/match_outcome_views.dart';
import 'package:arena/features_user/match_room/widgets/room_ready_view.dart';
import 'package:arena/features_user/match_room/widgets/score_flow_view.dart';
import 'package:arena/features_user/match_room/widgets/share_code_form.dart';
import 'package:flutter/material.dart';

/// Switche le corps de la match room selon `match.status` et le rôle
/// du user courant. Garde les observers sur des placeholders dédiés
/// tant qu'il n'y a rien à afficher pour eux.
class StepBody extends StatelessWidget {
  const StepBody({
    required this.match,
    required this.role,
    required this.selfId,
    super.key,
  });

  final ArenaMatch match;
  final MatchRole role;
  final String? selfId;

  @override
  Widget build(BuildContext context) {
    return switch (match.status) {
      MatchStatus.pending || MatchStatus.scheduled => _stepShareCode(),
      MatchStatus.ready => RoomReadyView(match: match, role: role),
      MatchStatus.inProgress ||
      MatchStatus.scorePending ||
      MatchStatus.awaitingValidation =>
        role == MatchRole.observer
            ? const ObserverWaitingPlaceholder(
                icon: Icons.sports_esports,
                title: 'Match en cours',
                description: 'Les joueurs sont en train de jouer ou de'
                    ' valider le score.',
              )
            : ScoreFlowView(match: match, role: role),
      MatchStatus.disputed => DisputedView(match: match, selfId: selfId),
      MatchStatus.completed => CompletedView(match: match, selfId: selfId),
      MatchStatus.cancelled => const TerminalCard(
          icon: Icons.block,
          color: ArenaColors.silverDim,
          title: 'MATCH ANNULÉ',
          description: "L'admin a annulé ce match.",
        ),
      MatchStatus.forfeited => const TerminalCard(
          icon: Icons.exit_to_app,
          color: ArenaColors.neonRed,
          title: 'FORFAIT',
          description: "L'un des joueurs n'a pas démarré à temps.",
        ),
    };
  }

  /// Status `pending`/`scheduled` : seul le joueur HOME voit le
  /// formulaire de partage du code room. L'AWAY voit un placeholder
  /// d'attente, l'observer un placeholder neutre.
  ///
  /// Fix item 4 prompt 2026-05-19 — avant, les 2 joueurs voyaient le
  /// formulaire en même temps, ce qui créait des conflits de saisie.
  Widget _stepShareCode() {
    if (role == MatchRole.observer) {
      return const ObserverWaitingPlaceholder(
        icon: Icons.vpn_key_outlined,
        title: 'En attente du code room',
        description: 'Les joueurs vont créer une room dans le jeu et'
            ' partager le code ici.',
      );
    }
    if (!role.isHomeOf(match)) {
      // AWAY player : attend que HOME envoie le code.
      return const ObserverWaitingPlaceholder(
        icon: Icons.hourglass_top,
        title: 'En attente du code de HOME',
        description: 'Tu es AWAY sur ce match. Le joueur à domicile '
            "crée la room dans le jeu et t'enverra le code ici dès "
            "qu'il l'aura partagé.",
      );
    }
    return ShareCodeForm(match: match);
  }
}

class ObserverWaitingPlaceholder extends StatelessWidget {
  const ObserverWaitingPlaceholder({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.xxl),
      child: EmptyState(
        icon: icon,
        title: title,
        description: description,
      ),
    );
  }
}
