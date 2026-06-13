import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Décide si une bannière tutoriel doit s'afficher pour un user donné.
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

/// Section bannières tutoriel ciblée par page (`home` / `competitions`).
///
/// Observe les bannières ACTIVES éligibles pour la [page] (inclut les
/// bannières `all`). Pour chaque bannière, n'affiche que celles dans la
/// fenêtre du user courant (`shouldShowTutorialBanner` sur la 1re impression).
/// Plusieurs bannières peuvent s'afficher → rendues dans une `Column`.
///
/// **N'affiche RIEN** s'il n'y a aucune bannière éligible (ni pendant le
/// loading / en cas d'erreur) — chaque bannière non résolue est masquée.
///
/// Au tap, le lien `videoUrl` s'ouvre en EXTERNE (navigateur / app vidéo)
/// via `url_launcher` (LaunchMode.externalApplication).
class TutorialBannerSection extends ConsumerWidget {
  const TutorialBannerSection({required this.page, super.key});

  final TutorialPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners =
        ref.watch(tutorialBannersForPageProvider(page)).valueOrNull ??
            const <TutorialVideo>[];
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final banner in banners)
          _TutorialBannerCard(key: ValueKey(banner.id), banner: banner),
      ],
    );
  }
}

/// Une bannière tutoriel. Observe la 1re impression du user pour la bannière
/// et se masque si hors fenêtre / non résolue (loading / erreur).
class _TutorialBannerCard extends ConsumerWidget {
  const _TutorialBannerCard({required this.banner, super.key});

  final TutorialVideo banner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fenêtre basée sur la 1re impression du user (enregistrée par la RPC à
    // la volée), pas sur l'âge du compte.
    //
    // - Loading : on ne flashe rien tant que la date n'est pas connue.
    // - Erreur : fallback masqué. La 1re impression n'est PAS perdue : la RPC
    //   est idempotente, donc elle sera enregistrée au prochain chargement
    //   réussi (la fenêtre démarrera simplement à ce moment-là).
    final firstSeen =
        ref.watch(tutorialFirstSeenProvider(banner.id)).valueOrNull;
    final show = shouldShowTutorialBanner(
      firstSeen: firstSeen,
      displayDays: banner.displayDays,
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
        onTap: () => _handleTap(context),
        child: Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            borderRadius: BorderRadius.circular(ArenaRadius.lg),
            border: Border.all(color: ArenaColors.neonRed),
          ),
          child: Row(
            children: [
              // Badge « logo YouTube » : rectangle rouge arrondi + triangle
              // play blanc (forme reconnaissable du bouton lecture YouTube).
              Container(
                width: 46,
                height: 32,
                decoration: BoxDecoration(
                  color: ArenaColors.neonRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: ArenaColors.bone,
                  size: 24,
                ),
              ),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.tutorialWatchCta,
                      style: ArenaText.monoSmall.copyWith(
                        color: ArenaColors.neonRed,
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

  void _handleTap(BuildContext context) {
    final target = banner.videoUrl.trim();
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
