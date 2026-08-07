import 'package:arena/data/repositories/profile_repository.dart'
    show supabaseClientProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// « Santé du compte » du joueur courant — indicateurs anti-triche agrégés par
/// la RPC `my_account_health` (SECURITY DEFINER).
class AccountHealth {
  const AccountHealth({
    required this.strikes,
    required this.strikesMax,
    required this.verifiedProofs,
    required this.isActive,
    required this.permanentBan,
  });

  factory AccountHealth.fromJson(Map<String, dynamic> json) => AccountHealth(
        strikes: (json['strikes'] as num?)?.toInt() ?? 0,
        strikesMax: (json['strikes_max'] as num?)?.toInt() ?? 3,
        verifiedProofs: (json['verified_proofs'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        permanentBan: json['permanent_ban'] as bool? ?? false,
      );

  final int strikes;
  final int strikesMax;
  final int verifiedProofs;
  final bool isActive;
  final bool permanentBan;

  /// Avertissements restants avant sanction (borné à 0).
  int get strikesRemaining => (strikesMax - strikes).clamp(0, strikesMax);

  /// Niveau de santé : ok (0 strike, actif) / warning (1-2 strikes) /
  /// critical (banni ou compte inactif).
  AccountHealthLevel get level {
    if (permanentBan || !isActive) return AccountHealthLevel.critical;
    if (strikes > 0) return AccountHealthLevel.warning;
    return AccountHealthLevel.ok;
  }
}

enum AccountHealthLevel { ok, warning, critical }

class AccountHealthRepository {
  const AccountHealthRepository(this._client);

  final SupabaseClient _client;

  Future<AccountHealth> fetch() async {
    // RPC `returns table` → PostgREST renvoie une liste de lignes (1 ici).
    final res = await _client.rpc<dynamic>('my_account_health');
    final rows = res as List<dynamic>;
    if (rows.isEmpty) {
      return const AccountHealth(
        strikes: 0,
        strikesMax: 3,
        verifiedProofs: 0,
        isActive: true,
        permanentBan: false,
      );
    }
    return AccountHealth.fromJson(rows.first as Map<String, dynamic>);
  }
}

final accountHealthRepositoryProvider = Provider<AccountHealthRepository>(
  (ref) => AccountHealthRepository(ref.watch(supabaseClientProvider)),
);

/// Santé du compte du joueur courant. `autoDispose` : rechargée à l'ouverture
/// du profil (invalidable au pull-to-refresh).
final accountHealthProvider = FutureProvider.autoDispose<AccountHealth>(
  (ref) => ref.watch(accountHealthRepositoryProvider).fetch(),
);
