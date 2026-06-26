import 'package:arena/core/services/persistent_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bibliothèque de **jeux de codes de paiement** réutilisables (admin).
///
/// Un jeu = une paire Orange Money + MTN MoMo nommée (les deux sont saisis
/// ensemble dans le wizard et requis ensemble pour une compétition payante).
/// L'admin enregistre ses codes une fois et les réapplique ensuite. Persisté en
/// local via [PersistentCache] (SharedPreferences, namespace
/// `admin.payment_code_templates_v1`) — préférence admin par appareil.

/// Une paire de codes marchands nommée.
class PaymentCodeTemplate {
  const PaymentCodeTemplate({
    required this.name,
    required this.orangeCode,
    required this.mtnCode,
  });

  factory PaymentCodeTemplate.fromJson(Map<String, dynamic> json) =>
      PaymentCodeTemplate(
        name: (json['name'] ?? '').toString(),
        orangeCode: (json['orangeCode'] ?? '').toString(),
        mtnCode: (json['mtnCode'] ?? '').toString(),
      );

  final String name;
  final String orangeCode;
  final String mtnCode;

  Map<String, dynamic> toJson() => {
        'name': name,
        'orangeCode': orangeCode,
        'mtnCode': mtnCode,
      };
}

/// État chargé : les jeux de codes enregistrés par l'admin.
class PaymentCodeTemplates {
  const PaymentCodeTemplates(this.saved);

  final List<PaymentCodeTemplate> saved;

  bool get hasSaved => saved.isNotEmpty;
}

/// Charge / enregistre la bibliothèque de jeux de codes de paiement.
class PaymentCodeTemplatesNotifier
    extends AsyncNotifier<PaymentCodeTemplates> {
  static const _ns = 'admin.payment_code_templates_v1';

  @override
  Future<PaymentCodeTemplates> build() async {
    final cache = await ref.watch(persistentCacheProvider.future);
    final list = cache.readList<PaymentCodeTemplate>(
          _ns,
          PaymentCodeTemplate.fromJson,
        ) ??
        const <PaymentCodeTemplate>[];
    return PaymentCodeTemplates(List.unmodifiable(list));
  }

  Future<void> _persist(List<PaymentCodeTemplate> list) async {
    final cache = await ref.read(persistentCacheProvider.future);
    await cache.writeList<PaymentCodeTemplate>(_ns, list, (t) => t.toJson());
    state = AsyncData(PaymentCodeTemplates(List.unmodifiable(list)));
  }

  /// Ajoute (ou remplace, par nom insensible à la casse) un jeu de codes.
  Future<void> saveTemplate(PaymentCodeTemplate tpl) async {
    final current = [...?state.valueOrNull?.saved];
    final idx = current.indexWhere(
      (t) => t.name.toLowerCase() == tpl.name.toLowerCase(),
    );
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

final paymentCodeTemplatesProvider =
    AsyncNotifierProvider<PaymentCodeTemplatesNotifier, PaymentCodeTemplates>(
  PaymentCodeTemplatesNotifier.new,
);
