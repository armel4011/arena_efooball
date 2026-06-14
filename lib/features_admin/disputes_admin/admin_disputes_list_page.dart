import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/dispute.dart';
import 'package:arena/data/repositories/admin/admin_disputes_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Liste des litiges ouverts — point d'entrée vers l'écran de résolution
/// `AdminDisputesPage` (route `/disputes/:matchId`).
///
/// Avant cet écran, la page de résolution n'avait AUCUN point d'entrée dans
/// l'app admin mobile (seule la route paramétrée existait) : les litiges
/// — et l'affichage des preuves — étaient inaccessibles. On liste ici
/// `adminOpenDisputesProvider` (polling) ; un tap ouvre le litige du match.
class AdminDisputesListPage extends ConsumerWidget {
  const AdminDisputesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputes = ref.watch(adminOpenDisputesProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: 'LITIGES'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: disputes.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(ArenaSpacing.lg),
                child: Text(
                  arenaErrorMessage(e),
                  textAlign: TextAlign.center,
                  style: ArenaText.body.copyWith(color: ArenaColors.silver),
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun litige ouvert.',
                    style:
                        ArenaText.body.copyWith(color: ArenaColors.silver),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(ArenaSpacing.lg),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: ArenaSpacing.sm),
                itemBuilder: (context, i) => _DisputeTile(dispute: list[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DisputeTile extends StatelessWidget {
  const _DisputeTile({required this.dispute});

  final Dispute dispute;

  @override
  Widget build(BuildContext context) {
    final matchShort =
        'M-${dispute.matchId.substring(0, 6).toUpperCase()}';
    final escalated = dispute.status == 'escalated';
    return InkWell(
      onTap: () => context.push(AdminRoutes.disputePath(dispute.matchId)),
      borderRadius: BorderRadius.circular(ArenaRadius.md),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(color: ArenaColors.borderHi),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        matchShort,
                        style: ArenaText.body.copyWith(
                          color: ArenaColors.bone,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      ArenaBadge(
                        label: escalated ? 'ESCALADÉ' : 'OUVERT',
                        variant: escalated
                            ? ArenaBadgeVariant.danger
                            : ArenaBadgeVariant.warn,
                      ),
                    ],
                  ),
                  if (dispute.reason != null &&
                      dispute.reason!.isNotEmpty) ...[
                    const SizedBox(height: ArenaSpacing.xs),
                    Text(
                      dispute.reason!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ArenaText.bodyMuted
                          .copyWith(color: ArenaColors.silver),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ArenaColors.silver),
          ],
        ),
      ),
    );
  }
}
