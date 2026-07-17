import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Drapeaux « déjà vu » one-shot par utilisateur (cf. `user_onboarding_seen`).
/// Sert à n'afficher qu'UNE fois un contenu d'aide (p. ex. l'intro de rôle).
class OnboardingFlagsRepository {
  const OnboardingFlagsRepository(this._client);

  final SupabaseClient _client;

  /// Marque [flag] comme vu pour l'utilisateur courant et renvoie `true`
  /// UNIQUEMENT la première fois (ligne fraîchement insérée). Toute valeur
  /// inattendue → `false` (on n'affiche pas le one-shot en cas de doute).
  Future<bool> markSeenOnce(String flag) async {
    final res = await _client.rpc<dynamic>(
      'onboarding_mark_seen_once',
      params: {'p_flag': flag},
    );
    return res == true;
  }
}

final onboardingFlagsRepositoryProvider =
    Provider<OnboardingFlagsRepository>((ref) {
  return OnboardingFlagsRepository(ref.watch(supabaseClientProvider));
});
