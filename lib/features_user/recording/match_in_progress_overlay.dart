import 'dart:ui';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 7 — visual stand-in for the in-game floating ARENA chip.
///
/// The actual native overlay (drawn over FIFA/eFootball with
/// `flutter_overlay_window`) lives in `recording/overlay/`. This page
/// matches `arena_v2.html` #17 — a 60×60 floating chip with the recording
/// timer and a long-press menu mocked at the bottom. It's primarily
/// reachable from the dev gallery so designers/QA can review the spec
/// without firing up a real game.
///
/// Maps to screen #17 of `arena_v2.html`.
class MatchInProgressOverlay extends StatelessWidget {
  const MatchInProgressOverlay({
    this.elapsed = const Duration(minutes: 24, seconds: 18),
    this.gameLabel = 'FIFA MOBILE',
    this.scoreLine = '2 - 1',
    this.matchPhase = "Mi-temps · 42'",
    super.key,
  });

  final Duration elapsed;
  final String gameLabel;
  final String scoreLine;
  final String matchPhase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _GameBackdrop(),
          _GameHud(
            gameLabel: gameLabel,
            scoreLine: scoreLine,
            matchPhase: matchPhase,
          ),
          Align(
            alignment: const Alignment(0.95, 0),
            child: _ArenaFloatingChip(elapsed: elapsed)
                .animate()
                .fadeIn(duration: ArenaDurations.medium)
                .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
          ),
          const _LongPressMenu(),
        ],
      ),
    );
  }
}

class _GameBackdrop extends StatelessWidget {
  const _GameBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3A18), Color(0xFF0A1A08)],
        ),
      ),
      child: Center(
        child: Text(
          '⚽',
          style: TextStyle(
            fontSize: 120,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }
}

class _GameHud extends StatelessWidget {
  const _GameHud({
    required this.gameLabel,
    required this.scoreLine,
    required this.matchPhase,
  });

  final String gameLabel;
  final String scoreLine;
  final String matchPhase;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ArenaSpacing.lg,
          ArenaSpacing.lg,
          ArenaSpacing.lg,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    gameLabel,
                    style: ArenaText.h2.copyWith(
                      color: Colors.white,
                      letterSpacing: 1,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  scoreLine,
                  style: ArenaText.mono.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              matchPhase,
              style: ArenaText.small.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArenaFloatingChip extends StatelessWidget {
  const _ArenaFloatingChip({required this.elapsed});

  final Duration elapsed;

  String get _formatted {
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: ArenaColors.neonRed,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ArenaColors.neonRed.withValues(alpha: 0.55),
            blurRadius: 24,
            spreadRadius: -2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ARENA',
            style: ArenaText.badge.copyWith(
              color: ArenaColors.bone,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatted,
            style: ArenaText.mono.copyWith(
              color: ArenaColors.bone,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LongPressMenu extends StatelessWidget {
  const _LongPressMenu();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            decoration: BoxDecoration(
              color: ArenaColors.void_.withValues(alpha: 0.95),
              border: const Border(
                top: BorderSide(color: ArenaColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                  child: Text(
                    'LONG PRESS → MENU',
                    style: ArenaText.inputLabel,
                  ),
                ),
                ArenaButton(
                  label: l10n.matchOverlayContinue,
                  variant: ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(height: ArenaSpacing.xs),
                ArenaButton(
                  label: l10n.matchOverlayPauseRecording,
                  variant: ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () {},
                ),
                const SizedBox(height: ArenaSpacing.xs),
                ArenaButton(
                  label: l10n.matchOverlayStopForfeit,
                  variant: ArenaButtonVariant.danger,
                  fullWidth: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
