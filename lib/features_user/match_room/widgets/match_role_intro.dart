import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/onboarding_flags_repository.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/features_shared/widgets/arena_youtube_player.dart';
import 'package:arena/features_user/match_room/match_room_page.dart'
    show MatchRole;
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Déclencheur (invisible) du dialogue d'intro de rôle à l'entrée en salle de
/// match football. À poser à l'étape 1 (salle de code) uniquement pour un
/// JOUEUR et un jeu de foot — c'est là que le rôle DOMICILE/EXTÉRIEUR décide de
/// qui partage le code.
///
/// One-shot **par rôle** : le dialogue s'affiche la 1re fois qu'un joueur est
/// DOMICILE, et la 1re fois qu'il est EXTÉRIEUR (deux flux distincts). La
/// garantie « une seule fois » est serveur (RPC `onboarding_mark_seen_once`,
/// atomique) — pas de re-déclenchement au remount ni sur un autre appareil.
class MatchRoleIntroGate extends ConsumerStatefulWidget {
  const MatchRoleIntroGate({
    required this.match,
    required this.role,
    required this.game,
    super.key,
  });

  final ArenaMatch match;
  final MatchRole role;
  final GameType game;

  @override
  ConsumerState<MatchRoleIntroGate> createState() => _MatchRoleIntroGateState();
}

class _MatchRoleIntroGateState extends ConsumerState<MatchRoleIntroGate> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    // initState ne s'exécute qu'une fois par montage ; ce garde couvre en plus
    // un éventuel post-frame double.
    if (_handled) return;
    _handled = true;

    final isHome = widget.role.isHomeOf(widget.match);
    final flag = 'match_role_intro:${isHome ? 'home' : 'away'}';
    final firstTime =
        await ref.read(onboardingFlagsRepositoryProvider).markSeenOnce(flag);
    if (!firstTime || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _MatchRoleIntroDialog(
        isHome: isHome,
        game: widget.game,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Contenu du dialogue : rôle (DOMICILE/EXTÉRIEUR), déroulé jusqu'à la saisie du
/// score, et vidéo explicative si l'admin en a publié une pour ce jeu.
class _MatchRoleIntroDialog extends ConsumerWidget {
  const _MatchRoleIntroDialog({required this.isHome, required this.game});

  final bool isHome;
  final GameType game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Vidéo DIFFÉRENTE selon le côté : Domicile (envoie le code) vs Extérieur
    // (le reçoit). L'admin publie une vidéo par côté.
    final side = isHome ? MatchRoleSide.home : MatchRoleSide.away;
    final video = ref
        .watch(matchRoleIntroVideoProvider((game: game, side: side)))
        .valueOrNull;
    final player =
        video == null ? null : ArenaYoutubePlayer.maybe(video.videoUrl);

    return AlertDialog(
      backgroundColor: ArenaColors.carbon,
      title: Text(
        isHome ? l10n.roleIntroHomeTitle : l10n.roleIntroAwayTitle,
        style: ArenaText.h3,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isHome ? l10n.roleIntroHomeBody : l10n.roleIntroAwayBody,
                style: ArenaText.body.copyWith(color: ArenaColors.silver),
              ),
              if (player != null) ...[
                const SizedBox(height: ArenaSpacing.lg),
                player,
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.roleIntroGotIt,
            style: ArenaText.body.copyWith(color: ArenaColors.signalBlue),
          ),
        ),
      ],
    );
  }
}
