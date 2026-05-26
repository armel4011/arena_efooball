import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_users_repository.dart';
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_filter_menu.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// PHASE 11 · SA3 — super-admin user management.
///
/// Lot C : tous les filtres scattered (status, pays, activité, coupable,
/// compétition) sont consolidés dans un seul `ArenaFilterMenu` déroulant
/// + une SearchField. Le filtre par compétition (item 2) liste les
/// compétitions actives via `filterableCompetitionsProvider`.
class SuperAdminUsers extends ConsumerStatefulWidget {
  const SuperAdminUsers({super.key});

  @override
  ConsumerState<SuperAdminUsers> createState() => _SuperAdminUsersState();
}

class _SuperAdminUsersState extends ConsumerState<SuperAdminUsers> {
  final _searchCtrl = TextEditingController();
  AdminUsersFilter _filter = const AdminUsersFilter();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider(_filter));
    final compsAsync = ref.watch(filterableCompetitionsProvider);

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'UTILISATEURS',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.mark_email_unread_outlined,
              color: ArenaColors.bone,
            ),
            tooltip: 'Arena Requête',
            onPressed: () => context.go(AdminRoutes.superReintegration),
          ),
          IconButton(
            icon: const Icon(
              Icons.campaign_outlined,
              color: ArenaColors.bone,
            ),
            tooltip: 'Notif broadcast',
            onPressed: () => context.go(AdminRoutes.superBroadcast),
          ),
        ],
      ),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              ArenaTextField(
                controller: _searchCtrl,
                hint: '🔍 Rechercher username, email…',
                onChanged: (v) => setState(() {
                  final q = v.trim();
                  _filter = _filter.copyWith(
                    searchQuery: q.isEmpty ? null : q,
                    resetSearch: q.isEmpty,
                  );
                }),
              ),
              const SizedBox(height: ArenaSpacing.md),
              // ─── Filter menu déroulant (item 1 + 2) ────────────────
              Row(
                children: [
                  compsAsync.when(
                    data: (comps) => ArenaFilterMenu(
                      activeCount: _activeFilterCount(),
                      sections: _buildSections(comps),
                      initialSelection: _selectionFromFilter(),
                      onApply: _applySelection,
                    ),
                    loading: () => const _LoadingFilterButton(),
                    error: (_, __) => ArenaFilterMenu(
                      activeCount: _activeFilterCount(),
                      sections: _buildSections(const []),
                      initialSelection: _selectionFromFilter(),
                      onApply: _applySelection,
                    ),
                  ),
                  const Spacer(),
                  if (_filter.hasAdvancedFilter ||
                      _filter.countryCode != null ||
                      _filter.filter != null)
                    TextButton(
                      onPressed: _resetAll,
                      child: Text(
                        'Réinitialiser',
                        style: ArenaText.small.copyWith(
                          color: ArenaColors.signalBlue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ArenaSpacing.sm),
              // Badges compétitions actives (item 2/C.2 — multi)
              if (_filter.competitionIds.isNotEmpty)
                _ActiveCompetitionsBadges(
                  competitionIds: _filter.competitionIds,
                  comps: compsAsync.asData?.value ?? const [],
                  onClearOne: (id) => setState(() {
                    final remaining =
                        _filter.competitionIds.where((c) => c != id).toList();
                    _filter = _filter.copyWith(
                      competitionIds: remaining,
                      resetCompetitionIds: remaining.isEmpty,
                    );
                  }),
                ),
              const SizedBox(height: ArenaSpacing.md),
              users.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erreur : $e', style: ArenaText.bodyMuted),
                data: (list) => list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(ArenaSpacing.md),
                        child: Text(
                          'Aucun utilisateur pour ces filtres.',
                          style: ArenaText.bodyMuted,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        children: [
                          for (final u in list) ...[
                            _UserCard(profile: u),
                            const SizedBox(height: ArenaSpacing.sm),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Filter helpers (mapping AdminUsersFilter ↔ ArenaFilterMenu) ───

  /// Build the filter sections — status, pays, activité, coupable,
  /// compétition. La liste compétitions est dynamique (passée en param).
  List<ArenaFilterSection> _buildSections(
    List<FilterableCompetition> comps,
  ) {
    return [
      const ArenaFilterSection(
        id: 'status',
        title: 'Statut',
        mode: ArenaFilterMode.radio,
        options: [
          ArenaFilterOption(id: 'active', label: 'Actifs'),
          ArenaFilterOption(id: 'banned', label: 'Bannis'),
          ArenaFilterOption(id: 'kyc_pending', label: 'KYC pending'),
        ],
      ),
      const ArenaFilterSection(
        id: 'country',
        title: 'Pays',
        mode: ArenaFilterMode.radio,
        options: [
          ArenaFilterOption(id: 'CM', label: '🇨🇲 Cameroun'),
          ArenaFilterOption(id: 'SN', label: '🇸🇳 Sénégal'),
          ArenaFilterOption(id: 'CI', label: "🇨🇮 Côte d'Ivoire"),
          ArenaFilterOption(id: 'BF', label: '🇧🇫 Burkina Faso'),
        ],
      ),
      const ArenaFilterSection(
        id: 'activity',
        title: 'Activité',
        options: [
          ArenaFilterOption(id: 'won', label: '🏆 A gagné'),
          ArenaFilterOption(id: 'paid', label: '💳 A payé'),
          ArenaFilterOption(id: 'rewarded', label: '💰 A reçu un gain'),
          ArenaFilterOption(id: 'disputed', label: '⚖ Litige'),
        ],
      ),
      const ArenaFilterSection(
        id: 'guilty',
        title: '3-strikes (verdicts coupables)',
        mode: ArenaFilterMode.radio,
        options: [
          ArenaFilterOption(id: '1', label: '🚨 ≥ 1'),
          ArenaFilterOption(id: '2', label: '🚨🚨 ≥ 2'),
          ArenaFilterOption(id: '3', label: '⛔ ≥ 3 (banni à vie)'),
        ],
      ),
      ArenaFilterSection(
        id: 'competition',
        title: 'Compétitions (multi-sélection)',
        options: [
          for (final c in comps)
            ArenaFilterOption(
              id: c.id,
              label: '${c.name} · ${c.currentPlayers}/${c.maxPlayers}',
            ),
        ],
      ),
    ];
  }

  Map<String, List<String>> _selectionFromFilter() {
    return {
      'status': [if (_filter.filter != null) _filter.filter!],
      'country': [if (_filter.countryCode != null) _filter.countryCode!],
      'activity': [
        if (_filter.wonCompetition) 'won',
        if (_filter.paidEntry) 'paid',
        if (_filter.receivedReward) 'rewarded',
        if (_filter.hadDispute) 'disputed',
      ],
      'guilty': [
        if (_filter.guiltyMinCount != null) '${_filter.guiltyMinCount}',
      ],
      'competition': _filter.competitionIds,
    };
  }

  void _applySelection(Map<String, List<String>> selection) {
    setState(() {
      final status = selection['status']?.firstOrNull;
      final country = selection['country']?.firstOrNull;
      final activity = selection['activity'] ?? const <String>[];
      final guiltyStr = selection['guilty']?.firstOrNull;
      final competitions = selection['competition'] ?? const <String>[];

      _filter = _filter.copyWith(
        filter: status,
        resetFilter: status == null,
        countryCode: country,
        resetCountryCode: country == null,
        wonCompetition: activity.contains('won'),
        paidEntry: activity.contains('paid'),
        receivedReward: activity.contains('rewarded'),
        hadDispute: activity.contains('disputed'),
        guiltyMinCount: guiltyStr == null ? null : int.parse(guiltyStr),
        resetGuiltyMin: guiltyStr == null,
        competitionIds: competitions,
        resetCompetitionIds: competitions.isEmpty,
      );
    });
  }

  int _activeFilterCount() {
    var n = 0;
    if (_filter.filter != null) n++;
    if (_filter.countryCode != null) n++;
    if (_filter.wonCompetition) n++;
    if (_filter.paidEntry) n++;
    if (_filter.receivedReward) n++;
    if (_filter.hadDispute) n++;
    if (_filter.guiltyMinCount != null) n++;
    if (_filter.competitionIds.isNotEmpty) n++;
    return n;
  }

  void _resetAll() {
    setState(() {
      final keepSearch = _filter.searchQuery;
      _filter = AdminUsersFilter(searchQuery: keepSearch);
    });
  }
}

class _LoadingFilterButton extends StatelessWidget {
  const _LoadingFilterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        border: Border.all(color: ArenaColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ArenaColors.silver,
            ),
          ),
          SizedBox(width: 6),
          Text('Chargement…'),
        ],
      ),
    );
  }
}

class _ActiveCompetitionsBadges extends StatelessWidget {
  const _ActiveCompetitionsBadges({
    required this.competitionIds,
    required this.comps,
    required this.onClearOne,
  });

  final List<String> competitionIds;
  final List<FilterableCompetition> comps;
  final ValueChanged<String> onClearOne;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.xs,
      runSpacing: ArenaSpacing.xs,
      children: [
        for (final id in competitionIds)
          _buildChip(id, comps.where((c) => c.id == id).firstOrNull),
      ],
    );
  }

  Widget _buildChip(String id, FilterableCompetition? c) {
    final label = c == null ? '🏆 Compétition ciblée' : '🏆 ${c.name}';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.signalBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        border: Border.all(color: ArenaColors.signalBlue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: ArenaText.small.copyWith(
                color: ArenaColors.signalBlue,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => onClearOne(id),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: ArenaColors.signalBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banned = !profile.isActive;
    final permaBanned = profile.permanentBan;
    final kycPending = profile.kycStatus == 'pending';
    final borderColor = banned
        ? ArenaColors.neonRed
        : kycPending
            ? ArenaColors.statusWarn
            : ArenaColors.border;

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border(
          top: const BorderSide(color: ArenaColors.border),
          right: const BorderSide(color: ArenaColors.border),
          bottom: const BorderSide(color: ArenaColors.border),
          left: BorderSide(color: borderColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ArenaAvatar(
                initials: profile.username.isEmpty
                    ? '?'
                    : profile.username[0].toUpperCase(),
                color: ArenaAvatarColor.blue,
                size: ArenaAvatarSize.sm,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username,
                      style:
                          ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(profile.email, style: ArenaText.bodyMuted),
                  ],
                ),
              ),
              if (permaBanned)
                const ArenaBadge(
                  label: 'BANNI À VIE',
                  variant: ArenaBadgeVariant.danger,
                )
              else if (banned)
                const ArenaBadge(
                  label: 'BANNI',
                  variant: ArenaBadgeVariant.danger,
                )
              else if (kycPending)
                const ArenaBadge(
                  label: 'KYC',
                  variant: ArenaBadgeVariant.warn,
                )
              else if (profile.isAdmin)
                const ArenaBadge(
                  label: 'ADMIN',
                  variant: ArenaBadgeVariant.info,
                )
              else
                const ArenaBadge(
                  label: 'ACTIF',
                  variant: ArenaBadgeVariant.success,
                ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: banned ? '✓ DÉBANNIR' : '🚫 BANNIR',
                  variant: banned
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.danger,
                  fullWidth: true,
                  onPressed: () => _toggleBan(context, ref),
                ),
              ),
              if (kycPending) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: ArenaButton(
                    label: '✅ KYC OK',
                    variant: ArenaButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () => _overrideKyc(context, ref, 'verified'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBan(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final shouldBan = profile.isActive;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: shouldBan
          ? 'Bannir ${profile.username}'
          : 'Débannir ${profile.username}',
    );
    if (!totpOk) return;
    if (!context.mounted) return;
    final repo = ref.read(adminUsersRepositoryProvider);
    final audit = ref.read(adminAuditLogRepositoryProvider);
    try {
      if (shouldBan) {
        await repo.ban(profile.id);
        await audit.record(
          adminId: adminId,
          action: 'user_banned',
          targetType: 'profile',
          targetId: profile.id,
          beforeState: {'is_active': true},
          afterState: {'is_active': false},
        );
      } else {
        await repo.unban(profile.id);
        await audit.record(
          adminId: adminId,
          action: 'user_unbanned',
          targetType: 'profile',
          targetId: profile.id,
          beforeState: {'is_active': false},
          afterState: {'is_active': true},
        );
      }
      ref.invalidate(adminUsersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shouldBan
                ? '${profile.username} banni.'
                : '${profile.username} débanni.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  Future<void> _overrideKyc(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Override KYC → $status pour ${profile.username}',
    );
    if (!totpOk) return;
    if (!context.mounted) return;
    try {
      await ref
          .read(adminUsersRepositoryProvider)
          .overrideKyc(userId: profile.id, status: status);
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'user_kyc_overridden',
        targetType: 'profile',
        targetId: profile.id,
        afterState: {'kyc_status': status},
      );
      ref.invalidate(adminUsersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KYC → $status pour ${profile.username}.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }
}
