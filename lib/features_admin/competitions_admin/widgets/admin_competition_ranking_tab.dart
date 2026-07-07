import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/payout_repository.dart';
import 'package:arena/features_admin/competitions_admin/widgets/admin_competition_registrants_tab.dart'
    show registrantAvatarColor;
import 'package:arena/features_shared/admin_result_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet CLASSEMENT — l'admin saisit le rang d'arrivée final de chaque
/// participant. Les rangs alimentent l'écran joueur (podium + gains
/// croisés avec `prize_distribution`). Réutilise le provider des
/// inscrits ; le tri par rang se fait côté client.
class AdminCompetitionRankingTab extends ConsumerWidget {
  const AdminCompetitionRankingTab({required this.competitionId, super.key});
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCompetitionRegistrantsProvider(competitionId));
    final isSuperAdmin =
        ref.watch(currentProfileProvider).valueOrNull?.isSuperAdmin ?? false;
    // Verrou serveur (audit 2026-07-07) : sur une compétition à prix CLÔTURÉE,
    // seul le super-admin peut modifier le classement final. On désactive la
    // saisie pour un admin simple plutôt que de le laisser échouer (42501).
    final competition =
        ref.watch(competitionByIdProvider(competitionId)).valueOrNull;
    final finalRankLocked = competition != null &&
        finalRankLockedForAdmin(
          isSuperAdmin: isSuperAdmin,
          competition: competition,
        );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
        await ref.read(
          adminCompetitionRegistrantsProvider(competitionId).future,
        );
      },
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [Text('Erreur : $e', style: ArenaText.bodyMuted)],
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              children: [
                Text(
                  'Aucun inscrit — le classement se remplira une fois '
                  'les inscriptions ouvertes.',
                  style: ArenaText.bodyMuted,
                ),
              ],
            );
          }
          final sorted = [...list]..sort((a, b) {
              final ra = a.finalRank ?? 1 << 30;
              final rb = b.finalRank ?? 1 << 30;
              if (ra != rb) return ra.compareTo(rb);
              return a.username
                  .toLowerCase()
                  .compareTo(b.username.toLowerCase());
            });
          final ranked = list.where((r) => r.finalRank != null).length;
          return ListView.separated(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: sorted.length + 1,
            separatorBuilder: (_, __) =>
                const SizedBox(height: ArenaSpacing.xs),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ArenaButton(
                        label: '⚡ CLASSEMENT AUTOMATIQUE',
                        variant: ArenaButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: () => _autoRank(context, ref),
                      ),
                      const SizedBox(height: ArenaSpacing.xs),
                      Text(
                        'Le classement final est publié automatiquement à la '
                        'fin de la compétition. Ce bouton le recalcule à la '
                        'demande (même logique) ; ajustable manuellement ensuite.',
                        style: ArenaText.small,
                      ),
                      const SizedBox(height: ArenaSpacing.sm),
                      Text(
                        '$ranked/${list.length} '
                        'classé${ranked > 1 ? "s" : ""}',
                        style: ArenaText.inputLabel,
                      ),
                      // Lien direct classement → versements : une fois le
                      // classement publié, le super-admin génère les gains sans
                      // changer d'écran (la RPC vérifie status=completed).
                      if (isSuperAdmin && ranked > 0) ...[
                        const SizedBox(height: ArenaSpacing.sm),
                        ArenaButton(
                          label: '💰 GÉNÉRER LES VERSEMENTS',
                          fullWidth: true,
                          onPressed: () => _generatePayouts(context, ref),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return _RankingRow(
                competitionId: competitionId,
                registrant: sorted[i - 1],
                participantCount: list.length,
                locked: finalRankLocked,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _autoRank(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Calculer le classement ?', style: ArenaText.h3),
        content: Text(
          'Les rangs seront recalculés côté serveur — le même classement que '
          'celui publié automatiquement à la clôture de la compétition. Cela '
          'écrase les rangs déjà saisis manuellement.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('CALCULER'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .autoRankFromResults(competitionId);
      ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Classement calculé automatiquement.')),
      );
      // Enchaîne sur les versements (super-admin) : le classement venant d'être
      // publié, on propose de générer les gains dans la foulée.
      final isSuper =
          ref.read(currentProfileProvider).valueOrNull?.isSuperAdmin ?? false;
      if (isSuper && context.mounted) {
        final gen = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: ArenaColors.carbon,
            title: Text('Générer les versements ?', style: ArenaText.h3),
            content: Text(
              'Le classement est publié. Tu peux générer les versements des '
              'gagnants maintenant (uniquement si la compétition est terminée).',
              style: ArenaText.bodyMuted,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('PLUS TARD'),
              ),
              TextButton(
                onPressed: () => Navigator.of(c).pop(true),
                child: const Text('GÉNÉRER'),
              ),
            ],
          ),
        );
        if ((gen ?? false) && context.mounted) {
          await _generatePayouts(context, ref);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }

  /// Génère les versements de la compétition (super-admin). La RPC est
  /// idempotente et vérifie que la compétition est terminée + le classement
  /// publié (sinon erreur explicite).
  Future<void> _generatePayouts(BuildContext context, WidgetRef ref) async {
    try {
      final n = await ref.read(payoutRepositoryProvider).generate(competitionId);
      ref
        ..invalidate(competitionsPendingPayoutProvider)
        ..invalidate(pendingPayoutsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n == 0
                ? 'Versements déjà générés (ou aucun gagnant/prix).'
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
}

class _RankingRow extends ConsumerWidget {
  const _RankingRow({
    required this.competitionId,
    required this.registrant,
    required this.participantCount,
    this.locked = false,
  });

  final String competitionId;
  final AdminCompetitionRegistrant registrant;
  final int participantCount;

  /// Saisie du rang désactivée (compétition à prix clôturée, admin simple).
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = registrant.finalRank;
    final initials = registrant.username.isNotEmpty
        ? registrant.username.substring(0, 1).toUpperCase()
        : '?';
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              rank == null ? '—' : prizeRankEmoji(rank - 1),
              style: ArenaText.body,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: ArenaSpacing.xs),
          ArenaAvatar(
            initials: initials,
            color: registrantAvatarColor(registrant.username),
            size: ArenaAvatarSize.sm,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              registrant.username,
              style: ArenaText.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          if (locked)
            const Tooltip(
              message: superAdminOnlyHint,
              child: Icon(Icons.lock_outline, color: ArenaColors.silver),
            )
          else
            DropdownButton<int?>(
              value: rank,
              hint: Text('Rang', style: ArenaText.bodyMuted),
              dropdownColor: ArenaColors.carbon,
              underline: const SizedBox.shrink(),
              style: ArenaText.body,
              items: [
                DropdownMenuItem<int?>(
                  child: Text('—', style: ArenaText.bodyMuted),
                ),
                for (var n = 1; n <= participantCount; n++)
                  DropdownMenuItem<int?>(
                    value: n,
                    child: Text('Rang $n', style: ArenaText.body),
                  ),
              ],
              onChanged: (value) => _setRank(context, ref, value),
            ),
        ],
      ),
    );
  }

  Future<void> _setRank(
    BuildContext context,
    WidgetRef ref,
    int? rank,
  ) async {
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .setFinalRank(competitionId, registrant.playerId, rank);
      ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rank == null
                ? 'Rang effacé pour ${registrant.username}.'
                : '${registrant.username} → rang $rank.',
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
