import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/features_shared/admin/competition_labels.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Onglet INFOS — récapitulatif lecture-seule de la compétition pour
/// l'admin (jeu, format, capacité, dates, tarif, commission, description).
class AdminCompetitionInfosTab extends StatelessWidget {
  const AdminCompetitionInfosTab({required this.competition, super.key});
  final Competition competition;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      children: [
        _InfoRow(label: 'Jeu', value: competition.game.label),
        _InfoRow(label: 'Format', value: competitionFormatLabel(competition.format)),
        _InfoRow(
          label: 'Joueurs',
          value: '${competition.currentPlayers}/${competition.maxPlayers}',
        ),
        _InfoRow(
          label: 'Début',
          value: DateFormat('dd/MM/yyyy HH:mm').format(competition.startDate),
        ),
        if (competition.registrationFee > 0)
          _InfoRow(
            label: 'Inscription',
            value: '${competition.registrationFee} '
                '${competition.registrationCurrency}',
          ),
        _InfoRow(
          label: 'Commission',
          value: '${competition.commissionPct.round()}%',
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Gestion auto', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        _InfoRow(
          label: 'Bracket auto',
          value: competition.autoGenerateBracket
              ? 'Activé — bracket généré au quota atteint'
              : 'Désactivé — bracket manuel',
        ),
        _InfoRow(
          label: 'Intervalle rounds',
          value: _intervalLabel(competition.matchIntervalMinutes),
        ),
        _InfoRow(
          label: 'Inscriptions restantes',
          value: competition.spotsLeft == 0
              ? '✓ quota atteint'
              : '${competition.spotsLeft} places à pourvoir',
        ),
        _InfoRow(
          label: 'À la une',
          value: competition.isPinned ? '📌 Épinglée' : 'Non épinglée',
        ),
        if (competition.description != null) ...[
          const SizedBox(height: ArenaSpacing.md),
          Text('Description', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.xs),
          Text(competition.description!, style: ArenaText.body),
        ],
      ],
    );
  }

  // _formatLabel → competitionFormatLabel (features_shared/admin/competition_labels.dart)

  static String _intervalLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    if (minutes < 1440) return '${minutes ~/ 60} h';
    final d = minutes ~/ 1440;
    return d == 1 ? '1 jour' : '$d jours';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
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
