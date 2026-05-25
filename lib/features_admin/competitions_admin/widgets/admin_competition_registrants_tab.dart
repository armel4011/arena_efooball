import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Hash déterministe seed→couleur pour l'avatar d'un inscrit / row de
/// classement. Exposé publiquement parce que partagé avec le ranking tab.
ArenaAvatarColor registrantAvatarColor(String seed) {
  if (seed.isEmpty) return ArenaAvatarColor.blue;
  final i = seed.codeUnitAt(0) % ArenaAvatarColor.values.length;
  return ArenaAvatarColor.values[i];
}

/// Onglet INSCRITS — liste les rows `competition_registrations` du
/// `adminCompetitionRegistrantsProvider`, avec statut + role badge.
class AdminCompetitionRegistrantsTab extends ConsumerWidget {
  const AdminCompetitionRegistrantsTab({
    required this.competitionId,
    super.key,
  });
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCompetitionRegistrantsProvider(competitionId));

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
                  'Aucun inscrit pour le moment.',
                  style: ArenaText.bodyMuted,
                ),
              ],
            );
          }
          final confirmed = list.where((r) => r.status == 'confirmed').length;
          return ListView.separated(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: list.length + 1,
            separatorBuilder: (_, __) =>
                const SizedBox(height: ArenaSpacing.xs),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                  child: Text(
                    '${list.length} inscrit${list.length > 1 ? "s" : ""} · '
                    '$confirmed confirmé${confirmed > 1 ? "s" : ""}',
                    style: ArenaText.inputLabel,
                  ),
                );
              }
              return _RegistrantRow(registrant: list[i - 1]);
            },
          );
        },
      ),
    );
  }
}

class _RegistrantRow extends StatelessWidget {
  const _RegistrantRow({required this.registrant});
  final AdminCompetitionRegistrant registrant;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
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
          ArenaAvatar(
            initials: initials,
            color: registrantAvatarColor(registrant.username),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        registrant.username,
                        style: ArenaText.body,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (registrant.role == UserRole.admin ||
                        registrant.role == UserRole.superAdmin) ...[
                      const SizedBox(width: 6),
                      ArenaBadge(
                        label: registrant.role == UserRole.superAdmin
                            ? 'SUPER'
                            : 'ADMIN',
                        variant: ArenaBadgeVariant.info,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${registrant.countryCode} · ${fmt.format(registrant.registeredAt.toLocal())}',
                  style: ArenaText.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          ArenaBadge(
            label: _statusLabel(registrant.status),
            variant: _statusVariant(registrant.status),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'confirmed':
        return 'PAYÉ';
      case 'pending':
        return 'EN ATTENTE';
      case 'refunded':
        return 'REMBOURSÉ';
      case 'withdrawn':
        return 'RETRAIT';
      default:
        return s.toUpperCase();
    }
  }

  static ArenaBadgeVariant _statusVariant(String s) {
    switch (s) {
      case 'confirmed':
        return ArenaBadgeVariant.success;
      case 'pending':
        return ArenaBadgeVariant.warn;
      case 'refunded':
      case 'withdrawn':
        return ArenaBadgeVariant.danger;
      default:
        return ArenaBadgeVariant.info;
    }
  }
}
