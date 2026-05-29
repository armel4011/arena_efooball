/// Aggregated competitive stats for a player.
///
/// Computed client-side by `MatchStatsRepository` from the `matches`
/// table. The eventual PHASE 12.5 Edge Function `recalculate_player_stats`
/// will own this same calculation server-side and persist a snapshot in
/// `profiles.stats jsonb`, but in V1.0 we recompute on each profile-page
/// open — match volume per player stays low enough that it's fine.
class PlayerStats {
  const PlayerStats({
    required this.wins,
    required this.losses,
    required this.draws,
    required this.goalsScored,
    required this.goalsConceded,
  });

  /// Empty snapshot, used when a player has not finished a single match
  /// yet (so the profile page can still render a coherent zero state).
  const PlayerStats.empty()
      : wins = 0,
        losses = 0,
        draws = 0,
        goalsScored = 0,
        goalsConceded = 0;

  /// Désérialisation depuis le cache offline (PersistentCache).
  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        losses: (json['losses'] as num?)?.toInt() ?? 0,
        draws: (json['draws'] as num?)?.toInt() ?? 0,
        goalsScored: (json['goals_scored'] as num?)?.toInt() ?? 0,
        goalsConceded: (json['goals_conceded'] as num?)?.toInt() ?? 0,
      );

  final int wins;
  final int losses;
  final int draws;
  final int goalsScored;
  final int goalsConceded;

  Map<String, dynamic> toJson() => {
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'goals_scored': goalsScored,
        'goals_conceded': goalsConceded,
      };

  int get totalMatches => wins + losses + draws;

  /// 0.0 when no match has been played — keeps the UI from rendering
  /// `NaN%`. Otherwise wins / total, in the [0.0, 1.0] range.
  double get winRatio => totalMatches == 0 ? 0 : wins / totalMatches;

  int get goalDifference => goalsScored - goalsConceded;
}
