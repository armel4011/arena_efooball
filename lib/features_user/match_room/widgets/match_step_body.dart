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
import 'package:arena/features_user/match_room/widgets/start_recording_form.dart';
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
      // `ready` est un statut LEGACY : plus aucun code (client ni serveur) ne
      // l'attribue — les matchs passent `pending`/`scheduled` → `in_progress`
      // directement. On le route comme `pending`/`scheduled` pour rester
      // cohérent avec le flux actuel ; sinon il affichait `RoomReadyView` aux
      // DEUX joueurs, où le HOME voyait un bouton « rejoindre » qui déclenchait
      // pourtant `markInProgress` + l'enregistrement (incohérence dormante).
      MatchStatus.pending ||
      MatchStatus.scheduled ||
      MatchStatus.ready =>
        isDraughts
            ? (role == MatchRole.observer
                ? _observerWaiting(context)
                : DraughtsLobbyView(match: match, selfId: selfId))
            : _stepPrepare(context),
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
                : _inProgressPlayerBody(context),
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

  /// Statut `pending`/`scheduled` (nouveau flux) : le HOME voit l'écran de
  /// démarrage (nom d'équipe + « DÉMARRER L'ENREGISTREMENT ») ; l'AWAY et
  /// l'observer attendent que l'hôte prépare la room.
  Widget _stepPrepare(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (role == MatchRole.observer) {
      return ObserverWaitingPlaceholder(
        icon: Icons.vpn_key_outlined,
        title: l10n.stepBodyAwaitRoomCodeTitle,
        description: l10n.stepBodyAwaitRoomCodeDesc,
      );
    }
    if (!role.isHomeOf(match)) {
      // AWAY : l'hôte démarre son enregistrement puis créera la room.
      return ObserverWaitingPlaceholder(
        icon: Icons.hourglass_top,
        title: l10n.stepBodyHostPreparingTitle,
        description: l10n.stepBodyHostPreparingDesc,
      );
    }
    return StartRecordingForm(match: match, role: role);
  }

  /// Nom d'équipe du joueur courant (signal « a rejoint la room »).
  String? _selfTeamName() {
    if (selfId == match.player1Id) return match.player1TeamName;
    if (selfId == match.player2Id) return match.player2TeamName;
    return null;
  }

  /// Corps `in_progress` pour un JOUEUR (non-dames, non-observer). Sous-état
  /// selon le rôle / la présence du code / le fait d'avoir rejoint.
  Widget _inProgressPlayerBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isHome = role.isHomeOf(match);
    final code = match.roomCode;
    final hasCode = code != null && code.isNotEmpty;
    final selfJoined = _selfTeamName()?.trim().isNotEmpty ?? false;

    // HOME sans code encore : il enregistre, doit créer sa room dans eFootball
    // puis envoyer le code depuis le bouton flottant rouge. (Testé AVANT
    // `selfJoined` : le HOME a posé son team name au démarrage.)
    if (isHome && !hasCode) {
      return ObserverWaitingPlaceholder(
        icon: Icons.fiber_manual_record,
        title: l10n.stepBodyHomeAwaitCreateRoomTitle,
        description: l10n.stepBodyHomeAwaitCreateRoomDesc,
      );
    }

    // Le joueur a rejoint (team name posé) → flux de score normal.
    if (selfJoined) {
      return ScoreFlowView(match: match, role: role);
    }

    // AWAY, code pas encore arrivé : attend le code de l'hôte.
    if (!hasCode) {
      return ObserverWaitingPlaceholder(
        icon: Icons.hourglass_top,
        title: l10n.stepBodyAwayAwaitCodeTitle,
        description: l10n.stepBodyAwayAwaitCodeDesc,
      );
    }

    // AWAY, code présent, pas encore rejoint : code + nom d'équipe +
    // « J'AI REJOINT LA ROOM ».
    return RoomReadyView(match: match, role: role);
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
