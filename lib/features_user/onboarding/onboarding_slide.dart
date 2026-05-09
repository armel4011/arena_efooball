import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Data for a single onboarding slide. Owned by [OnboardingPage]; the slide
/// itself is stateless and just renders [OnboardingSlide].
class OnboardingSlideData {
  const OnboardingSlideData({
    required this.emoji,
    required this.title,
    required this.description,
  });

  final String emoji;
  final String title;
  final String description;
}

/// One onboarding screen — emoji hero (70px with a soft signal-blue
/// drop-shadow glow), Bebas Neue h1, Space Grotesk paragraph, all centered.
///
/// Maps to `.onb-illu` / `.h1.center` / `.p.center` in `arena_v2.html`.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({required this.data, super.key});

  final OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Two-layer drop-shadow approximates the CSS
          // `filter: drop-shadow(0 0 30px var(--signal-blue-glow))`
          // — a tight inner glow plus a wider, fainter outer halo so the
          // emoji sits inside its own pool of light on the void backdrop.
          Text(
            data.emoji,
            style: TextStyle(
              fontSize: 70,
              shadows: [
                Shadow(
                  color: ArenaColors.signalBlue.withValues(alpha: 0.7),
                  blurRadius: 30,
                ),
                Shadow(
                  color: ArenaColors.signalBlue.withValues(alpha: 0.35),
                  blurRadius: 70,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ArenaSpacing.xxl),
          // Onboarding title is intentionally larger than the canonical
          // ArenaText.h1 (26 px) — Bebas Neue at the spec size renders
          // smaller than the CSS preview suggests, so we bump to 32 px
          // and a heavier weight here for parity with `arena_v2.html`.
          Text(
            data.title,
            style: ArenaText.h1.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            data.description,
            style: ArenaText.body.copyWith(color: ArenaColors.silver),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
