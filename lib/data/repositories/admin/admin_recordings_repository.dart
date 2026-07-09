import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Un enregistrement anti-triche tel que renvoyé par la RPC
/// `admin_list_recordings` : la capture (`streams`) jointe à son match, sa
/// compétition et ses joueurs pour la consultation/corrélation côté admin.
class AdminRecording {
  const AdminRecording({
    required this.recordingId,
    required this.matchId,
    required this.provider,
    required this.competitionName,
    required this.countryCode,
    required this.game,
    required this.playerUsername,
    required this.opponentUsername,
    required this.storagePath,
    required this.url,
    required this.startedAt,
    required this.endedAt,
    required this.hasOpenDispute,
  });

  factory AdminRecording.fromRpc(Map<String, dynamic> j) {
    DateTime? parseTs(dynamic v) =>
        v == null ? null : DateTime.tryParse(v as String)?.toLocal();
    return AdminRecording(
      recordingId: j['recording_id'] as String,
      matchId: j['match_id'] as String,
      provider: (j['provider'] as String?) ?? 'native_recorder',
      competitionName: j['competition_name'] as String?,
      countryCode: j['country_code'] as String?,
      game: j['game'] as String?,
      playerUsername: j['player_username'] as String?,
      opponentUsername: j['opponent_username'] as String?,
      storagePath: j['storage_path'] as String?,
      url: j['url'] as String?,
      startedAt: parseTs(j['started_at']),
      endedAt: parseTs(j['ended_at']),
      hasOpenDispute: (j['has_open_dispute'] as bool?) ?? false,
    );
  }

  final String recordingId;
  final String matchId;
  final String provider;
  final String? competitionName;

  /// Pays organisateur de la compétition (ISO-2). Sert au cloisonnement admin
  /// côté serveur (RPC/RLS) ; affiché + recherchable côté UI.
  final String? countryCode;
  final String? game;
  final String? playerUsername;
  final String? opponentUsername;
  final String? storagePath;
  final String? url;
  final DateTime? startedAt;
  final DateTime? endedAt;

  /// True si un litige est ouvert sur le match : la vidéo est alors conservée
  /// au-delà de la rétention J+1 (cf. cleanup-streams).
  final bool hasOpenDispute;

  bool get isLiveKit => provider == 'livekit_track_egress';

  /// Clé d'objet à signer : `storage_path` (LiveKit) sinon `url` (natif).
  String? get objectPath {
    final sp = storagePath;
    if (sp != null && sp.isNotEmpty) return sp;
    final u = url;
    if (u != null && u.isNotEmpty) return u;
    return null;
  }

  /// Texte de recherche client-side (compétition + joueurs).
  String get searchHaystack => [
        competitionName ?? '',
        countryCode ?? '',
        playerUsername ?? '',
        opponentUsername ?? '',
      ].join(' ').toLowerCase();
}

/// Accès admin aux enregistrements anti-triche (consultation hors litige).
class AdminRecordingsRepository {
  const AdminRecordingsRepository(this._client);

  static const _recordingsBucket = 'match-recordings';

  final SupabaseClient _client;

  /// Liste les captures anti-triche récentes (RPC `admin_list_recordings`,
  /// gardée `is_admin()`). Rétention 1j ⇒ jeu de données petit.
  Future<List<AdminRecording>> list({int limit = 100}) async {
    final rows = await _client.rpc<List<dynamic>>(
      'admin_list_recordings',
      params: {'p_limit': limit},
    );
    return [
      for (final r in rows)
        AdminRecording.fromRpc(Map<String, dynamic>.from(r as Map)),
    ];
  }

  /// Signe un objet privé du bucket `match-recordings` pour lecture (1h).
  Future<String> signedUrl(
    String path, {
    Duration expiresIn = const Duration(hours: 1),
  }) {
    return _client.storage
        .from(_recordingsBucket)
        .createSignedUrl(path, expiresIn.inSeconds);
  }
}

final adminRecordingsRepositoryProvider =
    Provider<AdminRecordingsRepository>((ref) {
  return AdminRecordingsRepository(ref.watch(supabaseClientProvider));
});

/// Liste des enregistrements anti-triche pour l'écran admin. Auto-dispose :
/// rechargé à chaque ouverture de l'écran (+ refresh manuel via invalidate).
final adminRecordingsProvider =
    FutureProvider.autoDispose<List<AdminRecording>>((ref) async {
  return ref.watch(adminRecordingsRepositoryProvider).list();
});
