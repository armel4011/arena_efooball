import 'package:arena/data/models/competition_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tutorial_video.freezed.dart';
part 'tutorial_video.g.dart';

/// Cible d'une vidéo tutoriel. Les cinq premières valeurs sont des PAGES sur
/// lesquelles s'affiche une bannière (lue en externe) ; les trois dernières
/// sont des contextes IN-APP où la vidéo est jouée directement dans ARENA.
enum TutorialPage {
  /// Page d'accueil utilisateur uniquement.
  @JsonValue('home')
  home,

  /// Liste des compétitions uniquement.
  @JsonValue('competitions')
  competitions,

  /// Page profil de l'utilisateur courant uniquement.
  @JsonValue('profile')
  profile,

  /// Boîte de réception messagerie uniquement.
  @JsonValue('messages')
  messages,

  /// Toutes les pages équipées (home + competitions + profile + messages).
  @JsonValue('all')
  all,

  /// Écran de verrouillage de la salle de match : règles du jeu. Discriminant
  /// [TutorialVideo.game] requis (une vidéo de règles par jeu).
  @JsonValue('match_locked')
  matchLocked,

  /// Étape 1 du match : rôle DOMICILE/EXTÉRIEUR. Football uniquement (les Dames
  /// se jouent in-app, sans rôle). Discriminant [TutorialVideo.game] requis.
  @JsonValue('match_role_intro')
  matchRoleIntro,

  /// Page de paiement : mode d'emploi par pays. Discriminant
  /// [TutorialVideo.countryCode] requis (un système de paiement par pays).
  @JsonValue('payment_tutorial')
  paymentTutorial,
}

/// Valeur "fil" (snake_case) attendue par la colonne `target_page` —
/// `.name` renvoie le camelCase Dart, inutilisable pour l'INSERT brut.
extension TutorialPageWire on TutorialPage {
  String get wire => switch (this) {
        TutorialPage.home => 'home',
        TutorialPage.competitions => 'competitions',
        TutorialPage.profile => 'profile',
        TutorialPage.messages => 'messages',
        TutorialPage.all => 'all',
        TutorialPage.matchLocked => 'match_locked',
        TutorialPage.matchRoleIntro => 'match_role_intro',
        TutorialPage.paymentTutorial => 'payment_tutorial',
      };

  /// Libellé FR pour les écrans admin.
  String get labelFr => switch (this) {
        TutorialPage.home => 'Accueil',
        TutorialPage.competitions => 'Compétitions',
        TutorialPage.profile => 'Profil',
        TutorialPage.messages => 'Messagerie',
        TutorialPage.all => 'Toutes les pages',
        TutorialPage.matchLocked => 'Salle verrouillée (règles du jeu)',
        TutorialPage.matchRoleIntro => 'Intro du rôle (étape 1 du match)',
        TutorialPage.paymentTutorial => 'Tuto paiement (par pays)',
      };

  /// `true` si la vidéo est jouée IN-APP (via `ArenaYoutubePlayer`) plutôt
  /// qu'ouverte en externe comme les bannières de page. Ces cibles exigent
  /// donc un lien YouTube exploitable.
  bool get isInApp => switch (this) {
        TutorialPage.matchLocked ||
        TutorialPage.matchRoleIntro ||
        TutorialPage.paymentTutorial =>
          true,
        _ => false,
      };

  /// `true` si la cible se discrimine par JEU (règles / rôle par jeu).
  bool get needsGame =>
      this == TutorialPage.matchLocked || this == TutorialPage.matchRoleIntro;

  /// `true` si la cible se discrimine par PAYS (un tuto paiement par pays).
  bool get needsCountry => this == TutorialPage.paymentTutorial;
}

/// Jeux proposables pour une cible discriminée par jeu : toutes pour la salle
/// verrouillée (règles), football uniquement pour l'intro de rôle (les Dames
/// n'ont pas de rôle DOMICILE/EXTÉRIEUR). Logique domaine partagée par les
/// formulaires admin mobile et desktop.
List<GameType> gamesForTutorialPage(TutorialPage page) {
  return page == TutorialPage.matchRoleIntro
      ? const [GameType.efootball, GameType.eaSportsFc, GameType.dreamLeague]
      : GameType.values;
}

/// Miroir de la table `tutorial_video`. Sert deux usages :
///  - BANNIÈRES de prise en main (cibles `home`…`all`), lues en EXTERNE ;
///  - vidéos CONTEXTUELLES IN-APP (cibles `match_locked`, `match_role_intro`,
///    `payment_tutorial`), jouées dans ARENA et discriminées par [game] ou
///    [countryCode].
/// La fenêtre d'affichage `displayDays` ne concerne que les bannières.
@Freezed(fromJson: true, toJson: true)
sealed class TutorialVideo with _$TutorialVideo {
  const factory TutorialVideo({
    required String id,
    required String title,
    required String videoUrl,
    @Default(true) bool isActive,
    @Default(7) int displayDays,
    @Default(TutorialPage.home) TutorialPage targetPage,

    /// Jeu ciblé (valeur fil `efootball|draughts|ea_sports_fc`) pour les cibles
    /// `match_locked` / `match_role_intro`. `null` sinon.
    String? game,

    /// Pays ciblé (ISO alpha-2) pour la cible `payment_tutorial`. `null` sinon.
    String? countryCode,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TutorialVideo;

  const TutorialVideo._();

  factory TutorialVideo.fromJson(Map<String, dynamic> json) =>
      _$TutorialVideoFromJson(json);

  /// [game] typé, ou `null` si absent / valeur inconnue (ne retombe PAS sur
  /// eFootball, contrairement à [GameType.fromValue] : ici l'absence est un
  /// état légitime des bannières).
  GameType? get gameType {
    final g = game;
    if (g == null) return null;
    for (final t in GameType.values) {
      if (t.value == g) return t;
    }
    return null;
  }
}
