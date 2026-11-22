// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutorial_video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TutorialVideo _$TutorialVideoFromJson(Map<String, dynamic> json) =>
    _TutorialVideo(
      id: json['id'] as String,
      title: json['title'] as String,
      videoUrl: json['video_url'] as String,
      isActive: json['is_active'] as bool? ?? true,
      displayDays: (json['display_days'] as num?)?.toInt() ?? 7,
      targetPage:
          $enumDecodeNullable(_$TutorialPageEnumMap, json['target_page']) ??
          TutorialPage.home,
      game: json['game'] as String?,
      countryCode: json['country_code'] as String?,
      operatorCode: json['operator_code'] as String?,
      roleSide: json['role_side'] as String?,
      locale: json['locale'] as String?,
      updatedBy: json['updated_by'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TutorialVideoToJson(_TutorialVideo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'video_url': instance.videoUrl,
      'is_active': instance.isActive,
      'display_days': instance.displayDays,
      'target_page': _$TutorialPageEnumMap[instance.targetPage]!,
      'game': ?instance.game,
      'country_code': ?instance.countryCode,
      'operator_code': ?instance.operatorCode,
      'role_side': ?instance.roleSide,
      'locale': ?instance.locale,
      'updated_by': ?instance.updatedBy,
      'created_at': ?instance.createdAt?.toIso8601String(),
      'updated_at': ?instance.updatedAt?.toIso8601String(),
    };

const _$TutorialPageEnumMap = {
  TutorialPage.home: 'home',
  TutorialPage.competitions: 'competitions',
  TutorialPage.profile: 'profile',
  TutorialPage.messages: 'messages',
  TutorialPage.all: 'all',
  TutorialPage.matchLocked: 'match_locked',
  TutorialPage.matchRoleIntro: 'match_role_intro',
  TutorialPage.paymentTutorial: 'payment_tutorial',
  TutorialPage.installCheck: 'install_check',
  TutorialPage.matchRules: 'match_rules',
};
