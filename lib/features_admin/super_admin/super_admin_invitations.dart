import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/invitation_code.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/admin/admin_invitations_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · SA2 — admin invitation codes management.
///
/// Reads `invitation_codes` via [adminInvitationsProvider] (super-admin
/// RLS). Generate / revoke flow lives in [AdminInvitationsRepository].
/// The actual redeem-and-grant-role flow is gated on the
/// `register_admin` Edge Function — PHASE 12.5.
///
/// Maps to screen SA2 of `arena_v2.html`.
class SuperAdminInvitations extends ConsumerStatefulWidget {
  const SuperAdminInvitations({super.key});

  @override
  ConsumerState<SuperAdminInvitations> createState() =>
      _SuperAdminInvitationsState();
}

class _SuperAdminInvitationsState
    extends ConsumerState<SuperAdminInvitations> {
  static const _gold = Color(0xFFFFD700);
  UserRole _role = UserRole.admin;
  _Expiration _expiration = _Expiration.thirtyDays;
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final codes = ref.watch(adminInvitationsProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Invitations admin'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            Text('CODES', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            codes.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('Erreur : $e', style: ArenaText.bodyMuted),
              data: (list) => list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(ArenaSpacing.md),
                      child: Text(
                        "Aucun code généré pour l'instant.",
                        style: ArenaText.bodyMuted,
                      ),
                    )
                  : Column(
                      children: [
                        for (final c in list) ...[
                          _CodeCard(code: c),
                          const SizedBox(height: ArenaSpacing.sm),
                        ],
                      ],
                    ),
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
              onRoleChanged: (r) => setState(() => _role = r),
              onExpirationChanged: (e) => setState(() => _expiration = e),
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final email = _emailCtrl.text.trim();
    try {
      await ref.read(adminInvitationsRepositoryProvider).create(
            generatedBy: adminId,
            role: _role,
            targetEmail: email.isEmpty ? null : email,
            expiresAt: _expiration.deadline,
          );
      _emailCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code généré.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}

enum _Expiration { sevenDays, thirtyDays, never }

extension on _Expiration {
  String get label {
    switch (this) {
      case _Expiration.sevenDays:
        return '7 JOURS';
      case _Expiration.thirtyDays:
        return '30 JOURS';
      case _Expiration.never:
        return 'JAMAIS';
    }
  }

  DateTime? get deadline {
    switch (this) {
      case _Expiration.sevenDays:
        return DateTime.now().toUtc().add(const Duration(days: 7));
      case _Expiration.thirtyDays:
        return DateTime.now().toUtc().add(const Duration(days: 30));
      case _Expiration.never:
        return null;
    }
  }
}

class _CodeCard extends ConsumerWidget {
  const _CodeCard({required this.code});
  final InvitationCode code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUsed = code.isUsed;
    final isActive = code.isActive;
    final borderColor = isActive
        ? ArenaColors.statusOk
        : isUsed
            ? ArenaColors.silverDim
            : ArenaColors.neonRed;
    final statusLabel = isActive
        ? 'VALIDE'
        : isUsed
            ? 'UTILISÉ'
            : 'EXPIRÉ';
    final statusVariant = isActive
        ? ArenaBadgeVariant.success
        : isUsed
            ? ArenaBadgeVariant.neutral
            : ArenaBadgeVariant.danger;

    final expirationLabel = code.expiresAt == null
        ? 'Expire jamais'
        : 'Expire ${DateFormat('dd/MM').format(code.expiresAt!)}';

    return Opacity(
      opacity: isUsed ? 0.7 : 1,
      child: Container(
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
                ArenaBadge(label: statusLabel, variant: statusVariant),
                const Spacer(),
                Text(expirationLabel, style: ArenaText.bodyMuted),
              ],
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              'ARENA-${code.code}',
              style: ArenaText.mono.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: ArenaSpacing.xs),
            Row(
              children: [
                Expanded(child: Text('Rôle', style: ArenaText.bodyMuted)),
                Text(
                  code.role == UserRole.superAdmin ? 'Super-admin' : 'Admin',
                  style: ArenaText.body.copyWith(
                    color: code.role == UserRole.superAdmin
                        ? const Color(0xFFFFD700)
                        : ArenaColors.bone,
                  ),
                ),
              ],
            ),
            if (code.targetEmail != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: Text('Cible', style: ArenaText.bodyMuted)),
                  Text(code.targetEmail!, style: ArenaText.body),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text('Usages', style: ArenaText.bodyMuted)),
                Text(
                  '${code.usesCount}/${code.maxUses}',
                  style: ArenaText.body,
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: ArenaSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ArenaButton(
                      label: '📋 COPIER',
                      variant: ArenaButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: 'ARENA-${code.code}'),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copié.')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ArenaButton(
                      label: '🚫 RÉVOQUER',
                      variant: ArenaButtonVariant.danger,
                      fullWidth: true,
                      onPressed: () async {
                        try {
                          await ref
                              .read(adminInvitationsRepositoryProvider)
                              .revoke(code.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code révoqué.'),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Échec : $e')),
                          );
                        }
                      },
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
    required this.onRoleChanged,
    required this.onExpirationChanged,
    required this.onSubmit,
  });

  final UserRole role;
  final _Expiration expiration;
  final TextEditingController emailCtrl;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<_Expiration> onExpirationChanged;
  final Future<void> Function() onSubmit;

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
                  variant: role == UserRole.admin
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => onRoleChanged(UserRole.admin),
                ),
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Expanded(
                child: ArenaButton(
                  label: 'SUPER-ADMIN',
                  variant: role == UserRole.superAdmin
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => onRoleChanged(UserRole.superAdmin),
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
              for (final e in _Expiration.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: ArenaSpacing.xs),
                    child: ArenaButton(
                      label: e.label,
                      variant: expiration == e
                          ? ArenaButtonVariant.primary
                          : ArenaButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () => onExpirationChanged(e),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaButton(
            label: '🔑 GÉNÉRER',
            fullWidth: true,
            onPressed: () async => onSubmit(),
          ),
        ],
      ),
    );
  }
}
