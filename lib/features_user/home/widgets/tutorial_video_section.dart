import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Décide si la bannière tutoriel doit s'afficher pour un user donné.
///
/// Règle : la fenêtre d'affichage démarre à la PREMIÈRE IMPRESSION du user
/// (`firstSeen`), pas à la création du compte. La bannière s'affiche tant que
/// `now - firstSeen` est strictement inférieur à `displayDays` jours, puis
/// disparaît définitivement pour ce user.
///
/// Fallback SÛR : si `firstSeen` est `null` (1re impression inconnue — RPC
/// pas encore résolue, erreur réseau…), on **ne montre pas** la bannière. On
/// préfère ne rien afficher plutôt que de risquer un calcul de fenêtre faux.
bool shouldShowTutorialBanner({
  required DateTime? firstSeen,
  required int displayDays,
  DateTime? now,
}) {
  if (firstSeen == null) return false;
  final reference = now ?? DateTime.now();
  final ageInDays = reference.difference(firstSeen).inDays;
  return ageInDays < displayDays;
}

/// Section vidéo tutoriel de la home utilisateur.
///
/// Affiche la vidéo de prise en main active (renseignée par le super-admin)
/// sous forme de bannière avec un CTA "Regarder le tutoriel". **N'affiche
/// RIEN** tant qu'aucune vidéo active n'existe (ni pendant le loading / en
/// cas d'erreur) — la section se replie en `SizedBox.shrink`.
///
/// Au tap, le lien `videoUrl` s'ouvre en EXTERNE (navigateur / app vidéo)
/// via `url_launcher` (LaunchMode.externalApplication).
class TutorialVideoSection extends ConsumerWidget {
  const TutorialVideoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(activeTutorialVideoProvider).valueOrNull;
    if (video == null) return const SizedBox.shrink();

    // Fenêtre basée sur la 1re impression du user (enregistrée par la RPC à
    // la volée), pas sur l'âge du compte.
    //
    // - Loading : on ne flashe rien tant que la date n'est pas connue.
    // - Erreur : fallback masqué. La 1re impression n'est PAS perdue : la RPC
    //   est idempotente, donc elle sera enregistrée au prochain chargement
    //   réussi (la fenêtre démarrera simplement à ce moment-là).
    final firstSeen = ref.watch(tutorialFirstSeenProvider(video.id)).valueOrNull;
    final show = shouldShowTutorialBanner(
      firstSeen: firstSeen,
      displayDays: video.displayDays,
    );
    if (!show) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.md,
        ArenaSpacing.lg,
        0,
      ),
      child: GestureDetector(
        onTap: () => _handleTap(context, video),
        child: Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            borderRadius: BorderRadius.circular(ArenaRadius.lg),
            border: Border.all(color: ArenaColors.signalBlue),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ArenaColors.signalBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: ArenaColors.signalBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.tutorialWatchCta,
                      style: ArenaText.monoSmall.copyWith(
                        color: ArenaColors.signalBlue,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                size: 16,
                color: ArenaColors.silver,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, TutorialVideo video) {
    final target = video.videoUrl.trim();
    if (target.isEmpty) return;
    unawaited(_launchExternal(context, target));
  }

  Future<void> _launchExternal(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.promoBannerLinkOpenError)),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.promoBannerLinkOpenError)),
      );
    }
  }
}
