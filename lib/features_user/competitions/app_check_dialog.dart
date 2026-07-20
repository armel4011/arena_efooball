import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_youtube_player.dart';
import 'package:arena/features_user/competitions/game_store_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialogue de CONTRÔLE affiché avant l'inscription à une compétition sur jeu
/// EXTERNE (eFootball, Mobile FC, Dream League — pas les Dames). Il rappelle à
/// l'utilisateur de vérifier que son app du jeu est à jour / identique à celle
/// des autres compétiteurs et qu'elle s'installe sur son téléphone, avec :
///   • un bouton « Store » (téléchargement de l'app du jeu) ;
///   • une vidéo YouTube lue in-app (cible `install_check`, par jeu, admin).
///
/// Retourne `true` si l'utilisateur choisit de POURSUIVRE l'inscription,
/// `false`/`null` s'il annule ou ferme le dialogue.
Future<bool> showAppCheckDialog(
  BuildContext context, {
  required GameType game,
}) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (_) => _AppCheckDialog(game: game),
  );
  return proceed ?? false;
}

class _AppCheckDialog extends ConsumerWidget {
  const _AppCheckDialog({required this.game});

  final GameType game;

  Future<void> _openStore(BuildContext context) async {
    final url = gameStoreUrl(game);
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir le store.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One-shot REST (pas le stream Realtime partagé) : le dialogue est
    // transitoire et doit afficher la vidéo de façon fiable, même si la
    // souscription Realtime n'a pas encore émis / reçu un INSERT admin récent.
    final videoUrl =
        ref.watch(installCheckVideoOnceProvider(game)).valueOrNull?.videoUrl;
    final player = ArenaYoutubePlayer.maybe(videoUrl);
    final hasStore = gameStoreUrl(game) != null;

    return Dialog(
      backgroundColor: ArenaColors.carbon,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.xl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: ArenaColors.signalBlue,
                    size: 28,
                  ),
                  const SizedBox(width: ArenaSpacing.sm),
                  Expanded(
                    child: Text(
                      "Avant de t'inscrire",
                      style: ArenaText.h3.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                '${game.label} se joue sur une application externe. Avant de '
                "t'inscrire, vérifie que :",
                style: ArenaText.body.copyWith(color: ArenaColors.silver),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              const _CheckLine(
                text: 'ton application est à jour et identique à celle des '
                    'autres compétiteurs,',
              ),
              const _CheckLine(
                text: "elle peut bien s'installer et se lancer sur ton "
                    'téléphone.',
              ),
              if (player != null) ...[
                const SizedBox(height: ArenaSpacing.md),
                Text(
                  'Guide vidéo',
                  style: ArenaText.small.copyWith(
                    color: ArenaColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.xs),
                player,
              ],
              if (hasStore) ...[
                const SizedBox(height: ArenaSpacing.md),
                ArenaButton(
                  label: 'Ouvrir le store',
                  variant: ArenaButtonVariant.secondary,
                  icon: Icons.storefront_outlined,
                  fullWidth: true,
                  onPressed: () => _openStore(context),
                ),
              ],
              const SizedBox(height: ArenaSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ArenaButton(
                      label: 'Annuler',
                      variant: ArenaButtonVariant.ghost,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: ArenaSpacing.sm),
                  Expanded(
                    child: ArenaButton(
                      label: 'Continuer',
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ArenaSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_outline,
              color: ArenaColors.signalBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
          ),
        ],
      ),
    );
  }
}
