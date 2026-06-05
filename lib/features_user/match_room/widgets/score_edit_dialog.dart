import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Numeric 2-digit score input field used by the score-flow forms and the
/// "edit my score" dispute dialog.
class ScoreField extends StatelessWidget {
  const ScoreField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.action,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputAction action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ArenaText.inputLabel),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: action,
          maxLength: 2,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: ArenaText.h2,
          decoration: const InputDecoration(
            hintText: '0',
            counterText: '',
            filled: true,
            fillColor: ArenaColors.carbon,
          ),
        ),
      ],
    );
  }
}

/// Result returned by [EditScoreDialog] when the player confirms a new
/// score during a dispute.
class EditedScore {
  const EditedScore({
    required this.my,
    required this.opp,
    required this.viaPenalties,
    this.myPen,
    this.oppPen,
  });
  final int my;
  final int opp;
  final bool viaPenalties;
  final int? myPen;
  final int? oppPen;
}

/// Modal dialog letting the disputing player re-submit their score
/// (and optionally penalty shootout for knockout matches).
class EditScoreDialog extends StatefulWidget {
  const EditScoreDialog({
    required this.myInitial,
    required this.oppInitial,
    required this.viaPenaltiesInitial,
    required this.myPenInitial,
    required this.oppPenInitial,
    required this.knockout,
    super.key,
  });

  final String myInitial;
  final String oppInitial;
  final bool viaPenaltiesInitial;
  final String myPenInitial;
  final String oppPenInitial;
  final bool knockout;

  @override
  State<EditScoreDialog> createState() => _EditScoreDialogState();
}

class _EditScoreDialogState extends State<EditScoreDialog> {
  late final _myCtrl = TextEditingController(text: widget.myInitial);
  late final _oppCtrl = TextEditingController(text: widget.oppInitial);
  late final _myPenCtrl = TextEditingController(text: widget.myPenInitial);
  late final _oppPenCtrl = TextEditingController(text: widget.oppPenInitial);
  late bool _viaPen = widget.viaPenaltiesInitial;
  String? _error;

  @override
  void dispose() {
    _myCtrl.dispose();
    _oppCtrl.dispose();
    _myPenCtrl.dispose();
    _oppPenCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final my = int.tryParse(_myCtrl.text.trim());
    final opp = int.tryParse(_oppCtrl.text.trim());
    if (my == null || opp == null || my < 0 || my > 99 || opp < 0 || opp > 99) {
      setState(() => _error = l10n.scoreEditErrorRange);
      return;
    }
    int? myPen;
    int? oppPen;
    if (_viaPen) {
      if (my != opp) {
        setState(
          () => _error = l10n.scoreEditErrorTieBeforePens,
        );
        return;
      }
      myPen = int.tryParse(_myPenCtrl.text.trim());
      oppPen = int.tryParse(_oppPenCtrl.text.trim());
      if (myPen == null ||
          oppPen == null ||
          myPen < 0 ||
          oppPen < 0 ||
          myPen > 30 ||
          oppPen > 30) {
        setState(() => _error = l10n.scoreEditErrorPensRange);
        return;
      }
      if (myPen == oppPen) {
        setState(
          () => _error = l10n.scoreEditErrorPensTie,
        );
        return;
      }
    }
    Navigator.of(context).pop(
      EditedScore(
        my: my,
        opp: opp,
        viaPenalties: _viaPen,
        myPen: myPen,
        oppPen: oppPen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: ArenaColors.surface,
      title: Text(l10n.scoreEditDialogTitle, style: ArenaText.h2),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ScoreField(
                  label: l10n.scoreEditMyScoreLabel,
                  controller: _myCtrl,
                  enabled: true,
                  action: TextInputAction.next,
                ),
              ),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: ScoreField(
                  label: l10n.scoreEditOpponentLabel,
                  controller: _oppCtrl,
                  enabled: true,
                  action: widget.knockout
                      ? TextInputAction.next
                      : TextInputAction.done,
                ),
              ),
            ],
          ),
          if (widget.knockout) ...[
            const SizedBox(height: ArenaSpacing.sm),
            SwitchListTile.adaptive(
              title: Text(l10n.scoreEditViaPenaltiesLabel, style: ArenaText.body),
              value: _viaPen,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _viaPen = v),
            ),
            if (_viaPen)
              Row(
                children: [
                  Expanded(
                    child: ScoreField(
                      label: l10n.scoreEditMyPenLabel,
                      controller: _myPenCtrl,
                      enabled: true,
                      action: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: ArenaSpacing.md),
                  Expanded(
                    child: ScoreField(
                      label: l10n.scoreEditOppPenLabel,
                      controller: _oppPenCtrl,
                      enabled: true,
                      action: TextInputAction.done,
                    ),
                  ),
                ],
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              _error!,
              style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.scoreEditCancelButton),
        ),
        ArenaButton(
          label: l10n.scoreEditResendButton,
          icon: Icons.send_outlined,
          onPressed: _submit,
        ),
      ],
    );
  }
}
