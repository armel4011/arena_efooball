// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'promo_banner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PromoBanner _$PromoBannerFromJson(Map<String, dynamic> json) {
  return _PromoBanner.fromJson(json);
}

/// @nodoc
mixin _$PromoBanner {
  String get id => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  PromoRedirectType get redirectType => throw _privateConstructorUsedError;
  String get redirectTarget => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get updatedBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PromoBanner to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PromoBanner
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PromoBannerCopyWith<PromoBanner> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PromoBannerCopyWith<$Res> {
  factory $PromoBannerCopyWith(
          PromoBanner value, $Res Function(PromoBanner) then) =
      _$PromoBannerCopyWithImpl<$Res, PromoBanner>;
  @useResult
  $Res call(
      {String id,
      String imageUrl,
      PromoRedirectType redirectType,
      String redirectTarget,
      bool isActive,
      String? updatedBy,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$PromoBannerCopyWithImpl<$Res, $Val extends PromoBanner>
    implements $PromoBannerCopyWith<$Res> {
  _$PromoBannerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PromoBanner
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imageUrl = null,
    Object? redirectType = null,
    Object? redirectTarget = null,
    Object? isActive = null,
    Object? updatedBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      redirectType: null == redirectType
          ? _value.redirectType
          : redirectType // ignore: cast_nullable_to_non_nullable
              as PromoRedirectType,
      redirectTarget: null == redirectTarget
          ? _value.redirectTarget
          : redirectTarget // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      updatedBy: freezed == updatedBy
          ? _value.updatedBy
          : updatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PromoBannerImplCopyWith<$Res>
    implements $PromoBannerCopyWith<$Res> {
  factory _$$PromoBannerImplCopyWith(
          _$PromoBannerImpl value, $Res Function(_$PromoBannerImpl) then) =
      __$$PromoBannerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String imageUrl,
      PromoRedirectType redirectType,
      String redirectTarget,
      bool isActive,
      String? updatedBy,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$PromoBannerImplCopyWithImpl<$Res>
    extends _$PromoBannerCopyWithImpl<$Res, _$PromoBannerImpl>
    implements _$$PromoBannerImplCopyWith<$Res> {
  __$$PromoBannerImplCopyWithImpl(
      _$PromoBannerImpl _value, $Res Function(_$PromoBannerImpl) _then)
      : super(_value, _then);

  /// Create a copy of PromoBanner
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imageUrl = null,
    Object? redirectType = null,
    Object? redirectTarget = null,
    Object? isActive = null,
    Object? updatedBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$PromoBannerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      redirectType: null == redirectType
          ? _value.redirectType
          : redirectType // ignore: cast_nullable_to_non_nullable
              as PromoRedirectType,
      redirectTarget: null == redirectTarget
          ? _value.redirectTarget
          : redirectTarget // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      updatedBy: freezed == updatedBy
          ? _value.updatedBy
          : updatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PromoBannerImpl implements _PromoBanner {
  const _$PromoBannerImpl(
      {required this.id,
      required this.imageUrl,
      required this.redirectType,
      required this.redirectTarget,
      this.isActive = true,
      this.updatedBy,
      this.createdAt,
      this.updatedAt});

  factory _$PromoBannerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PromoBannerImplFromJson(json);

  @override
  final String id;
  @override
  final String imageUrl;
  @override
  final PromoRedirectType redirectType;
  @override
  final String redirectTarget;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final String? updatedBy;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'PromoBanner(id: $id, imageUrl: $imageUrl, redirectType: $redirectType, redirectTarget: $redirectTarget, isActive: $isActive, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PromoBannerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.redirectType, redirectType) ||
                other.redirectType == redirectType) &&
            (identical(other.redirectTarget, redirectTarget) ||
                other.redirectTarget == redirectTarget) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.updatedBy, updatedBy) ||
                other.updatedBy == updatedBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, imageUrl, redirectType,
      redirectTarget, isActive, updatedBy, createdAt, updatedAt);

  /// Create a copy of PromoBanner
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PromoBannerImplCopyWith<_$PromoBannerImpl> get copyWith =>
      __$$PromoBannerImplCopyWithImpl<_$PromoBannerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PromoBannerImplToJson(
      this,
    );
  }
}

abstract class _PromoBanner implements PromoBanner {
  const factory _PromoBanner(
      {required final String id,
      required final String imageUrl,
      required final PromoRedirectType redirectType,
      required final String redirectTarget,
      final bool isActive,
      final String? updatedBy,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$PromoBannerImpl;

  factory _PromoBanner.fromJson(Map<String, dynamic> json) =
      _$PromoBannerImpl.fromJson;

  @override
  String get id;
  @override
  String get imageUrl;
  @override
  PromoRedirectType get redirectType;
  @override
  String get redirectTarget;
  @override
  bool get isActive;
  @override
  String? get updatedBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of PromoBanner
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PromoBannerImplCopyWith<_$PromoBannerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
