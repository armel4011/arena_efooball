import 'dart:math';

import 'package:arena/data/models/invitation_code.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Super-admin invitation codes (PHASE 11).
///
/// The actual redemption (claiming an admin / super-admin role) goes
/// through the `register_admin` Edge Function — deferred to PHASE 12.5.
/// Until that lands, the redeem screen just stamps `used_at` /
/// `used_by` for the audit trail but the role grant has to be done
/// manually (or by the EF when it ships).
class AdminInvitationsRepository {
  const AdminInvitationsRepository(this._client);

  static const _table = 'invitation_codes';
  static const _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  final SupabaseClient _client;

  Stream<List<InvitationCode>> watchAll() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => [
              for (final row in rows) InvitationCode.fromJson(row),
            ],);
  }

  Future<InvitationCode> create({
    required String generatedBy,
    required UserRole role,
    String? targetEmail,
    DateTime? expiresAt,
    int maxUses = 1,
  }) async {
    final code = _generateCode();
    final row = await _client.from(_table).insert({
      'code': code,
      'role': role.value,
      'generated_by': generatedBy,
      if (targetEmail != null && targetEmail.trim().isNotEmpty)
        'target_email': targetEmail.trim().toLowerCase(),
      if (expiresAt != null)
        'expires_at': expiresAt.toUtc().toIso8601String(),
      'max_uses': maxUses,
    }).select().single();
    return InvitationCode.fromJson(row);
  }

  /// Marks the code as used. The EF will eventually own this, but
  /// stamping the row keeps the audit trail honest until then.
  Future<void> markUsed({
    required String codeId,
    required String userId,
  }) async {
    await _client.from(_table).update({
      'used_at': DateTime.now().toUtc().toIso8601String(),
      'used_by': userId,
      'uses_count': 1,
    }).eq('id', codeId);
  }

  /// Revokes a code so it can't be redeemed any more. We can't DELETE
  /// (used codes have FK referrers) — we set `expires_at = now()`.
  Future<void> revoke(String codeId) async {
    await _client
        .from(_table)
        .update({'expires_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', codeId);
  }

  /// Supprime définitivement un code invitation. Réservé aux codes
  /// désactivés (UTILISÉ ou EXPIRÉ) côté UI — utile pour faire le
  /// ménage de l'écran SA2. Aucune FK ne pointe sur `invitation_codes`
  /// donc le DELETE est sûr même pour un code utilisé. RLS
  /// `invitation_codes_delete_su` restreint à super_admin.
  Future<void> delete(String codeId) async {
    await _client.from(_table).delete().eq('id', codeId);
  }

  /// Generates a 12-character base32 code (no ambiguous chars: 0/O/1/I/L).
  String _generateCode() {
    final rng = Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < 12; i++) {
      buf.write(_alphabet[rng.nextInt(_alphabet.length)]);
      if (i == 3 || i == 7) buf.write('-');
    }
    return buf.toString();
  }
}

final adminInvitationsRepositoryProvider =
    Provider<AdminInvitationsRepository>((ref) {
  return AdminInvitationsRepository(ref.watch(supabaseClientProvider));
});

final adminInvitationsProvider = StreamProvider<List<InvitationCode>>((ref) {
  return ref.watch(adminInvitationsRepositoryProvider).watchAll();
});
