import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
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
        _InfoRow(label: 'Format', value: _formatLabel(competition.format)),
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
        if (competition.description != null) ...[
          const SizedBox(height: ArenaSpacing.md),
          Text('Description', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.xs),
          Text(competition.description!, style: ArenaText.body),
        ],
      ],
    );
  }

  static String _formatLabel(TournamentFormat f) {
    switch (f) {
      case TournamentFormat.singleElimination:
        return 'Élimination directe';
      case TournamentFormat.groupsThenKnockout:
        return 'Poules + KO';
      case TournamentFormat.roundRobin:
        return 'Round robin';
    }
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
