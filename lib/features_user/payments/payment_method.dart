import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_payment_option.dart';
import 'package:flutter/material.dart';

/// Opérateur de paiement Mobile Money **libre** (paiement P2P manuel).
///
/// Remplace l'ancien enum `PaymentMethod` figé sur MTN / Orange : l'admin
/// créateur d'une compétition définit désormais librement ses opérateurs
/// (Orange Money, MTN MoMo, Wave, Moov, Free Money…) par pays via
/// `competition_payment_options`. Le joueur choisit son pays puis un
/// opérateur de ce pays, et voit le code de transfert associé.
///
/// Les 2 opérateurs historiques gardent leurs slugs canoniques
/// (`MTN_MOMO` / `ORANGE_MONEY`) et leur couleur de marque ; les autres
/// dérivent un slug MAJUSCULE depuis le label et une couleur neutre du
/// design system.
@immutable
class PaymentOperator {
  const PaymentOperator({
    required this.label,
    required this.code,
    required this.countryCode,
    this.transferCode,
    this.dialCode,
    this.paymentNumber,
  });

  /// Reconstruit un opérateur depuis une option de paiement compétition.
  factory PaymentOperator.fromOption(CompetitionPaymentOption o) {
    return PaymentOperator(
      label: o.operatorLabel,
      code: slugForLabel(o.operatorLabel),
      transferCode: o.transferCode,
      countryCode: o.countryCode,
      dialCode: o.dialCode,
      paymentNumber: o.paymentNumber,
    );
  }

  /// Reconstruit l'affichage d'un opérateur depuis son slug persisté (ex.
  /// pour l'historique paiements). [label] restaure le libellé exact saisi
  /// par l'admin ; à défaut on dérive un label lisible du code.
  factory PaymentOperator.fromCode(String code, {String? label}) {
    final hasLabel = label != null && label.trim().isNotEmpty;
    return PaymentOperator(
      label: hasLabel ? label.trim() : readableFromCode(code),
      code: code,
      countryCode: '',
    );
  }

  /// Libellé affiché (ex. "Orange Money", "Wave"). Vient du champ
  /// `operator_label` saisi par l'admin.
  final String label;

  /// Slug technique persisté dans `payments.payer_method` (ex.
  /// `ORANGE_MONEY`, `MTN_MOMO`, `WAVE`).
  final String code;

  /// Code de transfert Mobile Money à composer (peut être null si
  /// l'admin ne l'a pas encore configuré).
  final String? transferCode;

  /// ISO 3166-1 alpha-2 du pays de l'opérateur.
  final String countryCode;

  /// Indicatif E.164 (ex. `+237`). Repli sur `dialCodeFor(countryCode)`.
  final String? dialCode;

  /// Numéro destinataire du paiement (à copier par le joueur, zone CEMAC).
  final String? paymentNumber;

  /// Initiales dérivées du label (1–3 lettres majuscules) pour le logo.
  String get badge {
    if (code == 'MTN_MOMO') return 'MTN';
    if (code == 'ORANGE_MONEY') return 'OM';
    final words = label
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length >= 2) {
      return words.take(3).map((w) => w[0].toUpperCase()).join();
    }
    final single = words.first;
    return single.substring(0, single.length >= 3 ? 3 : single.length).toUpperCase();
  }

  /// Couleur de marque : MTN / Orange conservent leur token dédié ; les
  /// opérateurs libres retombent sur une couleur neutre du design system.
  Color get brandColor {
    if (code == 'MTN_MOMO') return ArenaColors.brandMtnMomo;
    if (code == 'ORANGE_MONEY') return ArenaColors.brandOrangeMoney;
    return ArenaColors.signalBlue;
  }

  /// Couleur de texte sur le badge coloré.
  Color get foreground => ArenaColors.bone;

  /// Dérive un slug MAJUSCULE depuis un libellé libre. Les 2 opérateurs
  /// connus gardent leur slug canonique ; sinon "Wave" → "WAVE",
  /// "Free Money" → "FREE_MONEY".
  static String slugForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('mtn')) return 'MTN_MOMO';
    if (l.contains('orange')) return 'ORANGE_MONEY';
    final slug = label
        .toUpperCase()
        .replaceAll(RegExp('[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'OPERATOR' : slug;
  }

  /// Repli lisible d'un slug (ex. `FREE_MONEY` → "Free Money").
  static String readableFromCode(String code) {
    switch (code) {
      case 'MTN_MOMO':
        return 'MTN MoMo';
      case 'ORANGE_MONEY':
        return 'Orange Money';
      default:
        final words = code
            .split('_')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase());
        final joined = words.join(' ');
        return joined.isEmpty ? code : joined;
    }
  }
}

/// Carré coloré aux initiales de l'opérateur. Réutilisé par le picker (P1),
/// les détails (P2), l'attente (P3), le succès (P4) et l'historique.
class PaymentOperatorLogo extends StatelessWidget {
  const PaymentOperatorLogo({
    required this.operator,
    this.size = 36,
    super.key,
  });

  final PaymentOperator operator;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: operator.brandColor,
        borderRadius: BorderRadius.circular(size / 4.5),
      ),
      alignment: Alignment.center,
      child: Text(
        operator.badge,
        style: ArenaText.h3.copyWith(
          color: operator.foreground,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
