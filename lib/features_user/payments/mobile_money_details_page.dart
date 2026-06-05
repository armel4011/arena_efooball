import 'dart:io';

import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// PHASE 11bis · P2 — Mobile Money details (paiement P2P manuel).
///
/// L'utilisateur saisit le numéro depuis lequel il va payer puis voit le
/// code marchand de la compétition (saisi par l'admin créateur). Deux
/// actions principales :
///   • **Copier** le code dans le presse-papier
///   • **Exécuter le paiement** — lance `tel:` avec le code USSD
///
/// Une fois le paiement effectué côté Mobile Money, l'utilisateur clique
/// "J'AI PAYÉ" : on INSERT un row `payments(status=awaiting_admin)` puis
/// on navigue vers P3 (page d'attente de validation super-admin).
///
/// Maps to screen P2 of `arena_v2.html`.
class MobileMoneyDetailsPage extends ConsumerStatefulWidget {
  const MobileMoneyDetailsPage({
    required this.method,
    required this.amountXaf,
    required this.competitionId,
    required this.competitionName,
    required this.merchantCode,
    this.dialCode = '+237',
    this.country = '🇨🇲 Cameroun',
    super.key,
  });

  final PaymentMethod method;
  final int amountXaf;
  final String competitionId;
  final String competitionName;

  /// Code marchand Orange Money OU MTN MoMo (selon [method]) saisi par
  /// l'admin créateur lors de la création de la compétition.
  final String merchantCode;
  final String dialCode;
  final String country;

  @override
  ConsumerState<MobileMoneyDetailsPage> createState() =>
      _MobileMoneyDetailsPageState();
}

class _MobileMoneyDetailsPageState
    extends ConsumerState<MobileMoneyDetailsPage> {
  final _phoneCtrl = TextEditingController();
  late final TextEditingController _countryCtrl =
      TextEditingController(text: widget.country);
  bool _submitting = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  bool get _phoneValid => _phoneCtrl.text.replaceAll(' ', '').length == 9;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final method = widget.method;
    final hasCode = widget.merchantCode.trim().isNotEmpty;
    return Scaffold(
      appBar: ArenaAppBar(title: method.label.toUpperCase()),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              _Hero(method: method, amountXaf: widget.amountXaf)
                  .animate()
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.lg),
              if (!hasCode) ...[
                const _MissingCodeBanner(),
                const SizedBox(height: ArenaSpacing.md),
              ] else
                _MerchantCodeCard(
                  method: method,
                  code: widget.merchantCode,
                  onCopy: () => _copyCode(context),
                  onDial: () => _dialPayment(context),
                ),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                l10n.mobileMoneyCountryLabel,
                style: ArenaText.monoSmall.copyWith(
                  color: ArenaColors.silver,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ArenaSpacing.xs),
              ArenaTextField(
                controller: _countryCtrl,
                enabled: false,
              ),
              const SizedBox(height: ArenaSpacing.md),
              Text(
                '${l10n.mobileMoneyNumberLabel}${method.label.toUpperCase()}',
                style: ArenaText.monoSmall.copyWith(
                  color: ArenaColors.silver,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                l10n.mobileMoneyNumberHelp,
                style: ArenaText.small,
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Row(
                children: [
                  _DialBox(label: widget.dialCode),
                  const SizedBox(width: ArenaSpacing.xs),
                  Expanded(
                    child: ArenaTextField(
                      controller: _phoneCtrl,
                      hint: '6 78 45 12 42',
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9 ]')),
                        LengthLimitingTextInputFormatter(13),
                      ],
                    ),
                  ),
                ],
              ),
              if (_phoneValid) ...[
                const SizedBox(height: ArenaSpacing.xs),
                Text(
                  '${l10n.mobileMoneyPhoneValid}${method.label}',
                  style:
                      ArenaText.bodyMuted.copyWith(color: ArenaColors.statusOk),
                ),
              ],
              const SizedBox(height: ArenaSpacing.lg),
              const _Disclaimer().animate(delay: 100.ms).fadeIn(
                    duration: ArenaDurations.medium,
                  ),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: _submitting
                    ? l10n.mobileMoneySubmitSending
                    : '${l10n.mobileMoneySubmitPaid}${_formatXaf(widget.amountXaf)} XAF',
                fullWidth: true,
                size: ArenaButtonSize.large,
                isLoading: _submitting,
                onPressed:
                    (_phoneValid && hasCode && !_submitting) ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.merchantCode));
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.mobileMoneyCodeCopied)),
    );
  }

  Future<void> _dialPayment(BuildContext context) async {
    // Codes USSD MoMo / Orange : `*` doit rester littéral (USSD séparateur),
    // mais `#` doit être encodé `%23` pour ne pas être interprété comme
    // fragment URI par Android — sinon le code arrive coupé dans le
    // composeur (et `%23` apparaît en `23` dans certains dialers).
    final ussd = widget.merchantCode.replaceAll('#', '%23');
    final uri = Uri.parse('tel:$ussd');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mobileMoneyDialerError),
        ),
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final id = await repo.submitManualPayment(
        competitionId: widget.competitionId,
        amountLocal: widget.amountXaf.toDouble(),
        currency: 'XAF',
        payerMethodCode: widget.method.code,
        payerPhone: '${widget.dialCode} ${_phoneCtrl.text.trim()}',
      );
      if (!mounted) return;
      context.go(
        UserRoutes.paymentProcessing,
        extra: PaymentProcessingArgs(
          paymentId: id,
          method: widget.method,
          amountXaf: widget.amountXaf,
          competitionName: widget.competitionName,
          maskedPhone: _maskPhone(_phoneCtrl.text.trim(), widget.dialCode),
        ),
      );
    } on PostgrestException catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.mobileMoneySubmitError}${e.message}')),
      );
    } on SocketException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.mobileMoneyNoConnection}$e')),
      );
    } catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.mobileMoneySubmitError}$e')),
      );
    }
  }
}

String _maskPhone(String raw, String dialCode) {
  final digits = raw.replaceAll(' ', '');
  if (digits.length < 4) return '$dialCode ••';
  final tail = digits.substring(digits.length - 2);
  return '$dialCode ••• •• •• $tail';
}

class _Hero extends StatelessWidget {
  const _Hero({required this.method, required this.amountXaf});

  final PaymentMethod method;
  final int amountXaf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        children: [
          PaymentMethodLogo(method: method, size: 70),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            '${l10n.mobileMoneyHeroPayment}${method.label}',
            style: ArenaText.h3,
          ),
          const SizedBox(height: 2),
          Text(
            '${l10n.mobileMoneyHeroForAmount}${_formatXaf(amountXaf)} XAF',
            style: ArenaText.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _MerchantCodeCard extends StatelessWidget {
  const _MerchantCodeCard({
    required this.method,
    required this.code,
    required this.onCopy,
    required this.onDial,
  });

  final PaymentMethod method;
  final String code;
  final VoidCallback onCopy;
  final VoidCallback onDial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: method.brandColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: method.brandColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📱', style: ArenaText.h3),
              const SizedBox(width: 6),
              Text(l10n.mobileMoneyMerchantCodeTitle, style: ArenaText.h3),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.md,
              vertical: ArenaSpacing.md,
            ),
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              border: Border.all(color: ArenaColors.borderHi),
            ),
            child: SelectableText(
              code,
              textAlign: TextAlign.center,
              style: ArenaText.mono.copyWith(
                fontSize: 22,
                color: method.brandColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: l10n.mobileMoneyCopyButton,
                  variant: ArenaButtonVariant.secondary,
                  onPressed: onCopy,
                ),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: ArenaButton(
                  label: l10n.mobileMoneyExecuteButton,
                  onPressed: onDial,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Compose ce code sur ton ${method.label}, paie le montant '
            'exact, puis reviens ici cliquer "J\'AI PAYÉ".',
            style: ArenaText.small,
          ),
        ],
      ),
    );
  }
}

class _MissingCodeBanner extends StatelessWidget {
  const _MissingCodeBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: arenaDangerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mobileMoneyMissingCodeTitle, style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            l10n.mobileMoneyMissingCodeBody,
            style: ArenaText.body,
          ),
        ],
      ),
    );
  }
}

class _DialBox extends StatelessWidget {
  const _DialBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.borderHi),
      ),
      child: Text(label, style: ArenaText.body),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  static const _items = <String>[
    'Paie le montant EXACT — sinon le super-admin refusera',
    'Garde le SMS de confirmation Mobile Money en preuve',
    "L'admin valide manuellement ton paiement après réception",
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaWarningCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mobileMoneyDisclaimerTitle, style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          for (final i in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: ArenaText.bodyMuted.copyWith(
                      color: ArenaColors.statusWarn,
                    ),
                  ),
                  Expanded(child: Text(i, style: ArenaText.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _formatXaf(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}
