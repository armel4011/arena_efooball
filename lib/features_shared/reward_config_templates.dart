import 'package:arena/core/services/persistent_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bibliothèque de **configurations de récompense** réutilisables (admin).
///
/// L'admin enregistre une distribution de prix nommée (nombre de récompensés +
/// parts des places 1-4 + parts par bloc) puis la réapplique dans n'importe
/// quelle compétition. Persistée en local via [PersistentCache]
/// (SharedPreferences, namespace `admin.reward_config_templates_v1`) — préférence
/// purement admin par appareil, pas de table serveur (même choix que
/// `competition_desc_templates`).

/// Une configuration de récompense nommée. On stocke la forme STRUCTURÉE (et
/// non la distribution aplatie) pour un round-trip exact des controllers du
/// wizard (`_topShareCtrls` = 4 places, `_blockShareCtrls` = blocs).
class RewardConfigTemplate {
  const RewardConfigTemplate({
    required this.name,
    required this.rewardedCount,
    required this.topShares,
    required this.blockShares,
  });

  factory RewardConfigTemplate.fromJson(Map<String, dynamic> json) =>
      RewardConfigTemplate(
        name: (json['name'] ?? '').toString(),
        rewardedCount: (json['rewardedCount'] as num?)?.toInt() ?? 4,
        topShares: _intList(json['topShares']),
        blockShares: _intList(json['blockShares']),
      );

  final String name;

  /// Nombre de récompensés (1 / 2 / 4 / 8 / 16 / 32 / 64).
  final int rewardedCount;

  /// Parts des places individuelles 1 à 4.
  final List<int> topShares;

  /// Parts « par place » de chaque bloc (5-8, 9-16, …).
  final List<int> blockShares;

  Map<String, dynamic> toJson() => {
        'name': name,
        'rewardedCount': rewardedCount,
        'topShares': topShares,
        'blockShares': blockShares,
      };

  /// Total distribué (places individuelles + montant de bloc × taille). Sert au
  /// sous-titre de la bibliothèque. [blockSizes] = tailles des blocs (alignées
  /// sur `prizeBlocks`).
  int totalShares(List<int> blockSizes) {
    var total = 0;
    final topCount = rewardedCount < 4 ? rewardedCount : 4;
    for (var i = 0; i < topCount && i < topShares.length; i++) {
      total += topShares[i];
    }
    for (var b = 0; b < blockShares.length && b < blockSizes.length; b++) {
      total += blockShares[b] * blockSizes[b];
    }
    return total;
  }
}

/// jsonDecode peut typer les nombres en `double` → cast défensif via `num`.
List<int> _intList(dynamic v) =>
    v is List ? [for (final e in v) (e as num).toInt()] : const <int>[];

/// État chargé : les configs de récompense enregistrées par l'admin.
class RewardConfigTemplates {
  const RewardConfigTemplates(this.saved);

  final List<RewardConfigTemplate> saved;

  bool get hasSaved => saved.isNotEmpty;
}

/// Charge / enregistre la bibliothèque de configs de récompense.
class RewardConfigTemplatesNotifier
    extends AsyncNotifier<RewardConfigTemplates> {
  static const _ns = 'admin.reward_config_templates_v1';

  @override
  Future<RewardConfigTemplates> build() async {
    final cache = await ref.watch(persistentCacheProvider.future);
    final list = cache.readList<RewardConfigTemplate>(
          _ns,
          RewardConfigTemplate.fromJson,
        ) ??
        const <RewardConfigTemplate>[];
    return RewardConfigTemplates(List.unmodifiable(list));
  }

  Future<void> _persist(List<RewardConfigTemplate> list) async {
    final cache = await ref.read(persistentCacheProvider.future);
    await cache.writeList<RewardConfigTemplate>(_ns, list, (t) => t.toJson());
    state = AsyncData(RewardConfigTemplates(List.unmodifiable(list)));
  }

  /// Ajoute (ou remplace, par nom insensible à la casse) une config nommée.
  Future<void> saveTemplate(RewardConfigTemplate tpl) async {
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

final rewardConfigTemplatesProvider =
    AsyncNotifierProvider<RewardConfigTemplatesNotifier, RewardConfigTemplates>(
  RewardConfigTemplatesNotifier.new,
);
