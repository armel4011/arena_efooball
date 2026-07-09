import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/admin/competition_draft.dart';
import 'package:flutter_test/flutter_test.dart';

CompetitionDraft _draft({
  bool publishNow = false,
  TournamentFormat format = TournamentFormat.singleElimination,
  List<int> prizeDistribution = const [50, 25, 15, 10],
  List<int>? roundIntervals,
  Map<String, dynamic> formatConfig = const {},
}) {
  return CompetitionDraft(
    name: 'Coupe Test',
    game: GameType.efootball,
    format: format,
    publishNow: publishNow,
    description: 'desc',
    startDate: DateTime.utc(2026, 8, 1, 10),
    maxPlayers: 16,
    fee: 1000,
    currency: 'XAF',
    countryCode: 'CM',
    commissionXaf: 500,
    commissionPct: 0.5,
    pool: 100000,
    prizeDistribution: prizeDistribution,
    autoGenerateBracket: true,
    matchIntervalMinutes: 60,
    thirdPlaceMatch: false,
    referralQuota: 0,
    roundIntervals: roundIntervals,
    formatConfig: formatConfig,
    androidStoreUrl: null,
    iosStoreUrl: null,
  );
}

void main() {
  group('buildCreateCompetitionPayload', () {
    test('status dérive de publishNow', () {
      expect(
        buildCreateCompetitionPayload(_draft(), createdBy: 'admin')['status'],
        'draft',
      );
      expect(
        buildCreateCompetitionPayload(
          _draft(publishNow: true),
          createdBy: 'admin',
        )['status'],
        'registration_open',
      );
    });

    test('sérialise game/format via .value + inclut les colonnes de création',
        () {
      final p = buildCreateCompetitionPayload(_draft(), createdBy: 'admin-42');
      expect(p['game'], 'efootball');
      expect(p['format'], 'single_elimination');
      expect(p['created_by'], 'admin-42');
      expect(p['max_players'], 16);
      expect(p['registration_fee'], 1000);
      expect(p['registration_currency'], 'XAF');
      expect(p['prize_pool_currency'], 'XAF');
      expect(p['prize_pool_local'], 100000);
      expect(p['referral_activity_mode'], 'any');
      expect(p['start_date'], '2026-08-01T10:00:00.000Z');
      expect(p['prize_distribution'], [50, 25, 15, 10]);
    });
  });

  group('buildUpdateCompetitionPayload', () {
    test('exclut jeu/format/capacité/frais/devise (champs figés en édition)',
        () {
      final p = buildUpdateCompetitionPayload(_draft());
      for (final k in const [
        'game',
        'format',
        'status',
        'max_players',
        'registration_fee',
        'registration_currency',
        'prize_pool_currency',
        'created_by',
      ]) {
        expect(p.containsKey(k), isFalse, reason: '$k ne doit pas être poussé');
      }
      // Champs « sûrs » présents.
      expect(p['name'], 'Coupe Test');
      expect(p['commission_xaf'], 500);
      expect(p['prize_pool_local'], 100000);
    });
  });

  group('computePrizeDistribution / computeShareTotal', () {
    test('noReward court-circuite', () {
      expect(
        computePrizeDistribution(
          noReward: true,
          rewardedCount: 4,
          topShareTexts: const ['50', '25', '15', '10'],
          blockShareTexts: const [],
        ),
        isEmpty,
      );
      expect(
        computeShareTotal(
          noReward: true,
          rewardedCount: 8,
          topShareTexts: const ['50', '25', '15', '10'],
          blockShareTexts: const ['5'],
        ),
        0,
      );
    });

    test('top 4 seuls quand rewardedCount=4', () {
      final dist = computePrizeDistribution(
        noReward: false,
        rewardedCount: 4,
        topShareTexts: const ['50', '25', '15', '10'],
        blockShareTexts: const ['5', '5', '5', '5', '5'],
      );
      expect(dist, [50, 25, 15, 10]);
      expect(
        computeShareTotal(
          noReward: false,
          rewardedCount: 4,
          topShareTexts: const ['50', '25', '15', '10'],
          blockShareTexts: const ['5'],
        ),
        100,
      );
    });

    test('rewardedCount=8 déplie le 1er bloc (5-8, taille 4)', () {
      final dist = computePrizeDistribution(
        noReward: false,
        rewardedCount: 8,
        topShareTexts: const ['50', '25', '15', '10'],
        blockShareTexts: const ['3', '0', '0', '0', '0'],
      );
      // top4 + 4 places du bloc à 3.
      expect(dist, [50, 25, 15, 10, 3, 3, 3, 3]);
      expect(
        computeShareTotal(
          noReward: false,
          rewardedCount: 8,
          topShareTexts: const ['50', '25', '15', '10'],
          blockShareTexts: const ['3', '0', '0', '0', '0'],
        ),
        100 + 12,
      );
    });
  });

  group('parseRoundIntervals', () {
    test('vide → null', () {
      expect(parseRoundIntervals(''), isNull);
      expect(parseRoundIntervals('   '), isNull);
    });
    test('CSV valide → liste', () {
      expect(parseRoundIntervals('30, 60,120'), [30, 60, 120]);
    });
    test('valeur invalide ou ≤0 → null (fallback)', () {
      expect(parseRoundIntervals('30,abc'), isNull);
      expect(parseRoundIntervals('30,0'), isNull);
      expect(parseRoundIntervals('30,-5'), isNull);
    });
  });

  group('buildFormatConfig', () {
    test('non-groupes → vide', () {
      expect(
        buildFormatConfig(
          format: TournamentFormat.singleElimination,
          groupCountText: '4',
          qualifiersText: '2',
        ),
        isEmpty,
      );
    });
    test('groupes → group_count / qualifiers_per_group (défauts 4/2)', () {
      expect(
        buildFormatConfig(
          format: TournamentFormat.groupsThenKnockout,
          groupCountText: '8',
          qualifiersText: '3',
        ),
        {'group_count': 8, 'qualifiers_per_group': 3},
      );
      expect(
        buildFormatConfig(
          format: TournamentFormat.groupsThenKnockout,
          groupCountText: '',
          qualifiersText: 'x',
        ),
        {'group_count': 4, 'qualifiers_per_group': 2},
      );
    });
  });

  group('canAdvanceCompetitionStep', () {
    bool step(int s, {String name = 'Coupe', String fee = '0'}) =>
        canAdvanceCompetitionStep(
          step: s,
          name: name,
          startDate: DateTime.utc(2026, 8, 1),
          maxPlayers: 16,
          entryFeeText: fee,
          paymentCountries: const [],
        );

    test('étape 0 : nom ≥ 3 + date', () {
      expect(step(0, name: 'ab'), isFalse);
      expect(step(0, name: 'abc'), isTrue);
      expect(
        canAdvanceCompetitionStep(
          step: 0,
          name: 'abc',
          startDate: null,
          maxPlayers: 16,
          entryFeeText: '0',
          paymentCountries: const [],
        ),
        isFalse,
      );
    });
    test('étape 2 (récompenses libres) toujours OK', () {
      expect(step(2), isTrue);
    });
    test('étape 3 : frais ≥ 0', () {
      expect(step(3, fee: '-1'), isFalse);
      expect(step(3, fee: 'abc'), isFalse);
      expect(step(3, fee: '0'), isTrue);
      expect(step(3, fee: '500'), isTrue);
    });
    test('étape 4 : gratuit → OK sans pays', () {
      expect(step(4, fee: '0'), isTrue);
    });
  });
}
