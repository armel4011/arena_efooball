// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_stream.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MatchStream _$MatchStreamFromJson(Map<String, dynamic> json) {
  return _MatchStream.fromJson(json);
}

/// @nodoc
mixin _$MatchStream {
  String get id => throw _privateConstructorUsedError;
  String get matchId => throw _privateConstructorUsedError;
  String get playerId => throw _privateConstructorUsedError;
  bool get isPublic => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get url => throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;
  DateTime? get endedAt =>
      throw _privateConstructorUsedError; // Système anti-triche DUAL : provenance de l'enregistrement.
// `native_recorder` (filet de sécurité) | `livekit_track_egress`.
  String get provider =>
      throw _privateConstructorUsedError; // Clé objet privée dans le bucket (résolue en URL signée côté admin).
  String? get storagePath =>
      throw _privateConstructorUsedError; // Identifiant LiveKit Track Egress (null pour le natif).
  String? get egressId =>
      throw _privateConstructorUsedError; // Échéance de rétention (purge cleanup-streams).
  DateTime? get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this MatchStream to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatchStream
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatchStreamCopyWith<MatchStream> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchStreamCopyWith<$Res> {
  factory $MatchStreamCopyWith(
          MatchStream value, $Res Function(MatchStream) then) =
      _$MatchStreamCopyWithImpl<$Res, MatchStream>;
  @useResult
  $Res call(
      {String id,
      String matchId,
      String playerId,
      bool isPublic,
      bool isActive,
      String? url,
      DateTime? startedAt,
      DateTime? endedAt,
      String provider,
      String? storagePath,
      String? egressId,
      DateTime? expiresAt});
}

/// @nodoc
class _$MatchStreamCopyWithImpl<$Res, $Val extends MatchStream>
    implements $MatchStreamCopyWith<$Res> {
  _$MatchStreamCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatchStream
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? matchId = null,
    Object? playerId = null,
    Object? isPublic = null,
    Object? isActive = null,
    Object? url = freezed,
    Object? startedAt = freezed,
    Object? endedAt = freezed,
    Object? provider = null,
    Object? storagePath = freezed,
    Object? egressId = freezed,
    Object? expiresAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      matchId: null == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String,
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String,
      storagePath: freezed == storagePath
          ? _value.storagePath
          : storagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      egressId: freezed == egressId
          ? _value.egressId
          : egressId // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MatchStreamImplCopyWith<$Res>
    implements $MatchStreamCopyWith<$Res> {
  factory _$$MatchStreamImplCopyWith(
          _$MatchStreamImpl value, $Res Function(_$MatchStreamImpl) then) =
      __$$MatchStreamImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String matchId,
      String playerId,
      bool isPublic,
      bool isActive,
      String? url,
      DateTime? startedAt,
      DateTime? endedAt,
      String provider,
      String? storagePath,
      String? egressId,
      DateTime? expiresAt});
}

/// @nodoc
class __$$MatchStreamImplCopyWithImpl<$Res>
    extends _$MatchStreamCopyWithImpl<$Res, _$MatchStreamImpl>
    implements _$$MatchStreamImplCopyWith<$Res> {
  __$$MatchStreamImplCopyWithImpl(
      _$MatchStreamImpl _value, $Res Function(_$MatchStreamImpl) _then)
      : super(_value, _then);

  /// Create a copy of MatchStream
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? matchId = null,
    Object? playerId = null,
    Object? isPublic = null,
    Object? isActive = null,
    Object? url = freezed,
    Object? startedAt = freezed,
    Object? endedAt = freezed,
    Object? provider = null,
    Object? storagePath = freezed,
    Object? egressId = freezed,
    Object? expiresAt = freezed,
  }) {
    return _then(_$MatchStreamImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      matchId: null == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String,
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String,
      storagePath: freezed == storagePath
          ? _value.storagePath
          : storagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      egressId: freezed == egressId
          ? _value.egressId
          : egressId // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchStreamImpl implements _MatchStream {
  const _$MatchStreamImpl(
      {required this.id,
      required this.matchId,
      required this.playerId,
      this.isPublic = false,
      this.isActive = true,
      this.url,
      this.startedAt,
      this.endedAt,
      this.provider = 'native_recorder',
      this.storagePath,
      this.egressId,
      this.expiresAt});

  factory _$MatchStreamImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchStreamImplFromJson(json);

  @override
  final String id;
  @override
  final String matchId;
  @override
  final String playerId;
  @override
  @JsonKey()
  final bool isPublic;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final String? url;
  @override
  final DateTime? startedAt;
  @override
  final DateTime? endedAt;
// Système anti-triche DUAL : provenance de l'enregistrement.
// `native_recorder` (filet de sécurité) | `livekit_track_egress`.
  @override
  @JsonKey()
  final String provider;
// Clé objet privée dans le bucket (résolue en URL signée côté admin).
  @override
  final String? storagePath;
// Identifiant LiveKit Track Egress (null pour le natif).
  @override
  final String? egressId;
// Échéance de rétention (purge cleanup-streams).
  @override
  final DateTime? expiresAt;

  @override
  String toString() {
    return 'MatchStream(id: $id, matchId: $matchId, playerId: $playerId, isPublic: $isPublic, isActive: $isActive, url: $url, startedAt: $startedAt, endedAt: $endedAt, provider: $provider, storagePath: $storagePath, egressId: $egressId, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchStreamImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.matchId, matchId) || other.matchId == matchId) &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.storagePath, storagePath) ||
                other.storagePath == storagePath) &&
            (identical(other.egressId, egressId) ||
                other.egressId == egressId) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      matchId,
      playerId,
      isPublic,
      isActive,
      url,
      startedAt,
      endedAt,
      provider,
      storagePath,
      egressId,
      expiresAt);

  /// Create a copy of MatchStream
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchStreamImplCopyWith<_$MatchStreamImpl> get copyWith =>
      __$$MatchStreamImplCopyWithImpl<_$MatchStreamImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchStreamImplToJson(
      this,
    );
  }
}

abstract class _MatchStream implements MatchStream {
  const factory _MatchStream(
      {required final String id,
      required final String matchId,
      required final String playerId,
      final bool isPublic,
      final bool isActive,
      final String? url,
      final DateTime? startedAt,
      final DateTime? endedAt,
      final String provider,
      final String? storagePath,
      final String? egressId,
      final DateTime? expiresAt}) = _$MatchStreamImpl;

  factory _MatchStream.fromJson(Map<String, dynamic> json) =
      _$MatchStreamImpl.fromJson;

  @override
  String get id;
  @override
  String get matchId;
  @override
  String get playerId;
  @override
  bool get isPublic;
  @override
  bool get isActive;
  @override
  String? get url;
  @override
  DateTime? get startedAt;
  @override
  DateTime?
      get endedAt; // Système anti-triche DUAL : provenance de l'enregistrement.
// `native_recorder` (filet de sécurité) | `livekit_track_egress`.
  @override
  String
      get provider; // Clé objet privée dans le bucket (résolue en URL signée côté admin).
  @override
  String?
      get storagePath; // Identifiant LiveKit Track Egress (null pour le natif).
  @override
  String? get egressId; // Échéance de rétention (purge cleanup-streams).
  @override
  DateTime? get expiresAt;

  /// Create a copy of MatchStream
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatchStreamImplCopyWith<_$MatchStreamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
