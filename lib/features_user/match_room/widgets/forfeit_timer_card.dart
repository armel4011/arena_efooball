import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Carte affichant un compte-à-rebours warning vers le forfait auto.
/// La fenêtre est de 10 minutes à partir de `scheduledAt`. Refresh
/// chaque seconde tant que le widget est monté.
class ForfeitTimerCard extends StatefulWidget {
  const ForfeitTimerCard({required this.scheduledAt, super.key});

  final DateTime scheduledAt;

  @override
  State<ForfeitTimerCard> createState() => _ForfeitTimerCardState();
}

class _ForfeitTimerCardState extends State<ForfeitTimerCard> {
  static const _forfeitWindow = Duration(minutes: 10);
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.scheduledAt.add(_forfeitWindow);
    final remaining = deadline.difference(DateTime.now());
    final mmss = _format(remaining);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.lg,
        vertical: ArenaSpacing.md,
      ),
      decoration: arenaWarningCardDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            color: ArenaColors.statusWarn,
            size: 18,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              'Timer forfait auto',
              style: ArenaText.body.copyWith(
                color: ArenaColors.bone,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            mmss,
            style: ArenaText.monoLg.copyWith(color: ArenaColors.statusWarn),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    if (d.isNegative) return '00:00';
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
