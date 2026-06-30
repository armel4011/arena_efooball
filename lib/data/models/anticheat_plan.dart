import 'package:flutter/foundation.dart';

/// Tier d'enregistrement anti-triche décidé par le serveur pour un match
/// (`match_anticheat_plans.mode`, cf. RPC `assign_anticheat_plan`).
enum AnticheatTier {
  /// Aucun egress LiveKit — seul le commitment hash (P3) couvre le match.
  nativeOnly,

  /// Egress LiveKit serveur d'UN joueur tiré au hasard (`recorded_player_id`).
  livekit,
}

/// Plan anti-triche d'un match : pourquoi (raison) et comment (tier) il est
/// couvert, plus le joueur égressé si tier livekit. Lecture admin (RLS
/// `is_admin` sur `match_anticheat_plans`).
@immutable
class AnticheatPlan {
  const AnticheatPlan({
    required this.tier,
    this.recordedPlayerId,
    this.reason,
    this.decidedAt,
  });

  factory AnticheatPlan.fromJson(Map<String, dynamic> json) {
    final decided = json['decided_at'];
    return AnticheatPlan(
      tier: (json['mode'] as String?) == 'livekit'
          ? AnticheatTier.livekit
          : AnticheatTier.nativeOnly,
      recordedPlayerId: json['recorded_player_id'] as String?,
      reason: json['reason'] as String?,
      decidedAt: decided is String ? DateTime.tryParse(decided) : null,
    );
  }

  final AnticheatTier tier;

  /// Joueur dont la piste est egressée (null si [AnticheatTier.nativeOnly]).
  final String? recordedPlayerId;

  /// Pourquoi le match est passé en tier livekit :
  /// `prize` | `surveillance` | `dispute` | `random` (null si native_only).
  final String? reason;

  final DateTime? decidedAt;

  bool get isLivekit => tier == AnticheatTier.livekit;
}

extension AnticheatTierLabel on AnticheatTier {
  /// Libellé court FR du tier, pour les écrans litiges (mobile + desktop).
  String get label => switch (this) {
        AnticheatTier.livekit => 'Egress LiveKit',
        AnticheatTier.nativeOnly => 'Natif seul (hash)',
      };
}

/// Libellé FR de la raison du tier livekit (décision `assign_anticheat_plan`).
String anticheatReasonLabel(String? reason) => switch (reason) {
      'prize' => 'Cagnotte élevée',
      'surveillance' => 'Joueur sous surveillance',
      'dispute' => 'Litige sur le match',
      'random' => 'Échantillon aléatoire',
      _ => 'Plancher de preuve (hash) seul',
    };
