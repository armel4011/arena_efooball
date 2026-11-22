// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tutorial_video.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TutorialVideo {

 String get id; String get title; String get videoUrl; bool get isActive; int get displayDays; TutorialPage get targetPage;/// Jeu ciblé (valeur fil `efootball|draughts|ea_sports_fc`) pour les cibles
/// `match_locked` / `match_role_intro`. `null` sinon.
 String? get game;/// Pays ciblé (ISO alpha-2) pour la cible `payment_tutorial`. `null` sinon.
 String? get countryCode;/// Opérateur ciblé (slug MAJUSCULE, ex. `ORANGE_MONEY`) pour la cible
/// `payment_tutorial`. OPTIONNEL : `null` = vidéo par défaut du pays (repli
/// si aucune vidéo propre à l'opérateur du joueur). `null` pour les autres
/// cibles.
 String? get operatorCode;/// Côté ciblé (`home`/`away`) pour la cible `match_role_intro` : Domicile et
/// Extérieur ont chacun leur vidéo. `null` pour toutes les autres cibles.
 String? get roleSide;/// Langue ciblée (`fr`/`en`/`es`/`pt`) : la vidéo n'est montrée qu'aux
/// utilisateurs de cette langue. `null` = vidéo par défaut (toutes langues,
/// repli si aucune vidéo propre à la langue de l'utilisateur).
 String? get locale; String? get updatedBy; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of TutorialVideo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TutorialVideoCopyWith<TutorialVideo> get copyWith => _$TutorialVideoCopyWithImpl<TutorialVideo>(this as TutorialVideo, _$identity);

  /// Serializes this TutorialVideo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TutorialVideo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TutorialVideo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.videoUrl, _this.videoUrl) || other.videoUrl == _this.videoUrl)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.displayDays, _this.displayDays) || other.displayDays == _this.displayDays)&&(identical(other.targetPage, _this.targetPage) || other.targetPage == _this.targetPage)&&(identical(other.game, _this.game) || other.game == _this.game)&&(identical(other.countryCode, _this.countryCode) || other.countryCode == _this.countryCode)&&(identical(other.operatorCode, _this.operatorCode) || other.operatorCode == _this.operatorCode)&&(identical(other.roleSide, _this.roleSide) || other.roleSide == _this.roleSide)&&(identical(other.locale, _this.locale) || other.locale == _this.locale)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TutorialVideo;
  return Object.hash(runtimeType,_this.id,_this.title,_this.videoUrl,_this.isActive,_this.displayDays,_this.targetPage,_this.game,_this.countryCode,_this.operatorCode,_this.roleSide,_this.locale,_this.updatedBy,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as TutorialVideo;
  return 'TutorialVideo(id: ${_this.id}, title: ${_this.title}, videoUrl: ${_this.videoUrl}, isActive: ${_this.isActive}, displayDays: ${_this.displayDays}, targetPage: ${_this.targetPage}, game: ${_this.game}, countryCode: ${_this.countryCode}, operatorCode: ${_this.operatorCode}, roleSide: ${_this.roleSide}, locale: ${_this.locale}, updatedBy: ${_this.updatedBy}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $TutorialVideoCopyWith<$Res>  {
  factory $TutorialVideoCopyWith(TutorialVideo value, $Res Function(TutorialVideo) _then) = _$TutorialVideoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String videoUrl, bool isActive, int displayDays, TutorialPage targetPage, String? game, String? countryCode, String? operatorCode, String? roleSide, String? locale, String? updatedBy, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$TutorialVideoCopyWithImpl<$Res>
    implements $TutorialVideoCopyWith<$Res> {
  _$TutorialVideoCopyWithImpl(this._self, this._then);

  final TutorialVideo _self;
  final $Res Function(TutorialVideo) _then;

/// Create a copy of TutorialVideo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? videoUrl = null,Object? isActive = null,Object? displayDays = null,Object? targetPage = null,Object? game = freezed,Object? countryCode = freezed,Object? operatorCode = freezed,Object? roleSide = freezed,Object? locale = freezed,Object? updatedBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(TutorialVideo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,videoUrl: null == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,displayDays: null == displayDays ? _self.displayDays : displayDays // ignore: cast_nullable_to_non_nullable
as int,targetPage: null == targetPage ? _self.targetPage : targetPage // ignore: cast_nullable_to_non_nullable
as TutorialPage,game: freezed == game ? _self.game : game // ignore: cast_nullable_to_non_nullable
as String?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,operatorCode: freezed == operatorCode ? _self.operatorCode : operatorCode // ignore: cast_nullable_to_non_nullable
as String?,roleSide: freezed == roleSide ? _self.roleSide : roleSide // ignore: cast_nullable_to_non_nullable
as String?,locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TutorialVideo].
extension TutorialVideoPatterns on TutorialVideo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TutorialVideo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TutorialVideo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TutorialVideo value)  $default,){
final _that = this;
switch (_that) {
case _TutorialVideo():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TutorialVideo value)?  $default,){
final _that = this;
switch (_that) {
case _TutorialVideo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String videoUrl,  bool isActive,  int displayDays,  TutorialPage targetPage,  String? game,  String? countryCode,  String? operatorCode,  String? roleSide,  String? locale,  String? updatedBy,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TutorialVideo() when $default != null:
return $default(_that.id,_that.title,_that.videoUrl,_that.isActive,_that.displayDays,_that.targetPage,_that.game,_that.countryCode,_that.operatorCode,_that.roleSide,_that.locale,_that.updatedBy,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String videoUrl,  bool isActive,  int displayDays,  TutorialPage targetPage,  String? game,  String? countryCode,  String? operatorCode,  String? roleSide,  String? locale,  String? updatedBy,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TutorialVideo():
return $default(_that.id,_that.title,_that.videoUrl,_that.isActive,_that.displayDays,_that.targetPage,_that.game,_that.countryCode,_that.operatorCode,_that.roleSide,_that.locale,_that.updatedBy,_that.createdAt,_that.updatedAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String videoUrl,  bool isActive,  int displayDays,  TutorialPage targetPage,  String? game,  String? countryCode,  String? operatorCode,  String? roleSide,  String? locale,  String? updatedBy,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TutorialVideo() when $default != null:
return $default(_that.id,_that.title,_that.videoUrl,_that.isActive,_that.displayDays,_that.targetPage,_that.game,_that.countryCode,_that.operatorCode,_that.roleSide,_that.locale,_that.updatedBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TutorialVideo extends TutorialVideo {
  const _TutorialVideo({required this.id, required this.title, required this.videoUrl, this.isActive = true, this.displayDays = 7, this.targetPage = TutorialPage.home, this.game, this.countryCode, this.operatorCode, this.roleSide, this.locale, this.updatedBy, this.createdAt, this.updatedAt}): super._();
  factory _TutorialVideo.fromJson(Map<String, dynamic> json) => _$TutorialVideoFromJson(json);

@override final  String id;
@override final  String title;
@override final  String videoUrl;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  int displayDays;
@override@JsonKey() final  TutorialPage targetPage;
/// Jeu ciblé (valeur fil `efootball|draughts|ea_sports_fc`) pour les cibles
/// `match_locked` / `match_role_intro`. `null` sinon.
@override final  String? game;
/// Pays ciblé (ISO alpha-2) pour la cible `payment_tutorial`. `null` sinon.
@override final  String? countryCode;
/// Opérateur ciblé (slug MAJUSCULE, ex. `ORANGE_MONEY`) pour la cible
/// `payment_tutorial`. OPTIONNEL : `null` = vidéo par défaut du pays (repli
/// si aucune vidéo propre à l'opérateur du joueur). `null` pour les autres
/// cibles.
@override final  String? operatorCode;
/// Côté ciblé (`home`/`away`) pour la cible `match_role_intro` : Domicile et
/// Extérieur ont chacun leur vidéo. `null` pour toutes les autres cibles.
@override final  String? roleSide;
/// Langue ciblée (`fr`/`en`/`es`/`pt`) : la vidéo n'est montrée qu'aux
/// utilisateurs de cette langue. `null` = vidéo par défaut (toutes langues,
/// repli si aucune vidéo propre à la langue de l'utilisateur).
@override final  String? locale;
@override final  String? updatedBy;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of TutorialVideo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TutorialVideoCopyWith<_TutorialVideo> get copyWith => __$TutorialVideoCopyWithImpl<_TutorialVideo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TutorialVideoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TutorialVideo&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.displayDays, displayDays) || other.displayDays == displayDays)&&(identical(other.targetPage, targetPage) || other.targetPage == targetPage)&&(identical(other.game, game) || other.game == game)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.operatorCode, operatorCode) || other.operatorCode == operatorCode)&&(identical(other.roleSide, roleSide) || other.roleSide == roleSide)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,videoUrl,isActive,displayDays,targetPage,game,countryCode,operatorCode,roleSide,locale,updatedBy,createdAt,updatedAt);
}

@override
String toString() {
    return 'TutorialVideo(id: $id, title: $title, videoUrl: $videoUrl, isActive: $isActive, displayDays: $displayDays, targetPage: $targetPage, game: $game, countryCode: $countryCode, operatorCode: $operatorCode, roleSide: $roleSide, locale: $locale, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TutorialVideoCopyWith<$Res> implements $TutorialVideoCopyWith<$Res> {
  factory _$TutorialVideoCopyWith(_TutorialVideo value, $Res Function(_TutorialVideo) _then) = __$TutorialVideoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String videoUrl, bool isActive, int displayDays, TutorialPage targetPage, String? game, String? countryCode, String? operatorCode, String? roleSide, String? locale, String? updatedBy, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$TutorialVideoCopyWithImpl<$Res>
    implements _$TutorialVideoCopyWith<$Res> {
  __$TutorialVideoCopyWithImpl(this._self, this._then);

  final _TutorialVideo _self;
  final $Res Function(_TutorialVideo) _then;

/// Create a copy of TutorialVideo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? videoUrl = null,Object? isActive = null,Object? displayDays = null,Object? targetPage = null,Object? game = freezed,Object? countryCode = freezed,Object? operatorCode = freezed,Object? roleSide = freezed,Object? locale = freezed,Object? updatedBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_TutorialVideo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,videoUrl: null == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,displayDays: null == displayDays ? _self.displayDays : displayDays // ignore: cast_nullable_to_non_nullable
as int,targetPage: null == targetPage ? _self.targetPage : targetPage // ignore: cast_nullable_to_non_nullable
as TutorialPage,game: freezed == game ? _self.game : game // ignore: cast_nullable_to_non_nullable
as String?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,operatorCode: freezed == operatorCode ? _self.operatorCode : operatorCode // ignore: cast_nullable_to_non_nullable
as String?,roleSide: freezed == roleSide ? _self.roleSide : roleSide // ignore: cast_nullable_to_non_nullable
as String?,locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
