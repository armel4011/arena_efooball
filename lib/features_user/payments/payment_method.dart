import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// V1.0 supported mobile-money providers (paiement P2P manuel).
///
/// CinetPay / NowPayments / Wave / Moov / crypto sont reportés en V2.
/// En V1, seuls MTN MoMo et Orange Money sont actifs : le joueur paie
/// directement sur le code marchand affiché en P2 (saisi par l'admin
/// créateur de la compétition), puis le super-admin valide manuellement.
enum PaymentMethod {
  mtnMoMo(
    code: 'MTN_MOMO',
    label: 'MTN Mobile Money',
    badge: 'MTN',
    countriesLine: "Cameroun, Côte d'Ivoire, Bénin",
    brandColor: Color(0xFFFFA500),
    foreground: Colors.white,
  ),
  orangeMoney(
    code: 'ORANGE_MONEY',
    label: 'Orange Money',
    badge: 'OM',
    countriesLine: 'Cameroun, Sénégal, Mali',
    brandColor: Color(0xFFFF6B00),
    foreground: Colors.white,
  );

  const PaymentMethod({
    required this.code,
    required this.label,
    required this.badge,
    required this.countriesLine,
    required this.brandColor,
    required this.foreground,
  });

  final String code;
  final String label;
  final String badge;
  final String countriesLine;
  final Color brandColor;
  final Color foreground;

  static PaymentMethod fromCode(String code) {
    return PaymentMethod.values.firstWhere(
      (m) => m.code == code,
      orElse: () => PaymentMethod.mtnMoMo,
    );
  }
}

/// Square brand-coloured chip with the provider initials. Reusable across
/// the picker, details, processing, success and history screens.
class PaymentMethodLogo extends StatelessWidget {
  const PaymentMethodLogo({
    required this.method,
    this.size = 36,
    super.key,
  });

  final PaymentMethod method;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: method.brandColor,
        borderRadius:
            BorderRadius.circular(size / 4.5),
      ),
      alignment: Alignment.center,
      child: Text(
        method.badge,
        style: ArenaText.h3.copyWith(
          color: method.foreground,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
