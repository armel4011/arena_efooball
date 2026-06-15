import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_admin/competitions_admin/widgets/competition_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Étape 5 du wizard — récapitulatif avant soumission.
///
/// Présentation pure : toutes les valeurs (y compris cagnotte / commission /
/// quota parrainage déjà calculées) sont fournies par le State du wizard.
class WizardStepReview extends StatelessWidget {
  const WizardStepReview({
    required this.name,
    required this.gameLabel,
    required this.format,
    required this.maxPlayers,
    required this.startDate,
    required this.fee,
    required this.currency,
    required this.pool,
    required this.commissionXaf,
    required this.autoGenerateBracket,
    required this.matchIntervalMinutes,
    required this.thirdPlaceMatch,
    required this.referralQuota,
    required this.isEditing,
    required this.publishNow,
    required this.submitting,
    required this.onPublishChanged,
    super.key,
  });

  final String name;
  final String gameLabel;
  final TournamentFormat format;
  final int maxPlayers;
  final DateTime? startDate;
  final double fee;
  final String currency;
  final double pool;
  final double commissionXaf;
  final bool autoGenerateBracket;
  final int matchIntervalMinutes;
  final bool thirdPlaceMatch;
  final int referralQuota;
  final bool isEditing;
  final bool publishNow;
  final bool submitting;
  final ValueChanged<bool> onPublishChanged;

  static String _matchIntervalLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    if (minutes < 1440) {
      final h = minutes ~/ 60;
      return '${h}h';
    }
    final d = minutes ~/ 1440;
    return d == 1 ? '1 jour' : '$d jours';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Récap', style: ArenaText.h3),
        const SizedBox(height: ArenaSpacing.md),
        ReviewRow(label: 'Nom', value: name),
        ReviewRow(label: 'Jeu', value: gameLabel),
        ReviewRow(label: 'Format', value: formatLabel(format)),
        ReviewRow(label: 'Joueurs', value: '$maxPlayers max'),
        ReviewRow(
          label: 'Date',
          value: startDate == null
              ? '—'
              : DateFormat('dd/MM/yyyy HH:mm').format(startDate!),
        ),
        ReviewRow(
          label: 'Inscription',
          value: fee == 0 ? 'Gratuit' : '${fmt.format(fee.round())} $currency',
        ),
        ReviewRow(
          label: 'Cagnotte (somme des récompenses)',
          value: '${fmt.format(pool.round())} $currency',
        ),
        ReviewRow(
          label: 'Commission ARENA',
          value: '${fmt.format(commissionXaf.round())} $currency',
        ),
        ReviewRow(
          label: 'Bracket auto',
          value:
              autoGenerateBracket ? 'Oui — au quota atteint' : 'Non — manuel',
        ),
        ReviewRow(
          label: 'Intervalle entre rounds',
          value: _matchIntervalLabel(matchIntervalMinutes),
        ),
        if (format != TournamentFormat.roundRobin)
          ReviewRow(
            label: 'Match de classement (3e place)',
            value: thirdPlaceMatch ? 'Oui' : 'Non',
          ),
        if (referralQuota > 0)
          ReviewRow(
            label: 'Parrainages requis',
            value: '$referralQuota ami(s) via code ARN-XXXX',
          ),
        const SizedBox(height: ArenaSpacing.lg),
        if (!isEditing)
          PublishToggleCard(
            publishNow: publishNow,
            onChanged: onPublishChanged,
          ),
        const SizedBox(height: ArenaSpacing.md),
        if (submitting) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
