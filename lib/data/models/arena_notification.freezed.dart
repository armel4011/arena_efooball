// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'arena_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArenaNotification {

 String get id; String get userId; String get type; String get title; String? get body; String? get imageUrl; Map<String, dynamic> get data; DateTime? get readAt; DateTime? get sentAt; DateTime? get createdAt;
/// Create a copy of ArenaNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArenaNotificationCopyWith<ArenaNotification> get copyWith => _$ArenaNotificationCopyWithImpl<ArenaNotification>(this as ArenaNotification, _$identity);

  /// Serializes this ArenaNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ArenaNotification;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArenaNotification&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&const DeepCollectionEquality().equals(other.data, _this.data)&&(identical(other.readAt, _this.readAt) || other.readAt == _this.readAt)&&(identical(other.sentAt, _this.sentAt) || other.sentAt == _this.sentAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ArenaNotification;
  return Object.hash(runtimeType,_this.id,_this.userId,_this.type,_this.title,_this.body,_this.imageUrl,const DeepCollectionEquality().hash(_this.data),_this.readAt,_this.sentAt,_this.createdAt);
}

@override
String toString() {
  final _this = this as ArenaNotification;
  return 'ArenaNotification(id: ${_this.id}, userId: ${_this.userId}, type: ${_this.type}, title: ${_this.title}, body: ${_this.body}, imageUrl: ${_this.imageUrl}, data: ${_this.data}, readAt: ${_this.readAt}, sentAt: ${_this.sentAt}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ArenaNotificationCopyWith<$Res>  {
  factory $ArenaNotificationCopyWith(ArenaNotification value, $Res Function(ArenaNotification) _then) = _$ArenaNotificationCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String type, String title, String? body, String? imageUrl, Map<String, dynamic> data, DateTime? readAt, DateTime? sentAt, DateTime? createdAt
});




}
/// @nodoc
class _$ArenaNotificationCopyWithImpl<$Res>
    implements $ArenaNotificationCopyWith<$Res> {
  _$ArenaNotificationCopyWithImpl(this._self, this._then);

  final ArenaNotification _self;
  final $Res Function(ArenaNotification) _then;

/// Create a copy of ArenaNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? type = null,Object? title = null,Object? body = freezed,Object? imageUrl = freezed,Object? data = null,Object? readAt = freezed,Object? sentAt = freezed,Object? createdAt = freezed,}) {
  return _then(ArenaNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArenaNotification].
extension ArenaNotificationPatterns on ArenaNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArenaNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArenaNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArenaNotification value)  $default,){
final _that = this;
switch (_that) {
case _ArenaNotification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArenaNotification value)?  $default,){
final _that = this;
switch (_that) {
case _ArenaNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String type,  String title,  String? body,  String? imageUrl,  Map<String, dynamic> data,  DateTime? readAt,  DateTime? sentAt,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArenaNotification() when $default != null:
return $default(_that.id,_that.userId,_that.type,_that.title,_that.body,_that.imageUrl,_that.data,_that.readAt,_that.sentAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String type,  String title,  String? body,  String? imageUrl,  Map<String, dynamic> data,  DateTime? readAt,  DateTime? sentAt,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ArenaNotification():
return $default(_that.id,_that.userId,_that.type,_that.title,_that.body,_that.imageUrl,_that.data,_that.readAt,_that.sentAt,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String type,  String title,  String? body,  String? imageUrl,  Map<String, dynamic> data,  DateTime? readAt,  DateTime? sentAt,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ArenaNotification() when $default != null:
return $default(_that.id,_that.userId,_that.type,_that.title,_that.body,_that.imageUrl,_that.data,_that.readAt,_that.sentAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArenaNotification extends ArenaNotification {
  const _ArenaNotification({required this.id, required this.userId, required this.type, required this.title, this.body, this.imageUrl,  Map<String, dynamic> data = const <String, dynamic>{}, this.readAt, this.sentAt, this.createdAt}): _data = data,super._();
  factory _ArenaNotification.fromJson(Map<String, dynamic> json) => _$ArenaNotificationFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String type;
@override final  String title;
@override final  String? body;
@override final  String? imageUrl;
 final  Map<String, dynamic> _data;
@override@JsonKey() Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}

@override final  DateTime? readAt;
@override final  DateTime? sentAt;
@override final  DateTime? createdAt;

/// Create a copy of ArenaNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArenaNotificationCopyWith<_ArenaNotification> get copyWith => __$ArenaNotificationCopyWithImpl<_ArenaNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArenaNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArenaNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other.data, _data)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,userId,type,title,body,imageUrl,const DeepCollectionEquality().hash(_data),readAt,sentAt,createdAt);
}

@override
String toString() {
    return 'ArenaNotification(id: $id, userId: $userId, type: $type, title: $title, body: $body, imageUrl: $imageUrl, data: $data, readAt: $readAt, sentAt: $sentAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ArenaNotificationCopyWith<$Res> implements $ArenaNotificationCopyWith<$Res> {
  factory _$ArenaNotificationCopyWith(_ArenaNotification value, $Res Function(_ArenaNotification) _then) = __$ArenaNotificationCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String type, String title, String? body, String? imageUrl, Map<String, dynamic> data, DateTime? readAt, DateTime? sentAt, DateTime? createdAt
});




}
/// @nodoc
class __$ArenaNotificationCopyWithImpl<$Res>
    implements _$ArenaNotificationCopyWith<$Res> {
  __$ArenaNotificationCopyWithImpl(this._self, this._then);

  final _ArenaNotification _self;
  final $Res Function(_ArenaNotification) _then;

/// Create a copy of ArenaNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? type = null,Object? title = null,Object? body = freezed,Object? imageUrl = freezed,Object? data = null,Object? readAt = freezed,Object? sentAt = freezed,Object? createdAt = freezed,}) {
  return _then(_ArenaNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
