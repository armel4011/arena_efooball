import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:flutter/material.dart';

/// Maps the match status onto the four-step v2 progress indicator.
///
/// Steps follow the v2 mockup (`docs/arena_v2.html` line 799+) :
///   1 — Code room  (HOME shares the code)
///   2 — Adversaire rejoint  (AWAY confirms in the room)
///   3 — Match en cours  (recording / score submission)
///   4 — Score validé  (terminal : completed / disputed / forfeited)
enum MatchStep {
  codeRoom(1, 'Code room'),
  opponentJoining(2, 'Adversaire rejoint'),
  matchInProgress(3, 'Match en cours'),
  result(4, 'Résultat');

  const MatchStep(this.number, this.label);

  final int number;
  final String label;

  static MatchStep fromStatus(MatchStatus s) => switch (s) {
        MatchStatus.pending || MatchStatus.scheduled => MatchStep.codeRoom,
        MatchStatus.ready => MatchStep.opponentJoining,
        MatchStatus.inProgress ||
        MatchStatus.scorePending ||
        MatchStatus.awaitingValidation =>
          MatchStep.matchInProgress,
        MatchStatus.completed ||
        MatchStatus.disputed ||
        MatchStatus.forfeited ||
        MatchStatus.cancelled =>
          MatchStep.result,
      };
}

class StepIndicator extends StatelessWidget {
  const StepIndicator({required this.step, super.key});

  final MatchStep step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final active = i + 1 <= step.number;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
            height: 4,
            decoration: BoxDecoration(
              color: active ? ArenaColors.signalBlue : ArenaColors.borderHi,
              borderRadius: BorderRadius.circular(2),
              boxShadow: active && i + 1 == step.number
                  ? [
                      BoxShadow(
                        color: ArenaColors.signalBlue.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class StepLabel extends StatelessWidget {
  const StepLabel({required this.step, super.key});

  final MatchStep step;

  /// Reproduit la maquette #13 : `ÉTAPE 01/04 · CODE ROOM` en mono small
  /// signalBlue avec letter-spacing pour donner du caractère "console".
  @override
  Widget build(BuildContext context) {
    final n = step.number.toString().padLeft(2, '0');
    return Text(
      'ÉTAPE $n/04 · ${step.label.toUpperCase()}',
      style: ArenaText.monoSmall.copyWith(
        color: ArenaColors.signalBlue,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
