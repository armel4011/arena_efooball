import 'package:arena/core/services/persistent_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modèles réutilisables de **codes de paiement** (Orange Money / MTN MoMo)
/// pour la création de compétitions payantes.
///
/// Avant : l'admin ressaisissait les numéros marchands à CHAQUE compétition.
/// Ici une bibliothèque locale de jeux de codes nommés (même mécanique que les
/// modèles de description), persistée via `PersistentCache` (SharedPreferences,
/// namespace `admin.payment_codes_templates_v1`). Préférence purement admin,
/// par appareil — pas de table serveur.
class PaymentCodesTemplate {
  const PaymentCodesTemplate({
    required this.name,
    required this.orangeCode,
    required this.mtnCode,
  });

  factory PaymentCodesTemplate.fromJson(Map<String, dynamic> json) =>
      PaymentCodesTemplate(
        name: (json['name'] ?? '').toString(),
        orangeCode: (json['orange'] ?? '').toString(),
        mtnCode: (json['mtn'] ?? '').toString(),
      );

  final String name;
  final String orangeCode;
  final String mtnCode;

  Map<String, dynamic> toJson() =>
      {'name': name, 'orange': orangeCode, 'mtn': mtnCode};

  /// Aperçu une ligne pour la bibliothèque.
  String get preview =>
      'Orange : ${orangeCode.isEmpty ? '—' : orangeCode}  ·  '
      'MTN : ${mtnCode.isEmpty ? '—' : mtnCode}';
}

class PaymentCodesTemplates {
  const PaymentCodesTemplates(this.saved);

  final List<PaymentCodesTemplate> saved;

  bool get hasSaved => saved.isNotEmpty;
}

class PaymentCodesTemplatesNotifier
    extends AsyncNotifier<PaymentCodesTemplates> {
  static const _ns = 'admin.payment_codes_templates_v1';

  @override
  Future<PaymentCodesTemplates> build() async {
    final cache = await ref.watch(persistentCacheProvider.future);
    final list = cache.readList<PaymentCodesTemplate>(
          _ns,
          PaymentCodesTemplate.fromJson,
        ) ??
        const <PaymentCodesTemplate>[];
    return PaymentCodesTemplates(List.unmodifiable(list));
  }

  Future<void> _persist(List<PaymentCodesTemplate> list) async {
    final cache = await ref.read(persistentCacheProvider.future);
    await cache.writeList<PaymentCodesTemplate>(_ns, list, (t) => t.toJson());
    state = AsyncData(PaymentCodesTemplates(List.unmodifiable(list)));
  }

  /// Ajoute (ou remplace si même nom, insensible à la casse) un jeu de codes.
  Future<void> saveTemplate(String name, String orange, String mtn) async {
    final current = [...?state.valueOrNull?.saved];
    final tpl =
        PaymentCodesTemplate(name: name, orangeCode: orange, mtnCode: mtn);
    final idx =
        current.indexWhere((t) => t.name.toLowerCase() == name.toLowerCase());
    if (idx >= 0) {
      current[idx] = tpl;
    } else {
      current.add(tpl);
    }
    await _persist(current);
  }

  Future<void> deleteTemplate(String name) async {
    final current = [...?state.valueOrNull?.saved]
      ..removeWhere((t) => t.name == name);
    await _persist(current);
  }
}

final paymentCodesTemplatesProvider = AsyncNotifierProvider<
    PaymentCodesTemplatesNotifier, PaymentCodesTemplates>(
  PaymentCodesTemplatesNotifier.new,
);
