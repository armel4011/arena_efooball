// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'standings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CompetitionGroup _$CompetitionGroupFromJson(Map<String, dynamic> json) {
  return _CompetitionGroup.fromJson(json);
}

/// @nodoc
mixin _$CompetitionGroup {
  String get id => throw _privateConstructorUsedError;
  String get competitionId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get groupNumber => throw _privateConstructorUsedError;

  /// Serializes this CompetitionGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompetitionGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompetitionGroupCopyWith<CompetitionGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompetitionGroupCopyWith<$Res> {
  factory $CompetitionGroupCopyWith(
          CompetitionGroup value, $Res Function(CompetitionGroup) then) =
      _$CompetitionGroupCopyWithImpl<$Res, CompetitionGroup>;
  @useResult
  $Res call({String id, String competitionId, String name, int groupNumber});
}

/// @nodoc
class _$CompetitionGroupCopyWithImpl<$Res, $Val extends CompetitionGroup>
    implements $CompetitionGroupCopyWith<$Res> {
  _$CompetitionGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompetitionGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? competitionId = null,
    Object? name = null,
    Object? groupNumber = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      groupNumber: null == groupNumber
          ? _value.groupNumber
          : groupNumber // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompetitionGroupImplCopyWith<$Res>
    implements $CompetitionGroupCopyWith<$Res> {
  factory _$$CompetitionGroupImplCopyWith(_$CompetitionGroupImpl value,
          $Res Function(_$CompetitionGroupImpl) then) =
      __$$CompetitionGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String competitionId, String name, int groupNumber});
}

/// @nodoc
class __$$CompetitionGroupImplCopyWithImpl<$Res>
    extends _$CompetitionGroupCopyWithImpl<$Res, _$CompetitionGroupImpl>
    implements _$$CompetitionGroupImplCopyWith<$Res> {
  __$$CompetitionGroupImplCopyWithImpl(_$CompetitionGroupImpl _value,
      $Res Function(_$CompetitionGroupImpl) _then)
      : super(_value, _then);

  /// Create a copy of CompetitionGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? competitionId = null,
    Object? name = null,
    Object? groupNumber = null,
  }) {
    return _then(_$CompetitionGroupImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      groupNumber: null == groupNumber
          ? _value.groupNumber
          : groupNumber // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompetitionGroupImpl implements _CompetitionGroup {
  const _$CompetitionGroupImpl(
      {required this.id,
      required this.competitionId,
      required this.name,
      required this.groupNumber});

  factory _$CompetitionGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompetitionGroupImplFromJson(json);

  @override
  final String id;
  @override
  final String competitionId;
  @override
  final String name;
  @override
  final int groupNumber;

  @override
  String toString() {
    return 'CompetitionGroup(id: $id, competitionId: $competitionId, name: $name, groupNumber: $groupNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompetitionGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.competitionId, competitionId) ||
                other.competitionId == competitionId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.groupNumber, groupNumber) ||
                other.groupNumber == groupNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, competitionId, name, groupNumber);

  /// Create a copy of CompetitionGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompetitionGroupImplCopyWith<_$CompetitionGroupImpl> get copyWith =>
      __$$CompetitionGroupImplCopyWithImpl<_$CompetitionGroupImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompetitionGroupImplToJson(
      this,
    );
  }
}

abstract class _CompetitionGroup implements CompetitionGroup {
  const factory _CompetitionGroup(
      {required final String id,
      required final String competitionId,
      required final String name,
      required final int groupNumber}) = _$CompetitionGroupImpl;

  factory _CompetitionGroup.fromJson(Map<String, dynamic> json) =
      _$CompetitionGroupImpl.fromJson;

  @override
  String get id;
  @override
  String get competitionId;
  @override
  String get name;
  @override
  int get groupNumber;

  /// Create a copy of CompetitionGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompetitionGroupImplCopyWith<_$CompetitionGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupStandingRow _$GroupStandingRowFromJson(Map<String, dynamic> json) {
  return _GroupStandingRow.fromJson(json);
}

/// @nodoc
mixin _$GroupStandingRow {
  String get id => throw _privateConstructorUsedError;
  String get groupId => throw _privateConstructorUsedError;
  String get profileId => throw _privateConstructorUsedError;
  int? get position => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  int get played => throw _privateConstructorUsedError;
  int get wins => throw _privateConstructorUsedError;
  int get draws => throw _privateConstructorUsedError;
  int get losses => throw _privateConstructorUsedError;
  int get goalsFor => throw _privateConstructorUsedError;
  int get goalsAgainst => throw _privateConstructorUsedError;
  int get goalDiff => throw _privateConstructorUsedError;

  /// Serializes this GroupStandingRow to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroupStandingRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupStandingRowCopyWith<GroupStandingRow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupStandingRowCopyWith<$Res> {
  factory $GroupStandingRowCopyWith(
          GroupStandingRow value, $Res Function(GroupStandingRow) then) =
      _$GroupStandingRowCopyWithImpl<$Res, GroupStandingRow>;
  @useResult
  $Res call(
      {String id,
      String groupId,
      String profileId,
      int? position,
      int points,
      int played,
      int wins,
      int draws,
      int losses,
      int goalsFor,
      int goalsAgainst,
      int goalDiff});
}

/// @nodoc
class _$GroupStandingRowCopyWithImpl<$Res, $Val extends GroupStandingRow>
    implements $GroupStandingRowCopyWith<$Res> {
  _$GroupStandingRowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupStandingRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? profileId = null,
    Object? position = freezed,
    Object? points = null,
    Object? played = null,
    Object? wins = null,
    Object? draws = null,
    Object? losses = null,
    Object? goalsFor = null,
    Object? goalsAgainst = null,
    Object? goalDiff = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      profileId: null == profileId
          ? _value.profileId
          : profileId // ignore: cast_nullable_to_non_nullable
              as String,
      position: freezed == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int?,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      played: null == played
          ? _value.played
          : played // ignore: cast_nullable_to_non_nullable
              as int,
      wins: null == wins
          ? _value.wins
          : wins // ignore: cast_nullable_to_non_nullable
              as int,
      draws: null == draws
          ? _value.draws
          : draws // ignore: cast_nullable_to_non_nullable
              as int,
      losses: null == losses
          ? _value.losses
          : losses // ignore: cast_nullable_to_non_nullable
              as int,
      goalsFor: null == goalsFor
          ? _value.goalsFor
          : goalsFor // ignore: cast_nullable_to_non_nullable
              as int,
      goalsAgainst: null == goalsAgainst
          ? _value.goalsAgainst
          : goalsAgainst // ignore: cast_nullable_to_non_nullable
              as int,
      goalDiff: null == goalDiff
          ? _value.goalDiff
          : goalDiff // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroupStandingRowImplCopyWith<$Res>
    implements $GroupStandingRowCopyWith<$Res> {
  factory _$$GroupStandingRowImplCopyWith(_$GroupStandingRowImpl value,
          $Res Function(_$GroupStandingRowImpl) then) =
      __$$GroupStandingRowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String groupId,
      String profileId,
      int? position,
      int points,
      int played,
      int wins,
      int draws,
      int losses,
      int goalsFor,
      int goalsAgainst,
      int goalDiff});
}

/// @nodoc
class __$$GroupStandingRowImplCopyWithImpl<$Res>
    extends _$GroupStandingRowCopyWithImpl<$Res, _$GroupStandingRowImpl>
    implements _$$GroupStandingRowImplCopyWith<$Res> {
  __$$GroupStandingRowImplCopyWithImpl(_$GroupStandingRowImpl _value,
      $Res Function(_$GroupStandingRowImpl) _then)
      : super(_value, _then);

  /// Create a copy of GroupStandingRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? profileId = null,
    Object? position = freezed,
    Object? points = null,
    Object? played = null,
    Object? wins = null,
    Object? draws = null,
    Object? losses = null,
    Object? goalsFor = null,
    Object? goalsAgainst = null,
    Object? goalDiff = null,
  }) {
    return _then(_$GroupStandingRowImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      profileId: null == profileId
          ? _value.profileId
          : profileId // ignore: cast_nullable_to_non_nullable
              as String,
      position: freezed == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int?,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      played: null == played
          ? _value.played
          : played // ignore: cast_nullable_to_non_nullable
              as int,
      wins: null == wins
          ? _value.wins
          : wins // ignore: cast_nullable_to_non_nullable
              as int,
      draws: null == draws
          ? _value.draws
          : draws // ignore: cast_nullable_to_non_nullable
              as int,
      losses: null == losses
          ? _value.losses
          : losses // ignore: cast_nullable_to_non_nullable
              as int,
      goalsFor: null == goalsFor
          ? _value.goalsFor
          : goalsFor // ignore: cast_nullable_to_non_nullable
              as int,
      goalsAgainst: null == goalsAgainst
          ? _value.goalsAgainst
          : goalsAgainst // ignore: cast_nullable_to_non_nullable
              as int,
      goalDiff: null == goalDiff
          ? _value.goalDiff
          : goalDiff // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupStandingRowImpl implements _GroupStandingRow {
  const _$GroupStandingRowImpl(
      {required this.id,
      required this.groupId,
      required this.profileId,
      this.position,
      this.points = 0,
      this.played = 0,
      this.wins = 0,
      this.draws = 0,
      this.losses = 0,
      this.goalsFor = 0,
      this.goalsAgainst = 0,
      this.goalDiff = 0});

  factory _$GroupStandingRowImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupStandingRowImplFromJson(json);

  @override
  final String id;
  @override
  final String groupId;
  @override
  final String profileId;
  @override
  final int? position;
  @override
  @JsonKey()
  final int points;
  @override
  @JsonKey()
  final int played;
  @override
  @JsonKey()
  final int wins;
  @override
  @JsonKey()
  final int draws;
  @override
  @JsonKey()
  final int losses;
  @override
  @JsonKey()
  final int goalsFor;
  @override
  @JsonKey()
  final int goalsAgainst;
  @override
  @JsonKey()
  final int goalDiff;

  @override
  String toString() {
    return 'GroupStandingRow(id: $id, groupId: $groupId, profileId: $profileId, position: $position, points: $points, played: $played, wins: $wins, draws: $draws, losses: $losses, goalsFor: $goalsFor, goalsAgainst: $goalsAgainst, goalDiff: $goalDiff)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupStandingRowImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.profileId, profileId) ||
                other.profileId == profileId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.played, played) || other.played == played) &&
            (identical(other.wins, wins) || other.wins == wins) &&
            (identical(other.draws, draws) || other.draws == draws) &&
            (identical(other.losses, losses) || other.losses == losses) &&
            (identical(other.goalsFor, goalsFor) ||
                other.goalsFor == goalsFor) &&
            (identical(other.goalsAgainst, goalsAgainst) ||
                other.goalsAgainst == goalsAgainst) &&
            (identical(other.goalDiff, goalDiff) ||
                other.goalDiff == goalDiff));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, groupId, profileId, position,
      points, played, wins, draws, losses, goalsFor, goalsAgainst, goalDiff);

  /// Create a copy of GroupStandingRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupStandingRowImplCopyWith<_$GroupStandingRowImpl> get copyWith =>
      __$$GroupStandingRowImplCopyWithImpl<_$GroupStandingRowImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupStandingRowImplToJson(
      this,
    );
  }
}

abstract class _GroupStandingRow implements GroupStandingRow {
  const factory _GroupStandingRow(
      {required final String id,
      required final String groupId,
      required final String profileId,
      final int? position,
      final int points,
      final int played,
      final int wins,
      final int draws,
      final int losses,
      final int goalsFor,
      final int goalsAgainst,
      final int goalDiff}) = _$GroupStandingRowImpl;

  factory _GroupStandingRow.fromJson(Map<String, dynamic> json) =
      _$GroupStandingRowImpl.fromJson;

  @override
  String get id;
  @override
  String get groupId;
  @override
  String get profileId;
  @override
  int? get position;
  @override
  int get points;
  @override
  int get played;
  @override
  int get wins;
  @override
  int get draws;
  @override
  int get losses;
  @override
  int get goalsFor;
  @override
  int get goalsAgainst;
  @override
  int get goalDiff;

  /// Create a copy of GroupStandingRow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupStandingRowImplCopyWith<_$GroupStandingRowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
