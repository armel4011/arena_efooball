import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PHASE 11bis · P3 — payment processor receipt + countdown.
///
/// Real flow lands inside a CinetPay/NowPayments WebView; this Flutter
/// page renders the same visual but locally so QA + designers can
/// validate the layout. The 90-second countdown matches CinetPay's
/// MoMo confirmation window. Tap CONFIRMER MAINTENANT routes to
/// [PaymentSuccessPage]; "Annuler" pops back.
///
/// Maps to screen P3 of `arena_v2.html`.
class PaymentProcessingPage extends StatefulWidget {
  const PaymentProcessingPage({
    required this.method,
    required this.amountXaf,
    required this.reference,
    required this.maskedPhone,
    this.beneficiary = 'ARENA SAS',
    this.onConfirm,
    this.onCancel,
    super.key,
  });

  final PaymentMethod method;
  final int amountXaf;
  final String reference;
  final String maskedPhone;
  final String beneficiary;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  static const _windowSec = 90;
  late Timer _ticker;
  int _remaining = _windowSec;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) _remaining--;
      });
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  String get _countdown {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.method.brandColor;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _ProcessorBar(
            method: widget.method,
            onClose:
                widget.onCancel ?? () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              children: [
                Center(
                  child: Column(
                    children: [
                      PaymentMethodLogo(method: widget.method, size: 60),
                      const SizedBox(height: ArenaSpacing.sm),
                      Text(
                        'Confirmer le paiement',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ArenaSpacing.lg),
                _Receipt(
                  method: widget.method,
                  amountXaf: widget.amountXaf,
                  beneficiary: widget.beneficiary,
                  reference: widget.reference,
                  maskedPhone: widget.maskedPhone,
                ),
                const SizedBox(height: ArenaSpacing.md),
                Text(
                  '📱 Tu vas recevoir un SMS ${widget.method.label}.\n'
                  'Confirme avec ton code PIN.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF666666),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.lg),
                Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(accent),
                      backgroundColor: const Color(0xFFF5F5F0),
                    ),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                Center(
                  child: Text(
                    'En attente · $_countdown',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF999999),
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.lg),
                _ConfirmButton(
                  color: accent,
                  onTap: widget.onConfirm ??
                      () => Navigator.maybePop(context, true),
                ),
                const SizedBox(height: ArenaSpacing.xs),
                TextButton(
                  onPressed: widget.onCancel ??
                      () => Navigator.maybePop(context, false),
                  child: Text(
                    'Annuler la transaction',
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF999999),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessorBar extends StatelessWidget {
  const _ProcessorBar({required this.method, required this.onClose});

  final PaymentMethod method;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final processor = method.family == PaymentFamily.crypto
        ? 'NowPayments'
        : 'CinetPay';
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.lg,
          vertical: ArenaSpacing.md,
        ),
        color: method.brandColor,
        child: Row(
          children: [
            InkWell(
              onTap: onClose,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Text(
                '$processor · ${method.label}',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '🔒 SSL',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({
    required this.method,
    required this.amountXaf,
    required this.beneficiary,
    required this.reference,
    required this.maskedPhone,
  });

  final PaymentMethod method;
  final int amountXaf;
  final String beneficiary;
  final String reference;
  final String maskedPhone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _Row(label: 'Bénéficiaire', value: beneficiary),
          const SizedBox(height: 4),
          _Row(label: 'Référence', value: reference, mono: true),
          const SizedBox(height: 4),
          _Row(label: 'Numéro', value: maskedPhone),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: ArenaSpacing.sm),
            child: Divider(color: Color(0xFFDDDDDD), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                '${_formatXaf(amountXaf)} XAF',
                style: GoogleFonts.spaceGrotesk(
                  color: method.brandColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            color: const Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: (mono ? GoogleFonts.jetBrainsMono : GoogleFonts.spaceGrotesk)(
            fontSize: 11,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Use a raw button — this whole page mocks an external WebView
    // (CinetPay), so we intentionally bypass ArenaButton to keep the
    // styling on-brand for the processor.
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(ArenaRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ArenaRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              'CONFIRMER MAINTENANT',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
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
