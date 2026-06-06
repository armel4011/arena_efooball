import 'package:freezed_annotation/freezed_annotation.dart';

part 'tutorial_video.freezed.dart';
part 'tutorial_video.g.dart';

/// Page de l'app sur laquelle une bannière tutoriel doit s'afficher.
enum TutorialPage {
  /// Page d'accueil utilisateur uniquement.
  @JsonValue('home')
  home,

  /// Liste des compétitions uniquement.
  @JsonValue('competitions')
  competitions,

  /// Toutes les pages équipées (home + competitions).
  @JsonValue('all')
  all,
}

/// Valeur "fil" (snake_case) attendue par la colonne `target_page` —
/// `.name` renvoie le camelCase Dart, inutilisable pour l'INSERT brut.
extension TutorialPageWire on TutorialPage {
  String get wire => switch (this) {
        TutorialPage.home => 'home',
        TutorialPage.competitions => 'competitions',
        TutorialPage.all => 'all',
      };

  /// Libellé FR pour l'écran super-admin.
  String get labelFr => switch (this) {
        TutorialPage.home => 'Accueil',
        TutorialPage.competitions => 'Compétitions',
        TutorialPage.all => 'Toutes les pages',
      };
}

/// Miroir de la table `tutorial_video`. Plusieurs bannières peuvent être
/// actives à la fois, chacune ciblant une page (`home` / `competitions`)
/// ou toutes (`all`). La fenêtre d'affichage par nouvel utilisateur est
/// gérée par bannière (cf. `tutorial_video_views` + RPC).
@Freezed(fromJson: true, toJson: true)
sealed class TutorialVideo with _$TutorialVideo {
  const factory TutorialVideo({
    required String id,
    required String title,
    required String videoUrl,
    @Default(true) bool isActive,
    @Default(7) int displayDays,
    @Default(TutorialPage.home) TutorialPage targetPage,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TutorialVideo;

  factory TutorialVideo.fromJson(Map<String, dynamic> json) =>
      _$TutorialVideoFromJson(json);
}
