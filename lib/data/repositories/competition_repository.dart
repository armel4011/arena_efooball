import 'dart:async';

import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/core/utils/error_reporter.dart';
import 'package:arena/core/utils/poll_stream.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Une ligne du classement général final d'une compétition, telle que
/// vue côté joueur (lecture seule) : le participant joint à son profil
/// et son rang d'arrivée.
@immutable
class CompetitionRankingEntry {
  const CompetitionRankingEntry({
    required this.playerId,
    required this.username,
    required this.countryCode,
    required this.avatarColor,
    required this.finalRank,
    this.avatarUrl,
  });

  final String playerId;
  final String username;
  final String countryCode;
  final String avatarColor;

  /// Photo d'avatar (NULL → repli cercle coloré).
  final String? avatarUrl;

  /// Rang d'arrivée — `null` tant que l'admin n'a pas publié le classement.
  final int? finalRank;
}

/// Un participant inscrit à une compétition (vue côté joueur), joint à son
/// profil public. Sert l'onglet PARTICIPANTS du détail compétition.
@immutable
class CompetitionParticipant {
  const CompetitionParticipant({
    required this.playerId,
    required this.username,
    required this.countryCode,
    required this.avatarColor,
    required this.status,
    this.avatarUrl,
  });

  final String playerId;
  final String username;
  final String countryCode;
  final String avatarColor;

  /// Photo d'avatar (NULL → repli cercle coloré).
  final String? avatarUrl;

  /// Statut d'inscription : `confirmed` · `pending` · …
  final String status;

  bool get isConfirmed => status == 'confirmed';
}

/// CRUD + Realtime over the `competitions` table.
///
/// Read-only from the User app — competitions are created server-side by
/// admins (PHASE 11). The User app only needs `list / getById / watch`.
class CompetitionRepository {
  const CompetitionRepository(this._client);

  static const _table = 'competitions';

  final SupabaseClient _client;

  /// Single fetch — typically not used directly by UI (prefer [watch]),
  /// but handy for tests and for one-shot lookups. Cap à 50 pour
  /// borner le résultat à scale (1M users + 10k compétitions).
  Future<List<Competition>> list({GameType? game, int limit = 50}) async {
    // Exclut les compétitions archivées (terminées depuis > 7 j, cf. cron
    // archive_old_completed_competitions) des listes côté joueur.
    final base = _client.from(_table).select().isFilter('archived_at', null);
    final filtered = game == null ? base : base.eq('game', game.value);
    final rows =
        await filtered.order('start_date', ascending: true).limit(limit);
    final list = [
      for (final row in rows as List<dynamic>)
        Competition.fromJson(row as Map<String, dynamic>),
    ];
    return _sortPinnedFirst(list);
  }

  Future<Competition?> getById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Competition.fromJson(row);
  }

  /// Realtime stream of competitions. The Supabase `.stream()` API does
  /// not support arbitrary `where` chaining — we filter by [game]
  /// client-side instead, which keeps the stream simple and avoids
  /// reconnections when the filter changes.
  Stream<List<Competition>> watch({GameType? game}) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('start_date')
        .map((rows) {
          // Exclut les archivées (filtre client-side : `.stream()` ne supporte
          // pas le `is null` côté serveur).
          final list = [
            for (final row in rows) Competition.fromJson(row),
          ].where((c) => c.archivedAt == null);
          final filtered = game == null
              ? list.toList()
              : list.where((c) => c.game == game).toList();
          return _sortPinnedFirst(filtered);
        });
  }

  /// Tri « épinglées d'abord », **stable** : les compétitions `isPinned`
  /// remontent en tête, ordonnées entre elles par `pinnedAt` décroissant
  /// (la plus récemment épinglée en premier, `null` traité comme le plus
  /// ancien). Les non-épinglées conservent l'ordre d'entrée (déjà trié par
  /// `start_date` croissant côté requête/stream). On s'appuie sur
  /// `List.sort` qui n'est pas garanti stable → on ré-implémente un tri
  /// stable explicite via un index d'origine comme dernier critère.
  static List<Competition> _sortPinnedFirst(List<Competition> input) {
    final indexed = [
      for (var i = 0; i < input.length; i++) (i, input[i]),
    ]..sort((a, b) {
        final ca = a.$2;
        final cb = b.$2;
        if (ca.isPinned != cb.isPinned) return ca.isPinned ? -1 : 1;
        if (ca.isPinned && cb.isPinned) {
          final pa = ca.pinnedAt;
          final pb = cb.pinnedAt;
          if (pa != null && pb != null && pa != pb) {
            return pb.compareTo(pa); // plus récent d'abord
          }
          if (pa == null && pb != null) return 1;
          if (pa != null && pb == null) return -1;
        }
        // Égalité de critère → on préserve l'ordre d'origine (stabilité).
        return a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  /// Realtime stream of a single competition. Emits `null` if the row
  /// doesn't exist (yet).
  Stream<Competition?> watchById(String id) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : Competition.fromJson(rows.first));
  }

  /// PHASE 11bis — inscription directe sur compétition GRATUITE.
  /// L'INSERT passe par la policy `registrations_free_self_insert` qui
  /// vérifie côté DB que `competitions.registration_fee = 0`.
  Future<void> registerSelfFree(String competitionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user — cannot register.');
    }
    await _client.from('competition_registrations').insert({
      'competition_id': competitionId,
      'player_id': userId,
      'status': 'confirmed',
    });
  }

  /// Classement général final d'une compétition : les participants
  /// joints à leur profil, triés par `final_rank` croissant. Les
  /// non-classés (`final_rank` null) sont renvoyés en fin de liste.
  Future<List<CompetitionRankingEntry>> getRanking(
    String competitionId,
  ) async {
    final rows = await _client
        .from('competition_registrations')
        .select('player_id, final_rank')
        .eq('competition_id', competitionId);
    final regs = [
      for (final r in rows as List<dynamic>) r as Map<String, dynamic>
    ];

    // Les profils joueurs sont résolus via la vue publique `public_profiles`
    // (la table `profiles` est restreinte à self+admin — fix C-1 résiduel).
    // On ne peut plus embarquer `profiles!player_id(...)` côté PostgREST.
    final ids = {for (final r in regs) r['player_id'] as String}.toList();
    final profilesById = <String, Map<String, dynamic>>{};
    if (ids.isNotEmpty) {
      final pr = await _client
          .from('public_profiles')
          .select('id, username, country_code, avatar_color, avatar_url')
          .inFilter('id', ids);
      for (final p in pr as List<dynamic>) {
        final m = p as Map<String, dynamic>;
        profilesById[m['id'] as String] = m;
      }
    }

    final list = [
      for (final row in regs)
        _mapRankingEntry(row, profilesById[row['player_id']]),
    ]..sort((a, b) {
        // Les non-classés tombent en fin de liste.
        final ra = a.finalRank ?? 1 << 30;
        final rb = b.finalRank ?? 1 << 30;
        if (ra != rb) return ra.compareTo(rb);
        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });
    return list;
  }

  /// Liste des participants inscrits à une compétition, joints à leur
  /// profil public, triés par nom. Les confirmés d'abord. Utilisé par
  /// l'onglet PARTICIPANTS (lecture seule côté joueur).
  Future<List<CompetitionParticipant>> getParticipants(
    String competitionId,
  ) async {
    final rows = await _client
        .from('competition_registrations')
        .select('player_id, status')
        .eq('competition_id', competitionId);
    final regs = [
      for (final r in rows as List<dynamic>) r as Map<String, dynamic>,
    ];

    // Profils résolus via la vue publique `public_profiles` (table `profiles`
    // restreinte à self+admin), comme `getRanking`.
    final ids = {for (final r in regs) r['player_id'] as String}.toList();
    final profilesById = <String, Map<String, dynamic>>{};
    if (ids.isNotEmpty) {
      final pr = await _client
          .from('public_profiles')
          .select('id, username, country_code, avatar_color, avatar_url')
          .inFilter('id', ids);
      for (final p in pr as List<dynamic>) {
        final m = p as Map<String, dynamic>;
        profilesById[m['id'] as String] = m;
      }
    }

    return [
      for (final row in regs)
        _mapParticipant(row, profilesById[row['player_id']]),
    ]..sort((a, b) {
        // Confirmés en tête, puis tri alphabétique.
        if (a.isConfirmed != b.isConfirmed) return a.isConfirmed ? -1 : 1;
        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });
  }

  CompetitionParticipant _mapParticipant(
    Map<String, dynamic> row,
    Map<String, dynamic>? profile,
  ) {
    final p = profile ?? const {};
    return CompetitionParticipant(
      playerId: row['player_id'] as String,
      username: p['username'] as String? ?? '—',
      countryCode: p['country_code'] as String? ?? '',
      avatarColor: p['avatar_color'] as String? ?? '#4C7AFF',
      avatarUrl: p['avatar_url'] as String?,
      status: row['status'] as String? ?? 'pending',
    );
  }

  CompetitionRankingEntry _mapRankingEntry(
    Map<String, dynamic> row,
    Map<String, dynamic>? profile,
  ) {
    final p = profile ?? const {};
    return CompetitionRankingEntry(
      playerId: row['player_id'] as String,
      username: p['username'] as String? ?? '—',
      countryCode: p['country_code'] as String? ?? '',
      avatarColor: p['avatar_color'] as String? ?? '#4C7AFF',
      avatarUrl: p['avatar_url'] as String?,
      finalRank: row['final_rank'] as int?,
    );
  }

  /// Stream realtime des ids de compétitions où le joueur courant est
  /// inscrit en `status='confirmed'`. Utilisé par la liste pour décider
  /// si on route vers le détail ou vers la page d'inscription.
  Stream<Set<String>> watchMyRegisteredCompetitionIds() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Stream.empty();
    }
    return _client
        .from('competition_registrations')
        .stream(primaryKey: ['competition_id', 'player_id'])
        .eq('player_id', userId)
        .map(
          (rows) => {
            for (final r in rows)
              if (r['status'] == 'confirmed') r['competition_id'] as String,
          },
        );
  }
}

final competitionRepositoryProvider = Provider<CompetitionRepository>((ref) {
  return CompetitionRepository(ref.watch(supabaseClientProvider));
});

/// Liste des compétitions, optionnellement filtrée par jeu.
///
/// Downgrade Realtime → poll (audit 2026-05-19) : la liste de compét.
/// n'a pas besoin d'updates instantanés (un admin crée une compét.
/// toutes les heures au mieux). Poll 60s tient la fraîcheur perçue
/// et libère 4 channels Realtime (1 par variant de filtre game).
/// `.autoDispose` cancel le polling quand l'écran ferme.
///
/// **Cold start cache** : la derniere liste reçue est persistee
/// (PersistentCache) et réémise instantanément au prochain démarrage —
/// la page Compétitions s'affiche immediatement avec la liste connue,
/// le poll/stream remplace dans la seconde si du nouveau est arrivé.
final competitionsListProvider = StreamProvider.family
    .autoDispose<List<Competition>, GameType?>((ref, game) async* {
  final repo = ref.watch(competitionRepositoryProvider);
  final source = pollStream(
    const Duration(seconds: 60),
    () => repo.list(game: game),
  );
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydrate<Competition>(
    namespace: 'competitions.${game?.name ?? "all"}',
    source: source,
    fromJson: Competition.fromJson,
    toJson: (c) => c.toJson(),
  );
});

/// Realtime stream of one competition by id. `.autoDispose` évite que
/// chaque competition visitée garde un stream WebSocket actif. Le cache
/// disque ne conserve que le dernier JSON connu par compétition →
/// l'écran détail reste affiché hors-ligne au lieu d'une ErrorState.
final competitionByIdProvider =
    StreamProvider.family.autoDispose<Competition?, String>((ref, id) async* {
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydrateSingle<Competition>(
    namespace: 'competition.$id',
    source: ref.watch(competitionRepositoryProvider).watchById(id),
    fromJson: Competition.fromJson,
    toJson: (c) => c.toJson(),
  );
});

/// Classement général final d'une compétition (lecture seule côté
/// joueur). `FutureProvider` — pas de Realtime en V1.0, on invalide au
/// pull-to-refresh, comme les standings de poule.
final competitionRankingProvider = FutureProvider.family
    .autoDispose<List<CompetitionRankingEntry>, String>((ref, competitionId) {
  return ref.watch(competitionRepositoryProvider).getRanking(competitionId);
});

/// Participants inscrits à une compétition (onglet PARTICIPANTS). Même
/// posture que le classement : `FutureProvider`, invalidation au
/// pull-to-refresh, pas de Realtime en V1.0.
final competitionParticipantsProvider = FutureProvider.family
    .autoDispose<List<CompetitionParticipant>, String>((ref, competitionId) {
  return ref
      .watch(competitionRepositoryProvider)
      .getParticipants(competitionId);
});

/// Realtime set des ids de comps où le joueur courant est inscrit
/// (status='confirmed'). Utilisé pour le gate du détail + le routage
/// liste → détail vs inscription.
///
/// Dépend explicitement de `currentSessionProvider` pour que la stream
/// soit reconstruite quand l'auth devient prête (sinon, lors d'un
/// cold-start avec session restaurée tardivement, la stream se crée
/// alors que `auth.currentUser` est encore null et reste vide).
final myRegisteredCompetitionIdsProvider =
    StreamProvider.autoDispose<Set<String>>((ref) async* {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    yield const <String>{};
    return;
  }
  final me = session.user.id;
  final cache = await ref.watch(persistentCacheProvider.future);
  // Offline-safe (onglet TOURNOIS de l'inbox) : on emet d'abord le set
  // connu (ou vide), puis on suit le stream et on avale les erreurs
  // reseau — la liste reste figee au lieu d'afficher une erreur.
  final ns = 'my_registered_comps.$me';
  final cached = cache.readList<String>(ns, (j) => j['id'] as String);
  yield (cached ?? const <String>[]).toSet();
  try {
    final source = ref
        .watch(competitionRepositoryProvider)
        .watchMyRegisteredCompetitionIds();
    await for (final ids in source) {
      yield ids;
      unawaited(cache.writeList<String>(ns, ids.toList(), (s) => {'id': s}));
    }
  } catch (e, st) {
    // Offline-safe : on avale les coupures réseau (la liste reste figée).
    // Mais une erreur NON-offline (RLS, parsing) est un vrai bug → on la
    // remonte pour observabilité au lieu de la perdre silencieusement.
    if (!PersistentCache.isOfflineError(e)) {
      unawaited(
        reportError(
          e,
          st,
          context: 'CompetitionRepository.myRegisteredIds_stream',
        ),
      );
    }
  }
});
