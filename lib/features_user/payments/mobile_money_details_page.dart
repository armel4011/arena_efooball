import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 11bis · P2 — mobile money details form.
///
/// Once the picker (#P1) returns a mobile-money method we collect the
/// recipient phone number + country dial code. Validation enforces a
/// 9-digit local number and confirms with a green tick. Tap "Payer N
/// XAF" forwards to the [PaymentProcessingPage] — CinetPay's WebView
/// session opens from there.
///
/// Maps to screen P2 of `arena_v2.html`.
class MobileMoneyDetailsPage extends StatefulWidget {
  const MobileMoneyDetailsPage({
    required this.method,
    required this.amountXaf,
    this.dialCode = '+237',
    this.country = '🇨🇲 Cameroun',
    this.onConfirm,
    super.key,
  });

  final PaymentMethod method;
  final int amountXaf;
  final String dialCode;
  final String country;
  final ValueChanged<String>? onConfirm;

  @override
  State<MobileMoneyDetailsPage> createState() =>
      _MobileMoneyDetailsPageState();
}

class _MobileMoneyDetailsPageState extends State<MobileMoneyDetailsPage> {
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isValid => _phoneCtrl.text.replaceAll(' ', '').length == 9;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArenaAppBar(title: widget.method.label),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            _Hero(method: widget.method, amountXaf: widget.amountXaf)
                .animate()
                .fadeIn(duration: ArenaDurations.medium),
            const SizedBox(height: ArenaSpacing.lg),
            Text('Pays', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.xs),
            ArenaTextField(
              controller: TextEditingController(text: widget.country),
              enabled: false,
            ),
            const SizedBox(height: ArenaSpacing.md),
            Text('Numéro Mobile Money', style: ArenaText.inputLabel),
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
            if (_isValid) ...[
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                '✓ Numéro valide ${widget.method.label}',
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
              label: 'PAYER ${_formatXaf(widget.amountXaf)} XAF',
              fullWidth: true,
              size: ArenaButtonSize.large,
              onPressed: _isValid
                  ? () {
                      final phone = _phoneCtrl.text.trim();
                      final cb = widget.onConfirm;
                      if (cb != null) {
                        cb(phone);
                      } else {
                        Navigator.maybePop(context, phone);
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
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
    'Assure-toi du solde + frais opérateur',
    'Tu recevras un SMS de confirmation',
    'Tape ton code PIN dans la pop-up',
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
