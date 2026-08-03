import 'dart:async';

import 'package:arena/core/services/recording_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carte « Enregistrement — temps restant » : compte à rebours de la durée
/// MAXIMALE d'un enregistrement (`RecordingService.maxDuration` = 25 min),
/// déclenché au démarrage de l'enregistrement.
///
/// Synchronisée avec le compte à rebours du bouton flottant rouge : les deux
/// dérivent de la MÊME source (`startedAt` + `maxDuration`), donc affichent le
/// même MM:SS. À 00:00, l'enregistrement s'arrête AUTOMATIQUEMENT (auto-stop du
/// `RecordingService`).
///
/// Rendu vide si aucun enregistrement n'est actif (l'appelant l'affiche déjà
/// sous le bandeau « enregistrement en cours », donc hors pause).
class RecordingCountdownCard extends ConsumerStatefulWidget {
  const RecordingCountdownCard({super.key});

  @override
  ConsumerState<RecordingCountdownCard> createState() =>
      _RecordingCountdownCardState();
}

class _RecordingCountdownCardState
    extends ConsumerState<RecordingCountdownCard> {
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
    final state = ref.watch(recordingStateProvider).valueOrNull;
    if (state is! RecordingActive) return const SizedBox.shrink();

    final max = ref.read(recordingServiceProvider).maxDuration;
    final raw = max - state.elapsed();
    final remaining = raw.isNegative ? Duration.zero : raw;
    final warning = remaining <= const Duration(seconds: 30);
    final accent = warning ? ArenaColors.statusWarn : ArenaColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.lg,
        vertical: ArenaSpacing.md,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: accent, size: 18),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              'Enregistrement — temps restant',
              style: ArenaText.body.copyWith(
                color: ArenaColors.bone,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(_format(remaining),
              style: ArenaText.monoLg.copyWith(color: accent),),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
