import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_user/draughts/ui/draughts_match_view.dart';
import 'package:arena/features_user/match_room/match_room_page.dart'
    show MatchRole;
import 'package:arena/features_user/match_room/widgets/match_outcome_views.dart';
import 'package:arena/features_user/match_room/widgets/room_ready_view.dart';
import 'package:arena/features_user/match_room/widgets/score_flow_view.dart';
import 'package:arena/features_user/match_room/widgets/share_code_form.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Switche le corps de la match room selon `match.status` et le rôle
/// du user courant. Garde les observers sur des placeholders dédiés
/// tant qu'il n'y a rien à afficher pour eux.
class StepBody extends StatelessWidget {
  const StepBody({
    required this.match,
    required this.role,
    required this.selfId,
    this.isDraughts = false,
    super.key,
  });

  final ArenaMatch match;
  final MatchRole role;
  final String? selfId;

  /// Compétition de jeu de dames → plateau jouable in-app au lieu du flux
  /// déclaratif (code room + saisie de score).
  final bool isDraughts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (match.status) {
      MatchStatus.pending || MatchStatus.scheduled => isDraughts
          ? (role == MatchRole.observer
              ? _observerWaiting(context)
              : DraughtsLobbyView(match: match, selfId: selfId))
          : _stepShareCode(context),
      MatchStatus.ready => isDraughts
          ? (role == MatchRole.observer
              ? _observerWaiting(context)
              : DraughtsLobbyView(match: match, selfId: selfId))
          : RoomReadyView(match: match, role: role),
      MatchStatus.inProgress ||
      MatchStatus.scorePending ||
      MatchStatus.awaitingValidation =>
        role == MatchRole.observer
            ? (isDraughts
                // Les dames se regardent in-app (lecture seule) ; les jeux
                // tiers n'ont rien à montrer côté observateur.
                ? DraughtsMatchView(
                    match: match,
                    selfId: selfId,
                    spectator: true,
                  )
                : ObserverWaitingPlaceholder(
                    icon: Icons.sports_esports,
                    title: l10n.stepBodyMatchInProgressTitle,
                    description: l10n.stepBodyMatchInProgressDesc,
                  ))
            : isDraughts
                ? DraughtsMatchView(match: match, selfId: selfId)
                : ScoreFlowView(match: match, role: role),
      MatchStatus.disputed =>
        DisputedView(match: match, selfId: selfId, isDraughts: isDraughts),
      MatchStatus.completed =>
        CompletedView(match: match, selfId: selfId, isDraughts: isDraughts),
      MatchStatus.cancelled => TerminalCard(
          icon: Icons.block,
          color: ArenaColors.silverDim,
          title: l10n.stepBodyMatchCancelledTitle,
          description: l10n.stepBodyMatchCancelledDesc,
        ),
      MatchStatus.forfeited => TerminalCard(
          icon: Icons.exit_to_app,
          color: ArenaColors.neonRed,
          title: l10n.stepBodyForfeitTitle,
          description: l10n.stepBodyForfeitDesc,
        ),
    };
  }

  /// Status `pending`/`scheduled` : seul le joueur HOME voit le
  /// formulaire de partage du code room. L'AWAY voit un placeholder
  /// d'attente, l'observer un placeholder neutre.
  ///
  /// Fix item 4 prompt 2026-05-19 — avant, les 2 joueurs voyaient le
  /// formulaire en même temps, ce qui créait des conflits de saisie.
  /// Placeholder d'attente pour un observateur (compétition draughts : il ne
  /// peut pas lire la partie — RLS réservée aux 2 joueurs).
  Widget _observerWaiting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ObserverWaitingPlaceholder(
      icon: Icons.grid_on,
      title: l10n.stepBodyMatchInProgressTitle,
      description: l10n.stepBodyMatchInProgressDesc,
    );
  }

  Widget _stepShareCode(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (role == MatchRole.observer) {
      return ObserverWaitingPlaceholder(
        icon: Icons.vpn_key_outlined,
        title: l10n.stepBodyAwaitRoomCodeTitle,
        description: l10n.stepBodyAwaitRoomCodeDesc,
      );
    }
    if (!role.isHomeOf(match)) {
      // AWAY player : attend que HOME envoie le code.
      return ObserverWaitingPlaceholder(
        icon: Icons.hourglass_top,
        title: l10n.stepBodyAwaitHomeCodeTitle,
        description: l10n.stepBodyAwaitHomeCodeDesc,
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
