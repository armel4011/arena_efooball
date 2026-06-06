import 'package:freezed_annotation/freezed_annotation.dart';

part 'tutorial_video.freezed.dart';
part 'tutorial_video.g.dart';

/// Miroir de la table `tutorial_video`. Une seule vidéo tutoriel est active
/// à la fois côté produit (cf. index unique partiel + repo).
@Freezed(fromJson: true, toJson: true)
sealed class TutorialVideo with _$TutorialVideo {
  const factory TutorialVideo({
    required String id,
    required String title,
    required String videoUrl,
    @Default(true) bool isActive,
    @Default(7) int displayDays,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TutorialVideo;

  factory TutorialVideo.fromJson(Map<String, dynamic> json) =>
      _$TutorialVideoFromJson(json);
}
