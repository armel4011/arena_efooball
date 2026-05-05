import 'package:arena/data/models/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD over the `profiles` table.
class ProfileRepository {
  const ProfileRepository(this._client);

  static const _table = 'profiles';

  final SupabaseClient _client;

  Future<Profile?> getById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }

  /// Create a profile row immediately after `auth.signUp`. The row id
  /// must equal `auth.users.id`.
  Future<Profile> create(Profile profile) async {
    final row = await _client
        .from(_table)
        .insert(profile.toJson())
        .select()
        .single();
    return Profile.fromJson(row);
  }

  Future<Profile> update(String id, Map<String, dynamic> patch) async {
    final row = await _client
        .from(_table)
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return Profile.fromJson(row);
  }

  /// Stream of the profile row matching [id]. Powered by Supabase
  /// Realtime, pushes updates whenever the row changes server-side.
  Stream<Profile?> watch(String id) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : Profile.fromJson(rows.first));
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
