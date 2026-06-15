import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Widgets utilitaires du wizard de création de compétition (PHASE 11.A8).
/// Sortis du fichier `create_competition_page.dart` pour le faire passer
/// sous 1000 lignes — chacun ici est une présentation pure (input + onChange)
/// qui ne touche pas au state du wizard.

/// Blocs de récompenses au-delà du top 4 : (libellé, taille, dernier rang).
/// Le bloc d'index `i` est actif dès que le nombre de récompensés atteint son
/// `lastRank`. La valeur saisie pour un bloc est le % attribué à *chaque* place
/// du bloc. Partagé par [BlockShareRow], `WizardStepPrizes` et le State du
/// wizard (calcul cagnotte / redistribution).
const List<({String label, int size, int lastRank})> prizeBlocks = [
  (label: '5ème – 8ème', size: 4, lastRank: 8),
  (label: '9ème – 16ème', size: 8, lastRank: 16),
  (label: '17ème – 32ème', size: 16, lastRank: 32),
  (label: '33ème – 64ème', size: 32, lastRank: 64),
  (label: '65ème – 128ème', size: 64, lastRank: 128),
];

/// Libellé public du format de tournoi. Utilisé à la fois par
/// [FormatPicker] et par le rendu Review du wizard.
String formatLabel(TournamentFormat f) {
  switch (f) {
    case TournamentFormat.singleElimination:
      return 'Élimination directe';
    case TournamentFormat.groupsThenKnockout:
      return 'Poules puis KO';
    case TournamentFormat.roundRobin:
      return 'Round robin';
  }
}

class GamePicker extends StatelessWidget {
  const GamePicker({required this.current, required this.onChanged, super.key});
  final GameType current;
  final ValueChanged<GameType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.xs,
      runSpacing: ArenaSpacing.xs,
      children: [
        for (final g in GameType.values)
          _OptionChip(
            label: g.label,
            active: g == current,
            onTap: () => onChanged(g),
          ),
      ],
    );
  }
}

class FormatPicker extends StatelessWidget {
  const FormatPicker({
    required this.current,
    required this.onChanged,
    super.key,
  });
  final TournamentFormat current;
  final ValueChanged<TournamentFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in TournamentFormat.values)
          Padding(
            padding: const EdgeInsets.only(bottom: ArenaSpacing.xs),
            child: ArenaButton(
              label: formatLabel(f).toUpperCase(),
              variant: f == current
                  ? ArenaButtonVariant.primary
                  : ArenaButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => onChanged(f),
            ),
          ),
      ],
    );
  }
}

class MaxPlayersPicker extends StatelessWidget {
  const MaxPlayersPicker({
    required this.current,
    required this.onChanged,
    super.key,
  });
  final int current;
  final ValueChanged<int> onChanged;

  static const _options = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.xs,
      runSpacing: ArenaSpacing.xs,
      children: [
        for (final n in _options)
          _OptionChip(
            label: '$n',
            active: n == current,
            onTap: () => onChanged(n),
          ),
      ],
    );
  }
}

class RewardedCountPicker extends StatelessWidget {
  const RewardedCountPicker({
    required this.current,
    required this.onChanged,
    super.key,
  });
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.xs,
      runSpacing: ArenaSpacing.xs,
      children: [
        for (final n in kRewardedRankOptions)
          _OptionChip(
            label: '$n',
            active: n == current,
            onTap: () => onChanged(n),
          ),
      ],
    );
  }
}

class CurrencyPicker extends StatelessWidget {
  const CurrencyPicker({
    required this.current,
    required this.onChanged,
    super.key,
  });
  final String current;
  final ValueChanged<String> onChanged;

  // V1.0 : paiement d'inscription disponible UNIQUEMENT au Cameroun (XAF).
  // XOF / USD (autres pays) reviendront dans une version ultérieure.
  static const _options = ['XAF'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: current,
      decoration: InputDecoration(
        filled: true,
        fillColor: ArenaColors.carbon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.border),
        ),
      ),
      dropdownColor: ArenaColors.carbon,
      style: ArenaText.body,
      items: [
        for (final c in _options)
          DropdownMenuItem(value: c, child: Text(c, style: ArenaText.body)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: active ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class ShareRow extends StatelessWidget {
  const ShareRow({
    required this.position,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final int position;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${prizeRankEmoji(position)} ${prizeRankLabel(position)} place',
          style: ArenaText.inputLabel,
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: controller,
          hint: 'Montant',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9]')),
            LengthLimitingTextInputFormatter(9),
          ],
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

/// Ligne de configuration d'un bloc de places (5-8, 9-16, …) : une
/// seule saisie = le montant attribué à *chaque* place du bloc.
class BlockShareRow extends StatelessWidget {
  const BlockShareRow({
    required this.block,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final ({String label, int size, int lastRank}) block;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🏅 ${block.label} place', style: ArenaText.inputLabel),
        const SizedBox(height: 2),
        Text(
          'Montant attribué à chacune des ${block.size} places du bloc',
          style: ArenaText.small,
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: controller,
          hint: 'Montant par place',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9]')),
            LengthLimitingTextInputFormatter(9),
          ],
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class ShareTotalCard extends StatelessWidget {
  const ShareTotalCard({
    required this.total,
    required this.currency,
    super.key,
  });
  final int total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: arenaSuccessCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '🏆 Cagnotte totale',
              style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${fmt.format(total)} $currency',
            style: ArenaText.mono.copyWith(
              color: ArenaColors.statusOk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewRow extends StatelessWidget {
  const ReviewRow({required this.label, required this.value, super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ArenaText.bodyMuted)),
          Text(value, style: ArenaText.body),
        ],
      ),
    );
  }
}

class PublishToggleCard extends StatelessWidget {
  const PublishToggleCard({
    required this.publishNow,
    required this.onChanged,
    super.key,
  });

  final bool publishNow;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = publishNow ? ArenaColors.statusOk : ArenaColors.signalBlue;
    return InkWell(
      onTap: () => onChanged(!publishNow),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: accent.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publishNow
                        ? '🚀 Publier maintenant'
                        : '💾 Sauver en brouillon',
                    style: ArenaText.h3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    publishNow
                        ? "Les inscriptions s'ouvrent immédiatement — "
                            'la compét. apparaît côté joueur avec le bouton '
                            "S'INSCRIRE."
                        : 'La compét. reste en brouillon — invisible côté '
                            'joueur. À publier plus tard depuis le détail '
                            'admin.',
                    style: ArenaText.small,
                  ),
                ],
              ),
            ),
            const SizedBox(width: ArenaSpacing.md),
            Switch.adaptive(
              value: publishNow,
              onChanged: onChanged,
              activeThumbColor: ArenaColors.statusOk,
            ),
          ],
        ),
      ),
    );
  }
}

/// Picker d'intervalle entre rounds (Lot A — auto-management). Valeurs
/// en minutes : 30 / 60 / 120 / 240 / 1440. Stocké tel quel dans la
/// colonne `competitions.match_interval_minutes`.
class MatchIntervalPicker extends StatelessWidget {
  const MatchIntervalPicker({
    required this.current,
    required this.onChanged,
    super.key,
  });

  final int current;
  final ValueChanged<int> onChanged;

  static const _options = <({int minutes, String label})>[
    (minutes: 30, label: '30 min'),
    (minutes: 60, label: '1 h'),
    (minutes: 120, label: '2 h'),
    (minutes: 240, label: '4 h'),
    (minutes: 1440, label: '1 jour'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.xs,
      runSpacing: ArenaSpacing.xs,
      children: [
        for (final opt in _options)
          IntervalChip(
            label: opt.label,
            active: opt.minutes == current,
            onTap: () => onChanged(opt.minutes),
          ),
      ],
    );
  }
}

/// Lot D.2 — Chip radio "Tout filleul" / "Filleul engagé".
class ModeChip extends StatelessWidget {
  const ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: active ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class IntervalChip extends StatelessWidget {
  const IntervalChip({
    required this.label,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: active ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
