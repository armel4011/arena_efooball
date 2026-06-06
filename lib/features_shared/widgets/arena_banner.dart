import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Full-width gradient banner identifying a game.
///
/// Maps to `.banner` / `.banner-efoot` / `.banner-draughts` / `.banner-fc` in
/// `arena_v2.html`. Text renders white over the gradient.
enum ArenaBannerGame { efoot, draughts, fc }

class ArenaBanner extends StatelessWidget {
  const ArenaBanner({
    required this.game,
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final ArenaBannerGame game;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  LinearGradient get _gradient => switch (game) {
        ArenaBannerGame.efoot => ArenaColors.bannerEfoot,
        ArenaBannerGame.draughts => ArenaColors.bannerDraughts,
        ArenaBannerGame.fc => ArenaColors.bannerFc,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: ArenaText.h2.copyWith(color: Colors.white),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: ArenaText.bodyMuted.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
