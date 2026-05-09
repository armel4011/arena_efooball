import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// PHASE 11 · A13 — payout validation page (CRITIQUE).
///
/// Five automated checks per payout (KYC / no dispute / no anti-cheat /
/// account not banned / valid MoMo number). Batch mode requires the
/// admin to type the exact total amount as anti-mistake guard before
/// validating multiple payouts in one go.
///
/// Maps to screen A13 of `arena_v2.html`.
class AdminPayoutsPage extends StatefulWidget {
  const AdminPayoutsPage({super.key});

  @override
  State<AdminPayoutsPage> createState() => _AdminPayoutsPageState();
}

class _AdminPayoutsPageState extends State<AdminPayoutsPage> {
  _PayoutMode _mode = _PayoutMode.oneByOne;
  final _batchCtrl = TextEditingController();

  static const _expectedBatchTotal = 105000;

  @override
  void dispose() {
    _batchCtrl.dispose();
    super.dispose();
  }

  bool get _batchEnabled =>
      int.tryParse(_batchCtrl.text.replaceAll(' ', '')) ==
      _expectedBatchTotal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(title: 'Payouts — validation'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            _Summary(
              mode: _mode,
              onModeChanged: (m) => setState(() => _mode = m),
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text('PAYOUT 1/12', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            const _PayoutCard(
              initials: 'K',
              color: ArenaAvatarColor.blue,
              name: 'KevinM_237',
              meta: 'FIFA Cup · 🥇 1er',
              amountLabel: '25 000 XAF',
              method: 'MTN MoMo',
              checks: _allOk,
              border: ArenaColors.statusOk,
              ctaLabel: '✅ VALIDER · 25 000 XAF',
              ctaSuccess: true,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _PayoutCard(
              initials: 'A',
              color: ArenaAvatarColor.orange,
              name: 'AhmedB',
              meta: 'FIFA Cup · 🥈 2e',
              amountLabel: '12 500 XAF',
              method: 'Orange Money',
              checks: _ahmedChecks,
              border: ArenaColors.neonRed,
              ctaLabel: '⚠ VOIR LE PROBLÈME',
              ctaWarning: true,
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text('MODE BATCH', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            _BatchCard(
              controller: _batchCtrl,
              onChanged: (_) => setState(() {}),
              enabled: _batchEnabled,
            ),
          ],
        ),
      ),
    );
  }
}

enum _PayoutMode { batch, oneByOne }

class _Check {
  const _Check({required this.label, required this.ok});
  final String label;
  final bool ok;
}

const _allOk = <_Check>[
  _Check(label: 'KYC vérifié', ok: true),
  _Check(label: 'Aucun litige ouvert', ok: true),
  _Check(label: "Pas d'alerte anti-cheat", ok: true),
  _Check(label: 'Compte non banni', ok: true),
  _Check(label: 'Numéro MoMo validé', ok: true),
];

const _ahmedChecks = <_Check>[
  _Check(label: 'KYC vérifié', ok: true),
  _Check(label: 'Litige ouvert M-4282', ok: false),
  _Check(label: "Pas d'alerte anti-cheat", ok: true),
  _Check(label: 'Compte non banni', ok: true),
  _Check(label: 'Numéro MoMo validé', ok: true),
];

class _Summary extends StatelessWidget {
  const _Summary({required this.mode, required this.onModeChanged});

  final _PayoutMode mode;
  final ValueChanged<_PayoutMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
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
                  '145 000 XAF',
                  style: ArenaText.bigNumber.copyWith(
                    color: ArenaColors.neonRed,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 2),
                Text('12 payouts pending', style: ArenaText.bodyMuted),
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

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({
    required this.initials,
    required this.color,
    required this.name,
    required this.meta,
    required this.amountLabel,
    required this.method,
    required this.checks,
    required this.border,
    required this.ctaLabel,
    this.ctaSuccess = false,
    this.ctaWarning = false,
  });

  final String initials;
  final ArenaAvatarColor color;
  final String name;
  final String meta;
  final String amountLabel;
  final String method;
  final List<_Check> checks;
  final Color border;
  final String ctaLabel;
  final bool ctaSuccess;
  final bool ctaWarning;

  @override
  Widget build(BuildContext context) {
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
                initials: initials,
                color: color,
                size: ArenaAvatarSize.sm,
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
                  Text(
                    amountLabel,
                    style: ArenaText.mono.copyWith(
                      color: ctaSuccess
                          ? ArenaColors.statusOk
                          : ArenaColors.silver,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(method, style: ArenaText.bodyMuted),
                ],
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text('5 CONTRÔLES AUTO', style: ArenaText.inputLabel),
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
          ArenaButton(
            label: ctaLabel,
            variant: ctaSuccess
                ? ArenaButtonVariant.primary
                : ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.controller,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
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
                const TextSpan(
                  text: 'tape le total à verser pour valider 8 payouts '
                      'éligibles.',
                ),
              ],
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'Total attendu : 105 000 XAF',
            style: ArenaText.inputLabel,
          ),
          const SizedBox(height: ArenaSpacing.xs),
          ArenaTextField(
            controller: controller,
            hint: 'Tape le montant…',
            onChanged: onChanged,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: '🔒 VALIDER 8 PAYOUTS',
            variant: ArenaButtonVariant.danger,
            fullWidth: true,
            onPressed: enabled ? () {} : null,
          ),
        ],
      ),
    );
  }
}
