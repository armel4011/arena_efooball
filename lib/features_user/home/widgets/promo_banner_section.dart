import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/promo_banner.dart';
import 'package:arena/data/repositories/promo_banner_repository.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Espace publicitaire de la home utilisateur.
///
/// Affiche la bannière promo active (uploadée par le super-admin) sous
/// forme d'image cliquable. **N'affiche RIEN** tant qu'aucune bannière
/// active n'existe (ni pendant le loading / en cas d'erreur) — la section
/// se replie en `SizedBox.shrink`.
///
/// Au tap, la redirection dépend de `redirectType` :
/// - `internalPage` → `context.push` vers une route interne de l'app ;
/// - `webLink` → ouverture du lien web externe ;
/// - `whatsapp` → ouverture de `wa.me/<numéro>`.
class PromoBannerSection extends ConsumerWidget {
  const PromoBannerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(activePromoBannerProvider).valueOrNull;
    if (banner == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.md,
        ArenaSpacing.lg,
        0,
      ),
      child: GestureDetector(
        onTap: () => _handleTap(context, banner),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: banner.imageUrl,
              fit: BoxFit.cover,
              // Pas de placeholder bruyant : si l'image casse, on replie la
              // section pour ne pas afficher un bloc d'erreur sur la home.
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
              placeholder: (_, __) => const ColoredBox(
                color: ArenaColors.carbon,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ArenaColors.silver,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, PromoBanner banner) {
    final target = banner.redirectTarget.trim();
    if (target.isEmpty) return;

    switch (banner.redirectType) {
      case PromoRedirectType.internalPage:
        unawaited(context.push<void>(target));
      case PromoRedirectType.webLink:
        unawaited(_launchExternal(context, target));
      case PromoRedirectType.whatsapp:
        // Construit wa.me à partir des chiffres du numéro (tolère +, espaces).
        final digits = target.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) return;
        unawaited(_launchExternal(context, 'https://wa.me/$digits'));
    }
  }

  Future<void> _launchExternal(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.promoBannerLinkOpenError)),
      );
    }
  }
}
