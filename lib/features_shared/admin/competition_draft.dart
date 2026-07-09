import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/payment_option_draft.dart';

/// Logique PURE du wizard de création/édition de compétition, partagée par les
/// deux consoles admin (mobile Material `CreateCompetitionPage` + desktop Fluent
/// `DesktopCreateCompetitionPage`). Extrait la duplication de payloads, calculs
/// et validation qui avait déjà commencé à diverger (garde `noReward` présente
/// côté mobile, absente côté desktop). Aucun widget ici — les deux consoles
/// gardent leur UI propre et n'appellent que ces fonctions.
///
/// Voir aussi `admin_result_gate.dart` (même pattern de logique admin partagée).

/// Blocs de récompenses au-delà du top 4 : (libellé, taille, dernier rang). Le
/// bloc d'index `i` est actif dès que le nombre de récompensés atteint son
/// `lastRank` ; la valeur saisie est le montant attribué à *chaque* place du
/// bloc. Source unique (était dupliquée mot pour mot mobile/desktop).
const List<({String label, int size, int lastRank})> prizeBlocks = [
  (label: '5ème – 8ème', size: 4, lastRank: 8),
  (label: '9ème – 16ème', size: 8, lastRank: 16),
  (label: '17ème – 32ème', size: 16, lastRank: 32),
  (label: '33ème – 64ème', size: 32, lastRank: 64),
  (label: '65ème – 128ème', size: 64, lastRank: 128),
];

/// Liste plate des **montants** par place : places individuelles 1-4 puis chaque
/// bloc actif déplié (même montant répété sur toutes ses places).
///
/// [noReward] court-circuite (compétition sans récompense — toggle mobile ; le
/// desktop passe `false`, il n'a pas ce toggle). [topShareTexts] = textes bruts
/// des controllers du top 4 ; [blockShareTexts] = un texte par bloc.
List<int> computePrizeDistribution({
  required bool noReward,
  required int rewardedCount,
  required List<String> topShareTexts,
  required List<String> blockShareTexts,
}) {
  if (noReward) return const [];
  final raw = <int>[];
  final topCount = rewardedCount < 4 ? rewardedCount : 4;
  for (var i = 0; i < topCount; i++) {
    raw.add(int.tryParse(topShareTexts[i]) ?? 0);
  }
  for (var b = 0; b < prizeBlocks.length; b++) {
    final block = prizeBlocks[b];
    if (rewardedCount < block.lastRank) break;
    final perPlace = int.tryParse(blockShareTexts[b]) ?? 0;
    for (var k = 0; k < block.size; k++) {
      raw.add(perPlace);
    }
  }
  return raw;
}

/// Somme des montants distribués (places individuelles + montant de bloc × sa
/// taille) = la cagnotte totale. Même logique que [computePrizeDistribution].
int computeShareTotal({
  required bool noReward,
  required int rewardedCount,
  required List<String> topShareTexts,
  required List<String> blockShareTexts,
}) {
  if (noReward) return 0;
  var total = 0;
  final topCount = rewardedCount < 4 ? rewardedCount : 4;
  for (var i = 0; i < topCount; i++) {
    total += int.tryParse(topShareTexts[i]) ?? 0;
  }
  for (var b = 0; b < prizeBlocks.length; b++) {
    final block = prizeBlocks[b];
    if (rewardedCount < block.lastRank) break;
    total += (int.tryParse(blockShareTexts[b]) ?? 0) * block.size;
  }
  return total;
}

/// Parse le CSV des intervalles par round → `List<int>?`. Vide ou malformé
/// (non-entier ou ≤ 0) → null (le serveur retombe sur l'intervalle global).
List<int>? parseRoundIntervals(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final parts =
      trimmed.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
  final ints = <int>[];
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n <= 0) return null;
    ints.add(n);
  }
  return ints.isEmpty ? null : ints;
}

/// Config `format_config` (groupes) — non vide uniquement pour
/// `groupsThenKnockout`. Défauts : 4 groupes, 2 qualifiés/groupe.
Map<String, dynamic> buildFormatConfig({
  required TournamentFormat format,
  required String groupCountText,
  required String qualifiersText,
}) {
  if (format != TournamentFormat.groupsThenKnockout) {
    return const <String, dynamic>{};
  }
  return <String, dynamic>{
    'group_count': int.tryParse(groupCountText.trim()) ?? 4,
    'qualifiers_per_group': int.tryParse(qualifiersText.trim()) ?? 2,
  };
}

/// Validation « peut-on avancer » d'une étape du wizard (6 étapes). Identique
/// mobile/desktop. Les montants de récompense (étape 2) sont libres, 0 compris.
bool canAdvanceCompetitionStep({
  required int step,
  required String name,
  required DateTime? startDate,
  required int maxPlayers,
  required String entryFeeText,
  required List<PaymentDraftCountry> paymentCountries,
}) {
  switch (step) {
    case 0:
      return name.trim().length >= 3 && startDate != null;
    case 1:
      return maxPlayers >= 2;
    case 2:
      return true;
    case 3:
      final fee = double.tryParse(entryFeeText) ?? -1;
      return fee >= 0;
    case 4:
      final fee = double.tryParse(entryFeeText) ?? 0;
      if (fee <= 0) return true;
      return paymentDraftsValid(paymentCountries);
    default:
      return true;
  }
}

/// Valeurs résolues d'un wizard de compétition, indépendantes de la plateforme.
/// Chaque console construit ce draft depuis ses controllers, puis appelle
/// [buildCreateCompetitionPayload] / [buildUpdateCompetitionPayload] — les deux
/// payloads (colonnes DB) vivent désormais à UN seul endroit.
class CompetitionDraft {
  const CompetitionDraft({
    required this.name,
    required this.game,
    required this.format,
    required this.publishNow,
    required this.description,
    required this.startDate,
    required this.maxPlayers,
    required this.fee,
    required this.currency,
    required this.countryCode,
    required this.commissionXaf,
    required this.commissionPct,
    required this.pool,
    required this.prizeDistribution,
    required this.autoGenerateBracket,
    required this.matchIntervalMinutes,
    required this.thirdPlaceMatch,
    required this.referralQuota,
    required this.roundIntervals,
    required this.formatConfig,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
  });

  final String name;
  final GameType game;
  final TournamentFormat format;
  final bool publishNow;
  final String? description;
  final DateTime startDate;
  final int maxPlayers;
  final double fee;
  final String currency;
  final String countryCode;
  final double commissionXaf;
  final double commissionPct;
  final double pool;
  final List<int> prizeDistribution;
  final bool autoGenerateBracket;
  final int matchIntervalMinutes;
  final bool thirdPlaceMatch;
  final int referralQuota;
  final List<int>? roundIntervals;
  final Map<String, dynamic> formatConfig;
  final String? androidStoreUrl;
  final String? iosStoreUrl;
}

/// Payload d'INSERT d'une compétition (colonnes complètes). `status` dérive de
/// [CompetitionDraft.publishNow]. [createdBy] = id de l'admin.
Map<String, dynamic> buildCreateCompetitionPayload(
  CompetitionDraft d, {
  required String createdBy,
}) {
  return <String, dynamic>{
    'name': d.name,
    'game': d.game.value,
    'format': d.format.value,
    'status': d.publishNow ? 'registration_open' : 'draft',
    'description': d.description,
    'start_date': d.startDate.toUtc().toIso8601String(),
    'max_players': d.maxPlayers,
    'registration_fee': d.fee,
    'registration_currency': d.currency,
    'country_code': d.countryCode,
    'commission_xaf': d.commissionXaf,
    'commission_pct': d.commissionPct,
    'prize_pool_local': d.pool,
    'prize_pool_currency': d.currency,
    'prize_distribution': d.prizeDistribution,
    'created_by': createdBy,
    'auto_generate_bracket': d.autoGenerateBracket,
    'match_interval_minutes': d.matchIntervalMinutes,
    'third_place_match': d.thirdPlaceMatch,
    'referral_quota': d.referralQuota,
    'referral_activity_mode': 'any',
    'round_intervals': d.roundIntervals,
    'format_config': d.formatConfig,
    'android_store_url': d.androidStoreUrl,
    'ios_store_url': d.iosStoreUrl,
  };
}

/// Payload d'UPDATE d'une compétition : seuls les champs « sûrs ». Jeu, format,
/// capacité, frais et devise restent ceux d'origine (non poussés).
Map<String, dynamic> buildUpdateCompetitionPayload(CompetitionDraft d) {
  return <String, dynamic>{
    'name': d.name,
    'description': d.description,
    'start_date': d.startDate.toUtc().toIso8601String(),
    'country_code': d.countryCode,
    'commission_xaf': d.commissionXaf,
    'commission_pct': d.commissionPct,
    'prize_pool_local': d.pool,
    'prize_distribution': d.prizeDistribution,
    'auto_generate_bracket': d.autoGenerateBracket,
    'match_interval_minutes': d.matchIntervalMinutes,
    'third_place_match': d.thirdPlaceMatch,
    'referral_quota': d.referralQuota,
    'referral_activity_mode': 'any',
    'round_intervals': d.roundIntervals,
    'format_config': d.formatConfig,
    'android_store_url': d.androidStoreUrl,
    'ios_store_url': d.iosStoreUrl,
  };
}
