// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invitation_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InvitationCode _$InvitationCodeFromJson(Map<String, dynamic> json) {
  return _InvitationCode.fromJson(json);
}

/// @nodoc
mixin _$InvitationCode {
  String get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  @UserRoleConverter()
  UserRole get role => throw _privateConstructorUsedError;
  String? get generatedBy => throw _privateConstructorUsedError;
  String? get targetEmail => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  int get maxUses => throw _privateConstructorUsedError;
  int get usesCount => throw _privateConstructorUsedError;
  DateTime? get usedAt => throw _privateConstructorUsedError;
  String? get usedBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this InvitationCode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InvitationCode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvitationCodeCopyWith<InvitationCode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvitationCodeCopyWith<$Res> {
  factory $InvitationCodeCopyWith(
          InvitationCode value, $Res Function(InvitationCode) then) =
      _$InvitationCodeCopyWithImpl<$Res, InvitationCode>;
  @useResult
  $Res call(
      {String id,
      String code,
      @UserRoleConverter() UserRole role,
      String? generatedBy,
      String? targetEmail,
      DateTime? expiresAt,
      int maxUses,
      int usesCount,
      DateTime? usedAt,
      String? usedBy,
      DateTime? createdAt});
}

/// @nodoc
class _$InvitationCodeCopyWithImpl<$Res, $Val extends InvitationCode>
    implements $InvitationCodeCopyWith<$Res> {
  _$InvitationCodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InvitationCode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? role = null,
    Object? generatedBy = freezed,
    Object? targetEmail = freezed,
    Object? expiresAt = freezed,
    Object? maxUses = null,
    Object? usesCount = null,
    Object? usedAt = freezed,
    Object? usedBy = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      generatedBy: freezed == generatedBy
          ? _value.generatedBy
          : generatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      targetEmail: freezed == targetEmail
          ? _value.targetEmail
          : targetEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      maxUses: null == maxUses
          ? _value.maxUses
          : maxUses // ignore: cast_nullable_to_non_nullable
              as int,
      usesCount: null == usesCount
          ? _value.usesCount
          : usesCount // ignore: cast_nullable_to_non_nullable
              as int,
      usedAt: freezed == usedAt
          ? _value.usedAt
          : usedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      usedBy: freezed == usedBy
          ? _value.usedBy
          : usedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InvitationCodeImplCopyWith<$Res>
    implements $InvitationCodeCopyWith<$Res> {
  factory _$$InvitationCodeImplCopyWith(_$InvitationCodeImpl value,
          $Res Function(_$InvitationCodeImpl) then) =
      __$$InvitationCodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String code,
      @UserRoleConverter() UserRole role,
      String? generatedBy,
      String? targetEmail,
      DateTime? expiresAt,
      int maxUses,
      int usesCount,
      DateTime? usedAt,
      String? usedBy,
      DateTime? createdAt});
}

/// @nodoc
class __$$InvitationCodeImplCopyWithImpl<$Res>
    extends _$InvitationCodeCopyWithImpl<$Res, _$InvitationCodeImpl>
    implements _$$InvitationCodeImplCopyWith<$Res> {
  __$$InvitationCodeImplCopyWithImpl(
      _$InvitationCodeImpl _value, $Res Function(_$InvitationCodeImpl) _then)
      : super(_value, _then);

  /// Create a copy of InvitationCode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? role = null,
    Object? generatedBy = freezed,
    Object? targetEmail = freezed,
    Object? expiresAt = freezed,
    Object? maxUses = null,
    Object? usesCount = null,
    Object? usedAt = freezed,
    Object? usedBy = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$InvitationCodeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      generatedBy: freezed == generatedBy
          ? _value.generatedBy
          : generatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      targetEmail: freezed == targetEmail
          ? _value.targetEmail
          : targetEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      maxUses: null == maxUses
          ? _value.maxUses
          : maxUses // ignore: cast_nullable_to_non_nullable
              as int,
      usesCount: null == usesCount
          ? _value.usesCount
          : usesCount // ignore: cast_nullable_to_non_nullable
              as int,
      usedAt: freezed == usedAt
          ? _value.usedAt
          : usedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      usedBy: freezed == usedBy
          ? _value.usedBy
          : usedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InvitationCodeImpl extends _InvitationCode {
  const _$InvitationCodeImpl(
      {required this.id,
      required this.code,
      @UserRoleConverter() this.role = UserRole.admin,
      this.generatedBy,
      this.targetEmail,
      this.expiresAt,
      this.maxUses = 1,
      this.usesCount = 0,
      this.usedAt,
      this.usedBy,
      this.createdAt})
      : super._();

  factory _$InvitationCodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvitationCodeImplFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  @JsonKey()
  @UserRoleConverter()
  final UserRole role;
  @override
  final String? generatedBy;
  @override
  final String? targetEmail;
  @override
  final DateTime? expiresAt;
  @override
  @JsonKey()
  final int maxUses;
  @override
  @JsonKey()
  final int usesCount;
  @override
  final DateTime? usedAt;
  @override
  final String? usedBy;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'InvitationCode(id: $id, code: $code, role: $role, generatedBy: $generatedBy, targetEmail: $targetEmail, expiresAt: $expiresAt, maxUses: $maxUses, usesCount: $usesCount, usedAt: $usedAt, usedBy: $usedBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvitationCodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.generatedBy, generatedBy) ||
                other.generatedBy == generatedBy) &&
            (identical(other.targetEmail, targetEmail) ||
                other.targetEmail == targetEmail) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.maxUses, maxUses) || other.maxUses == maxUses) &&
            (identical(other.usesCount, usesCount) ||
                other.usesCount == usesCount) &&
            (identical(other.usedAt, usedAt) || other.usedAt == usedAt) &&
            (identical(other.usedBy, usedBy) || other.usedBy == usedBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, code, role, generatedBy,
      targetEmail, expiresAt, maxUses, usesCount, usedAt, usedBy, createdAt);

  /// Create a copy of InvitationCode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvitationCodeImplCopyWith<_$InvitationCodeImpl> get copyWith =>
      __$$InvitationCodeImplCopyWithImpl<_$InvitationCodeImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvitationCodeImplToJson(
      this,
    );
  }
}

abstract class _InvitationCode extends InvitationCode {
  const factory _InvitationCode(
      {required final String id,
      required final String code,
      @UserRoleConverter() final UserRole role,
      final String? generatedBy,
      final String? targetEmail,
      final DateTime? expiresAt,
      final int maxUses,
      final int usesCount,
      final DateTime? usedAt,
      final String? usedBy,
      final DateTime? createdAt}) = _$InvitationCodeImpl;
  const _InvitationCode._() : super._();

  factory _InvitationCode.fromJson(Map<String, dynamic> json) =
      _$InvitationCodeImpl.fromJson;

  @override
  String get id;
  @override
  String get code;
  @override
  @UserRoleConverter()
  UserRole get role;
  @override
  String? get generatedBy;
  @override
  String? get targetEmail;
  @override
  DateTime? get expiresAt;
  @override
  int get maxUses;
  @override
  int get usesCount;
  @override
  DateTime? get usedAt;
  @override
  String? get usedBy;
  @override
  DateTime? get createdAt;

  /// Create a copy of InvitationCode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvitationCodeImplCopyWith<_$InvitationCodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
