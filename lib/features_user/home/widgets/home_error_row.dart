import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Affiche une ligne d'erreur inline dans les sections de la home.
/// Partagé entre `_UpcomingMatchesScroller`, `_LiveStreamsSection` et
/// `_ActiveCompetitionsSection`.
class HomeErrorRow extends StatelessWidget {
  const HomeErrorRow({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      child: Text(
        message,
        style: ArenaText.body.copyWith(color: ArenaColors.danger),
      ),
    );
  }
}
