import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_admin/competitions_admin/widgets/competition_form_widgets.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Étape 2 du wizard — format / capacité / auto-management / intervalles.
class WizardStepFormat extends StatelessWidget {
  const WizardStepFormat({
    required this.format,
    required this.maxPlayers,
    required this.autoGenerateBracket,
    required this.matchIntervalMinutes,
    required this.roundIntervalsCtrl,
    required this.groupCountCtrl,
    required this.qualifiersPerGroupCtrl,
    required this.isEditing,
    required this.onFormatChanged,
    required this.onMaxPlayersChanged,
    required this.onAutoGenerateChanged,
    required this.onMatchIntervalChanged,
    required this.onChanged,
    super.key,
  });

  final TournamentFormat format;
  final int maxPlayers;
  final bool autoGenerateBracket;
  final int matchIntervalMinutes;
  final TextEditingController roundIntervalsCtrl;
  final TextEditingController groupCountCtrl;
  final TextEditingController qualifiersPerGroupCtrl;
  final bool isEditing;
  final ValueChanged<TournamentFormat> onFormatChanged;
  final ValueChanged<int> onMaxPlayersChanged;
  final ValueChanged<bool> onAutoGenerateChanged;
  final ValueChanged<int> onMatchIntervalChanged;
  final VoidCallback onChanged;

  Widget _lockable(Widget child) {
    if (!isEditing) return child;
    return IgnorePointer(
      child: Opacity(opacity: 0.45, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isEditing) ...[
          Container(
            padding: const EdgeInsets.all(ArenaSpacing.md),
            decoration: BoxDecoration(
              color: ArenaColors.signalBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              border: Border.all(
                color: ArenaColors.signalBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'ℹ Format et capacité ne sont pas modifiables après '
              'création — ils conditionnent le bracket déjà calculé.',
              style: ArenaText.body,
            ),
          ),
          const SizedBox(height: ArenaSpacing.md),
        ],
        Text('Format du tournoi', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        _lockable(FormatPicker(current: format, onChanged: onFormatChanged)),
        const SizedBox(height: ArenaSpacing.md),
        Text('Nombre de joueurs max', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        _lockable(
          MaxPlayersPicker(
            current: maxPlayers,
            onChanged: onMaxPlayersChanged,
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        Text('Gestion automatique', style: ArenaText.h3),
        const SizedBox(height: ArenaSpacing.xs),
        Text(
          'Le bracket est généré + le scheduling des rounds se fait sans '
          'intervention quand toutes les places sont prises.',
          style: ArenaText.small,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ArenaSpacing.md,
            vertical: ArenaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            borderRadius: BorderRadius.circular(ArenaRadius.md),
            border: Border.all(color: ArenaColors.border),
          ),
          child: SwitchListTile.adaptive(
            value: autoGenerateBracket,
            onChanged: onAutoGenerateChanged,
            title: Text('Bracket auto', style: ArenaText.body),
            subtitle: Text(
              'Génère le bracket dès que les inscriptions atteignent le quota.',
              style: ArenaText.small,
            ),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: ArenaColors.signalBlue,
          ),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Intervalle entre rounds (défaut)', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        MatchIntervalPicker(
          current: matchIntervalMinutes,
          onChanged: onMatchIntervalChanged,
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          'Intervalles personnalisés par round',
          style: ArenaText.inputLabel,
        ),
        const SizedBox(height: ArenaSpacing.xs),
        Text(
          'Liste de minutes séparées par virgules (1 par round). Ex. : '
          '30,60,120,1440 = round1 → 30min, round2 → 1h, etc. Laisser vide '
          "pour utiliser l'intervalle par défaut.",
          style: ArenaText.small,
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: roundIntervalsCtrl,
          hint: 'Ex. 30,60,120,1440 (vide = défaut)',
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9, ]')),
          ],
          onChanged: (_) => onChanged(),
        ),
        if (format == TournamentFormat.groupsThenKnockout) ...[
          const SizedBox(height: ArenaSpacing.lg),
          Text('Config groupes', style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            'Nombre de groupes + qualifiés par groupe pour la phase '
            'knockout qui suit.',
            style: ArenaText.small,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Groupes', style: ArenaText.inputLabel),
                    const SizedBox(height: 4),
                    ArenaTextField(
                      controller: groupCountCtrl,
                      hint: '4',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => onChanged(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qualifiés / groupe', style: ArenaText.inputLabel),
                    const SizedBox(height: 4),
                    ArenaTextField(
                      controller: qualifiersPerGroupCtrl,
                      hint: '2',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => onChanged(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
