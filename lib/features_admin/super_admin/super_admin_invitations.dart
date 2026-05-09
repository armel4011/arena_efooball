import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';

/// PHASE 11 · SA2 — admin invitation codes management.
///
/// Codes are formatted ARENA-XXXX-XXXX-XXXX. Lists active / used codes
/// then shows a generation form (role + target email + expiration +
/// max uses). Backed by `admin_invitations` table (PHASE 11.5).
///
/// Maps to screen SA2 of `arena_v2.html`.
class SuperAdminInvitations extends StatefulWidget {
  const SuperAdminInvitations({super.key});

  @override
  State<SuperAdminInvitations> createState() => _SuperAdminInvitationsState();
}

class _SuperAdminInvitationsState extends State<SuperAdminInvitations> {
  static const _gold = Color(0xFFFFD700);
  _Role _role = _Role.admin;
  _Expiration _expiration = _Expiration.thirtyDays;
  final _emailCtrl = TextEditingController();
  final _usesCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Invitations admin',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _gold, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            Text('CODES ACTIFS', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            const _CodeCard(
              borderColor: ArenaColors.statusOk,
              statusBadge: 'VALIDE',
              statusVariant: ArenaBadgeVariant.success,
              expirationLabel: 'Expire 16/05',
              code: 'ARENA-7K3M-9PN2-FQ4X',
              role: 'Modérateur',
              target: 'paul.eboto@gmail.com',
              uses: '0/1',
              showActions: true,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _CodeCard(
              borderColor: ArenaColors.statusOk,
              statusBadge: 'VALIDE',
              statusVariant: ArenaBadgeVariant.success,
              expirationLabel: 'Expire jamais',
              code: 'ARENA-XK4P-2NM7-WZ8Y',
              role: 'Super-admin',
              roleColor: _gold,
              target: '— libre',
              uses: '0/1',
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _CodeCard(
              borderColor: ArenaColors.silverDim,
              statusBadge: 'UTILISÉ',
              statusVariant: ArenaBadgeVariant.neutral,
              expirationLabel: 'Le 06/05',
              code: 'ARENA-MQ8R-V3LP-7AB2',
              target: 'Modérateur1',
              targetLabel: 'Utilisé par',
              opacity: 0.7,
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text(
              '+ GÉNÉRER UN CODE',
              style: ArenaText.inputLabel.copyWith(color: _gold),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            _GenerateCard(
              role: _role,
              expiration: _expiration,
              emailCtrl: _emailCtrl,
              usesCtrl: _usesCtrl,
              onRoleChanged: (r) => setState(() => _role = r),
              onExpirationChanged: (e) => setState(() => _expiration = e),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Role { admin, superAdmin }

enum _Expiration { sevenDays, thirtyDays, never }

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.borderColor,
    required this.statusBadge,
    required this.statusVariant,
    required this.expirationLabel,
    required this.code,
    this.role,
    this.roleColor,
    this.target,
    this.targetLabel = 'Cible',
    this.uses,
    this.showActions = false,
    this.opacity = 1,
  });

  final Color borderColor;
  final String statusBadge;
  final ArenaBadgeVariant statusVariant;
  final String expirationLabel;
  final String code;
  final String? role;
  final Color? roleColor;
  final String? target;
  final String targetLabel;
  final String? uses;
  final bool showActions;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
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
                ArenaBadge(label: statusBadge, variant: statusVariant),
                const Spacer(),
                Text(expirationLabel, style: ArenaText.bodyMuted),
              ],
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              code,
              style: ArenaText.mono.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontSize: 13,
              ),
            ),
            if (role != null) ...[
              const SizedBox(height: ArenaSpacing.xs),
              Row(
                children: [
                  Expanded(child: Text('Rôle', style: ArenaText.bodyMuted)),
                  Text(
                    role!,
                    style: ArenaText.body
                        .copyWith(color: roleColor ?? ArenaColors.bone),
                  ),
                ],
              ),
            ],
            if (target != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(targetLabel, style: ArenaText.bodyMuted),
                  ),
                  Text(target!, style: ArenaText.body),
                ],
              ),
            ],
            if (uses != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: Text('Usages', style: ArenaText.bodyMuted)),
                  Text(uses!, style: ArenaText.body),
                ],
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: ArenaSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ArenaButton(
                      label: '📋 COPIER',
                      variant: ArenaButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ArenaButton(
                      label: '📤 PARTAGER',
                      variant: ArenaButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ArenaButton(
                      label: '🚫 RÉVOQUER',
                      variant: ArenaButtonVariant.danger,
                      fullWidth: true,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GenerateCard extends StatelessWidget {
  const _GenerateCard({
    required this.role,
    required this.expiration,
    required this.emailCtrl,
    required this.usesCtrl,
    required this.onRoleChanged,
    required this.onExpirationChanged,
  });

  final _Role role;
  final _Expiration expiration;
  final TextEditingController emailCtrl;
  final TextEditingController usesCtrl;
  final ValueChanged<_Role> onRoleChanged;
  final ValueChanged<_Expiration> onExpirationChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaGlowCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Rôle cible', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.xs),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: 'ADMIN',
                  variant: role == _Role.admin
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => onRoleChanged(_Role.admin),
                ),
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Expanded(
                child: ArenaButton(
                  label: 'SUPER-ADMIN',
                  variant: role == _Role.superAdmin
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => onRoleChanged(_Role.superAdmin),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text('Email cible (optionnel)', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.xs),
          ArenaTextField(
            controller: emailCtrl,
            hint: 'laisse vide pour libre',
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text('Expiration', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.xs),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: '7 JOURS',
                  variant: expiration == _Expiration.sevenDays
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => onExpirationChanged(_Expiration.sevenDays),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ArenaButton(
                  label: '30 JOURS',
                  variant: expiration == _Expiration.thirtyDays
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () =>
                      onExpirationChanged(_Expiration.thirtyDays),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ArenaButton(
                  label: 'JAMAIS',
                  variant: expiration == _Expiration.never
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => onExpirationChanged(_Expiration.never),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            "Nombre d'usages max",
            style: ArenaText.inputLabel,
          ),
          const SizedBox(height: ArenaSpacing.xs),
          ArenaTextField(controller: usesCtrl),
          const SizedBox(height: ArenaSpacing.md),
          ArenaButton(
            label: '🎟 GÉNÉRER',
            variant: ArenaButtonVariant.danger,
            fullWidth: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
