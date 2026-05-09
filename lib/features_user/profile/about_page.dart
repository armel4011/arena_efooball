import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// PHASE 9.5 — static "About" screen with version + legal links.
///
/// Mirrors `arena_v2.html` #28 — branded ARENA wordmark, mission card,
/// 5-row link list. The actual page handlers (CGU, Privacy, Cookies,
/// Support, marketing site) ship in PHASE 12.5 alongside the legal copy
/// hosted on `arena.app`. This screen is reachable from `SettingsPage`.
///
/// Maps to screen #28 of `arena_v2.html`.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _version = '1.0.0';
  static const _build = '4287';

  static const _links = <_AboutLink>[
    _AboutLink(emoji: '📜', label: 'CGU'),
    _AboutLink(emoji: '🔒', label: 'Privacy Policy'),
    _AboutLink(emoji: '🍪', label: 'Cookies'),
    _AboutLink(emoji: '📞', label: 'Support'),
    _AboutLink(emoji: '📱', label: 'Site arena.app', external: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(title: 'À propos'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            const SizedBox(height: ArenaSpacing.lg),
            const Center(child: ArenaLogo(fontSize: 48, letterSpacing: 6))
                .animate()
                .fadeIn(duration: ArenaDurations.long)
                .slideY(
                  begin: -0.1,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'e-sport panafricain',
                style: ArenaText.serifTagline,
              ),
            ),
            const SizedBox(height: ArenaSpacing.md),
            Center(
              child: Text(
                'v$_version · build $_build',
                style: ArenaText.monoSmall,
              ),
            ),
            const SizedBox(height: ArenaSpacing.xl),
            const _MissionCard()
                .animate(delay: 150.ms)
                .fadeIn(duration: ArenaDurations.medium),
            const SizedBox(height: ArenaSpacing.lg),
            Text('LIENS', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            _LinksCard(links: _links)
                .animate(delay: 250.ms)
                .fadeIn(duration: ArenaDurations.medium),
            const SizedBox(height: ArenaSpacing.lg),
            Center(
              child: Text(
                '© 2026 ARENA SAS',
                style: ArenaText.small,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Made in Cameroun 🇨🇲',
                style: ArenaText.small,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutLink {
  const _AboutLink({
    required this.emoji,
    required this.label,
    this.external = false,
  });

  final String emoji;
  final String label;
  final bool external;
}

class _MissionCard extends StatelessWidget {
  const _MissionCard();

  @override
  Widget build(BuildContext context) {
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
          Text('📜 Notre mission', style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            "ARENA démocratise l'e-sport mobile en Afrique en offrant des "
            'tournois équitables, des gains en mobile money, et une '
            'expérience premium aux passionnés de football virtuel.',
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
                      style: GoogleFonts.spaceGrotesk(fontSize: 14),
                    ),
                    const SizedBox(width: ArenaSpacing.sm),
                    Expanded(
                      child: Text(
                        links[i].label,
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

  void _onLinkTap(BuildContext context, _AboutLink link) {
    // Real handlers (url_launcher / in-app webview) ship in PHASE 12.5.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${link.label} arrive en PHASE 12.5'),
      ),
    );
  }
}
