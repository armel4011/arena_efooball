import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lot D — Système de parrainage.
///
/// 1. `count_user_referrals(uuid)` retourne le nombre de filleuls actifs.
/// 2. `can_register_via_referral(uuid, uuid)` retourne {eligible, current,
///    target} pour une compétition donnée.
/// 3. Le code parrainage du joueur courant est lu directement depuis
///    `profiles.referral_code`.
class ReferralRepository {
  const ReferralRepository(this._client);

  final SupabaseClient _client;

  Future<int> countMyReferrals(String userId) async {
    final res = await _client.rpc<dynamic>(
      'count_user_referrals',
      params: {'p_user_id': userId},
    );
    return (res as num?)?.toInt() ?? 0;
  }

  Future<ReferralEligibility> checkEligibility({
    required String userId,
    required String competitionId,
  }) async {
    final res = await _client.rpc<dynamic>(
      'can_register_via_referral',
      params: {
        'p_user_id': userId,
        'p_competition_id': competitionId,
      },
    );
    return ReferralEligibility.fromJson(res as Map<String, dynamic>);
  }
}

class ReferralEligibility {
  const ReferralEligibility({
    required this.eligible,
    required this.current,
    required this.target,
    required this.reason,
  });

  factory ReferralEligibility.fromJson(Map<String, dynamic> json) =>
      ReferralEligibility(
        eligible: (json['eligible'] as bool?) ?? false,
        current: (json['current'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt() ?? 0,
        reason: (json['reason'] as String?) ?? '',
      );

  final bool eligible;
  final int current;
  final int target;
  final String reason;

  bool get hasQuota => target > 0;
}

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepository(ref.watch(supabaseClientProvider));
});

/// Éligibilité du user courant pour une compétition.
/// `(competitionId, userId)` keyed family pour le cache automatique.
/// `.autoDispose` — l'éligibilité est checkée uniquement sur l'écran
/// d'inscription. Rien ne la consomme ensuite.
final referralEligibilityProvider = FutureProvider.family
    .autoDispose<ReferralEligibility, String>((ref, competitionId) {
  final userId = ref.watch(currentSessionProvider)?.user.id;
  if (userId == null) {
    return Future.value(const ReferralEligibility(
      eligible: false,
      current: 0,
      target: 0,
      reason: 'not_authenticated',
    ),);
  }
  return ref.watch(referralRepositoryProvider).checkEligibility(
        userId: userId,
        competitionId: competitionId,
      );
});

/// Code parrainage du joueur courant (depuis `profiles.referral_code`).
final myReferralCodeProvider = FutureProvider<String?>((ref) async {
  final userId = ref.watch(currentSessionProvider)?.user.id;
  if (userId == null) return null;
  final client = ref.watch(supabaseClientProvider);
  final row = await client
      .from('profiles')
      .select('referral_code')
      .eq('id', userId)
      .maybeSingle();
  return row?['referral_code'] as String?;
});
