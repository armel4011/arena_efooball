// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo_banner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PromoBanner _$PromoBannerFromJson(Map<String, dynamic> json) => _PromoBanner(
  id: json['id'] as String,
  imageUrl: json['image_url'] as String,
  redirectType: $enumDecode(_$PromoRedirectTypeEnumMap, json['redirect_type']),
  redirectTarget: json['redirect_target'] as String,
  isActive: json['is_active'] as bool? ?? true,
  updatedBy: json['updated_by'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PromoBannerToJson(_PromoBanner instance) =>
    <String, dynamic>{
      'id': instance.id,
      'image_url': instance.imageUrl,
      'redirect_type': _$PromoRedirectTypeEnumMap[instance.redirectType]!,
      'redirect_target': instance.redirectTarget,
      'is_active': instance.isActive,
      'updated_by': ?instance.updatedBy,
      'created_at': ?instance.createdAt?.toIso8601String(),
      'updated_at': ?instance.updatedAt?.toIso8601String(),
    };

const _$PromoRedirectTypeEnumMap = {
  PromoRedirectType.internalPage: 'internal_page',
  PromoRedirectType.webLink: 'web_link',
  PromoRedirectType.whatsapp: 'whatsapp',
};
