import 'dart:async';

import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/match_alarm_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Écran de RÉVEIL du rappel de match (≠ écran d'appel). Ouvert par la notif
/// d'alarme plein écran ([MatchAlarmService]) : « C'est l'heure ! » + un gros
/// bouton OUVRIR LE MATCH et un discret Ignorer. Les deux COUPENT la sonnerie
/// (annulation de la notif insistante) avant de naviguer.
class MatchAlarmScreen extends StatelessWidget {
  const MatchAlarmScreen({required this.matchId, super.key});

  final String matchId;

  Future<void> _open(BuildContext context) async {
    await MatchAlarmService.cancel();
    if (!context.mounted) return;
    // Remplace l'alarme par la salle de match (base accueil dessous pour le back).
    context.go(UserRoutes.home);
    unawaited(context.push(UserRoutes.matchPath(matchId)));
  }

  Future<void> _dismiss(BuildContext context) async {
    await MatchAlarmService.cancel();
    if (!context.mounted) return;
    context.go(UserRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    // Écran plein, sans AppBar : on veut un vrai « réveil » immersif.
    return PopScope(
      // Le back matériel doit AUSSI couper la sonnerie (sinon elle continue).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismiss(context);
      },
      child: Scaffold(
        backgroundColor: ArenaColors.void_,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ArenaSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.alarm,
                  size: 88,
                  color: ArenaColors.signalBlue,
                ),
                const SizedBox(height: ArenaSpacing.lg),
                Text(
                  "C'EST L'HEURE !",
                  textAlign: TextAlign.center,
                  style: ArenaText.h1.copyWith(color: ArenaColors.bone),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                Text(
                  'Ton match va commencer — rejoins la salle.',
                  textAlign: TextAlign.center,
                  style: ArenaText.body.copyWith(color: ArenaColors.silver),
                ),
                const SizedBox(height: ArenaSpacing.xxl),
                ArenaButton(
                  label: 'OUVRIR LE MATCH',
                  icon: Icons.sports_esports,
                  fullWidth: true,
                  size: ArenaButtonSize.large,
                  onPressed: () => _open(context),
                ),
                const SizedBox(height: ArenaSpacing.md),
                TextButton(
                  onPressed: () => _dismiss(context),
                  child: Text(
                    'Ignorer',
                    style: ArenaText.body.copyWith(color: ArenaColors.silver),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
