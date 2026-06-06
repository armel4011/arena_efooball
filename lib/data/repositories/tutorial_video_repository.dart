import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD sur la table `tutorial_video` (vidéo de prise en main de la home).
///
/// Côté user : [watchActive] alimente la section tutoriel (null = rien à
/// afficher). Côté super-admin : [getCurrent] préremplit l'écran de
/// gestion, [saveActive] publie une nouvelle vidéo (en désactivant
/// l'ancienne d'abord — une seule active à la fois), [deactivate] retire
/// la vidéo courante de la home.
class TutorialVideoRepository {
  const TutorialVideoRepository(this._client);

  static const _table = 'tutorial_video';

  final SupabaseClient _client;

  /// Realtime stream de la vidéo active (ou `null`). Limité à 1 ligne
  /// (index unique partiel garantit l'unicité côté DB).
  Stream<TutorialVideo?> watchActive() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .limit(1)
        .map(
          (rows) => rows.isEmpty ? null : TutorialVideo.fromJson(rows.first),
        );
  }

  /// Vidéo la plus récente (active ou non) — sert à préremplir l'écran
  /// super-admin avec l'état courant.
  Future<TutorialVideo?> getCurrent() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('updated_at', ascending: false)
        .limit(1);
    final list = rows as List<dynamic>;
    return list.isEmpty
        ? null
        : TutorialVideo.fromJson(list.first as Map<String, dynamic>);
  }

  /// Publie une nouvelle vidéo active. Désactive d'abord toute vidéo active
  /// existante pour respecter l'index unique partiel, puis insère.
  Future<void> saveActive({
    required String title,
    required String videoUrl,
    String? updatedBy,
  }) async {
    await _client
        .from(_table)
        .update({'is_active': false, 'updated_at': _now()})
        .eq('is_active', true);
    await _client.from(_table).insert({
      'title': title,
      'video_url': videoUrl,
      'is_active': true,
      if (updatedBy != null) 'updated_by': updatedBy,
    });
  }

  /// Retire la vidéo de la home (toutes les lignes actives passent à
  /// `is_active = false`). L'historique est conservé.
  Future<void> deactivate() async {
    await _client
        .from(_table)
        .update({'is_active': false, 'updated_at': _now()})
        .eq('is_active', true);
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();
}

final tutorialVideoRepositoryProvider = Provider<TutorialVideoRepository>((ref) {
  return TutorialVideoRepository(ref.watch(supabaseClientProvider));
});

/// Vidéo tutoriel active de la home — `null` si aucune. Offline-safe : la
/// dernière vidéo connue reste affichée hors-ligne (cache disque).
final activeTutorialVideoProvider =
    StreamProvider.autoDispose<TutorialVideo?>((ref) async* {
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydrateSingle<TutorialVideo>(
    namespace: 'tutorial_video.active',
    source: ref.watch(tutorialVideoRepositoryProvider).watchActive(),
    fromJson: TutorialVideo.fromJson,
    toJson: (v) => v.toJson(),
  );
});

/// État courant de la vidéo pour l'écran super-admin (active ou non).
final currentTutorialVideoProvider =
    FutureProvider.autoDispose<TutorialVideo?>((ref) {
  return ref.watch(tutorialVideoRepositoryProvider).getCurrent();
});
