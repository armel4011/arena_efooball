// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reintegration_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReintegrationRequest {

 String get id; String get userId; String get message; String get status; DateTime? get createdAt; DateTime? get resolvedAt; String? get resolvedBy; String? get resolutionReason; DateTime? get updatedAt;
/// Create a copy of ReintegrationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReintegrationRequestCopyWith<ReintegrationRequest> get copyWith => _$ReintegrationRequestCopyWithImpl<ReintegrationRequest>(this as ReintegrationRequest, _$identity);

  /// Serializes this ReintegrationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReintegrationRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReintegrationRequest&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.resolvedAt, _this.resolvedAt) || other.resolvedAt == _this.resolvedAt)&&(identical(other.resolvedBy, _this.resolvedBy) || other.resolvedBy == _this.resolvedBy)&&(identical(other.resolutionReason, _this.resolutionReason) || other.resolutionReason == _this.resolutionReason)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReintegrationRequest;
  return Object.hash(runtimeType,_this.id,_this.userId,_this.message,_this.status,_this.createdAt,_this.resolvedAt,_this.resolvedBy,_this.resolutionReason,_this.updatedAt);
}

@override
String toString() {
  final _this = this as ReintegrationRequest;
  return 'ReintegrationRequest(id: ${_this.id}, userId: ${_this.userId}, message: ${_this.message}, status: ${_this.status}, createdAt: ${_this.createdAt}, resolvedAt: ${_this.resolvedAt}, resolvedBy: ${_this.resolvedBy}, resolutionReason: ${_this.resolutionReason}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ReintegrationRequestCopyWith<$Res>  {
  factory $ReintegrationRequestCopyWith(ReintegrationRequest value, $Res Function(ReintegrationRequest) _then) = _$ReintegrationRequestCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String message, String status, DateTime? createdAt, DateTime? resolvedAt, String? resolvedBy, String? resolutionReason, DateTime? updatedAt
});




}
/// @nodoc
class _$ReintegrationRequestCopyWithImpl<$Res>
    implements $ReintegrationRequestCopyWith<$Res> {
  _$ReintegrationRequestCopyWithImpl(this._self, this._then);

  final ReintegrationRequest _self;
  final $Res Function(ReintegrationRequest) _then;

/// Create a copy of ReintegrationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? message = null,Object? status = null,Object? createdAt = freezed,Object? resolvedAt = freezed,Object? resolvedBy = freezed,Object? resolutionReason = freezed,Object? updatedAt = freezed,}) {
  return _then(ReintegrationRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedBy: freezed == resolvedBy ? _self.resolvedBy : resolvedBy // ignore: cast_nullable_to_non_nullable
as String?,resolutionReason: freezed == resolutionReason ? _self.resolutionReason : resolutionReason // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReintegrationRequest].
extension ReintegrationRequestPatterns on ReintegrationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReintegrationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReintegrationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReintegrationRequest value)  $default,){
final _that = this;
switch (_that) {
case _ReintegrationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReintegrationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ReintegrationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String message,  String status,  DateTime? createdAt,  DateTime? resolvedAt,  String? resolvedBy,  String? resolutionReason,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReintegrationRequest() when $default != null:
return $default(_that.id,_that.userId,_that.message,_that.status,_that.createdAt,_that.resolvedAt,_that.resolvedBy,_that.resolutionReason,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String message,  String status,  DateTime? createdAt,  DateTime? resolvedAt,  String? resolvedBy,  String? resolutionReason,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ReintegrationRequest():
return $default(_that.id,_that.userId,_that.message,_that.status,_that.createdAt,_that.resolvedAt,_that.resolvedBy,_that.resolutionReason,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String message,  String status,  DateTime? createdAt,  DateTime? resolvedAt,  String? resolvedBy,  String? resolutionReason,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ReintegrationRequest() when $default != null:
return $default(_that.id,_that.userId,_that.message,_that.status,_that.createdAt,_that.resolvedAt,_that.resolvedBy,_that.resolutionReason,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReintegrationRequest extends ReintegrationRequest {
  const _ReintegrationRequest({required this.id, required this.userId, required this.message, this.status = 'pending', this.createdAt, this.resolvedAt, this.resolvedBy, this.resolutionReason, this.updatedAt}): super._();
  factory _ReintegrationRequest.fromJson(Map<String, dynamic> json) => _$ReintegrationRequestFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String message;
@override@JsonKey() final  String status;
@override final  DateTime? createdAt;
@override final  DateTime? resolvedAt;
@override final  String? resolvedBy;
@override final  String? resolutionReason;
@override final  DateTime? updatedAt;

/// Create a copy of ReintegrationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReintegrationRequestCopyWith<_ReintegrationRequest> get copyWith => __$ReintegrationRequestCopyWithImpl<_ReintegrationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReintegrationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReintegrationRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.resolvedBy, resolvedBy) || other.resolvedBy == resolvedBy)&&(identical(other.resolutionReason, resolutionReason) || other.resolutionReason == resolutionReason)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,userId,message,status,createdAt,resolvedAt,resolvedBy,resolutionReason,updatedAt);
}

@override
String toString() {
    return 'ReintegrationRequest(id: $id, userId: $userId, message: $message, status: $status, createdAt: $createdAt, resolvedAt: $resolvedAt, resolvedBy: $resolvedBy, resolutionReason: $resolutionReason, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ReintegrationRequestCopyWith<$Res> implements $ReintegrationRequestCopyWith<$Res> {
  factory _$ReintegrationRequestCopyWith(_ReintegrationRequest value, $Res Function(_ReintegrationRequest) _then) = __$ReintegrationRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String message, String status, DateTime? createdAt, DateTime? resolvedAt, String? resolvedBy, String? resolutionReason, DateTime? updatedAt
});




}
/// @nodoc
class __$ReintegrationRequestCopyWithImpl<$Res>
    implements _$ReintegrationRequestCopyWith<$Res> {
  __$ReintegrationRequestCopyWithImpl(this._self, this._then);

  final _ReintegrationRequest _self;
  final $Res Function(_ReintegrationRequest) _then;

/// Create a copy of ReintegrationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? message = null,Object? status = null,Object? createdAt = freezed,Object? resolvedAt = freezed,Object? resolvedBy = freezed,Object? resolutionReason = freezed,Object? updatedAt = freezed,}) {
  return _then(_ReintegrationRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedBy: freezed == resolvedBy ? _self.resolvedBy : resolvedBy // ignore: cast_nullable_to_non_nullable
as String?,resolutionReason: freezed == resolutionReason ? _self.resolutionReason : resolutionReason // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
