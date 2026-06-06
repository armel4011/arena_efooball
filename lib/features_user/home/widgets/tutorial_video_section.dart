import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Décide si la bannière tutoriel doit s'afficher pour un user donné.
///
/// Règle : la bannière ne cible que les NOUVEAUX comptes. Elle s'affiche
/// tant que l'âge du compte (`now - accountCreatedAt`) est strictement
/// inférieur à `displayDays` jours, puis disparaît.
///
/// Fallback SÛR : si `accountCreatedAt` est `null` (date de création
/// inconnue — profil non hydraté, cache vide…), on **ne montre pas** la
/// bannière. On préfère ne rien afficher plutôt que de spammer un user dont
/// on ignore l'ancienneté.
bool shouldShowTutorialBanner({
  required DateTime? accountCreatedAt,
  required int displayDays,
  DateTime? now,
}) {
  if (accountCreatedAt == null) return false;
  final reference = now ?? DateTime.now();
  final ageInDays = reference.difference(accountCreatedAt).inDays;
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

    // Ciblage nouveaux users : on n'affiche que si le compte est plus jeune
    // que `video.displayDays`. Fallback sûr si createdAt inconnu → masqué.
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final show = shouldShowTutorialBanner(
      accountCreatedAt: profile?.createdAt,
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
