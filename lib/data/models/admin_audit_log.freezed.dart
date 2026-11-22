// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_audit_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdminAuditLog {

 String get id; String get adminId; String get action; String? get targetType; String? get targetId; Map<String, dynamic> get beforeState; Map<String, dynamic> get afterState; String? get ipAddress; String? get userAgent; DateTime? get createdAt;
/// Create a copy of AdminAuditLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminAuditLogCopyWith<AdminAuditLog> get copyWith => _$AdminAuditLogCopyWithImpl<AdminAuditLog>(this as AdminAuditLog, _$identity);

  /// Serializes this AdminAuditLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AdminAuditLog;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminAuditLog&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.adminId, _this.adminId) || other.adminId == _this.adminId)&&(identical(other.action, _this.action) || other.action == _this.action)&&(identical(other.targetType, _this.targetType) || other.targetType == _this.targetType)&&(identical(other.targetId, _this.targetId) || other.targetId == _this.targetId)&&const DeepCollectionEquality().equals(other.beforeState, _this.beforeState)&&const DeepCollectionEquality().equals(other.afterState, _this.afterState)&&(identical(other.ipAddress, _this.ipAddress) || other.ipAddress == _this.ipAddress)&&(identical(other.userAgent, _this.userAgent) || other.userAgent == _this.userAgent)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AdminAuditLog;
  return Object.hash(runtimeType,_this.id,_this.adminId,_this.action,_this.targetType,_this.targetId,const DeepCollectionEquality().hash(_this.beforeState),const DeepCollectionEquality().hash(_this.afterState),_this.ipAddress,_this.userAgent,_this.createdAt);
}

@override
String toString() {
  final _this = this as AdminAuditLog;
  return 'AdminAuditLog(id: ${_this.id}, adminId: ${_this.adminId}, action: ${_this.action}, targetType: ${_this.targetType}, targetId: ${_this.targetId}, beforeState: ${_this.beforeState}, afterState: ${_this.afterState}, ipAddress: ${_this.ipAddress}, userAgent: ${_this.userAgent}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $AdminAuditLogCopyWith<$Res>  {
  factory $AdminAuditLogCopyWith(AdminAuditLog value, $Res Function(AdminAuditLog) _then) = _$AdminAuditLogCopyWithImpl;
@useResult
$Res call({
 String id, String adminId, String action, String? targetType, String? targetId, Map<String, dynamic> beforeState, Map<String, dynamic> afterState, String? ipAddress, String? userAgent, DateTime? createdAt
});




}
/// @nodoc
class _$AdminAuditLogCopyWithImpl<$Res>
    implements $AdminAuditLogCopyWith<$Res> {
  _$AdminAuditLogCopyWithImpl(this._self, this._then);

  final AdminAuditLog _self;
  final $Res Function(AdminAuditLog) _then;

/// Create a copy of AdminAuditLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? adminId = null,Object? action = null,Object? targetType = freezed,Object? targetId = freezed,Object? beforeState = null,Object? afterState = null,Object? ipAddress = freezed,Object? userAgent = freezed,Object? createdAt = freezed,}) {
  return _then(AdminAuditLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,adminId: null == adminId ? _self.adminId : adminId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,targetType: freezed == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String?,targetId: freezed == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String?,beforeState: null == beforeState ? _self.beforeState : beforeState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,afterState: null == afterState ? _self.afterState : afterState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,userAgent: freezed == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminAuditLog].
extension AdminAuditLogPatterns on AdminAuditLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminAuditLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminAuditLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminAuditLog value)  $default,){
final _that = this;
switch (_that) {
case _AdminAuditLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminAuditLog value)?  $default,){
final _that = this;
switch (_that) {
case _AdminAuditLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String adminId,  String action,  String? targetType,  String? targetId,  Map<String, dynamic> beforeState,  Map<String, dynamic> afterState,  String? ipAddress,  String? userAgent,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminAuditLog() when $default != null:
return $default(_that.id,_that.adminId,_that.action,_that.targetType,_that.targetId,_that.beforeState,_that.afterState,_that.ipAddress,_that.userAgent,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String adminId,  String action,  String? targetType,  String? targetId,  Map<String, dynamic> beforeState,  Map<String, dynamic> afterState,  String? ipAddress,  String? userAgent,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AdminAuditLog():
return $default(_that.id,_that.adminId,_that.action,_that.targetType,_that.targetId,_that.beforeState,_that.afterState,_that.ipAddress,_that.userAgent,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String adminId,  String action,  String? targetType,  String? targetId,  Map<String, dynamic> beforeState,  Map<String, dynamic> afterState,  String? ipAddress,  String? userAgent,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminAuditLog() when $default != null:
return $default(_that.id,_that.adminId,_that.action,_that.targetType,_that.targetId,_that.beforeState,_that.afterState,_that.ipAddress,_that.userAgent,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminAuditLog extends AdminAuditLog {
  const _AdminAuditLog({required this.id, required this.adminId, required this.action, this.targetType, this.targetId,  Map<String, dynamic> beforeState = const <String, dynamic>{},  Map<String, dynamic> afterState = const <String, dynamic>{}, this.ipAddress, this.userAgent, this.createdAt}): _beforeState = beforeState,_afterState = afterState,super._();
  factory _AdminAuditLog.fromJson(Map<String, dynamic> json) => _$AdminAuditLogFromJson(json);

@override final  String id;
@override final  String adminId;
@override final  String action;
@override final  String? targetType;
@override final  String? targetId;
 final  Map<String, dynamic> _beforeState;
@override@JsonKey() Map<String, dynamic> get beforeState {
  if (_beforeState is EqualUnmodifiableMapView) return _beforeState;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_beforeState);
}

 final  Map<String, dynamic> _afterState;
@override@JsonKey() Map<String, dynamic> get afterState {
  if (_afterState is EqualUnmodifiableMapView) return _afterState;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_afterState);
}

@override final  String? ipAddress;
@override final  String? userAgent;
@override final  DateTime? createdAt;

/// Create a copy of AdminAuditLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminAuditLogCopyWith<_AdminAuditLog> get copyWith => __$AdminAuditLogCopyWithImpl<_AdminAuditLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminAuditLogToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminAuditLog&&(identical(other.id, id) || other.id == id)&&(identical(other.adminId, adminId) || other.adminId == adminId)&&(identical(other.action, action) || other.action == action)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&const DeepCollectionEquality().equals(other.beforeState, _beforeState)&&const DeepCollectionEquality().equals(other.afterState, _afterState)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,adminId,action,targetType,targetId,const DeepCollectionEquality().hash(_beforeState),const DeepCollectionEquality().hash(_afterState),ipAddress,userAgent,createdAt);
}

@override
String toString() {
    return 'AdminAuditLog(id: $id, adminId: $adminId, action: $action, targetType: $targetType, targetId: $targetId, beforeState: $beforeState, afterState: $afterState, ipAddress: $ipAddress, userAgent: $userAgent, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AdminAuditLogCopyWith<$Res> implements $AdminAuditLogCopyWith<$Res> {
  factory _$AdminAuditLogCopyWith(_AdminAuditLog value, $Res Function(_AdminAuditLog) _then) = __$AdminAuditLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String adminId, String action, String? targetType, String? targetId, Map<String, dynamic> beforeState, Map<String, dynamic> afterState, String? ipAddress, String? userAgent, DateTime? createdAt
});




}
/// @nodoc
class __$AdminAuditLogCopyWithImpl<$Res>
    implements _$AdminAuditLogCopyWith<$Res> {
  __$AdminAuditLogCopyWithImpl(this._self, this._then);

  final _AdminAuditLog _self;
  final $Res Function(_AdminAuditLog) _then;

/// Create a copy of AdminAuditLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? adminId = null,Object? action = null,Object? targetType = freezed,Object? targetId = freezed,Object? beforeState = null,Object? afterState = null,Object? ipAddress = freezed,Object? userAgent = freezed,Object? createdAt = freezed,}) {
  return _then(_AdminAuditLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,adminId: null == adminId ? _self.adminId : adminId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,targetType: freezed == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String?,targetId: freezed == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String?,beforeState: null == beforeState ? _self._beforeState : beforeState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,afterState: null == afterState ? _self._afterState : afterState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,userAgent: freezed == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
