// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friendship.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Friendship {

 String get id; String get requesterId; String get addresseeId; String get status; String? get blockedBy; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendshipCopyWith<Friendship> get copyWith => _$FriendshipCopyWithImpl<Friendship>(this as Friendship, _$identity);

  /// Serializes this Friendship to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Friendship;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Friendship&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.requesterId, _this.requesterId) || other.requesterId == _this.requesterId)&&(identical(other.addresseeId, _this.addresseeId) || other.addresseeId == _this.addresseeId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.blockedBy, _this.blockedBy) || other.blockedBy == _this.blockedBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Friendship;
  return Object.hash(runtimeType,_this.id,_this.requesterId,_this.addresseeId,_this.status,_this.blockedBy,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Friendship;
  return 'Friendship(id: ${_this.id}, requesterId: ${_this.requesterId}, addresseeId: ${_this.addresseeId}, status: ${_this.status}, blockedBy: ${_this.blockedBy}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $FriendshipCopyWith<$Res>  {
  factory $FriendshipCopyWith(Friendship value, $Res Function(Friendship) _then) = _$FriendshipCopyWithImpl;
@useResult
$Res call({
 String id, String requesterId, String addresseeId, String status, String? blockedBy, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$FriendshipCopyWithImpl<$Res>
    implements $FriendshipCopyWith<$Res> {
  _$FriendshipCopyWithImpl(this._self, this._then);

  final Friendship _self;
  final $Res Function(Friendship) _then;

/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? requesterId = null,Object? addresseeId = null,Object? status = null,Object? blockedBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(Friendship(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requesterId: null == requesterId ? _self.requesterId : requesterId // ignore: cast_nullable_to_non_nullable
as String,addresseeId: null == addresseeId ? _self.addresseeId : addresseeId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,blockedBy: freezed == blockedBy ? _self.blockedBy : blockedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Friendship].
extension FriendshipPatterns on Friendship {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Friendship value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Friendship() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Friendship value)  $default,){
final _that = this;
switch (_that) {
case _Friendship():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Friendship value)?  $default,){
final _that = this;
switch (_that) {
case _Friendship() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String requesterId,  String addresseeId,  String status,  String? blockedBy,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Friendship() when $default != null:
return $default(_that.id,_that.requesterId,_that.addresseeId,_that.status,_that.blockedBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String requesterId,  String addresseeId,  String status,  String? blockedBy,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Friendship():
return $default(_that.id,_that.requesterId,_that.addresseeId,_that.status,_that.blockedBy,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String requesterId,  String addresseeId,  String status,  String? blockedBy,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Friendship() when $default != null:
return $default(_that.id,_that.requesterId,_that.addresseeId,_that.status,_that.blockedBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Friendship extends Friendship {
  const _Friendship({required this.id, required this.requesterId, required this.addresseeId, this.status = 'pending', this.blockedBy, this.createdAt, this.updatedAt}): super._();
  factory _Friendship.fromJson(Map<String, dynamic> json) => _$FriendshipFromJson(json);

@override final  String id;
@override final  String requesterId;
@override final  String addresseeId;
@override@JsonKey() final  String status;
@override final  String? blockedBy;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendshipCopyWith<_Friendship> get copyWith => __$FriendshipCopyWithImpl<_Friendship>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FriendshipToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Friendship&&(identical(other.id, id) || other.id == id)&&(identical(other.requesterId, requesterId) || other.requesterId == requesterId)&&(identical(other.addresseeId, addresseeId) || other.addresseeId == addresseeId)&&(identical(other.status, status) || other.status == status)&&(identical(other.blockedBy, blockedBy) || other.blockedBy == blockedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,requesterId,addresseeId,status,blockedBy,createdAt,updatedAt);
}

@override
String toString() {
    return 'Friendship(id: $id, requesterId: $requesterId, addresseeId: $addresseeId, status: $status, blockedBy: $blockedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FriendshipCopyWith<$Res> implements $FriendshipCopyWith<$Res> {
  factory _$FriendshipCopyWith(_Friendship value, $Res Function(_Friendship) _then) = __$FriendshipCopyWithImpl;
@override @useResult
$Res call({
 String id, String requesterId, String addresseeId, String status, String? blockedBy, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$FriendshipCopyWithImpl<$Res>
    implements _$FriendshipCopyWith<$Res> {
  __$FriendshipCopyWithImpl(this._self, this._then);

  final _Friendship _self;
  final $Res Function(_Friendship) _then;

/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requesterId = null,Object? addresseeId = null,Object? status = null,Object? blockedBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Friendship(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requesterId: null == requesterId ? _self.requesterId : requesterId // ignore: cast_nullable_to_non_nullable
as String,addresseeId: null == addresseeId ? _self.addresseeId : addresseeId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,blockedBy: freezed == blockedBy ? _self.blockedBy : blockedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
