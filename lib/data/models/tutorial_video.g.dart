// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutorial_video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TutorialVideoImpl _$$TutorialVideoImplFromJson(Map<String, dynamic> json) =>
    _$TutorialVideoImpl(
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
      updatedBy: json['updated_by'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$TutorialVideoImplToJson(_$TutorialVideoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'video_url': instance.videoUrl,
      'is_active': instance.isActive,
      'display_days': instance.displayDays,
      'target_page': _$TutorialPageEnumMap[instance.targetPage]!,
      if (instance.game case final value?) 'game': value,
      if (instance.countryCode case final value?) 'country_code': value,
      if (instance.updatedBy case final value?) 'updated_by': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updated_at': value,
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
};
