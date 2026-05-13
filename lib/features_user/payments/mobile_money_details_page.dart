import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _submitting = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _phoneValid => _phoneCtrl.text.replaceAll(' ', '').length == 9;

  @override
  Widget build(BuildContext context) {
    final method = widget.method;
    final hasCode = widget.merchantCode.trim().isNotEmpty;
    return Scaffold(
      appBar: ArenaAppBar(title: method.label),
      body: SafeArea(
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
            Text('Pays', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.xs),
            ArenaTextField(
              controller: TextEditingController(text: widget.country),
              enabled: false,
            ),
            const SizedBox(height: ArenaSpacing.md),
            Text(
              'Ton numéro ${method.label}',
              style: ArenaText.inputLabel,
            ),
            const SizedBox(height: ArenaSpacing.xs),
            Text(
              'Le numéro depuis lequel tu vas payer (utile au super-admin '
              'pour retrouver ta transaction).',
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
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                      LengthLimitingTextInputFormatter(13),
                    ],
                  ),
                ),
              ],
            ),
            if (_phoneValid) ...[
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                '✓ Numéro valide ${method.label}',
                style: ArenaText.bodyMuted
                    .copyWith(color: ArenaColors.statusOk),
              ),
            ],
            const SizedBox(height: ArenaSpacing.lg),
            const _Disclaimer().animate(delay: 100.ms).fadeIn(
                  duration: ArenaDurations.medium,
                ),
            const SizedBox(height: ArenaSpacing.xl),
            ArenaButton(
              label: _submitting
                  ? 'ENVOI…'
                  : "J'AI PAYÉ ${_formatXaf(widget.amountXaf)} XAF",
              fullWidth: true,
              size: ArenaButtonSize.large,
              isLoading: _submitting,
              onPressed: (_phoneValid && hasCode && !_submitting)
                  ? _submit
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.merchantCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code marchand copié.')),
    );
  }

  Future<void> _dialPayment(BuildContext context) async {
    // Sur la plupart des opérateurs MoMo / Orange en Afrique francophone,
    // le code marchand est un short-code à envoyer directement par dial,
    // ex. *126*1*MERCHANT*AMOUNT#. On laisse le joueur compléter dans
    // l'app dialer — pré-remplir n'est pas standard d'un opérateur à
    // l'autre.
    final uri = Uri.parse('tel:${widget.merchantCode}');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'ouvrir le composeur. Copie le code."),
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi : $e')),
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
    return Center(
      child: Column(
        children: [
          PaymentMethodLogo(method: method, size: 70),
          const SizedBox(height: ArenaSpacing.sm),
          Text('Paiement ${method.label}', style: ArenaText.h3),
          const SizedBox(height: 2),
          Text('Pour ${_formatXaf(amountXaf)} XAF',
              style: ArenaText.bodyMuted),
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
              Text('Code marchand', style: ArenaText.h3),
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
                  label: '📋 COPIER',
                  variant: ArenaButtonVariant.secondary,
                  onPressed: onCopy,
                ),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: ArenaButton(
                  label: '📞 EXÉCUTER',
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
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: arenaDangerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠ Code marchand manquant', style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            "L'admin n'a pas encore configuré de code marchand pour "
            'cette méthode sur cette compétition. Choisis une autre '
            'méthode ou contacte le support.',
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
    'Tu as 15 min après "J\'AI PAYÉ" pour la validation',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaWarningCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠ Avant de continuer', style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          for (final i in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ',
                      style: ArenaText.bodyMuted.copyWith(
                        color: ArenaColors.statusWarn,
                      )),
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
