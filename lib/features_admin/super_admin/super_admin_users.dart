import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';

/// PHASE 11 · SA3 — super-admin user management.
///
/// Search bar + status filter chips + country chips + a list of user
/// cards with admin actions (voir / reset password / audit / ban).
/// Banned users surface a "débannir" CTA. KYC-pending users get a warn
/// badge.
///
/// Maps to screen SA3 of `arena_v2.html`.
class SuperAdminUsers extends StatefulWidget {
  const SuperAdminUsers({super.key});

  @override
  State<SuperAdminUsers> createState() => _SuperAdminUsersState();
}

class _SuperAdminUsersState extends State<SuperAdminUsers> {
  final _searchCtrl = TextEditingController();
  String _filter = 'Tous (12 048)';
  String _country = '';

  static const _statusFilters = [
    'Tous (12 048)',
    'Actifs',
    'Bannis (3)',
    'KYC pending',
  ];
  static const _countryFilters = ['🇨🇲', '🇸🇳', '🇨🇮', '+10'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Utilisateurs',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: ArenaColors.silver),
            onPressed: () {},
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
            ),
            const SizedBox(height: ArenaSpacing.md),
            Text('FILTRES', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            _ChipsRow(
              labels: _statusFilters,
              current: _filter,
              onTap: (l) => setState(() => _filter = l),
            ),
            const SizedBox(height: ArenaSpacing.xs),
            _ChipsRow(
              labels: _countryFilters,
              current: _country,
              onTap: (l) => setState(() => _country = l),
            ),
            const SizedBox(height: ArenaSpacing.md),
            const _UserCard(
              initials: 'K',
              color: ArenaAvatarColor.blue,
              name: 'KevinM_237',
              meta: 'kevin@gmail.com · 🇨🇲',
              statusBadge: 'ACTIF',
              statusVariant: ArenaBadgeVariant.success,
              roleBadge: 'USER',
              roleVariant: ArenaBadgeVariant.tierBronze,
              showActions: true,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _UserCard(
              initials: 'A',
              color: ArenaAvatarColor.orange,
              name: 'AdminPaul',
              meta: 'paul@arena.app · 🇸🇳',
              statusBadge: 'ACTIF',
              statusVariant: ArenaBadgeVariant.success,
              roleBadge: 'ADMIN',
              roleVariant: ArenaBadgeVariant.danger,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _UserCard(
              initials: 'X',
              color: ArenaAvatarColor.red,
              name: 'XploitR_99',
              meta: 'xploit@temp.io · 🇧🇫',
              statusBadge: 'BANNI',
              statusVariant: ArenaBadgeVariant.danger,
              banned: true,
              note: '⚠ Triche détectée 2× · banni le 28/04',
              showUnban: true,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _UserCard(
              initials: 'L',
              color: ArenaAvatarColor.purple,
              name: 'LindaO',
              meta: 'linda@yahoo.fr · 🇨🇮',
              statusBadge: 'KYC PENDING',
              statusVariant: ArenaBadgeVariant.warn,
              roleBadge: 'USER',
              roleVariant: ArenaBadgeVariant.tierBronze,
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
    required this.current,
    required this.onTap,
  });

  final List<String> labels;
  final String current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final l in labels)
            Padding(
              padding: const EdgeInsets.only(right: ArenaSpacing.xs),
              child: InkWell(
                onTap: () => onTap(l),
                borderRadius: BorderRadius.circular(ArenaRadius.round),
                child: AnimatedContainer(
                  duration: ArenaDurations.short,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: l == current
                        ? ArenaColors.signalBlue.withValues(alpha: 0.15)
                        : ArenaColors.carbon,
                    borderRadius:
                        BorderRadius.circular(ArenaRadius.round),
                    border: Border.all(
                      color: l == current
                          ? ArenaColors.signalBlue
                          : ArenaColors.border,
                    ),
                  ),
                  child: Text(
                    l,
                    style: ArenaText.body.copyWith(
                      color: l == current
                          ? ArenaColors.signalBlue
                          : ArenaColors.silver,
                      fontWeight: l == current
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

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.initials,
    required this.color,
    required this.name,
    required this.meta,
    required this.statusBadge,
    required this.statusVariant,
    this.roleBadge,
    this.roleVariant,
    this.banned = false,
    this.note,
    this.showActions = false,
    this.showUnban = false,
  });

  final String initials;
  final ArenaAvatarColor color;
  final String name;
  final String meta;
  final String statusBadge;
  final ArenaBadgeVariant statusVariant;
  final String? roleBadge;
  final ArenaBadgeVariant? roleVariant;
  final bool banned;
  final String? note;
  final bool showActions;
  final bool showUnban;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: banned
            ? ArenaColors.neonRed.withValues(alpha: 0.05)
            : ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: banned ? ArenaColors.neonRed : ArenaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ArenaAvatar(
                initials: initials,
                color: color,
                size: ArenaAvatarSize.md,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(meta, style: ArenaText.bodyMuted),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ArenaBadge(label: statusBadge, variant: statusVariant),
                  if (roleBadge != null) ...[
                    const SizedBox(height: 4),
                    ArenaBadge(label: roleBadge!, variant: roleVariant!),
                  ],
                ],
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              note!,
              style: ArenaText.bodyMuted
                  .copyWith(color: ArenaColors.neonRed),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ArenaButton(
                  label: '👁 VOIR',
                  variant: ArenaButtonVariant.secondary,
                  onPressed: () {},
                ),
                ArenaButton(
                  label: '🔑 RESET PWD',
                  variant: ArenaButtonVariant.secondary,
                  onPressed: () {},
                ),
                ArenaButton(
                  label: '📜 AUDIT',
                  variant: ArenaButtonVariant.secondary,
                  onPressed: () {},
                ),
                ArenaButton(
                  label: '🚫 BANNIR',
                  variant: ArenaButtonVariant.danger,
                  onPressed: () {},
                ),
              ],
            ),
          ],
          if (showUnban) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ArenaButton(
                    label: '📜 AUDIT',
                    variant: ArenaButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ArenaButton(
                    label: '↻ DÉBANNIR',
                    fullWidth: true,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
