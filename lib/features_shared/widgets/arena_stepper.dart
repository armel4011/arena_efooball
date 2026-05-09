import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Horizontal step indicator for multi-step flows.
///
/// Maps to `.stepper` / `.step` / `.step.active` / `.step.done` in
/// `arena_v2.html`. Each step is a flex 1 bar (4 dp tall) coloured by status
/// — active step glows in `signalBlue`, completed step is `statusOk`, todo
/// step is `carbon2`.
class ArenaStepper extends StatelessWidget {
  const ArenaStepper({
    required this.totalSteps,
    required this.currentStep,
    super.key,
  })  : assert(totalSteps >= 2, 'ARENA stepper requires at least 2 steps'),
        assert(
          currentStep >= 0 && currentStep < totalSteps,
          'currentStep must be within [0, totalSteps)',
        );

  final int totalSteps;

  /// Zero-based index of the active step. Steps before are rendered as
  /// "done", steps after as "todo".
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < totalSteps; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(child: _bar(_status(i))),
        ],
      ],
    );
  }

  _StepStatus _status(int i) {
    if (i < currentStep) return _StepStatus.done;
    if (i == currentStep) return _StepStatus.active;
    return _StepStatus.todo;
  }

  Widget _bar(_StepStatus status) {
    return AnimatedContainer(
      duration: ArenaDurations.short,
      height: 4,
      decoration: BoxDecoration(
        color: switch (status) {
          _StepStatus.todo => ArenaColors.carbon2,
          _StepStatus.active => ArenaColors.signalBlue,
          _StepStatus.done => ArenaColors.statusOk,
        },
        borderRadius: BorderRadius.circular(2),
        boxShadow: status == _StepStatus.active
            ? [
                BoxShadow(
                  color: ArenaColors.signalBlue.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}

enum _StepStatus { todo, active, done }
