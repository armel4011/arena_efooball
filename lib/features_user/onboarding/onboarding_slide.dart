import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Visual content for a single onboarding slide.
///
/// Composed inside the OnBoardingSlider from `flutter_onboarding_slider`
/// — see `onboarding_page.dart`. Holds no state and no skip/next logic;
/// the parent slider drives transitions and persistence.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.iconBackground,
    super.key,
  });

  /// Slide headline (rendered with the Orbitron face).
  final String title;

  /// Body copy under the title.
  final String description;

  /// Glyph rendered inside the round visual.
  final IconData icon;

  /// Tint applied to the icon and the dotted ring around it.
  final Color accentColor;

  /// Optional fill behind the icon. Defaults to a translucent [accentColor].
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final bg = iconBackground ?? accentColor.withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.xl,
        vertical: ArenaSpacing.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IllustrationRing(color: accentColor, fill: bg, icon: icon),
          const SizedBox(height: ArenaSpacing.xxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: ArenaTypography.headlineLarge,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            description,
            textAlign: TextAlign.center,
            style: ArenaTypography.bodyLarge.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationRing extends StatelessWidget {
  const _IllustrationRing({
    required this.color,
    required this.fill,
    required this.icon,
  });

  final Color color;
  final Color fill;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, size: 84, color: color),
    );
  }
}
