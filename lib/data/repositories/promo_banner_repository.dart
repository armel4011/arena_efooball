import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/data/models/promo_banner.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD sur la table `promo_banner` (espace publicitaire de la home).
///
/// Côté user : [watchActive] alimente la section pub (null = rien à
/// afficher). Côté super-admin : [getCurrent] préremplit l'écran de
/// gestion, [saveActive] publie une nouvelle bannière (en désactivant
/// l'ancienne d'abord — une seule active à la fois), [deactivate] retire
/// la bannière courante de la home.
class PromoBannerRepository {
  const PromoBannerRepository(this._client);

  static const _table = 'promo_banner';

  final SupabaseClient _client;

  /// Realtime stream de la bannière active (ou `null`). Limité à 1 ligne
  /// (index unique partiel garantit l'unicité côté DB).
  Stream<PromoBanner?> watchActive() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .limit(1)
        .map((rows) => rows.isEmpty ? null : PromoBanner.fromJson(rows.first));
  }

  /// Bannière la plus récente (active ou non) — sert à préremplir l'écran
  /// super-admin avec l'état courant.
  Future<PromoBanner?> getCurrent() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('updated_at', ascending: false)
        .limit(1);
    final list = rows as List<dynamic>;
    return list.isEmpty
        ? null
        : PromoBanner.fromJson(list.first as Map<String, dynamic>);
  }

  /// Publie une nouvelle bannière active. Désactive d'abord toute bannière
  /// active existante pour respecter l'index unique partiel, puis insère.
  Future<void> saveActive({
    required String imageUrl,
    required PromoRedirectType redirectType,
    required String redirectTarget,
    String? updatedBy,
  }) async {
    await _client
        .from(_table)
        .update({'is_active': false, 'updated_at': _now()})
        .eq('is_active', true);
    await _client.from(_table).insert({
      'image_url': imageUrl,
      'redirect_type': redirectType.wire,
      'redirect_target': redirectTarget,
      'is_active': true,
      if (updatedBy != null) 'updated_by': updatedBy,
    });
  }

  /// Retire la bannière de la home (toutes les lignes actives passent à
  /// `is_active = false`). L'historique est conservé.
  Future<void> deactivate() async {
    await _client
        .from(_table)
        .update({'is_active': false, 'updated_at': _now()})
        .eq('is_active', true);
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();
}

final promoBannerRepositoryProvider = Provider<PromoBannerRepository>((ref) {
  return PromoBannerRepository(ref.watch(supabaseClientProvider));
});

/// Bannière active de la home — `null` si aucune. Offline-safe : la
/// dernière bannière connue reste affichée hors-ligne (cache disque).
final activePromoBannerProvider =
    StreamProvider.autoDispose<PromoBanner?>((ref) async* {
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydrateSingle<PromoBanner>(
    namespace: 'promo_banner.active',
    source: ref.watch(promoBannerRepositoryProvider).watchActive(),
    fromJson: PromoBanner.fromJson,
    toJson: (b) => b.toJson(),
  );
});

/// État courant de la bannière pour l'écran super-admin (active ou non).
final currentPromoBannerProvider =
    FutureProvider.autoDispose<PromoBanner?>((ref) {
  return ref.watch(promoBannerRepositoryProvider).getCurrent();
});
