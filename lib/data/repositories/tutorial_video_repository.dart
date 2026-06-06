import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD sur la table `tutorial_video` (bannières de prise en main).
///
/// La feature est passée d'UNE bannière active à PLUSIEURS, chacune ciblant
/// une page (`home` / `competitions`) ou toutes (`all`). Côté user, chaque
/// page observe [watchActiveForPage] ; côté super-admin, [watchAll] alimente
/// la liste CRUD. La fenêtre d'affichage par nouvel utilisateur est gérée par
/// bannière via [recordAndGetFirstView].
class TutorialVideoRepository {
  const TutorialVideoRepository(this._client);

  static const _table = 'tutorial_video';

  final SupabaseClient _client;

  /// Filtre pur (testable sans realtime) : conserve les bannières actives
  /// dont la page cible vaut [page] ou `all`, triées par `created_at` croissant.
  static List<TutorialVideo> filterActiveForPage(
    List<TutorialVideo> banners,
    TutorialPage page,
  ) {
    final filtered = banners
        .where(
          (b) =>
              b.isActive &&
              (b.targetPage == page || b.targetPage == TutorialPage.all),
        )
        .toList()
      ..sort((a, b) => _createdAtOf(a).compareTo(_createdAtOf(b)));
    return filtered;
  }

  static DateTime _createdAtOf(TutorialVideo v) =>
      v.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Realtime stream des bannières ACTIVES éligibles pour [page] (inclut les
  /// bannières `all`). On stream toute la table — petite — puis on filtre en
  /// Dart via [filterActiveForPage].
  Stream<List<TutorialVideo>> watchActiveForPage(TutorialPage page) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .map(
          (rows) => filterActiveForPage(
            rows.map(TutorialVideo.fromJson).toList(),
            page,
          ),
        );
  }

  /// Realtime stream de TOUTES les bannières (actives ou non), triées par
  /// `created_at` décroissant — pour l'écran super-admin.
  Stream<List<TutorialVideo>> watchAll() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(TutorialVideo.fromJson).toList());
  }

  /// Crée une nouvelle bannière active.
  Future<void> createBanner({
    required String title,
    required String videoUrl,
    required TutorialPage targetPage,
    required int displayDays,
    String? updatedBy,
  }) async {
    await _client.from(_table).insert({
      'title': title,
      'video_url': videoUrl,
      'target_page': targetPage.wire,
      'is_active': true,
      'display_days': displayDays,
      if (updatedBy != null) 'updated_by': updatedBy,
    });
  }

  /// Met à jour une bannière existante (tous les champs éditables).
  Future<void> updateBanner({
    required String id,
    required String title,
    required String videoUrl,
    required TutorialPage targetPage,
    required int displayDays,
    required bool isActive,
    String? updatedBy,
  }) async {
    await _client.from(_table).update({
      'title': title,
      'video_url': videoUrl,
      'target_page': targetPage.wire,
      'display_days': displayDays,
      'is_active': isActive,
      'updated_at': _now(),
      if (updatedBy != null) 'updated_by': updatedBy,
    }).eq('id', id);
  }

  /// Active / désactive une bannière sans toucher au reste.
  // ignore: avoid_positional_boolean_parameters
  Future<void> setActive(String id, bool isActive) async {
    await _client
        .from(_table)
        .update({'is_active': isActive, 'updated_at': _now()}).eq('id', id);
  }

  /// Supprime définitivement une bannière.
  Future<void> deleteBanner(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Enregistre (si absente) la 1re impression du user courant pour la
  /// bannière [tutorialId] et renvoie l'instant de cette 1re impression —
  /// existant si déjà vue, neuf sinon. Idempotent.
  ///
  /// Délègue à la RPC `tutorial_record_and_get_view` (identité via
  /// `auth.uid()`) qui renvoie un scalaire `timestamptz`. Supabase sérialise
  /// ce scalaire en `String` ISO (ou `null`) ; on parse en [DateTime] (UTC).
  /// Toute valeur inattendue (type imprévu, String non parsable) → `null`.
  Future<DateTime?> recordAndGetFirstView(String tutorialId) async {
    final res = await _client.rpc<dynamic>(
      'tutorial_record_and_get_view',
      params: {'p_tutorial_id': tutorialId},
    );
    if (res == null) return null;
    if (res is DateTime) return res;
    if (res is String) return DateTime.tryParse(res);
    return null;
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();
}

final tutorialVideoRepositoryProvider = Provider<TutorialVideoRepository>((ref) {
  return TutorialVideoRepository(ref.watch(supabaseClientProvider));
});

/// Bannières tutoriel ACTIVES éligibles pour une page donnée (inclut `all`).
final tutorialBannersForPageProvider =
    StreamProvider.family<List<TutorialVideo>, TutorialPage>((ref, page) {
  return ref.watch(tutorialVideoRepositoryProvider).watchActiveForPage(page);
});

/// Toutes les bannières (actives ou non) — pour l'écran super-admin.
final allTutorialBannersProvider =
    StreamProvider.autoDispose<List<TutorialVideo>>((ref) {
  return ref.watch(tutorialVideoRepositoryProvider).watchAll();
});

/// Instant de la 1re impression du user courant pour la bannière `id` —
/// `null` tant qu'on ne sait pas (la RPC enregistre la 1re vue à la volée et
/// renvoie sa date). La fenêtre d'affichage est calculée à partir de cet
/// instant, pas de l'âge du compte.
final tutorialFirstSeenProvider =
    FutureProvider.family<DateTime?, String>((ref, id) {
  return ref.watch(tutorialVideoRepositoryProvider).recordAndGetFirstView(id);
});
