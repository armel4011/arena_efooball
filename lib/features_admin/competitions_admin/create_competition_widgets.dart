part of 'create_competition_page.dart';

/// Helpers de calcul du wizard, extraits de [_CreateCompetitionPageState] pour
/// garder `create_competition_page.dart` sous le seuil god-file. L'extension
/// vit dans la même librairie (`part of`) → accès complet aux champs privés du
/// State. Aucune méthode appelant `setState` n'y figure : `setState` est
/// @protected (réservé aux sous-classes de State) et inaccessible depuis une
/// extension — ces méthodes restent dans le State.
extension _CreateCompetitionComputations on _CreateCompetitionPageState {
  bool get _canAdvance => canAdvanceCompetitionStep(
        step: _step,
        name: _nameCtrl.text,
        startDate: _startDate,
        maxPlayers: _maxPlayers,
        entryFeeText: _entryFeeCtrl.text,
        paymentCountries: _paymentCountries,
      );

  /// Construit la liste plate des **montants** par place : places
  /// individuelles 1-4 puis chaque bloc actif déplié (même montant
  /// répété sur toutes ses places).
  List<int> _prizeDistribution() => computePrizeDistribution(
        noReward: _noReward,
        rewardedCount: _rewardedCount,
        topShareTexts: _topShareCtrls.map((c) => c.text).toList(),
        blockShareTexts: _blockShareCtrls.map((c) => c.text).toList(),
      );

  /// Somme des montants : places individuelles + (montant de bloc × sa
  /// taille). C'est la cagnotte totale distribuée.
  int _shareTotal() => computeShareTotal(
        noReward: _noReward,
        rewardedCount: _rewardedCount,
        topShareTexts: _topShareCtrls.map((c) => c.text).toList(),
        blockShareTexts: _blockShareCtrls.map((c) => c.text).toList(),
      );

  /// Cagnotte à persister dans `prize_pool_local` : la somme des
  /// montants de récompense saisis.
  double _computedPool() => _shareTotal().toDouble();

  /// Commission ARENA en montant XAF (Lot B). Parse l'input numérique.
  double _commissionXaf() =>
      double.tryParse(_commissionXafCtrl.text.trim()) ?? 0;

  /// Quota parrainages requis (Lot D). 0 = pas de gating.
  int _referralQuota() => int.tryParse(_referralQuotaCtrl.text.trim()) ?? 0;

  /// Lot A.2 — Parse `_roundIntervalsCtrl` CSV → `List<int>?`. Vide ou
  /// malformé → null (utilise l'intervalle global).
  List<int>? _roundIntervals() =>
      parseRoundIntervals(_roundIntervalsCtrl.text);

  /// Lot F.1 — Config groupes pour groups_then_knockout.
  Map<String, dynamic> _formatConfig() => buildFormatConfig(
        format: _format,
        groupCountText: _groupCountCtrl.text,
        qualifiersText: _qualifiersPerGroupCtrl.text,
      );
}

/// Ramène une longueur de distribution arbitraire au palier valide
/// le plus proche par défaut (1, 2, 4, 8, 16, 32, 64).
int _snapRewardedCount(int length) {
  var snapped = kRewardedRankOptions.first;
  for (final opt in kRewardedRankOptions) {
    if (opt <= length) snapped = opt;
  }
  return snapped;
}

String _stepTitle(int step) {
  switch (step) {
    case 0:
      return 'Infos';
    case 1:
      return 'Format';
    case 2:
      return 'Récompenses';
    case 3:
      return 'Frais';
    case 4:
      return 'Pays';
    case 5:
      return 'Récap';
    default:
      return '';
  }
}
