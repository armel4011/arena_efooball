// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_audit_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AdminAuditLog _$AdminAuditLogFromJson(Map<String, dynamic> json) {
  return _AdminAuditLog.fromJson(json);
}

/// @nodoc
mixin _$AdminAuditLog {
  String get id => throw _privateConstructorUsedError;
  String get adminId => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  String? get targetType => throw _privateConstructorUsedError;
  String? get targetId => throw _privateConstructorUsedError;
  Map<String, dynamic> get beforeState => throw _privateConstructorUsedError;
  Map<String, dynamic> get afterState => throw _privateConstructorUsedError;
  String? get ipAddress => throw _privateConstructorUsedError;
  String? get userAgent => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this AdminAuditLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminAuditLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminAuditLogCopyWith<AdminAuditLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminAuditLogCopyWith<$Res> {
  factory $AdminAuditLogCopyWith(
          AdminAuditLog value, $Res Function(AdminAuditLog) then) =
      _$AdminAuditLogCopyWithImpl<$Res, AdminAuditLog>;
  @useResult
  $Res call(
      {String id,
      String adminId,
      String action,
      String? targetType,
      String? targetId,
      Map<String, dynamic> beforeState,
      Map<String, dynamic> afterState,
      String? ipAddress,
      String? userAgent,
      DateTime? createdAt});
}

/// @nodoc
class _$AdminAuditLogCopyWithImpl<$Res, $Val extends AdminAuditLog>
    implements $AdminAuditLogCopyWith<$Res> {
  _$AdminAuditLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminAuditLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? adminId = null,
    Object? action = null,
    Object? targetType = freezed,
    Object? targetId = freezed,
    Object? beforeState = null,
    Object? afterState = null,
    Object? ipAddress = freezed,
    Object? userAgent = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      adminId: null == adminId
          ? _value.adminId
          : adminId // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      targetType: freezed == targetType
          ? _value.targetType
          : targetType // ignore: cast_nullable_to_non_nullable
              as String?,
      targetId: freezed == targetId
          ? _value.targetId
          : targetId // ignore: cast_nullable_to_non_nullable
              as String?,
      beforeState: null == beforeState
          ? _value.beforeState
          : beforeState // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      afterState: null == afterState
          ? _value.afterState
          : afterState // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      ipAddress: freezed == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      userAgent: freezed == userAgent
          ? _value.userAgent
          : userAgent // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminAuditLogImplCopyWith<$Res>
    implements $AdminAuditLogCopyWith<$Res> {
  factory _$$AdminAuditLogImplCopyWith(
          _$AdminAuditLogImpl value, $Res Function(_$AdminAuditLogImpl) then) =
      __$$AdminAuditLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String adminId,
      String action,
      String? targetType,
      String? targetId,
      Map<String, dynamic> beforeState,
      Map<String, dynamic> afterState,
      String? ipAddress,
      String? userAgent,
      DateTime? createdAt});
}

/// @nodoc
class __$$AdminAuditLogImplCopyWithImpl<$Res>
    extends _$AdminAuditLogCopyWithImpl<$Res, _$AdminAuditLogImpl>
    implements _$$AdminAuditLogImplCopyWith<$Res> {
  __$$AdminAuditLogImplCopyWithImpl(
      _$AdminAuditLogImpl _value, $Res Function(_$AdminAuditLogImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdminAuditLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? adminId = null,
    Object? action = null,
    Object? targetType = freezed,
    Object? targetId = freezed,
    Object? beforeState = null,
    Object? afterState = null,
    Object? ipAddress = freezed,
    Object? userAgent = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$AdminAuditLogImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      adminId: null == adminId
          ? _value.adminId
          : adminId // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      targetType: freezed == targetType
          ? _value.targetType
          : targetType // ignore: cast_nullable_to_non_nullable
              as String?,
      targetId: freezed == targetId
          ? _value.targetId
          : targetId // ignore: cast_nullable_to_non_nullable
              as String?,
      beforeState: null == beforeState
          ? _value._beforeState
          : beforeState // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      afterState: null == afterState
          ? _value._afterState
          : afterState // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      ipAddress: freezed == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      userAgent: freezed == userAgent
          ? _value.userAgent
          : userAgent // ignore: cast_nullable_to_non_nullable
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
class _$AdminAuditLogImpl extends _AdminAuditLog {
  const _$AdminAuditLogImpl(
      {required this.id,
      required this.adminId,
      required this.action,
      this.targetType,
      this.targetId,
      final Map<String, dynamic> beforeState = const <String, dynamic>{},
      final Map<String, dynamic> afterState = const <String, dynamic>{},
      this.ipAddress,
      this.userAgent,
      this.createdAt})
      : _beforeState = beforeState,
        _afterState = afterState,
        super._();

  factory _$AdminAuditLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminAuditLogImplFromJson(json);

  @override
  final String id;
  @override
  final String adminId;
  @override
  final String action;
  @override
  final String? targetType;
  @override
  final String? targetId;
  final Map<String, dynamic> _beforeState;
  @override
  @JsonKey()
  Map<String, dynamic> get beforeState {
    if (_beforeState is EqualUnmodifiableMapView) return _beforeState;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_beforeState);
  }

  final Map<String, dynamic> _afterState;
  @override
  @JsonKey()
  Map<String, dynamic> get afterState {
    if (_afterState is EqualUnmodifiableMapView) return _afterState;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_afterState);
  }

  @override
  final String? ipAddress;
  @override
  final String? userAgent;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'AdminAuditLog(id: $id, adminId: $adminId, action: $action, targetType: $targetType, targetId: $targetId, beforeState: $beforeState, afterState: $afterState, ipAddress: $ipAddress, userAgent: $userAgent, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminAuditLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.adminId, adminId) || other.adminId == adminId) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.targetType, targetType) ||
                other.targetType == targetType) &&
            (identical(other.targetId, targetId) ||
                other.targetId == targetId) &&
            const DeepCollectionEquality()
                .equals(other._beforeState, _beforeState) &&
            const DeepCollectionEquality()
                .equals(other._afterState, _afterState) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.userAgent, userAgent) ||
                other.userAgent == userAgent) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      adminId,
      action,
      targetType,
      targetId,
      const DeepCollectionEquality().hash(_beforeState),
      const DeepCollectionEquality().hash(_afterState),
      ipAddress,
      userAgent,
      createdAt);

  /// Create a copy of AdminAuditLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminAuditLogImplCopyWith<_$AdminAuditLogImpl> get copyWith =>
      __$$AdminAuditLogImplCopyWithImpl<_$AdminAuditLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminAuditLogImplToJson(
      this,
    );
  }
}

abstract class _AdminAuditLog extends AdminAuditLog {
  const factory _AdminAuditLog(
      {required final String id,
      required final String adminId,
      required final String action,
      final String? targetType,
      final String? targetId,
      final Map<String, dynamic> beforeState,
      final Map<String, dynamic> afterState,
      final String? ipAddress,
      final String? userAgent,
      final DateTime? createdAt}) = _$AdminAuditLogImpl;
  const _AdminAuditLog._() : super._();

  factory _AdminAuditLog.fromJson(Map<String, dynamic> json) =
      _$AdminAuditLogImpl.fromJson;

  @override
  String get id;
  @override
  String get adminId;
  @override
  String get action;
  @override
  String? get targetType;
  @override
  String? get targetId;
  @override
  Map<String, dynamic> get beforeState;
  @override
  Map<String, dynamic> get afterState;
  @override
  String? get ipAddress;
  @override
  String? get userAgent;
  @override
  DateTime? get createdAt;

  /// Create a copy of AdminAuditLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminAuditLogImplCopyWith<_$AdminAuditLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
