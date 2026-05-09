import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Catalog of supported payment methods for V1.0.
///
/// Mobile money providers route through CinetPay (PHASE 11bis); crypto
/// goes via NowPayments. Each entry carries the brand colour, label and
/// a short context line so the picker UI can stay declarative.
enum PaymentMethod {
  mtnMoMo(
    code: 'MTN_MOMO',
    label: 'MTN Mobile Money',
    badge: 'MTN',
    countriesLine: "Cameroun, Côte d'Ivoire, Bénin",
    brandColor: Color(0xFFFFA500),
    foreground: Colors.white,
    family: PaymentFamily.mobileMoney,
  ),
  orangeMoney(
    code: 'ORANGE_MONEY',
    label: 'Orange Money',
    badge: 'OM',
    countriesLine: 'Cameroun, Sénégal, Mali',
    brandColor: Color(0xFFFF6B00),
    foreground: Colors.white,
    family: PaymentFamily.mobileMoney,
  ),
  wave(
    code: 'WAVE',
    label: 'Wave',
    badge: 'W',
    countriesLine: "Sénégal, Côte d'Ivoire",
    brandColor: Color(0xFF0066CC),
    foreground: Colors.white,
    family: PaymentFamily.mobileMoney,
  ),
  moovMoney(
    code: 'MOOV_MONEY',
    label: 'Moov Money',
    badge: 'M',
    countriesLine: 'Bénin, Togo, Burkina',
    brandColor: Color(0xFF003DA5),
    foreground: Colors.white,
    family: PaymentFamily.mobileMoney,
  ),
  usdt(
    code: 'USDT_TRC20',
    label: 'USDT (TRC20)',
    badge: '₮',
    countriesLine: 'Stablecoin · réseau Tron',
    brandColor: Color(0xFF26A17B),
    foreground: Colors.white,
    family: PaymentFamily.crypto,
  ),
  bitcoin(
    code: 'BITCOIN',
    label: 'Bitcoin',
    badge: '₿',
    countriesLine: 'Réseau lightning supporté',
    brandColor: Color(0xFFF7931A),
    foreground: Colors.white,
    family: PaymentFamily.crypto,
  );

  const PaymentMethod({
    required this.code,
    required this.label,
    required this.badge,
    required this.countriesLine,
    required this.brandColor,
    required this.foreground,
    required this.family,
  });

  final String code;
  final String label;
  final String badge;
  final String countriesLine;
  final Color brandColor;
  final Color foreground;
  final PaymentFamily family;
}

enum PaymentFamily { mobileMoney, crypto }

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
