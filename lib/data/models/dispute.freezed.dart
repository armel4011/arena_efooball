// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dispute.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Dispute {

 String get id; String get matchId; String get openedBy; String get status; String? get reason; Map<String, dynamic> get evidence; int get escalationLevel; DateTime? get botAttemptedAt; DateTime? get escalatedAt; DateTime? get resolvedAt; String? get resolvedBy; String? get resolution; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Dispute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DisputeCopyWith<Dispute> get copyWith => _$DisputeCopyWithImpl<Dispute>(this as Dispute, _$identity);

  /// Serializes this Dispute to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Dispute;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Dispute&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.matchId, _this.matchId) || other.matchId == _this.matchId)&&(identical(other.openedBy, _this.openedBy) || other.openedBy == _this.openedBy)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&const DeepCollectionEquality().equals(other.evidence, _this.evidence)&&(identical(other.escalationLevel, _this.escalationLevel) || other.escalationLevel == _this.escalationLevel)&&(identical(other.botAttemptedAt, _this.botAttemptedAt) || other.botAttemptedAt == _this.botAttemptedAt)&&(identical(other.escalatedAt, _this.escalatedAt) || other.escalatedAt == _this.escalatedAt)&&(identical(other.resolvedAt, _this.resolvedAt) || other.resolvedAt == _this.resolvedAt)&&(identical(other.resolvedBy, _this.resolvedBy) || other.resolvedBy == _this.resolvedBy)&&(identical(other.resolution, _this.resolution) || other.resolution == _this.resolution)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Dispute;
  return Object.hash(runtimeType,_this.id,_this.matchId,_this.openedBy,_this.status,_this.reason,const DeepCollectionEquality().hash(_this.evidence),_this.escalationLevel,_this.botAttemptedAt,_this.escalatedAt,_this.resolvedAt,_this.resolvedBy,_this.resolution,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Dispute;
  return 'Dispute(id: ${_this.id}, matchId: ${_this.matchId}, openedBy: ${_this.openedBy}, status: ${_this.status}, reason: ${_this.reason}, evidence: ${_this.evidence}, escalationLevel: ${_this.escalationLevel}, botAttemptedAt: ${_this.botAttemptedAt}, escalatedAt: ${_this.escalatedAt}, resolvedAt: ${_this.resolvedAt}, resolvedBy: ${_this.resolvedBy}, resolution: ${_this.resolution}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $DisputeCopyWith<$Res>  {
  factory $DisputeCopyWith(Dispute value, $Res Function(Dispute) _then) = _$DisputeCopyWithImpl;
@useResult
$Res call({
 String id, String matchId, String openedBy, String status, String? reason, Map<String, dynamic> evidence, int escalationLevel, DateTime? botAttemptedAt, DateTime? escalatedAt, DateTime? resolvedAt, String? resolvedBy, String? resolution, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$DisputeCopyWithImpl<$Res>
    implements $DisputeCopyWith<$Res> {
  _$DisputeCopyWithImpl(this._self, this._then);

  final Dispute _self;
  final $Res Function(Dispute) _then;

/// Create a copy of Dispute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? matchId = null,Object? openedBy = null,Object? status = null,Object? reason = freezed,Object? evidence = null,Object? escalationLevel = null,Object? botAttemptedAt = freezed,Object? escalatedAt = freezed,Object? resolvedAt = freezed,Object? resolvedBy = freezed,Object? resolution = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(Dispute(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,openedBy: null == openedBy ? _self.openedBy : openedBy // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,escalationLevel: null == escalationLevel ? _self.escalationLevel : escalationLevel // ignore: cast_nullable_to_non_nullable
as int,botAttemptedAt: freezed == botAttemptedAt ? _self.botAttemptedAt : botAttemptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,escalatedAt: freezed == escalatedAt ? _self.escalatedAt : escalatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedBy: freezed == resolvedBy ? _self.resolvedBy : resolvedBy // ignore: cast_nullable_to_non_nullable
as String?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Dispute].
extension DisputePatterns on Dispute {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Dispute value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Dispute() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Dispute value)  $default,){
final _that = this;
switch (_that) {
case _Dispute():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Dispute value)?  $default,){
final _that = this;
switch (_that) {
case _Dispute() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String matchId,  String openedBy,  String status,  String? reason,  Map<String, dynamic> evidence,  int escalationLevel,  DateTime? botAttemptedAt,  DateTime? escalatedAt,  DateTime? resolvedAt,  String? resolvedBy,  String? resolution,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Dispute() when $default != null:
return $default(_that.id,_that.matchId,_that.openedBy,_that.status,_that.reason,_that.evidence,_that.escalationLevel,_that.botAttemptedAt,_that.escalatedAt,_that.resolvedAt,_that.resolvedBy,_that.resolution,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String matchId,  String openedBy,  String status,  String? reason,  Map<String, dynamic> evidence,  int escalationLevel,  DateTime? botAttemptedAt,  DateTime? escalatedAt,  DateTime? resolvedAt,  String? resolvedBy,  String? resolution,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Dispute():
return $default(_that.id,_that.matchId,_that.openedBy,_that.status,_that.reason,_that.evidence,_that.escalationLevel,_that.botAttemptedAt,_that.escalatedAt,_that.resolvedAt,_that.resolvedBy,_that.resolution,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String matchId,  String openedBy,  String status,  String? reason,  Map<String, dynamic> evidence,  int escalationLevel,  DateTime? botAttemptedAt,  DateTime? escalatedAt,  DateTime? resolvedAt,  String? resolvedBy,  String? resolution,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Dispute() when $default != null:
return $default(_that.id,_that.matchId,_that.openedBy,_that.status,_that.reason,_that.evidence,_that.escalationLevel,_that.botAttemptedAt,_that.escalatedAt,_that.resolvedAt,_that.resolvedBy,_that.resolution,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Dispute extends Dispute {
  const _Dispute({required this.id, required this.matchId, required this.openedBy, this.status = 'open', this.reason,  Map<String, dynamic> evidence = const <String, dynamic>{}, this.escalationLevel = 0, this.botAttemptedAt, this.escalatedAt, this.resolvedAt, this.resolvedBy, this.resolution, this.createdAt, this.updatedAt}): _evidence = evidence,super._();
  factory _Dispute.fromJson(Map<String, dynamic> json) => _$DisputeFromJson(json);

@override final  String id;
@override final  String matchId;
@override final  String openedBy;
@override@JsonKey() final  String status;
@override final  String? reason;
 final  Map<String, dynamic> _evidence;
@override@JsonKey() Map<String, dynamic> get evidence {
  if (_evidence is EqualUnmodifiableMapView) return _evidence;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_evidence);
}

@override@JsonKey() final  int escalationLevel;
@override final  DateTime? botAttemptedAt;
@override final  DateTime? escalatedAt;
@override final  DateTime? resolvedAt;
@override final  String? resolvedBy;
@override final  String? resolution;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Dispute
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DisputeCopyWith<_Dispute> get copyWith => __$DisputeCopyWithImpl<_Dispute>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DisputeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Dispute&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.openedBy, openedBy) || other.openedBy == openedBy)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.evidence, _evidence)&&(identical(other.escalationLevel, escalationLevel) || other.escalationLevel == escalationLevel)&&(identical(other.botAttemptedAt, botAttemptedAt) || other.botAttemptedAt == botAttemptedAt)&&(identical(other.escalatedAt, escalatedAt) || other.escalatedAt == escalatedAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.resolvedBy, resolvedBy) || other.resolvedBy == resolvedBy)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,matchId,openedBy,status,reason,const DeepCollectionEquality().hash(_evidence),escalationLevel,botAttemptedAt,escalatedAt,resolvedAt,resolvedBy,resolution,createdAt,updatedAt);
}

@override
String toString() {
    return 'Dispute(id: $id, matchId: $matchId, openedBy: $openedBy, status: $status, reason: $reason, evidence: $evidence, escalationLevel: $escalationLevel, botAttemptedAt: $botAttemptedAt, escalatedAt: $escalatedAt, resolvedAt: $resolvedAt, resolvedBy: $resolvedBy, resolution: $resolution, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DisputeCopyWith<$Res> implements $DisputeCopyWith<$Res> {
  factory _$DisputeCopyWith(_Dispute value, $Res Function(_Dispute) _then) = __$DisputeCopyWithImpl;
@override @useResult
$Res call({
 String id, String matchId, String openedBy, String status, String? reason, Map<String, dynamic> evidence, int escalationLevel, DateTime? botAttemptedAt, DateTime? escalatedAt, DateTime? resolvedAt, String? resolvedBy, String? resolution, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$DisputeCopyWithImpl<$Res>
    implements _$DisputeCopyWith<$Res> {
  __$DisputeCopyWithImpl(this._self, this._then);

  final _Dispute _self;
  final $Res Function(_Dispute) _then;

/// Create a copy of Dispute
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? matchId = null,Object? openedBy = null,Object? status = null,Object? reason = freezed,Object? evidence = null,Object? escalationLevel = null,Object? botAttemptedAt = freezed,Object? escalatedAt = freezed,Object? resolvedAt = freezed,Object? resolvedBy = freezed,Object? resolution = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Dispute(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,openedBy: null == openedBy ? _self.openedBy : openedBy // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,evidence: null == evidence ? _self._evidence : evidence // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,escalationLevel: null == escalationLevel ? _self.escalationLevel : escalationLevel // ignore: cast_nullable_to_non_nullable
as int,botAttemptedAt: freezed == botAttemptedAt ? _self.botAttemptedAt : botAttemptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,escalatedAt: freezed == escalatedAt ? _self.escalatedAt : escalatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedBy: freezed == resolvedBy ? _self.resolvedBy : resolvedBy // ignore: cast_nullable_to_non_nullable
as String?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
