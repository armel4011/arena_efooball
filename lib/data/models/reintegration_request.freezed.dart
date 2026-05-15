// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reintegration_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReintegrationRequest _$ReintegrationRequestFromJson(Map<String, dynamic> json) {
  return _ReintegrationRequest.fromJson(json);
}

/// @nodoc
mixin _$ReintegrationRequest {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // pending | approved | rejected
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get resolvedAt => throw _privateConstructorUsedError;
  String? get resolvedBy => throw _privateConstructorUsedError;
  String? get resolutionReason => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ReintegrationRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReintegrationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReintegrationRequestCopyWith<ReintegrationRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReintegrationRequestCopyWith<$Res> {
  factory $ReintegrationRequestCopyWith(ReintegrationRequest value,
          $Res Function(ReintegrationRequest) then) =
      _$ReintegrationRequestCopyWithImpl<$Res, ReintegrationRequest>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String message,
      String status,
      DateTime? createdAt,
      DateTime? resolvedAt,
      String? resolvedBy,
      String? resolutionReason,
      DateTime? updatedAt});
}

/// @nodoc
class _$ReintegrationRequestCopyWithImpl<$Res,
        $Val extends ReintegrationRequest>
    implements $ReintegrationRequestCopyWith<$Res> {
  _$ReintegrationRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReintegrationRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? message = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
    Object? resolutionReason = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      resolvedAt: freezed == resolvedAt
          ? _value.resolvedAt
          : resolvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      resolvedBy: freezed == resolvedBy
          ? _value.resolvedBy
          : resolvedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      resolutionReason: freezed == resolutionReason
          ? _value.resolutionReason
          : resolutionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReintegrationRequestImplCopyWith<$Res>
    implements $ReintegrationRequestCopyWith<$Res> {
  factory _$$ReintegrationRequestImplCopyWith(_$ReintegrationRequestImpl value,
          $Res Function(_$ReintegrationRequestImpl) then) =
      __$$ReintegrationRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String message,
      String status,
      DateTime? createdAt,
      DateTime? resolvedAt,
      String? resolvedBy,
      String? resolutionReason,
      DateTime? updatedAt});
}

/// @nodoc
class __$$ReintegrationRequestImplCopyWithImpl<$Res>
    extends _$ReintegrationRequestCopyWithImpl<$Res, _$ReintegrationRequestImpl>
    implements _$$ReintegrationRequestImplCopyWith<$Res> {
  __$$ReintegrationRequestImplCopyWithImpl(_$ReintegrationRequestImpl _value,
      $Res Function(_$ReintegrationRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReintegrationRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? message = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
    Object? resolutionReason = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ReintegrationRequestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      resolvedAt: freezed == resolvedAt
          ? _value.resolvedAt
          : resolvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      resolvedBy: freezed == resolvedBy
          ? _value.resolvedBy
          : resolvedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      resolutionReason: freezed == resolutionReason
          ? _value.resolutionReason
          : resolutionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReintegrationRequestImpl extends _ReintegrationRequest {
  const _$ReintegrationRequestImpl(
      {required this.id,
      required this.userId,
      required this.message,
      this.status = 'pending',
      this.createdAt,
      this.resolvedAt,
      this.resolvedBy,
      this.resolutionReason,
      this.updatedAt})
      : super._();

  factory _$ReintegrationRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReintegrationRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String message;
  @override
  @JsonKey()
  final String status;
// pending | approved | rejected
  @override
  final DateTime? createdAt;
  @override
  final DateTime? resolvedAt;
  @override
  final String? resolvedBy;
  @override
  final String? resolutionReason;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ReintegrationRequest(id: $id, userId: $userId, message: $message, status: $status, createdAt: $createdAt, resolvedAt: $resolvedAt, resolvedBy: $resolvedBy, resolutionReason: $resolutionReason, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReintegrationRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.resolvedAt, resolvedAt) ||
                other.resolvedAt == resolvedAt) &&
            (identical(other.resolvedBy, resolvedBy) ||
                other.resolvedBy == resolvedBy) &&
            (identical(other.resolutionReason, resolutionReason) ||
                other.resolutionReason == resolutionReason) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, message, status,
      createdAt, resolvedAt, resolvedBy, resolutionReason, updatedAt);

  /// Create a copy of ReintegrationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReintegrationRequestImplCopyWith<_$ReintegrationRequestImpl>
      get copyWith =>
          __$$ReintegrationRequestImplCopyWithImpl<_$ReintegrationRequestImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReintegrationRequestImplToJson(
      this,
    );
  }
}

abstract class _ReintegrationRequest extends ReintegrationRequest {
  const factory _ReintegrationRequest(
      {required final String id,
      required final String userId,
      required final String message,
      final String status,
      final DateTime? createdAt,
      final DateTime? resolvedAt,
      final String? resolvedBy,
      final String? resolutionReason,
      final DateTime? updatedAt}) = _$ReintegrationRequestImpl;
  const _ReintegrationRequest._() : super._();

  factory _ReintegrationRequest.fromJson(Map<String, dynamic> json) =
      _$ReintegrationRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get message;
  @override
  String get status; // pending | approved | rejected
  @override
  DateTime? get createdAt;
  @override
  DateTime? get resolvedAt;
  @override
  String? get resolvedBy;
  @override
  String? get resolutionReason;
  @override
  DateTime? get updatedAt;

  /// Create a copy of ReintegrationRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReintegrationRequestImplCopyWith<_$ReintegrationRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}
