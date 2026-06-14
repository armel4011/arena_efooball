import 'dart:async';

import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/data/repositories/payout_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Onglet ACTIONS — boutons admin : éditer, gérer le bracket, ouvrir /
/// fermer les inscriptions, annuler la compétition.
class AdminCompetitionActionsTab extends ConsumerWidget {
  const AdminCompetitionActionsTab({required this.competition, super.key});
  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La génération des versements est une action super-admin (la RPC le force
    // déjà côté serveur ; on évite juste qu'un admin simple voie un bouton
    // qui échouerait).
    final isSuperAdmin =
        ref.watch(currentProfileProvider).valueOrNull?.isSuperAdmin ?? false;
    return ListView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      children: [
        Text(
          '⚡ ACTIONS ADMIN',
          style: ArenaText.inputLabel.copyWith(color: ArenaColors.neonRed),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: '✏️ MODIFIER LA COMPÉTITION',
          variant: ArenaButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => context.push(
            AdminRoutes.competitionEditPath(competition.id),
            extra: competition,
          ),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaButton(
          label: competition.isPinned
              ? '📌 DÉSÉPINGLER (RETIRER DE LA UNE)'
              : '📌 ÉPINGLER À LA UNE',
          variant: ArenaButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => _togglePinned(context, ref),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaButton(
          label: '🏆 GÉRER LE BRACKET',
          fullWidth: true,
          onPressed: () => context.push(
            AdminRoutes.bracketPath(competition.id),
          ),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        if (competition.status == CompetitionStatus.draft ||
            competition.status == CompetitionStatus.registrationOpen)
          ArenaButton(
            label: '▶ OUVRIR LES INSCRIPTIONS',
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () =>
                _setStatus(context, ref, CompetitionStatus.registrationOpen),
          ),
        if (competition.status == CompetitionStatus.registrationOpen)
          ArenaButton(
            label: '⏸ FERMER LES INSCRIPTIONS',
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => _setStatus(
              context,
              ref,
              CompetitionStatus.registrationClosed,
            ),
          ),
        if (competition.status == CompetitionStatus.completed) ...[
          if (isSuperAdmin) ...[
            const SizedBox(height: ArenaSpacing.xs),
            ArenaButton(
              label: '💰 GÉNÉRER LES VERSEMENTS',
              fullWidth: true,
              onPressed: () => _generatePayouts(context, ref),
            ),
          ],
          const SizedBox(height: ArenaSpacing.xs),
          ArenaButton(
            label: '🔄 RÉGÉNÉRER LA COMPÉTITION',
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => _regenerate(context, ref),
          ),
        ],
        const SizedBox(height: ArenaSpacing.xs),
        ArenaButton(
          label: '🚫 ANNULER LA COMPÉTITION',
          variant: ArenaButtonVariant.danger,
          fullWidth: true,
          onPressed: () => _cancel(context, ref),
        ),
      ],
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    CompetitionStatus status,
  ) async {
    try {
      await ref.read(adminCompetitionsRepositoryProvider).update(
        competition.id,
        {'status': status.value},
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut → ${status.value}.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }

  Future<void> _togglePinned(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session admin introuvable.')),
      );
      return;
    }
    final willPin = !competition.isPinned;
    try {
      await ref.read(adminCompetitionsRepositoryProvider).setPinned(
            competitionId: competition.id,
            pinned: willPin,
            adminId: adminId,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willPin
                ? '« ${competition.name} » épinglée à la une.'
                : '« ${competition.name} » retirée de la une.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Régénérer la compétition ?', style: ArenaText.h3),
        content: Text(
          'Une nouvelle compétition est créée avec la même configuration '
          '(jeu, format, frais, récompenses…). Les inscriptions repartent '
          'à zéro et la date de début est fixée à J+7 — modifiable ensuite. '
          '« ${competition.name} » reste inchangée.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('NON'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('RÉGÉNÉRER'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final fresh = await ref
          .read(adminCompetitionsRepositoryProvider)
          .regenerate(competition.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('« ${fresh.name} » créée — inscriptions ouvertes.'),
        ),
      );
      unawaited(context.push(AdminRoutes.competitionDetailPath(fresh.id)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }

  /// Génère les lignes de versement des gains (super-admin). Idempotent côté
  /// serveur : un 2e clic ne recrée rien. Réservé au super-admin par la RPC.
  Future<void> _generatePayouts(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Générer les versements ?', style: ArenaText.h3),
        content: Text(
          'Crée une ligne de versement pour chaque gagnant selon le classement '
          'final et la répartition des prix. Les gagnants sont notifiés et '
          'pourront réclamer leur gain (numéro Mobile Money). Action sans effet '
          'si les versements ont déjà été générés.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('NON'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('GÉNÉRER'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final n = await ref
          .read(payoutRepositoryProvider)
          .generate(competition.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n == 0
                ? 'Aucun versement généré (déjà fait, ou pas de gagnant/prix).'
                : '$n versement(s) généré(s) — gagnants notifiés.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Annuler la compétition ?', style: ArenaText.h3),
        content: Text(
          "L'opération est irréversible côté joueurs. Les joueurs ayant payé "
          'leur inscription seront notifiés et remboursés manuellement '
          '(Mobile Money) par le staff.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('NON'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: ArenaColors.neonRed),
            child: const Text('OUI'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final notified = await ref
          .read(adminCompetitionsRepositoryProvider)
          .cancel(competition.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '« ${competition.name} » annulée — '
            '$notified joueur(s) payeur(s) notifié(s).',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}
