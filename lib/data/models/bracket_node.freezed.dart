// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bracket_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BracketNode _$BracketNodeFromJson(Map<String, dynamic> json) {
  return _BracketNode.fromJson(json);
}

/// @nodoc
mixin _$BracketNode {
  String get id => throw _privateConstructorUsedError;
  String get phaseId => throw _privateConstructorUsedError;
  String get competitionId => throw _privateConstructorUsedError;
  int get roundNumber => throw _privateConstructorUsedError;
  int get positionInRound => throw _privateConstructorUsedError;
  int get totalRounds => throw _privateConstructorUsedError;
  String? get matchId => throw _privateConstructorUsedError;
  String? get nextNodeId => throw _privateConstructorUsedError;
  String? get parentNodeId => throw _privateConstructorUsedError;
  String? get nextPosition => throw _privateConstructorUsedError;
  bool get isGrandFinal => throw _privateConstructorUsedError;
  bool get isThirdPlaceMatch => throw _privateConstructorUsedError;
  bool get isBye => throw _privateConstructorUsedError;
  String? get byePlayerId => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this BracketNode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BracketNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BracketNodeCopyWith<BracketNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BracketNodeCopyWith<$Res> {
  factory $BracketNodeCopyWith(
          BracketNode value, $Res Function(BracketNode) then) =
      _$BracketNodeCopyWithImpl<$Res, BracketNode>;
  @useResult
  $Res call(
      {String id,
      String phaseId,
      String competitionId,
      int roundNumber,
      int positionInRound,
      int totalRounds,
      String? matchId,
      String? nextNodeId,
      String? parentNodeId,
      String? nextPosition,
      bool isGrandFinal,
      bool isThirdPlaceMatch,
      bool isBye,
      String? byePlayerId,
      DateTime? createdAt});
}

/// @nodoc
class _$BracketNodeCopyWithImpl<$Res, $Val extends BracketNode>
    implements $BracketNodeCopyWith<$Res> {
  _$BracketNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BracketNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phaseId = null,
    Object? competitionId = null,
    Object? roundNumber = null,
    Object? positionInRound = null,
    Object? totalRounds = null,
    Object? matchId = freezed,
    Object? nextNodeId = freezed,
    Object? parentNodeId = freezed,
    Object? nextPosition = freezed,
    Object? isGrandFinal = null,
    Object? isThirdPlaceMatch = null,
    Object? isBye = null,
    Object? byePlayerId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      phaseId: null == phaseId
          ? _value.phaseId
          : phaseId // ignore: cast_nullable_to_non_nullable
              as String,
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as String,
      roundNumber: null == roundNumber
          ? _value.roundNumber
          : roundNumber // ignore: cast_nullable_to_non_nullable
              as int,
      positionInRound: null == positionInRound
          ? _value.positionInRound
          : positionInRound // ignore: cast_nullable_to_non_nullable
              as int,
      totalRounds: null == totalRounds
          ? _value.totalRounds
          : totalRounds // ignore: cast_nullable_to_non_nullable
              as int,
      matchId: freezed == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String?,
      nextNodeId: freezed == nextNodeId
          ? _value.nextNodeId
          : nextNodeId // ignore: cast_nullable_to_non_nullable
              as String?,
      parentNodeId: freezed == parentNodeId
          ? _value.parentNodeId
          : parentNodeId // ignore: cast_nullable_to_non_nullable
              as String?,
      nextPosition: freezed == nextPosition
          ? _value.nextPosition
          : nextPosition // ignore: cast_nullable_to_non_nullable
              as String?,
      isGrandFinal: null == isGrandFinal
          ? _value.isGrandFinal
          : isGrandFinal // ignore: cast_nullable_to_non_nullable
              as bool,
      isThirdPlaceMatch: null == isThirdPlaceMatch
          ? _value.isThirdPlaceMatch
          : isThirdPlaceMatch // ignore: cast_nullable_to_non_nullable
              as bool,
      isBye: null == isBye
          ? _value.isBye
          : isBye // ignore: cast_nullable_to_non_nullable
              as bool,
      byePlayerId: freezed == byePlayerId
          ? _value.byePlayerId
          : byePlayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BracketNodeImplCopyWith<$Res>
    implements $BracketNodeCopyWith<$Res> {
  factory _$$BracketNodeImplCopyWith(
          _$BracketNodeImpl value, $Res Function(_$BracketNodeImpl) then) =
      __$$BracketNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String phaseId,
      String competitionId,
      int roundNumber,
      int positionInRound,
      int totalRounds,
      String? matchId,
      String? nextNodeId,
      String? parentNodeId,
      String? nextPosition,
      bool isGrandFinal,
      bool isThirdPlaceMatch,
      bool isBye,
      String? byePlayerId,
      DateTime? createdAt});
}

/// @nodoc
class __$$BracketNodeImplCopyWithImpl<$Res>
    extends _$BracketNodeCopyWithImpl<$Res, _$BracketNodeImpl>
    implements _$$BracketNodeImplCopyWith<$Res> {
  __$$BracketNodeImplCopyWithImpl(
      _$BracketNodeImpl _value, $Res Function(_$BracketNodeImpl) _then)
      : super(_value, _then);

  /// Create a copy of BracketNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phaseId = null,
    Object? competitionId = null,
    Object? roundNumber = null,
    Object? positionInRound = null,
    Object? totalRounds = null,
    Object? matchId = freezed,
    Object? nextNodeId = freezed,
    Object? parentNodeId = freezed,
    Object? nextPosition = freezed,
    Object? isGrandFinal = null,
    Object? isThirdPlaceMatch = null,
    Object? isBye = null,
    Object? byePlayerId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$BracketNodeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      phaseId: null == phaseId
          ? _value.phaseId
          : phaseId // ignore: cast_nullable_to_non_nullable
              as String,
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as String,
      roundNumber: null == roundNumber
          ? _value.roundNumber
          : roundNumber // ignore: cast_nullable_to_non_nullable
              as int,
      positionInRound: null == positionInRound
          ? _value.positionInRound
          : positionInRound // ignore: cast_nullable_to_non_nullable
              as int,
      totalRounds: null == totalRounds
          ? _value.totalRounds
          : totalRounds // ignore: cast_nullable_to_non_nullable
              as int,
      matchId: freezed == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String?,
      nextNodeId: freezed == nextNodeId
          ? _value.nextNodeId
          : nextNodeId // ignore: cast_nullable_to_non_nullable
              as String?,
      parentNodeId: freezed == parentNodeId
          ? _value.parentNodeId
          : parentNodeId // ignore: cast_nullable_to_non_nullable
              as String?,
      nextPosition: freezed == nextPosition
          ? _value.nextPosition
          : nextPosition // ignore: cast_nullable_to_non_nullable
              as String?,
      isGrandFinal: null == isGrandFinal
          ? _value.isGrandFinal
          : isGrandFinal // ignore: cast_nullable_to_non_nullable
              as bool,
      isThirdPlaceMatch: null == isThirdPlaceMatch
          ? _value.isThirdPlaceMatch
          : isThirdPlaceMatch // ignore: cast_nullable_to_non_nullable
              as bool,
      isBye: null == isBye
          ? _value.isBye
          : isBye // ignore: cast_nullable_to_non_nullable
              as bool,
      byePlayerId: freezed == byePlayerId
          ? _value.byePlayerId
          : byePlayerId // ignore: cast_nullable_to_non_nullable
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
class _$BracketNodeImpl implements _BracketNode {
  const _$BracketNodeImpl(
      {required this.id,
      required this.phaseId,
      required this.competitionId,
      required this.roundNumber,
      required this.positionInRound,
      required this.totalRounds,
      this.matchId,
      this.nextNodeId,
      this.parentNodeId,
      this.nextPosition,
      this.isGrandFinal = false,
      this.isThirdPlaceMatch = false,
      this.isBye = false,
      this.byePlayerId,
      this.createdAt});

  factory _$BracketNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$BracketNodeImplFromJson(json);

  @override
  final String id;
  @override
  final String phaseId;
  @override
  final String competitionId;
  @override
  final int roundNumber;
  @override
  final int positionInRound;
  @override
  final int totalRounds;
  @override
  final String? matchId;
  @override
  final String? nextNodeId;
  @override
  final String? parentNodeId;
  @override
  final String? nextPosition;
  @override
  @JsonKey()
  final bool isGrandFinal;
  @override
  @JsonKey()
  final bool isThirdPlaceMatch;
  @override
  @JsonKey()
  final bool isBye;
  @override
  final String? byePlayerId;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'BracketNode(id: $id, phaseId: $phaseId, competitionId: $competitionId, roundNumber: $roundNumber, positionInRound: $positionInRound, totalRounds: $totalRounds, matchId: $matchId, nextNodeId: $nextNodeId, parentNodeId: $parentNodeId, nextPosition: $nextPosition, isGrandFinal: $isGrandFinal, isThirdPlaceMatch: $isThirdPlaceMatch, isBye: $isBye, byePlayerId: $byePlayerId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BracketNodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.phaseId, phaseId) || other.phaseId == phaseId) &&
            (identical(other.competitionId, competitionId) ||
                other.competitionId == competitionId) &&
            (identical(other.roundNumber, roundNumber) ||
                other.roundNumber == roundNumber) &&
            (identical(other.positionInRound, positionInRound) ||
                other.positionInRound == positionInRound) &&
            (identical(other.totalRounds, totalRounds) ||
                other.totalRounds == totalRounds) &&
            (identical(other.matchId, matchId) || other.matchId == matchId) &&
            (identical(other.nextNodeId, nextNodeId) ||
                other.nextNodeId == nextNodeId) &&
            (identical(other.parentNodeId, parentNodeId) ||
                other.parentNodeId == parentNodeId) &&
            (identical(other.nextPosition, nextPosition) ||
                other.nextPosition == nextPosition) &&
            (identical(other.isGrandFinal, isGrandFinal) ||
                other.isGrandFinal == isGrandFinal) &&
            (identical(other.isThirdPlaceMatch, isThirdPlaceMatch) ||
                other.isThirdPlaceMatch == isThirdPlaceMatch) &&
            (identical(other.isBye, isBye) || other.isBye == isBye) &&
            (identical(other.byePlayerId, byePlayerId) ||
                other.byePlayerId == byePlayerId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      phaseId,
      competitionId,
      roundNumber,
      positionInRound,
      totalRounds,
      matchId,
      nextNodeId,
      parentNodeId,
      nextPosition,
      isGrandFinal,
      isThirdPlaceMatch,
      isBye,
      byePlayerId,
      createdAt);

  /// Create a copy of BracketNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BracketNodeImplCopyWith<_$BracketNodeImpl> get copyWith =>
      __$$BracketNodeImplCopyWithImpl<_$BracketNodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BracketNodeImplToJson(
      this,
    );
  }
}

abstract class _BracketNode implements BracketNode {
  const factory _BracketNode(
      {required final String id,
      required final String phaseId,
      required final String competitionId,
      required final int roundNumber,
      required final int positionInRound,
      required final int totalRounds,
      final String? matchId,
      final String? nextNodeId,
      final String? parentNodeId,
      final String? nextPosition,
      final bool isGrandFinal,
      final bool isThirdPlaceMatch,
      final bool isBye,
      final String? byePlayerId,
      final DateTime? createdAt}) = _$BracketNodeImpl;

  factory _BracketNode.fromJson(Map<String, dynamic> json) =
      _$BracketNodeImpl.fromJson;

  @override
  String get id;
  @override
  String get phaseId;
  @override
  String get competitionId;
  @override
  int get roundNumber;
  @override
  int get positionInRound;
  @override
  int get totalRounds;
  @override
  String? get matchId;
  @override
  String? get nextNodeId;
  @override
  String? get parentNodeId;
  @override
  String? get nextPosition;
  @override
  bool get isGrandFinal;
  @override
  bool get isThirdPlaceMatch;
  @override
  bool get isBye;
  @override
  String? get byePlayerId;
  @override
  DateTime? get createdAt;

  /// Create a copy of BracketNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BracketNodeImplCopyWith<_$BracketNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
