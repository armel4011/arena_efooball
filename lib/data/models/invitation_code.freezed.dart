// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invitation_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvitationCode {

 String get id; String get code;@UserRoleConverter() UserRole get role; String? get generatedBy; String? get targetEmail; DateTime? get expiresAt; int get maxUses; int get usesCount; DateTime? get usedAt; String? get usedBy; List<String>? get allowedCountryCodes; List<String>? get allowedSections; DateTime? get createdAt;
/// Create a copy of InvitationCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvitationCodeCopyWith<InvitationCode> get copyWith => _$InvitationCodeCopyWithImpl<InvitationCode>(this as InvitationCode, _$identity);

  /// Serializes this InvitationCode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InvitationCode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvitationCode&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.generatedBy, _this.generatedBy) || other.generatedBy == _this.generatedBy)&&(identical(other.targetEmail, _this.targetEmail) || other.targetEmail == _this.targetEmail)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.maxUses, _this.maxUses) || other.maxUses == _this.maxUses)&&(identical(other.usesCount, _this.usesCount) || other.usesCount == _this.usesCount)&&(identical(other.usedAt, _this.usedAt) || other.usedAt == _this.usedAt)&&(identical(other.usedBy, _this.usedBy) || other.usedBy == _this.usedBy)&&const DeepCollectionEquality().equals(other.allowedCountryCodes, _this.allowedCountryCodes)&&const DeepCollectionEquality().equals(other.allowedSections, _this.allowedSections)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InvitationCode;
  return Object.hash(runtimeType,_this.id,_this.code,_this.role,_this.generatedBy,_this.targetEmail,_this.expiresAt,_this.maxUses,_this.usesCount,_this.usedAt,_this.usedBy,const DeepCollectionEquality().hash(_this.allowedCountryCodes),const DeepCollectionEquality().hash(_this.allowedSections),_this.createdAt);
}

@override
String toString() {
  final _this = this as InvitationCode;
  return 'InvitationCode(id: ${_this.id}, code: ${_this.code}, role: ${_this.role}, generatedBy: ${_this.generatedBy}, targetEmail: ${_this.targetEmail}, expiresAt: ${_this.expiresAt}, maxUses: ${_this.maxUses}, usesCount: ${_this.usesCount}, usedAt: ${_this.usedAt}, usedBy: ${_this.usedBy}, allowedCountryCodes: ${_this.allowedCountryCodes}, allowedSections: ${_this.allowedSections}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $InvitationCodeCopyWith<$Res>  {
  factory $InvitationCodeCopyWith(InvitationCode value, $Res Function(InvitationCode) _then) = _$InvitationCodeCopyWithImpl;
@useResult
$Res call({
 String id, String code,@UserRoleConverter() UserRole role, String? generatedBy, String? targetEmail, DateTime? expiresAt, int maxUses, int usesCount, DateTime? usedAt, String? usedBy, List<String>? allowedCountryCodes, List<String>? allowedSections, DateTime? createdAt
});




}
/// @nodoc
class _$InvitationCodeCopyWithImpl<$Res>
    implements $InvitationCodeCopyWith<$Res> {
  _$InvitationCodeCopyWithImpl(this._self, this._then);

  final InvitationCode _self;
  final $Res Function(InvitationCode) _then;

/// Create a copy of InvitationCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? role = null,Object? generatedBy = freezed,Object? targetEmail = freezed,Object? expiresAt = freezed,Object? maxUses = null,Object? usesCount = null,Object? usedAt = freezed,Object? usedBy = freezed,Object? allowedCountryCodes = freezed,Object? allowedSections = freezed,Object? createdAt = freezed,}) {
  return _then(InvitationCode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,generatedBy: freezed == generatedBy ? _self.generatedBy : generatedBy // ignore: cast_nullable_to_non_nullable
as String?,targetEmail: freezed == targetEmail ? _self.targetEmail : targetEmail // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,usesCount: null == usesCount ? _self.usesCount : usesCount // ignore: cast_nullable_to_non_nullable
as int,usedAt: freezed == usedAt ? _self.usedAt : usedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,usedBy: freezed == usedBy ? _self.usedBy : usedBy // ignore: cast_nullable_to_non_nullable
as String?,allowedCountryCodes: freezed == allowedCountryCodes ? _self.allowedCountryCodes : allowedCountryCodes // ignore: cast_nullable_to_non_nullable
as List<String>?,allowedSections: freezed == allowedSections ? _self.allowedSections : allowedSections // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [InvitationCode].
extension InvitationCodePatterns on InvitationCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvitationCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvitationCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvitationCode value)  $default,){
final _that = this;
switch (_that) {
case _InvitationCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvitationCode value)?  $default,){
final _that = this;
switch (_that) {
case _InvitationCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code, @UserRoleConverter()  UserRole role,  String? generatedBy,  String? targetEmail,  DateTime? expiresAt,  int maxUses,  int usesCount,  DateTime? usedAt,  String? usedBy,  List<String>? allowedCountryCodes,  List<String>? allowedSections,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvitationCode() when $default != null:
return $default(_that.id,_that.code,_that.role,_that.generatedBy,_that.targetEmail,_that.expiresAt,_that.maxUses,_that.usesCount,_that.usedAt,_that.usedBy,_that.allowedCountryCodes,_that.allowedSections,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code, @UserRoleConverter()  UserRole role,  String? generatedBy,  String? targetEmail,  DateTime? expiresAt,  int maxUses,  int usesCount,  DateTime? usedAt,  String? usedBy,  List<String>? allowedCountryCodes,  List<String>? allowedSections,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _InvitationCode():
return $default(_that.id,_that.code,_that.role,_that.generatedBy,_that.targetEmail,_that.expiresAt,_that.maxUses,_that.usesCount,_that.usedAt,_that.usedBy,_that.allowedCountryCodes,_that.allowedSections,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code, @UserRoleConverter()  UserRole role,  String? generatedBy,  String? targetEmail,  DateTime? expiresAt,  int maxUses,  int usesCount,  DateTime? usedAt,  String? usedBy,  List<String>? allowedCountryCodes,  List<String>? allowedSections,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _InvitationCode() when $default != null:
return $default(_that.id,_that.code,_that.role,_that.generatedBy,_that.targetEmail,_that.expiresAt,_that.maxUses,_that.usesCount,_that.usedAt,_that.usedBy,_that.allowedCountryCodes,_that.allowedSections,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvitationCode extends InvitationCode {
  const _InvitationCode({required this.id, required this.code, @UserRoleConverter() this.role = UserRole.admin, this.generatedBy, this.targetEmail, this.expiresAt, this.maxUses = 1, this.usesCount = 0, this.usedAt, this.usedBy,  List<String>? allowedCountryCodes,  List<String>? allowedSections, this.createdAt}): _allowedCountryCodes = allowedCountryCodes,_allowedSections = allowedSections,super._();
  factory _InvitationCode.fromJson(Map<String, dynamic> json) => _$InvitationCodeFromJson(json);

@override final  String id;
@override final  String code;
@override@JsonKey()@UserRoleConverter() final  UserRole role;
@override final  String? generatedBy;
@override final  String? targetEmail;
@override final  DateTime? expiresAt;
@override@JsonKey() final  int maxUses;
@override@JsonKey() final  int usesCount;
@override final  DateTime? usedAt;
@override final  String? usedBy;
 final  List<String>? _allowedCountryCodes;
@override List<String>? get allowedCountryCodes {
  final value = _allowedCountryCodes;
  if (value == null) return null;
  if (_allowedCountryCodes is EqualUnmodifiableListView) return _allowedCountryCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _allowedSections;
@override List<String>? get allowedSections {
  final value = _allowedSections;
  if (value == null) return null;
  if (_allowedSections is EqualUnmodifiableListView) return _allowedSections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  DateTime? createdAt;

/// Create a copy of InvitationCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitationCodeCopyWith<_InvitationCode> get copyWith => __$InvitationCodeCopyWithImpl<_InvitationCode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvitationCodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitationCode&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.role, role) || other.role == role)&&(identical(other.generatedBy, generatedBy) || other.generatedBy == generatedBy)&&(identical(other.targetEmail, targetEmail) || other.targetEmail == targetEmail)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.usesCount, usesCount) || other.usesCount == usesCount)&&(identical(other.usedAt, usedAt) || other.usedAt == usedAt)&&(identical(other.usedBy, usedBy) || other.usedBy == usedBy)&&const DeepCollectionEquality().equals(other.allowedCountryCodes, _allowedCountryCodes)&&const DeepCollectionEquality().equals(other.allowedSections, _allowedSections)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,code,role,generatedBy,targetEmail,expiresAt,maxUses,usesCount,usedAt,usedBy,const DeepCollectionEquality().hash(_allowedCountryCodes),const DeepCollectionEquality().hash(_allowedSections),createdAt);
}

@override
String toString() {
    return 'InvitationCode(id: $id, code: $code, role: $role, generatedBy: $generatedBy, targetEmail: $targetEmail, expiresAt: $expiresAt, maxUses: $maxUses, usesCount: $usesCount, usedAt: $usedAt, usedBy: $usedBy, allowedCountryCodes: $allowedCountryCodes, allowedSections: $allowedSections, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InvitationCodeCopyWith<$Res> implements $InvitationCodeCopyWith<$Res> {
  factory _$InvitationCodeCopyWith(_InvitationCode value, $Res Function(_InvitationCode) _then) = __$InvitationCodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String code,@UserRoleConverter() UserRole role, String? generatedBy, String? targetEmail, DateTime? expiresAt, int maxUses, int usesCount, DateTime? usedAt, String? usedBy, List<String>? allowedCountryCodes, List<String>? allowedSections, DateTime? createdAt
});




}
/// @nodoc
class __$InvitationCodeCopyWithImpl<$Res>
    implements _$InvitationCodeCopyWith<$Res> {
  __$InvitationCodeCopyWithImpl(this._self, this._then);

  final _InvitationCode _self;
  final $Res Function(_InvitationCode) _then;

/// Create a copy of InvitationCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? role = null,Object? generatedBy = freezed,Object? targetEmail = freezed,Object? expiresAt = freezed,Object? maxUses = null,Object? usesCount = null,Object? usedAt = freezed,Object? usedBy = freezed,Object? allowedCountryCodes = freezed,Object? allowedSections = freezed,Object? createdAt = freezed,}) {
  return _then(_InvitationCode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,generatedBy: freezed == generatedBy ? _self.generatedBy : generatedBy // ignore: cast_nullable_to_non_nullable
as String?,targetEmail: freezed == targetEmail ? _self.targetEmail : targetEmail // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,usesCount: null == usesCount ? _self.usesCount : usesCount // ignore: cast_nullable_to_non_nullable
as int,usedAt: freezed == usedAt ? _self.usedAt : usedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,usedBy: freezed == usedBy ? _self.usedBy : usedBy // ignore: cast_nullable_to_non_nullable
as String?,allowedCountryCodes: freezed == allowedCountryCodes ? _self._allowedCountryCodes : allowedCountryCodes // ignore: cast_nullable_to_non_nullable
as List<String>?,allowedSections: freezed == allowedSections ? _self._allowedSections : allowedSections // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
