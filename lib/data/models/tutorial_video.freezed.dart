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
  int get displayDays => throw _privateConstructorUsedError;
  TutorialPage get targetPage => throw _privateConstructorUsedError;

  /// Jeu ciblé (valeur fil `efootball|draughts|ea_sports_fc`) pour les cibles
  /// `match_locked` / `match_role_intro`. `null` sinon.
  String? get game => throw _privateConstructorUsedError;

  /// Pays ciblé (ISO alpha-2) pour la cible `payment_tutorial`. `null` sinon.
  String? get countryCode => throw _privateConstructorUsedError;

  /// Côté ciblé (`home`/`away`) pour la cible `match_role_intro` : Domicile et
  /// Extérieur ont chacun leur vidéo. `null` pour toutes les autres cibles.
  String? get roleSide => throw _privateConstructorUsedError;
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
      int displayDays,
      TutorialPage targetPage,
      String? game,
      String? countryCode,
      String? roleSide,
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
    Object? displayDays = null,
    Object? targetPage = null,
    Object? game = freezed,
    Object? countryCode = freezed,
    Object? roleSide = freezed,
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
      displayDays: null == displayDays
          ? _value.displayDays
          : displayDays // ignore: cast_nullable_to_non_nullable
              as int,
      targetPage: null == targetPage
          ? _value.targetPage
          : targetPage // ignore: cast_nullable_to_non_nullable
              as TutorialPage,
      game: freezed == game
          ? _value.game
          : game // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      roleSide: freezed == roleSide
          ? _value.roleSide
          : roleSide // ignore: cast_nullable_to_non_nullable
              as String?,
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
      int displayDays,
      TutorialPage targetPage,
      String? game,
      String? countryCode,
      String? roleSide,
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
    Object? displayDays = null,
    Object? targetPage = null,
    Object? game = freezed,
    Object? countryCode = freezed,
    Object? roleSide = freezed,
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
      displayDays: null == displayDays
          ? _value.displayDays
          : displayDays // ignore: cast_nullable_to_non_nullable
              as int,
      targetPage: null == targetPage
          ? _value.targetPage
          : targetPage // ignore: cast_nullable_to_non_nullable
              as TutorialPage,
      game: freezed == game
          ? _value.game
          : game // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      roleSide: freezed == roleSide
          ? _value.roleSide
          : roleSide // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$TutorialVideoImpl extends _TutorialVideo {
  const _$TutorialVideoImpl(
      {required this.id,
      required this.title,
      required this.videoUrl,
      this.isActive = true,
      this.displayDays = 7,
      this.targetPage = TutorialPage.home,
      this.game,
      this.countryCode,
      this.roleSide,
      this.updatedBy,
      this.createdAt,
      this.updatedAt})
      : super._();

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
  @JsonKey()
  final int displayDays;
  @override
  @JsonKey()
  final TutorialPage targetPage;

  /// Jeu ciblé (valeur fil `efootball|draughts|ea_sports_fc`) pour les cibles
  /// `match_locked` / `match_role_intro`. `null` sinon.
  @override
  final String? game;

  /// Pays ciblé (ISO alpha-2) pour la cible `payment_tutorial`. `null` sinon.
  @override
  final String? countryCode;

  /// Côté ciblé (`home`/`away`) pour la cible `match_role_intro` : Domicile et
  /// Extérieur ont chacun leur vidéo. `null` pour toutes les autres cibles.
  @override
  final String? roleSide;
  @override
  final String? updatedBy;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'TutorialVideo(id: $id, title: $title, videoUrl: $videoUrl, isActive: $isActive, displayDays: $displayDays, targetPage: $targetPage, game: $game, countryCode: $countryCode, roleSide: $roleSide, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
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
            (identical(other.displayDays, displayDays) ||
                other.displayDays == displayDays) &&
            (identical(other.targetPage, targetPage) ||
                other.targetPage == targetPage) &&
            (identical(other.game, game) || other.game == game) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.roleSide, roleSide) ||
                other.roleSide == roleSide) &&
            (identical(other.updatedBy, updatedBy) ||
                other.updatedBy == updatedBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      videoUrl,
      isActive,
      displayDays,
      targetPage,
      game,
      countryCode,
      roleSide,
      updatedBy,
      createdAt,
      updatedAt);

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

abstract class _TutorialVideo extends TutorialVideo {
  const factory _TutorialVideo(
      {required final String id,
      required final String title,
      required final String videoUrl,
      final bool isActive,
      final int displayDays,
      final TutorialPage targetPage,
      final String? game,
      final String? countryCode,
      final String? roleSide,
      final String? updatedBy,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$TutorialVideoImpl;
  const _TutorialVideo._() : super._();

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
  int get displayDays;
  @override
  TutorialPage get targetPage;

  /// Jeu ciblé (valeur fil `efootball|draughts|ea_sports_fc`) pour les cibles
  /// `match_locked` / `match_role_intro`. `null` sinon.
  @override
  String? get game;

  /// Pays ciblé (ISO alpha-2) pour la cible `payment_tutorial`. `null` sinon.
  @override
  String? get countryCode;

  /// Côté ciblé (`home`/`away`) pour la cible `match_role_intro` : Domicile et
  /// Extérieur ont chacun leur vidéo. `null` pour toutes les autres cibles.
  @override
  String? get roleSide;
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
