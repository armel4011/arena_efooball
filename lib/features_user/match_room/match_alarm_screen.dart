import 'dart:async';

import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/match_alarm_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Écran de RÉVEIL du rappel de match (≠ écran d'appel). Ouvert par la notif
/// d'alarme plein écran ([MatchAlarmService]) : « C'est l'heure ! » + un gros
/// bouton OUVRIR LE MATCH et un discret Ignorer.
///
/// À l'ouverture, l'écran ANNULE la notif (coupe son son bref) et démarre une
/// vraie sonnerie de réveil EN BOUCLE côté natif — coupée dès que l'utilisateur
/// agit ou quitte l'écran (comme un réveil).
class MatchAlarmScreen extends StatefulWidget {
  const MatchAlarmScreen({required this.matchId, super.key});

  final String matchId;

  @override
  State<MatchAlarmScreen> createState() => _MatchAlarmScreenState();
}

class _MatchAlarmScreenState extends State<MatchAlarmScreen> {
  @override
  void initState() {
    super.initState();
    // Coupe la notif (et son son bref FLAG_INSISTENT), puis lance la vraie
    // sonnerie de réveil en boucle.
    unawaited(MatchAlarmService.cancel());
    unawaited(MatchAlarmService.startRinging());
  }

  @override
  void dispose() {
    // Filet de sécurité : la sonnerie ne doit JAMAIS survivre à l'écran.
    unawaited(MatchAlarmService.stopRinging());
    super.dispose();
  }

  Future<void> _open() async {
    await MatchAlarmService.stopRinging();
    if (!mounted) return;
    // Routeur capturé AVANT `go` : après, ce widget est remplacé → son contexte
    // n'est plus valide pour le `push` qui suit. Base accueil dessous pour un
    // back cohérent, puis la salle de match.
    final router = GoRouter.of(context);
    // ignore: cascade_invocations
    router.go(UserRoutes.home);
    unawaited(router.push(UserRoutes.matchPath(widget.matchId)));
  }

  Future<void> _dismiss() async {
    await MatchAlarmService.stopRinging();
    if (!mounted) return;
    context.go(UserRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Le back matériel doit AUSSI couper la sonnerie.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_dismiss());
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
                  onPressed: () => unawaited(_open()),
                ),
                const SizedBox(height: ArenaSpacing.md),
                TextButton(
                  onPressed: () => unawaited(_dismiss()),
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
