import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/profile/support_options_sheet.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

/// PHASE 9.5 — "About" screen with version + legal links.
///
/// Mirrors `arena_v2.html` #28 — branded ARENA wordmark, mission card,
/// link list. Les pages légales/site sont hébergées sur `arena237.com`
/// (ouvertes via `url_launcher`) ; le lien Support ouvre le fil de support
/// in-app (« Contact / Aide »). Reachable from `SettingsPage`.
///
/// Maps to screen #28 of `arena_v2.html`.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Tenu à jour avec `pubspec.yaml` (version: x.y.z+build) à chaque release.
  static const _version = '1.0.8';
  static const _build = '9';

  /// Base du site vitrine déployé (cf. landing/upload-site.ps1).
  static const _siteBase = 'https://arena237.com';

  static const _links = <_AboutLink>[
    _AboutLink(
      emoji: '📜',
      id: _AboutLinkId.cgu,
      url: '$_siteBase/conditions/',
      external: true,
    ),
    _AboutLink(
      emoji: '🔒',
      id: _AboutLinkId.privacy,
      url: '$_siteBase/confidentialite/',
      external: true,
    ),
    // Pas de page Cookies dédiée → repli sur la Politique de confidentialité.
    _AboutLink(
      emoji: '🍪',
      id: _AboutLinkId.cookies,
      url: '$_siteBase/confidentialite/',
      external: true,
    ),
    _AboutLink(emoji: '📞', id: _AboutLinkId.support),
    _AboutLink(
      emoji: '📱',
      id: _AboutLinkId.site,
      url: _siteBase,
      external: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: ArenaAppBar(title: l10n.aboutAppBarTitle),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              const SizedBox(height: ArenaSpacing.lg),
              const Center(child: ArenaLogo(fontSize: 56, letterSpacing: 8))
                  .animate()
                  .fadeIn(duration: ArenaDurations.long)
                  .slideY(
                    begin: -0.1,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'v$_version · build $_build',
                  style: ArenaText.monoSmall.copyWith(
                    color: ArenaColors.silver,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  l10n.aboutMadeInCameroon,
                  style: ArenaText.serifAccent.copyWith(
                    color: ArenaColors.iceCyan,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              const Divider(color: ArenaColors.border, height: 1),
              const SizedBox(height: ArenaSpacing.lg),
              const _MissionCard()
                  .animate(delay: 150.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                l10n.aboutLinksLabel,
                style: ArenaText.monoSmall.copyWith(
                  color: ArenaColors.silver,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              const _LinksCard(links: _links)
                  .animate(delay: 250.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.xl),
              Center(
                child: Text(
                  l10n.aboutBuiltWith,
                  style: ArenaText.serifAccent.copyWith(
                    color: ArenaColors.pearl,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  'FLUTTER · SUPABASE · AGORA',
                  style: ArenaText.monoSmall.copyWith(
                    color: ArenaColors.silver,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '© 2026 ARENA',
                  style: ArenaText.small.copyWith(color: ArenaColors.silver),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AboutLinkId { cgu, privacy, cookies, support, site }

class _AboutLink {
  const _AboutLink({
    required this.emoji,
    required this.id,
    this.url,
    this.external = false,
  });

  final String emoji;
  final _AboutLinkId id;

  /// URL externe à ouvrir (null pour le Support → navigation in-app).
  final String? url;
  final bool external;

  /// Localized label for the link row.
  String labelOf(AppLocalizations l10n) {
    switch (id) {
      case _AboutLinkId.cgu:
        return l10n.aboutLinkCgu;
      case _AboutLinkId.privacy:
        return l10n.aboutLinkPrivacy;
      case _AboutLinkId.cookies:
        return l10n.aboutLinkCookies;
      case _AboutLinkId.support:
        return l10n.aboutLinkSupport;
      case _AboutLinkId.site:
        return l10n.aboutLinkSite;
    }
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.aboutMissionTitle, style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            l10n.aboutMissionBody,
            style: ArenaText.body,
          ),
        ],
      ),
    );
  }
}

class _LinksCard extends StatelessWidget {
  const _LinksCard({required this.links});
  final List<_AboutLink> links;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < links.length; i++) ...[
            InkWell(
              onTap: () => _onLinkTap(context, links[i]),
              borderRadius: BorderRadius.circular(ArenaRadius.lg),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.md,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      links[i].emoji,
                      style: ArenaText.body.copyWith(fontSize: 14),
                    ),
                    const SizedBox(width: ArenaSpacing.sm),
                    Expanded(
                      child: Text(
                        links[i].labelOf(l10n),
                        style: ArenaText.body
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      links[i].external ? '↗' : '›',
                      style: ArenaText.bodyMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (i < links.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: ArenaColors.border,
                indent: ArenaSpacing.md,
                endIndent: ArenaSpacing.md,
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _onLinkTap(BuildContext context, _AboutLink link) async {
    // Support → sélecteur de canaux (chat in-app + e-mail).
    if (link.id == _AboutLinkId.support) {
      await showSupportOptionsSheet(context);
      return;
    }
    // Liens légaux / site → ouverture externe (arena237.com).
    final url = link.url;
    if (url == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.aboutLinkComingSoon(link.labelOf(l10n)))),
      );
    }
  }
}
