import 'package:arena/data/models/call_record.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Au-delà de cette ancienneté, un appel `ringing` est considéré périmé
/// (app appelante tuée en plein ring) et n'est plus présenté au
/// destinataire — évite les « appels fantômes ».
const _kRingingTtl = Duration(seconds: 90);

/// CRUD + flux temps réel sur la table `calls` (signalisation d'appel).
class CallRepository {
  const CallRepository(this._client);

  static const _table = 'calls';

  final SupabaseClient _client;

  /// Place un appel sortant : insère une ligne `ringing`.
  /// [scope] = `friend` | `match`, [scopeId] = friendshipId | matchId.
  Future<CallRecord> placeCall({
    required String scope,
    required String scopeId,
    required String calleeId,
  }) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) throw StateError('placeCall: utilisateur non connecté');
    final row = await _client.from(_table).insert({
      'scope': scope,
      'scope_id': scopeId,
      'caller_id': me,
      'callee_id': calleeId,
      'status': 'ringing',
      'agora_channel': 'call_${scope}_$scopeId',
    }).select().single();
    return CallRecord.fromJson(row);
  }

  /// Le destinataire décroche.
  Future<void> accept(String callId) =>
      _setStatus(callId, 'accepted', stampAnswered: true);

  /// Le destinataire refuse.
  Future<void> decline(String callId) => _setStatus(callId, 'declined');

  /// L'appelant raccroche avant que le destinataire ait décroché.
  Future<void> cancel(String callId) => _setStatus(callId, 'cancelled');

  /// Sans réponse après le timeout de sonnerie.
  Future<void> markMissed(String callId) => _setStatus(callId, 'missed');

  /// Un des deux raccroche en cours d'appel.
  Future<void> end(String callId) =>
      _setStatus(callId, 'ended', stampEnded: true);

  Future<void> _setStatus(
    String callId,
    String status, {
    bool stampAnswered = false,
    bool stampEnded = false,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from(_table).update({
      'status': status,
      if (stampAnswered) 'answered_at': now,
      if (stampEnded) 'ended_at': now,
    }).eq('id', callId);
  }

  /// Flux Realtime du dernier appel ENTRANT en sonnerie pour [userId].
  /// `null` quand il n'y a pas d'appel entrant actif.
  Stream<CallRecord?> watchIncomingCall(String userId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('callee_id', userId)
        .order('created_at')
        .map((rows) {
          final fresh = rows
              .map(CallRecord.fromJson)
              .where(
                (c) =>
                    c.isRinging &&
                    DateTime.now().toUtc().difference(c.createdAt.toUtc()) <
                        _kRingingTtl,
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return fresh.isEmpty ? null : fresh.first;
        });
  }

  /// Flux Realtime d'un appel précis — l'appelant suit le statut
  /// (accepté / refusé / annulé).
  Stream<CallRecord?> watchCall(String callId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .map((rows) => rows.isEmpty ? null : CallRecord.fromJson(rows.first));
  }

  Future<CallRecord?> getById(String callId) async {
    final row =
        await _client.from(_table).select().eq('id', callId).maybeSingle();
    return row == null ? null : CallRecord.fromJson(row);
  }

  /// Username d'un profil — pour afficher « X vous appelle ».
  Future<String> usernameOf(String userId) async {
    final row = await _client
        .from('profiles')
        .select('username')
        .eq('id', userId)
        .maybeSingle();
    return (row?['username'] as String?) ?? 'Joueur';
  }
}

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(ref.watch(supabaseClientProvider));
});

/// Appel entrant en cours pour l'utilisateur courant. Écouté globalement
/// par le shell de l'app pour faire surgir l'écran d'appel entrant.
final incomingCallProvider = StreamProvider.autoDispose<CallRecord?>((ref) {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return Stream<CallRecord?>.value(null);
  return ref.watch(callRepositoryProvider).watchIncomingCall(me);
});

/// Suivi temps réel d'un appel précis (côté appelant).
final callByIdProvider =
    StreamProvider.autoDispose.family<CallRecord?, String>((ref, callId) {
  return ref.watch(callRepositoryProvider).watchCall(callId);
});
