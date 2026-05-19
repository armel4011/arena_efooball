import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/payout.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_payouts_repository.dart';
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · A13 — payout validation page (CRITIQUE).
///
/// Reads pending payouts via [adminPendingPayoutsProvider] and lets
/// the admin validate them — flipping `payouts.status` to `validated`
/// + recording an `admin_audit_log` row. The provider dispatch step
/// (`validate_payout` Edge Function) lands in PHASE 11bis / 12.5.
///
/// Maps to screen A13 of `arena_v2.html`.
class AdminPayoutsPage extends ConsumerStatefulWidget {
  const AdminPayoutsPage({super.key});

  @override
  ConsumerState<AdminPayoutsPage> createState() => _AdminPayoutsPageState();
}

class _AdminPayoutsPageState extends ConsumerState<AdminPayoutsPage> {
  _PayoutMode _mode = _PayoutMode.oneByOne;
  final _batchCtrl = TextEditingController();

  @override
  void dispose() {
    _batchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payouts = ref.watch(adminPendingPayoutsProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Payouts — validation'),
      body: SafeArea(
        child: payouts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: Text(
              'Erreur de chargement : $e',
              style: ArenaText.bodyMuted,
            ),
          ),
          data: (list) => ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              _Summary(
                mode: _mode,
                onModeChanged: (m) => setState(() => _mode = m),
                payouts: list,
              ),
              const SizedBox(height: ArenaSpacing.lg),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  child: Text(
                    '✅ Aucun payout en attente.',
                    style: ArenaText.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                for (var i = 0; i < list.length; i++) ...[
                  Text(
                    'PAYOUT ${i + 1}/${list.length}',
                    style: ArenaText.inputLabel,
                  ),
                  const SizedBox(height: ArenaSpacing.sm),
                  _PayoutCard(payout: list[i]),
                  const SizedBox(height: ArenaSpacing.md),
                ],
                if (_mode == _PayoutMode.batch) ...[
                  Text('MODE BATCH', style: ArenaText.inputLabel),
                  const SizedBox(height: ArenaSpacing.sm),
                  _BatchCard(
                    controller: _batchCtrl,
                    payouts: list,
                    onValidated: () {
                      ref.invalidate(adminPendingPayoutsProvider);
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _PayoutMode { batch, oneByOne }

class _Summary extends StatelessWidget {
  const _Summary({
    required this.mode,
    required this.onModeChanged,
    required this.payouts,
  });

  final _PayoutMode mode;
  final ValueChanged<_PayoutMode> onModeChanged;
  final List<Payout> payouts;

  @override
  Widget build(BuildContext context) {
    final total = payouts.fold<double>(0, (a, p) => a + p.amountLocal);
    final fmt = NumberFormat('#,###', 'fr_FR')
        .format(total.round())
        .replaceAll(',', ' ');

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaDangerCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('À verser', style: ArenaText.bodyMuted),
                const SizedBox(height: 4),
                Text(
                  '$fmt XAF',
                  style: ArenaText.bigNumber.copyWith(
                    color: ArenaColors.neonRed,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${payouts.length} payouts pending',
                  style: ArenaText.bodyMuted,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ArenaButton(
                label: '📦 BATCH',
                variant: mode == _PayoutMode.batch
                    ? ArenaButtonVariant.primary
                    : ArenaButtonVariant.secondary,
                onPressed: () => onModeChanged(_PayoutMode.batch),
              ),
              const SizedBox(height: 4),
              ArenaButton(
                label: '1×1',
                variant: mode == _PayoutMode.oneByOne
                    ? ArenaButtonVariant.primary
                    : ArenaButtonVariant.secondary,
                onPressed: () => onModeChanged(_PayoutMode.oneByOne),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutCard extends ConsumerWidget {
  const _PayoutCard({required this.payout});
  final Payout payout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOk = payout.allAutoChecksPassed;
    final border = allOk ? ArenaColors.statusOk : ArenaColors.neonRed;
    final amountFmt = NumberFormat('#,###', 'fr_FR')
        .format(payout.amountLocal.round())
        .replaceAll(',', ' ');

    final checks = _buildChecks(payout);

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ArenaAvatar(
                initials: payout.userId.substring(0, 1).toUpperCase(),
                color: ArenaAvatarColor.blue,
                size: ArenaAvatarSize.sm,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ${payout.userId.substring(0, 8)}',
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compétition ${payout.competitionId.substring(0, 8)}',
                      style: ArenaText.bodyMuted,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountFmt ${payout.currency}',
                    style: ArenaText.mono.copyWith(
                      color: allOk ? ArenaColors.statusOk : ArenaColors.silver,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payout.payoutMethod ?? '—',
                    style: ArenaText.bodyMuted,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            '${checks.length} CONTRÔLES AUTO',
            style: ArenaText.inputLabel,
          ),
          const SizedBox(height: ArenaSpacing.xs),
          for (final c in checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.ok ? '✓' : '✗',
                    style: ArenaText.body.copyWith(
                      color: c.ok ? ArenaColors.statusOk : ArenaColors.neonRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: ArenaSpacing.sm),
                  Expanded(
                    child: Text(
                      c.label,
                      style: ArenaText.body.copyWith(
                        color:
                            c.ok ? ArenaColors.bone : ArenaColors.neonRed,
                        fontWeight: c.ok ? null : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: ArenaSpacing.sm),
          if (allOk)
            ArenaButton(
              label: '✅ VALIDER · $amountFmt ${payout.currency}',
              variant: ArenaButtonVariant.primary,
              fullWidth: true,
              onPressed: () => _validate(context, ref),
            )
          else
            ArenaButton(
              label: '⚠ REVUE MANUELLE',
              variant: ArenaButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => _manualReview(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _validate(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final justification = await _askJustification(
      context,
      title: 'Valider ce payout ?',
      hint: 'Justification (vérifications effectuées)',
    );
    if (justification == null) return;
    if (!context.mounted) return;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Valider un payout · ${payout.currency} '
          '${payout.amountLocal.round()}',
    );
    if (!totpOk) return;
    try {
      await ref.read(adminPayoutsRepositoryProvider).validate(
            payoutId: payout.id,
            adminId: adminId,
            justification: justification,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'payout_validated',
        targetType: 'payout',
        targetId: payout.id,
        afterState: {
          'amount_local': payout.amountLocal,
          'currency': payout.currency,
          'justification': justification,
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  Future<void> _manualReview(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final action = await showDialog<_PayoutAction>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Revue manuelle', style: ArenaText.h3),
        content: Text(
          'Au moins une vérification automatique a échoué. Tu peux quand '
          'même valider après revue, ou refuser le payout.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(_PayoutAction.cancel),
            child: const Text('FERMER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(_PayoutAction.refuse),
            style: TextButton.styleFrom(foregroundColor: ArenaColors.neonRed),
            child: const Text('REFUSER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(_PayoutAction.validate),
            child: const Text('VALIDER QUAND MÊME'),
          ),
        ],
      ),
    );
    if (action == null || action == _PayoutAction.cancel) return;

    if (!context.mounted) return;
    final justification = await _askJustification(
      context,
      title: action == _PayoutAction.refuse
          ? 'Refuser ce payout ?'
          : 'Valider ce payout ?',
      hint: 'Justification écrite (obligatoire)',
    );
    if (justification == null) return;
    if (!context.mounted) return;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: action == _PayoutAction.refuse
          ? 'Refuser un payout'
          : 'Override validation payout (revue manuelle)',
    );
    if (!totpOk) return;

    final repo = ref.read(adminPayoutsRepositoryProvider);
    final audit = ref.read(adminAuditLogRepositoryProvider);
    try {
      if (action == _PayoutAction.validate) {
        await repo.validate(
          payoutId: payout.id,
          adminId: adminId,
          justification: justification,
        );
        await audit.record(
          adminId: adminId,
          action: 'payout_validated',
          targetType: 'payout',
          targetId: payout.id,
          afterState: {
            'justification': justification,
            'override': true,
          },
        );
      } else {
        await repo.refuse(
          payoutId: payout.id,
          adminId: adminId,
          justification: justification,
        );
        await audit.record(
          adminId: adminId,
          action: 'payout_refused',
          targetType: 'payout',
          targetId: payout.id,
          afterState: {'justification': justification},
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  Future<String?> _askJustification(
    BuildContext context, {
    required String title,
    required String hint,
  }) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text(title, style: ArenaText.h3),
        content: ArenaTextField(controller: ctrl, hint: hint, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              Navigator.of(c).pop(v);
            },
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );
    // Différer la dispose pour laisser le framework finir le tear-down
    // du dialog (sinon "_dependents.isEmpty: is not true" + "controller
    // used after dispose").
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    return result;
  }

  static List<_Check> _buildChecks(Payout payout) {
    final raw = payout.autoChecks;
    if (raw.isEmpty) {
      return const [_Check(label: 'Aucun contrôle auto', ok: false)];
    }
    return [
      for (final entry in raw.entries)
        _Check(label: _labelFor(entry.key), ok: entry.value == true),
    ];
  }

  static String _labelFor(String key) {
    switch (key) {
      case 'kyc_verified':
      case 'kyc':
        return 'KYC vérifié';
      case 'no_dispute':
        return 'Aucun litige ouvert';
      case 'no_anti_cheat':
      case 'anti_cheat':
        return "Pas d'alerte anti-cheat";
      case 'not_banned':
      case 'account_active':
        return 'Compte non banni';
      case 'momo_valid':
      case 'payment_destination':
        return 'Destination paiement valide';
      default:
        return key.replaceAll('_', ' ');
    }
  }
}

enum _PayoutAction { validate, refuse, cancel }

class _Check {
  const _Check({required this.label, required this.ok});
  final String label;
  final bool ok;
}

class _BatchCard extends ConsumerWidget {
  const _BatchCard({
    required this.controller,
    required this.payouts,
    required this.onValidated,
  });

  final TextEditingController controller;
  final List<Payout> payouts;
  final VoidCallback onValidated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligible = payouts.where((p) => p.allAutoChecksPassed).toList();
    final expectedTotal = eligible.fold<double>(
      0,
      (acc, p) => acc + p.amountLocal,
    );
    final fmt = NumberFormat('#,###', 'fr_FR')
        .format(expectedTotal.round())
        .replaceAll(',', ' ');
    final typed = int.tryParse(controller.text.replaceAll(' ', '')) ?? 0;
    final enabled = eligible.isNotEmpty && typed == expectedTotal.round();

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: arenaWarningCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            text: TextSpan(
              style: ArenaText.body,
              children: [
                const TextSpan(text: '⚠ '),
                TextSpan(
                  text: 'Anti-erreur : ',
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: 'tape le total à verser pour valider '
                      '${eligible.length} payouts éligibles.',
                ),
              ],
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'Total attendu : $fmt XAF',
            style: ArenaText.inputLabel,
          ),
          const SizedBox(height: ArenaSpacing.xs),
          ArenaTextField(
            controller: controller,
            hint: 'Tape le montant…',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9 ]')),
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: '🔒 VALIDER ${eligible.length} PAYOUTS',
            variant: ArenaButtonVariant.danger,
            fullWidth: true,
            onPressed:
                enabled ? () => _runBatch(context, ref, eligible) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _runBatch(
    BuildContext context,
    WidgetRef ref,
    List<Payout> eligible,
  ) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Valider ${eligible.length} payouts en batch',
    );
    if (!totpOk) return;
    final repo = ref.read(adminPayoutsRepositoryProvider);
    final audit = ref.read(adminAuditLogRepositoryProvider);
    final justification =
        'Validation batch (${eligible.length} payouts) — anti-erreur OK.';
    try {
      for (final p in eligible) {
        await repo.validate(
          payoutId: p.id,
          adminId: adminId,
          justification: justification,
        );
        await audit.record(
          adminId: adminId,
          action: 'payout_validated',
          targetType: 'payout',
          targetId: p.id,
          afterState: {
            'amount_local': p.amountLocal,
            'batch': true,
          },
        );
      }
      controller.clear();
      onValidated();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${eligible.length} payouts validés.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }
}
