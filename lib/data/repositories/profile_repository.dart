import 'package:arena/data/models/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD over the `profiles` table.
class ProfileRepository {
  const ProfileRepository(this._client);

  static const _table = 'profiles';

  /// Colonnes lues côté client. **Liste explicite volontaire** : ni
  /// `totp_secret` ni `backup_codes` n'y figurent — ces colonnes sont
  /// réservées au service role (Edge Functions TOTP) et `REVOKE`'d pour
  /// `anon`/`authenticated` (migration 20260601_… — fix audit C-1). Un
  /// `select()` implicite (`*`) lèverait désormais `permission denied for
  /// column profiles.totp_secret`. Garder synchro avec le modèle [Profile].
  static const _columns =
      'id, username, email, country_code, avatar_color, role, is_active, '
      'permanent_ban, fcm_token, stats, auth_provider, auth_provider_id, '
      'whatsapp_number, preferred_language, preferred_currency, timezone, '
      'onboarding_completed, onboarding_completed_at, totp_enabled, '
      'cgu_accepted_at, cgu_version_accepted, privacy_policy_accepted_at, '
      'marketing_consent, account_deletion_requested_at, '
      'account_deletion_reason, deleted_at, kyc_status, kyc_verified_at, '
      'referral_code, referred_by, created_at, updated_at';

  final SupabaseClient _client;

  Future<Profile?> getById(String id) async {
    final row =
        await _client.from(_table).select(_columns).eq('id', id).maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }

  /// Récupère plusieurs profils en un round-trip. Utilisé par la home
  /// "Prochains matchs" et l'inbox messages pour hydrater les opponents
  /// sans N round-trips.
  Future<Map<String, Profile>> getByIds(Iterable<String> ids) async {
    final list = ids.toSet().toList();
    if (list.isEmpty) return const {};
    final rows = await _client
        .from(_table)
        .select(_columns)
        .inFilter('id', list);
    return {
      for (final row in rows as List<dynamic>)
        () {
          final p = Profile.fromJson(row as Map<String, dynamic>);
          return p.id;
        }(): Profile.fromJson(row as Map<String, dynamic>),
    };
  }

  /// True if a profile already owns this username (case-insensitive). Used
  /// pre-signup to surface a clear error instead of letting the unique
  /// constraint blow up after `auth.signUp` already created an auth row.
  Future<bool> usernameExists(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return false;
    final row = await _client
        .from(_table)
        .select('id')
        .ilike('username', trimmed)
        .maybeSingle();
    return row != null;
  }

  /// Create a profile row immediately after `auth.signUp`. The row id
  /// must equal `auth.users.id`.
  Future<Profile> create(Profile profile) async {
    final row = await _client
        .from(_table)
        .insert(profile.toJson())
        .select(_columns)
        .single();
    return Profile.fromJson(row);
  }

  Future<Profile> update(String id, Map<String, dynamic> patch) async {
    final row = await _client
        .from(_table)
        .update(patch)
        .eq('id', id)
        .select(_columns)
        .single();
    return Profile.fromJson(row);
  }

  /// Soft-deletes the account: stamps `account_deletion_requested_at`,
  /// `deleted_at`, optional `account_deletion_reason`, and flips
  /// `is_active = false` so the profile drops out of every "active
  /// players" RLS clause without losing the row immediately.
  ///
  /// The Edge Function `cleanup_deleted_accounts` (PHASE 12.5, cron 24h)
  /// will permanently anonymise rows whose `account_deletion_requested_at`
  /// is older than 30 days. Until then the user can come back and undo
  /// — though no UI surfaces that today.
  Future<void> requestAccountDeletion({
    required String id,
    String? reason,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from(_table).update({
      'account_deletion_requested_at': now,
      'deleted_at': now,
      'account_deletion_reason': reason,
      'is_active': false,
    }).eq('id', id);
  }

}

/// Supabase client. Overridable in tests (or in builds where Supabase
/// isn't initialized — the bootstrap skips init when creds are missing).
///
/// Reading it before Supabase is initialized throws — so override it
/// in tests via `ProviderScope.overrides`, or guard with try/catch in
/// providers that may fire too early.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

/// Resolve un set d'ids profils en un map id→Profile. AutoDispose +
/// family : la clé est l'identité du set (joined). Riverpod réutilise
/// le résultat tant que la clé est stable.
final profilesByIdsProvider = FutureProvider.autoDispose
    .family<Map<String, Profile>, String>((ref, joinedIds) {
  if (joinedIds.isEmpty) return Future.value(const {});
  final ids = joinedIds.split(',');
  return ref.watch(profileRepositoryProvider).getByIds(ids);
});
