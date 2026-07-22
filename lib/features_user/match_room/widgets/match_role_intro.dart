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
      // BLOQUANT : ni tap hors dialogue, ni back ne le ferment. On ne sort que
      // par « J'ai compris », lui-même déverrouillé par la case de confirmation.
      barrierDismissible: false,
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
///
/// BLOQUANT : le joueur ne peut sortir qu'après avoir coché la case confirmant
/// qu'il a DÉJÀ lancé le jeu (menu principal). Le bouton « J'ai compris » reste
/// désactivé tant que la case n'est pas cochée.
class _MatchRoleIntroDialog extends ConsumerStatefulWidget {
  const _MatchRoleIntroDialog({required this.isHome, required this.game});

  final bool isHome;
  final GameType game;

  @override
  ConsumerState<_MatchRoleIntroDialog> createState() =>
      _MatchRoleIntroDialogState();
}

class _MatchRoleIntroDialogState extends ConsumerState<_MatchRoleIntroDialog> {
  bool _confirmed = false;

  /// Découpe le corps localisé en lignes espacées : les libellés « Étape N » et
  /// la ligne d'avertissement adoptent le style du titre (h3) ; les descriptions
  /// restent en corps. Un léger espacement sépare chaque ligne.
  List<Widget> _bodyLines(String body) {
    // Détecte un début d'étape dans les 3 langues (Étape / Step / الخطوة).
    final stepRe = RegExp(r'^(Étape|Step|الخطوة)\s*\d+', unicode: true);
    final widgets = <Widget>[];
    for (final raw in body.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: ArenaSpacing.sm));
      }
      if (line.startsWith('⚠')) {
        widgets.add(
          Text(line, style: ArenaText.h3.copyWith(color: ArenaColors.danger)),
        );
      } else if (stepRe.hasMatch(line)) {
        final sep = line.indexOf(':');
        if (sep > 0) {
          widgets.add(
            Text.rich(
              TextSpan(
                children: [
                  // Libellé « Étape N » au style du titre.
                  TextSpan(
                    text: line.substring(0, sep).trim(),
                    style: ArenaText.h3,
                  ),
                  TextSpan(
                    text: ' : ${line.substring(sep + 1).trim()}',
                    style: ArenaText.body.copyWith(color: ArenaColors.silver),
                  ),
                ],
              ),
            ),
          );
        } else {
          widgets.add(Text(line, style: ArenaText.h3));
        }
      } else {
        // Paragraphe d'intro + ligne « NB : … ».
        widgets.add(
          Text(
            line,
            style: ArenaText.body.copyWith(color: ArenaColors.silver),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isHome = widget.isHome;
    final game = widget.game;
    // Vidéo DIFFÉRENTE selon le côté : Domicile (envoie le code) vs Extérieur
    // (le reçoit). L'admin publie une vidéo par côté.
    final side = isHome ? MatchRoleSide.home : MatchRoleSide.away;
    final video = ref
        .watch(matchRoleIntroVideoProvider((game: game, side: side)))
        .valueOrNull;
    final player =
        video == null ? null : ArenaYoutubePlayer.maybe(video.videoUrl);

    return PopScope(
      // Le back matériel ne doit PAS contourner la confirmation.
      canPop: false,
      child: AlertDialog(
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
                ..._bodyLines(
                  isHome
                      ? l10n.roleIntroHomeBody(game.label)
                      : l10n.roleIntroAwayBody(game.label),
                ),
                if (player != null) ...[
                  const SizedBox(height: ArenaSpacing.lg),
                  player,
                ],
                const SizedBox(height: ArenaSpacing.md),
                // Case de confirmation OBLIGATOIRE : déverrouille « J'ai compris ».
                InkWell(
                  onTap: () => setState(() => _confirmed = !_confirmed),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _confirmed,
                        activeColor: ArenaColors.signalBlue,
                        onChanged: (v) =>
                            setState(() => _confirmed = v ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(top: ArenaSpacing.sm),
                          child: Text(
                            l10n.roleIntroConfirmLaunched(game.label),
                            style: ArenaText.body
                                .copyWith(color: ArenaColors.bone),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            // Désactivé tant que la case n'est pas cochée.
            onPressed:
                _confirmed ? () => Navigator.of(context).pop() : null,
            child: Text(
              l10n.roleIntroGotIt,
              style: ArenaText.body.copyWith(
                color:
                    _confirmed ? ArenaColors.signalBlue : ArenaColors.silverDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
