import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Dialogue BLOQUANT de réglages du match, affiché au clic sur « Continuer »
/// après la saisie du nom d'équipe. Rappelle au joueur de RÉGLER, dans son jeu
/// (eFootball / Mobile FC / Dream League), les **prolongations** et les **tirs
/// au but** selon la nature du match :
///   * match KO (élimination) → il faut un vainqueur → **ACTIVER** ;
///   * match de classement (poule) → le nul est autorisé → **DÉSACTIVER**.
///
/// Le joueur doit cocher « J'ai compris » pour débloquer « OK ». Retourne `true`
/// si confirmé, `false` sinon.
Future<bool> showMatchRulesDialog(
  BuildContext context, {
  required bool isKo,
  required String gameLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MatchRulesDialog(isKo: isKo, gameLabel: gameLabel),
  );
  return result ?? false;
}

class _MatchRulesDialog extends StatefulWidget {
  const _MatchRulesDialog({required this.isKo, required this.gameLabel});

  final bool isKo;
  final String gameLabel;

  @override
  State<_MatchRulesDialog> createState() => _MatchRulesDialogState();
}

class _MatchRulesDialogState extends State<_MatchRulesDialog> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final isKo = widget.isKo;
    final action = isKo ? 'ACTIVER' : 'DÉSACTIVER';
    final actionColor = isKo ? ArenaColors.statusOk : ArenaColors.statusWarn;
    final reason = isKo
        ? 'Ce match est à élimination directe : il faut un vainqueur.'
        : 'Ce match compte pour le classement : le match nul est autorisé.';

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: ArenaColors.bone,
        title: Text(
          'Prolongations & tirs au but',
          style: ArenaText.h3.copyWith(color: ArenaColors.carbon),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                reason,
                style: ArenaText.body.copyWith(color: ArenaColors.carbon),
              ),
              const SizedBox(height: ArenaSpacing.md),
              // Bandeau d'action (à activer / à désactiver).
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.md,
                  vertical: ArenaSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(ArenaRadius.md),
                  border: Border.all(color: actionColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isKo ? Icons.check_circle_outline : Icons.block,
                      color: actionColor,
                      size: 20,
                    ),
                    const SizedBox(width: ArenaSpacing.sm),
                    Expanded(
                      child: Text(
                        'Dans ${widget.gameLabel}, $action les '
                        'prolongations et les tirs au but.',
                        style: ArenaText.body.copyWith(
                          color: ArenaColors.carbon,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ArenaSpacing.md),
              // Case obligatoire pour débloquer OK.
              InkWell(
                onTap: () => setState(() => _confirmed = !_confirmed),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _confirmed,
                      activeColor: ArenaColors.signalBlue,
                      checkColor: ArenaColors.bone,
                      side: const BorderSide(
                        color: ArenaColors.silverDim,
                        width: 2,
                      ),
                      onChanged: (v) =>
                          setState(() => _confirmed = v ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: ArenaSpacing.sm),
                        child: Text(
                          "J'ai compris et réglé mon jeu en conséquence.",
                          style: ArenaText.body
                              .copyWith(color: ArenaColors.carbon),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _confirmed ? () => Navigator.of(context).pop(true) : null,
            child: Text(
              'OK',
              style: ArenaText.body.copyWith(
                color: _confirmed
                    ? ArenaColors.signalBlue
                    : ArenaColors.silverDim,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
