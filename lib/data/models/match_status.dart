import 'package:freezed_annotation/freezed_annotation.dart';

/// Mirror of Postgres enum `public.match_status`.
enum MatchStatus {
  pending('pending'),
  scheduled('scheduled'),
  ready('ready'),
  inProgress('in_progress'),
  scorePending('score_pending'),
  awaitingValidation('awaiting_validation'),
  disputed('disputed'),
  completed('completed'),
  cancelled('cancelled'),
  forfeited('forfeited');

  const MatchStatus(this.value);

  final String value;

  static MatchStatus fromValue(String? value) {
    return MatchStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => MatchStatus.pending,
    );
  }

  bool get isCompleted => this == MatchStatus.completed;
  bool get isCancelled => this == MatchStatus.cancelled;
  bool get isLive =>
      this == MatchStatus.inProgress || this == MatchStatus.scorePending;
}

class MatchStatusConverter implements JsonConverter<MatchStatus, String?> {
  const MatchStatusConverter();

  @override
  MatchStatus fromJson(String? value) => MatchStatus.fromValue(value);

  @override
  String toJson(MatchStatus status) => status.value;
}
