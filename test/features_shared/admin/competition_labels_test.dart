import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/admin/competition_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('competitionFormatLabel', () {
    test('tous les formats mappés', () {
      expect(
        competitionFormatLabel(TournamentFormat.singleElimination),
        'Élimination directe',
      );
      expect(
        competitionFormatLabel(TournamentFormat.groupsThenKnockout),
        'Poules puis KO',
      );
      expect(
        competitionFormatLabel(TournamentFormat.roundRobin),
        'Round robin',
      );
    });

    test('couvre exhaustivement enum (aucun format sans libellé)', () {
      for (final f in TournamentFormat.values) {
        expect(competitionFormatLabel(f), isNotEmpty, reason: f.name);
      }
    });
  });
}
