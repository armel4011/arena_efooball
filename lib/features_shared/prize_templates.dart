import 'package:arena/core/services/persistent_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modèles réutilisables de **barème de récompenses** (distribution des prix)
/// pour la création de compétitions.
///
/// Avant : l'admin ressaisissait le barème à CHAQUE compétition. Ici une
/// bibliothèque locale de barèmes nommés (même mécanique que les modèles de
/// description), persistée via `PersistentCache`
/// (namespace `admin.prize_templates_v1`). Stocke le nombre de récompensés +
/// les parts (texte brut des champs) pour réinjection exacte dans le wizard.
class PrizeTemplate {
  const PrizeTemplate({
    required this.name,
    required this.rewardedCount,
    required this.topShares,
    required this.blockShares,
  });

  factory PrizeTemplate.fromJson(Map<String, dynamic> json) {
    List<String> strList(Object? v) => v is List
        ? v.map((e) => e.toString()).toList()
        : const <String>[];
    return PrizeTemplate(
      name: (json['name'] ?? '').toString(),
      rewardedCount: (json['rewarded'] as num?)?.toInt() ?? 4,
      topShares: strList(json['top']),
      blockShares: strList(json['blocks']),
    );
  }

  final String name;

  /// Nombre de places récompensées (1/2/4/8/16/32/64).
  final int rewardedCount;

  /// Parts (texte) des places individuelles 1..4.
  final List<String> topShares;

  /// Parts (texte) par bloc (5-8, 9-16, …) — aligné sur `prizeBlocks`.
  final List<String> blockShares;

  Map<String, dynamic> toJson() => {
        'name': name,
        'rewarded': rewardedCount,
        'top': topShares,
        'blocks': blockShares,
      };

  String get preview {
    final top = topShares.where((s) => s.trim().isNotEmpty).join(' / ');
    return '$rewardedCount récompensés · top : ${top.isEmpty ? '—' : top}';
  }
}

class PrizeTemplates {
  const PrizeTemplates(this.saved);

  final List<PrizeTemplate> saved;

  bool get hasSaved => saved.isNotEmpty;
}

class PrizeTemplatesNotifier extends AsyncNotifier<PrizeTemplates> {
  static const _ns = 'admin.prize_templates_v1';

  @override
  Future<PrizeTemplates> build() async {
    final cache = await ref.watch(persistentCacheProvider.future);
    final list =
        cache.readList<PrizeTemplate>(_ns, PrizeTemplate.fromJson) ??
            const <PrizeTemplate>[];
    return PrizeTemplates(List.unmodifiable(list));
  }

  Future<void> _persist(List<PrizeTemplate> list) async {
    final cache = await ref.read(persistentCacheProvider.future);
    await cache.writeList<PrizeTemplate>(_ns, list, (t) => t.toJson());
    state = AsyncData(PrizeTemplates(List.unmodifiable(list)));
  }

  Future<void> saveTemplate(
    String name,
    int rewardedCount,
    List<String> topShares,
    List<String> blockShares,
  ) async {
    final current = [...?state.valueOrNull?.saved];
    final tpl = PrizeTemplate(
      name: name,
      rewardedCount: rewardedCount,
      topShares: topShares,
      blockShares: blockShares,
    );
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

final prizeTemplatesProvider =
    AsyncNotifierProvider<PrizeTemplatesNotifier, PrizeTemplates>(
  PrizeTemplatesNotifier.new,
);
