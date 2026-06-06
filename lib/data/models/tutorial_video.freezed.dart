// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tutorial_video.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TutorialVideo _$TutorialVideoFromJson(Map<String, dynamic> json) {
  return _TutorialVideo.fromJson(json);
}

/// @nodoc
mixin _$TutorialVideo {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get videoUrl => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get updatedBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TutorialVideo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TutorialVideo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TutorialVideoCopyWith<TutorialVideo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TutorialVideoCopyWith<$Res> {
  factory $TutorialVideoCopyWith(
          TutorialVideo value, $Res Function(TutorialVideo) then) =
      _$TutorialVideoCopyWithImpl<$Res, TutorialVideo>;
  @useResult
  $Res call(
      {String id,
      String title,
      String videoUrl,
      bool isActive,
      String? updatedBy,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$TutorialVideoCopyWithImpl<$Res, $Val extends TutorialVideo>
    implements $TutorialVideoCopyWith<$Res> {
  _$TutorialVideoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TutorialVideo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? videoUrl = null,
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
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      videoUrl: null == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
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
abstract class _$$TutorialVideoImplCopyWith<$Res>
    implements $TutorialVideoCopyWith<$Res> {
  factory _$$TutorialVideoImplCopyWith(
          _$TutorialVideoImpl value, $Res Function(_$TutorialVideoImpl) then) =
      __$$TutorialVideoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String videoUrl,
      bool isActive,
      String? updatedBy,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$TutorialVideoImplCopyWithImpl<$Res>
    extends _$TutorialVideoCopyWithImpl<$Res, _$TutorialVideoImpl>
    implements _$$TutorialVideoImplCopyWith<$Res> {
  __$$TutorialVideoImplCopyWithImpl(
      _$TutorialVideoImpl _value, $Res Function(_$TutorialVideoImpl) _then)
      : super(_value, _then);

  /// Create a copy of TutorialVideo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? videoUrl = null,
    Object? isActive = null,
    Object? updatedBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$TutorialVideoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      videoUrl: null == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
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
class _$TutorialVideoImpl implements _TutorialVideo {
  const _$TutorialVideoImpl(
      {required this.id,
      required this.title,
      required this.videoUrl,
      this.isActive = true,
      this.updatedBy,
      this.createdAt,
      this.updatedAt});

  factory _$TutorialVideoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TutorialVideoImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String videoUrl;
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
    return 'TutorialVideo(id: $id, title: $title, videoUrl: $videoUrl, isActive: $isActive, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TutorialVideoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
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
  int get hashCode => Object.hash(runtimeType, id, title, videoUrl, isActive,
      updatedBy, createdAt, updatedAt);

  /// Create a copy of TutorialVideo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TutorialVideoImplCopyWith<_$TutorialVideoImpl> get copyWith =>
      __$$TutorialVideoImplCopyWithImpl<_$TutorialVideoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TutorialVideoImplToJson(
      this,
    );
  }
}

abstract class _TutorialVideo implements TutorialVideo {
  const factory _TutorialVideo(
      {required final String id,
      required final String title,
      required final String videoUrl,
      final bool isActive,
      final String? updatedBy,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$TutorialVideoImpl;

  factory _TutorialVideo.fromJson(Map<String, dynamic> json) =
      _$TutorialVideoImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get videoUrl;
  @override
  bool get isActive;
  @override
  String? get updatedBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of TutorialVideo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TutorialVideoImplCopyWith<_$TutorialVideoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
