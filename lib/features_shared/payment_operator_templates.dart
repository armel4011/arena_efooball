import 'package:arena/core/services/persistent_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modèles réutilisables d'**opérateurs de paiement** (pays + nom
/// d'opérateur + code de transfert) pour l'étape « Pays » du wizard de
/// création de compétition.
///
/// Généralise l'esprit de `payment_codes_templates.dart` (Orange/MTN figés)
/// au nouveau modèle multi-pays / opérateurs libres. Choix : un NOUVEAU
/// provider dédié plutôt que muter l'ancien — l'ancien reste utilisé par le
/// flux legacy (colonnes `orange_money_code` / `mtn_momo_code`) et le muter
/// aurait cassé sa signature à 2 codes. Persisté par appareil via
/// `PersistentCache` (SharedPreferences, namespace
/// `admin.payment_operator_templates_v1`), pas de table serveur.
class PaymentOperatorTemplate {
  const PaymentOperatorTemplate({
    required this.countryCode,
    required this.operatorLabel,
    required this.transferCode,
  });

  factory PaymentOperatorTemplate.fromJson(Map<String, dynamic> json) =>
      PaymentOperatorTemplate(
        countryCode: (json['country'] ?? 'CM').toString(),
        operatorLabel: (json['label'] ?? '').toString(),
        transferCode: (json['code'] ?? '').toString(),
      );

  final String countryCode;
  final String operatorLabel;
  final String transferCode;

  Map<String, dynamic> toJson() => {
        'country': countryCode,
        'label': operatorLabel,
        'code': transferCode,
      };

  /// Clé d'unicité insensible à la casse (un même opérateur dans un même pays
  /// ne s'enregistre qu'une fois).
  String get _key => '${countryCode.toUpperCase()}::${operatorLabel.toLowerCase()}';
}

class PaymentOperatorTemplates {
  const PaymentOperatorTemplates(this.saved);

  final List<PaymentOperatorTemplate> saved;

  bool get hasSaved => saved.isNotEmpty;
}

class PaymentOperatorTemplatesNotifier
    extends AsyncNotifier<PaymentOperatorTemplates> {
  static const _ns = 'admin.payment_operator_templates_v1';

  @override
  Future<PaymentOperatorTemplates> build() async {
    final cache = await ref.watch(persistentCacheProvider.future);
    final list = cache.readList<PaymentOperatorTemplate>(
          _ns,
          PaymentOperatorTemplate.fromJson,
        ) ??
        const <PaymentOperatorTemplate>[];
    return PaymentOperatorTemplates(List.unmodifiable(list));
  }

  Future<void> _persist(List<PaymentOperatorTemplate> list) async {
    final cache = await ref.read(persistentCacheProvider.future);
    await cache.writeList<PaymentOperatorTemplate>(
      _ns,
      list,
      (t) => t.toJson(),
    );
    state = AsyncData(PaymentOperatorTemplates(List.unmodifiable(list)));
  }

  /// Ajoute (ou remplace si même pays + même nom) un opérateur réutilisable.
  Future<void> saveTemplate(PaymentOperatorTemplate tpl) async {
    final current = [...?state.valueOrNull?.saved];
    final idx = current.indexWhere((t) => t._key == tpl._key);
    if (idx >= 0) {
      current[idx] = tpl;
    } else {
      current.add(tpl);
    }
    await _persist(current);
  }

  Future<void> deleteTemplate(PaymentOperatorTemplate tpl) async {
    final current = [...?state.valueOrNull?.saved]
      ..removeWhere((t) => t._key == tpl._key);
    await _persist(current);
  }
}

final paymentOperatorTemplatesProvider = AsyncNotifierProvider<
    PaymentOperatorTemplatesNotifier, PaymentOperatorTemplates>(
  PaymentOperatorTemplatesNotifier.new,
);
