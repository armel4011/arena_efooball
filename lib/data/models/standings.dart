import 'package:freezed_annotation/freezed_annotation.dart';

part 'standings.freezed.dart';
part 'standings.g.dart';

/// Mirror of `groups` (id, name, number).
@Freezed(fromJson: true, toJson: true)
sealed class CompetitionGroup with _$CompetitionGroup {
  const factory CompetitionGroup({
    required String id,
    required String competitionId,
    required String name,
    required int groupNumber,
  }) = _CompetitionGroup;

  factory CompetitionGroup.fromJson(Map<String, dynamic> json) =>
      _$CompetitionGroupFromJson(json);
}

/// Mirror of `group_memberships` — one row per (group, player).
///
/// Used to render a single line of the standings table.
@Freezed(fromJson: true, toJson: true)
sealed class GroupStandingRow with _$GroupStandingRow {
  const factory GroupStandingRow({
    required String id,
    required String groupId,
    required String profileId,
    int? position,
    @Default(0) int points,
    @Default(0) int played,
    @Default(0) int wins,
    @Default(0) int draws,
    @Default(0) int losses,
    @Default(0) int goalsFor,
    @Default(0) int goalsAgainst,
    @Default(0) int goalDiff,
  }) = _GroupStandingRow;

  factory GroupStandingRow.fromJson(Map<String, dynamic> json) =>
      _$GroupStandingRowFromJson(json);
}

/// One group + its sorted memberships, ready to render.
class StandingsBucket {
  const StandingsBucket({required this.group, required this.rows});
  final CompetitionGroup group;
  final List<GroupStandingRow> rows;
}
