import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD sur la table `tutorial_video` (bannières de prise en main).
///
/// La feature est passée d'UNE bannière active à PLUSIEURS, chacune ciblant
/// une page (`home` / `competitions`) ou toutes (`all`). Côté user, toutes les
/// pages partagent UNE souscription [watchAllRaw] (filtrée par page en Dart) ;
/// côté super-admin, [watchAll] alimente la liste CRUD. La fenêtre d'affichage
/// par nouvel utilisateur est gérée par bannière via [recordAndGetFirstView].
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

  /// Filtre pur : la vidéo contextuelle IN-APP active pour une cible et son
  /// discriminant. [gameWire] pour `match_locked`/`match_role_intro`,
  /// [countryCode] pour `payment_tutorial`. Retourne `null` si aucune. La DB
  /// garantit l'unicité (index partiel), mais on prend la 1re par sûreté.
  static TutorialVideo? activeContextualVideo(
    List<TutorialVideo> videos,
    TutorialPage target, {
    String? gameWire,
    String? countryCode,
  }) {
    for (final v in videos) {
      if (!v.isActive || v.targetPage != target) continue;
      if (target.needsGame && v.game != gameWire) continue;
      if (target.needsCountry && v.countryCode != countryCode) continue;
      return v;
    }
    return null;
  }

  /// Realtime stream de TOUTES les bannières (brut, actives ou non). UNE seule
  /// souscription partagée par les 4 pages user — le filtrage par page se fait
  /// en Dart côté provider via [filterActiveForPage]. Avant, chaque page
  /// ouvrait son propre canal Realtime sur la même (petite) table : 4 canaux
  /// redondants → 1, ce qui allège chaque rafale de reconnexion/resume.
  Stream<List<TutorialVideo>> watchAllRaw() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(TutorialVideo.fromJson).toList());
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

  /// Récupération ONE-SHOT (REST, sans Realtime) de la vidéo `install_check`
  /// active d'un jeu. Le dialogue de contrôle d'installation est transitoire :
  /// il ne doit PAS dépendre de l'état de la souscription Realtime partagée
  /// (souvent en (re)connexion à l'ouverture, ou n'ayant pas reçu un INSERT
  /// admin récent) — sinon la vidéo « n'apparaît pas » alors qu'elle existe.
  Future<TutorialVideo?> fetchInstallCheckVideo(GameType game) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('target_page', TutorialPage.installCheck.wire)
        .eq('game', game.value)
        .eq('is_active', true)
        .limit(1);
    return rows.isEmpty ? null : TutorialVideo.fromJson(rows.first);
  }

  /// Crée une nouvelle bannière / vidéo contextuelle active. [game] (valeur
  /// fil) et [countryCode] sont les discriminants des cibles contextuelles ;
  /// on écrit toujours les deux (NULL compris) pour respecter le CHECK de
  /// cohérence côté DB — une bannière de page les remet à NULL.
  Future<void> createBanner({
    required String title,
    required String videoUrl,
    required TutorialPage targetPage,
    required int displayDays,
    String? game,
    String? countryCode,
    String? updatedBy,
  }) async {
    await _client.from(_table).insert({
      'title': title,
      'video_url': videoUrl,
      'target_page': targetPage.wire,
      'is_active': true,
      'display_days': displayDays,
      'game': game,
      'country_code': countryCode,
      if (updatedBy != null) 'updated_by': updatedBy,
    });
  }

  /// Met à jour une bannière / vidéo contextuelle (tous les champs éditables).
  /// [game] / [countryCode] sont réécrits (NULL compris) pour rester cohérents
  /// avec la cible si celle-ci a changé.
  Future<void> updateBanner({
    required String id,
    required String title,
    required String videoUrl,
    required TutorialPage targetPage,
    required int displayDays,
    required bool isActive,
    String? game,
    String? countryCode,
    String? updatedBy,
  }) async {
    await _client.from(_table).update({
      'title': title,
      'video_url': videoUrl,
      'target_page': targetPage.wire,
      'display_days': displayDays,
      'is_active': isActive,
      'game': game,
      'country_code': countryCode,
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

/// Source unique : stream brut de toute la table `tutorial_video`. Une seule
/// souscription Realtime partagée par les 4 pages (vs 1 canal/page avant), ce
/// qui réduit le nombre de canaux ouverts et la pression sur la limite de taux
/// de jointures Supabase (`ChannelRateLimitReached`). `autoDispose` : le canal
/// se ferme dès que plus aucune page ne l'observe (logout, app fermée).
final _allTutorialBannersStreamProvider =
    StreamProvider.autoDispose<List<TutorialVideo>>((ref) {
  return ref.watch(tutorialVideoRepositoryProvider).watchAllRaw();
});

/// Bannières tutoriel ACTIVES éligibles pour une page donnée (inclut `all`).
/// Dérivé en Dart de [_allTutorialBannersStreamProvider] : n'ouvre PAS de canal
/// Realtime propre, il filtre la source partagée. Conserve un type
/// `AsyncValue` pour ne rien changer côté consommateur (`.valueOrNull`).
final tutorialBannersForPageProvider = Provider.autoDispose
    .family<AsyncValue<List<TutorialVideo>>, TutorialPage>((ref, page) {
  return ref.watch(_allTutorialBannersStreamProvider).whenData(
        (all) => TutorialVideoRepository.filterActiveForPage(all, page),
      );
});

/// Toutes les bannières (actives ou non) — pour l'écran super-admin.
final allTutorialBannersProvider =
    StreamProvider.autoDispose<List<TutorialVideo>>((ref) {
  return ref.watch(tutorialVideoRepositoryProvider).watchAll();
});

/// Vidéo IN-APP active de l'écran de verrouillage de salle, pour un [GameType].
/// Dérivée du stream partagé : n'ouvre PAS de canal Realtime propre.
final matchLockedVideoProvider = Provider.autoDispose
    .family<AsyncValue<TutorialVideo?>, GameType>((ref, game) {
  return ref.watch(_allTutorialBannersStreamProvider).whenData(
        (all) => TutorialVideoRepository.activeContextualVideo(
          all,
          TutorialPage.matchLocked,
          gameWire: game.value,
        ),
      );
});

/// Vidéo IN-APP active de l'intro de rôle (étape 1), pour un [GameType]
/// (football uniquement). Dérivée du stream partagé.
final matchRoleIntroVideoProvider = Provider.autoDispose
    .family<AsyncValue<TutorialVideo?>, GameType>((ref, game) {
  return ref.watch(_allTutorialBannersStreamProvider).whenData(
        (all) => TutorialVideoRepository.activeContextualVideo(
          all,
          TutorialPage.matchRoleIntro,
          gameWire: game.value,
        ),
      );
});

/// Vidéo IN-APP active du dialogue de contrôle d'installation (avant
/// inscription), pour un [GameType] externe. Dérivée du stream partagé.
final installCheckVideoProvider = Provider.autoDispose
    .family<AsyncValue<TutorialVideo?>, GameType>((ref, game) {
  return ref.watch(_allTutorialBannersStreamProvider).whenData(
        (all) => TutorialVideoRepository.activeContextualVideo(
          all,
          TutorialPage.installCheck,
          gameWire: game.value,
        ),
      );
});

/// Variante ONE-SHOT (REST) de [installCheckVideoProvider], utilisée par le
/// dialogue d'inscription. Fiable même quand la souscription Realtime partagée
/// n'a pas encore émis / n'a pas reçu un INSERT admin récent. Le dialogue est
/// transitoire → aucune mise à jour live nécessaire.
final installCheckVideoOnceProvider = FutureProvider.autoDispose
    .family<TutorialVideo?, GameType>((ref, game) {
  return ref.watch(tutorialVideoRepositoryProvider).fetchInstallCheckVideo(game);
});

/// Vidéo IN-APP active du tuto paiement, pour un pays (ISO alpha-2). Dérivée
/// du stream partagé.
final paymentTutorialVideoProvider = Provider.autoDispose
    .family<AsyncValue<TutorialVideo?>, String>((ref, countryCode) {
  return ref.watch(_allTutorialBannersStreamProvider).whenData(
        (all) => TutorialVideoRepository.activeContextualVideo(
          all,
          TutorialPage.paymentTutorial,
          countryCode: countryCode,
        ),
      );
});

/// Instant de la 1re impression du user courant pour la bannière `id` —
/// `null` tant qu'on ne sait pas (la RPC enregistre la 1re vue à la volée et
/// renvoie sa date). La fenêtre d'affichage est calculée à partir de cet
/// instant, pas de l'âge du compte.
final tutorialFirstSeenProvider =
    FutureProvider.family<DateTime?, String>((ref, id) {
  return ref.watch(tutorialVideoRepositoryProvider).recordAndGetFirstView(id);
});
