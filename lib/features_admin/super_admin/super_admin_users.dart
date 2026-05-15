import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_users_repository.dart';
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/core/router/admin_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// PHASE 11 · SA3 — super-admin user management.
///
/// Reads `profiles` via [adminUsersProvider]. Filters: status (active /
/// banned / KYC pending) + country. Ban / unban flip `is_active` under
/// `profiles_admin_all` RLS; KYC override stamps `kyc_status` directly.
/// Every write appends an audit log row.
///
/// Maps to screen SA3 of `arena_v2.html`.
class SuperAdminUsers extends ConsumerStatefulWidget {
  const SuperAdminUsers({super.key});

  @override
  ConsumerState<SuperAdminUsers> createState() => _SuperAdminUsersState();
}

class _SuperAdminUsersState extends ConsumerState<SuperAdminUsers> {
  final _searchCtrl = TextEditingController();
  String? _statusFilter;
  String? _countryCode;
  String _searchQuery = '';
  bool _wonCompetition = false;
  bool _paidEntry = false;
  bool _receivedReward = false;
  bool _hadDispute = false;
  // null = pas de filtre. 1/2/3 = seuil min de verdicts coupables.
  // 3 cible spécifiquement les bannis à vie (règle 3-strikes).
  int? _guiltyMinCount;

  static const _statusFilters = <(String?, String)>[
    (null, 'Tous'),
    ('active', 'Actifs'),
    ('banned', 'Bannis'),
    ('kyc_pending', 'KYC pending'),
  ];
  static const _countryFilters = <(String?, String)>[
    (null, 'Tous pays'),
    ('CM', '🇨🇲'),
    ('SN', '🇸🇳'),
    ('CI', '🇨🇮'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  AdminUsersFilter get _filter => AdminUsersFilter(
        countryCode: _countryCode,
        filter: _statusFilter,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        wonCompetition: _wonCompetition,
        paidEntry: _paidEntry,
        receivedReward: _receivedReward,
        hadDispute: _hadDispute,
        guiltyMinCount: _guiltyMinCount,
      );

  void _resetAdvanced() {
    setState(() {
      _wonCompetition = false;
      _paidEntry = false;
      _receivedReward = false;
      _hadDispute = false;
      _guiltyMinCount = null;
    });
  }

  // Toggle exclusif : retape la même valeur → désélectionne.
  void _setGuiltyMin(int value) {
    setState(() => _guiltyMinCount = (_guiltyMinCount == value) ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    final filter = _filter;
    final users = ref.watch(adminUsersProvider(filter));

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Utilisateurs',
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            ArenaTextField(
              controller: _searchCtrl,
              hint: '🔍 Rechercher username, email…',
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
            const SizedBox(height: ArenaSpacing.md),
            Text('FILTRES', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            _ChipsRow(
              labels: [for (final (_, l) in _statusFilters) l],
              currentIndex:
                  _statusFilters.indexWhere((e) => e.$1 == _statusFilter),
              onTap: (i) =>
                  setState(() => _statusFilter = _statusFilters[i].$1),
            ),
            const SizedBox(height: ArenaSpacing.xs),
            _ChipsRow(
              labels: [for (final (_, l) in _countryFilters) l],
              currentIndex:
                  _countryFilters.indexWhere((e) => e.$1 == _countryCode),
              onTap: (i) =>
                  setState(() => _countryCode = _countryFilters[i].$1),
            ),
            const SizedBox(height: ArenaSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text('ACTIVITÉ', style: ArenaText.inputLabel),
                ),
                if (filter.hasAdvancedFilter)
                  TextButton(
                    onPressed: _resetAdvanced,
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
            _ToggleChipsWrap(
              chips: [
                _ToggleChipData(
                  label: '🏆 A gagné',
                  active: _wonCompetition,
                  onTap: () =>
                      setState(() => _wonCompetition = !_wonCompetition),
                ),
                _ToggleChipData(
                  label: '💳 A payé',
                  active: _paidEntry,
                  onTap: () => setState(() => _paidEntry = !_paidEntry),
                ),
                _ToggleChipData(
                  label: '💰 A reçu un gain',
                  active: _receivedReward,
                  onTap: () =>
                      setState(() => _receivedReward = !_receivedReward),
                ),
                _ToggleChipData(
                  label: '⚖ Litige',
                  active: _hadDispute,
                  onTap: () => setState(() => _hadDispute = !_hadDispute),
                ),
                _ToggleChipData(
                  label: '🚨 Coupable ≥ 1',
                  active: _guiltyMinCount == 1,
                  onTap: () => _setGuiltyMin(1),
                ),
                _ToggleChipData(
                  label: '🚨🚨 Coupable ≥ 2',
                  active: _guiltyMinCount == 2,
                  onTap: () => _setGuiltyMin(2),
                ),
                _ToggleChipData(
                  label: '⛔ Coupable ≥ 3 (banni à vie)',
                  active: _guiltyMinCount == 3,
                  onTap: () => _setGuiltyMin(3),
                ),
              ],
            ),
            const SizedBox(height: ArenaSpacing.md),
            users.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
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
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.labels,
    required this.currentIndex,
    required this.onTap,
  });

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: ArenaSpacing.xs),
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(ArenaRadius.round),
                child: AnimatedContainer(
                  duration: ArenaDurations.short,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? ArenaColors.signalBlue.withValues(alpha: 0.15)
                        : ArenaColors.carbon,
                    borderRadius:
                        BorderRadius.circular(ArenaRadius.round),
                    border: Border.all(
                      color: i == currentIndex
                          ? ArenaColors.signalBlue
                          : ArenaColors.border,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: ArenaText.body.copyWith(
                      color: i == currentIndex
                          ? ArenaColors.signalBlue
                          : ArenaColors.silver,
                      fontWeight: i == currentIndex
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Données d'un chip toggle multi-select (chaque chip s'allume/éteint
/// indépendamment, contrairement à `_ChipsRow` qui est mono-select).
class _ToggleChipData {
  const _ToggleChipData({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
}

class _ToggleChipsWrap extends StatelessWidget {
  const _ToggleChipsWrap({required this.chips});

  final List<_ToggleChipData> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.xs,
      runSpacing: ArenaSpacing.xs,
      children: [
        for (final c in chips)
          InkWell(
            onTap: c.onTap,
            borderRadius: BorderRadius.circular(ArenaRadius.round),
            child: AnimatedContainer(
              duration: ArenaDurations.short,
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: c.active
                    ? ArenaColors.signalBlue.withValues(alpha: 0.15)
                    : ArenaColors.carbon,
                borderRadius: BorderRadius.circular(ArenaRadius.round),
                border: Border.all(
                  color: c.active ? ArenaColors.signalBlue : ArenaColors.border,
                ),
              ),
              child: Text(
                c.label,
                style: ArenaText.body.copyWith(
                  color: c.active
                      ? ArenaColors.signalBlue
                      : ArenaColors.silver,
                  fontWeight: c.active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
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
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w700),
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
        SnackBar(content: Text('Échec : $e')),
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
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}
