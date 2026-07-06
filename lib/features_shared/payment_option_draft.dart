import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/models/competition_payment_option.dart';
import 'package:flutter/widgets.dart';

/// Structure d'édition d'une option de paiement dans le wizard de
/// création/édition de compétition (étape « Pays »).
///
/// Le modèle serveur [CompetitionPaymentOption] est immuable et n'a pas de
/// controllers ; ces classes-ci portent les [TextEditingController] vivants
/// pendant l'édition, groupés par pays. Partagées entre le wizard mobile
/// (`WizardStepCountry`) et le wizard desktop (`_buildCountryStep`).

/// Un opérateur en cours d'édition : nom libre (Orange Money, Wave…) + son
/// code de transfert Mobile Money.
class PaymentDraftOperator {
  PaymentDraftOperator({String label = '', String code = ''})
      : labelCtrl = TextEditingController(text: label),
        codeCtrl = TextEditingController(text: code);

  final TextEditingController labelCtrl;
  final TextEditingController codeCtrl;

  void dispose() {
    labelCtrl.dispose();
    codeCtrl.dispose();
  }
}

/// Un pays activé + la liste libre de ses opérateurs. `countryCode` est
/// mutable (l'admin peut le changer via le picker).
class PaymentDraftCountry {
  PaymentDraftCountry({
    required this.countryCode,
    List<PaymentDraftOperator>? operators,
  }) : operators = operators ?? [PaymentDraftOperator()];

  String countryCode;
  final List<PaymentDraftOperator> operators;

  void dispose() {
    for (final o in operators) {
      o.dispose();
    }
  }
}

/// Reconstruit la liste de brouillons groupée par pays depuis les options
/// serveur (préremplissage en édition). Préserve l'ordre d'apparition des
/// pays et le `sort_order` des opérateurs (déjà trié côté fetch).
List<PaymentDraftCountry> paymentDraftsFromOptions(
  List<CompetitionPaymentOption> options,
) {
  final byCountry = <String, PaymentDraftCountry>{};
  final order = <String>[];
  for (final o in options) {
    final group = byCountry.putIfAbsent(o.countryCode, () {
      order.add(o.countryCode);
      return PaymentDraftCountry(
        countryCode: o.countryCode,
        operators: <PaymentDraftOperator>[],
      );
    });
    group.operators.add(
      PaymentDraftOperator(label: o.operatorLabel, code: o.transferCode),
    );
  }
  return [for (final code in order) byCountry[code]!];
}

/// Aplati les brouillons en options serveur prêtes pour la RPC
/// `set_competition_payment_options`. Ignore les lignes incomplètes
/// (label ou code vide), attribue un `sortOrder` croissant global, et
/// résout le `dialCode` depuis le pays.
List<CompetitionPaymentOption> paymentOptionsFromDrafts(
  List<PaymentDraftCountry> countries,
) {
  final out = <CompetitionPaymentOption>[];
  var sort = 0;
  for (final country in countries) {
    for (final op in country.operators) {
      final label = op.labelCtrl.text.trim();
      final code = op.codeCtrl.text.trim();
      if (label.isEmpty || code.isEmpty) continue;
      out.add(
        CompetitionPaymentOption(
          id: '',
          competitionId: '',
          countryCode: country.countryCode,
          operatorLabel: label,
          transferCode: code,
          dialCode: dialCodeFor(country.countryCode),
          sortOrder: sort++,
        ),
      );
    }
  }
  return out;
}

/// Valide les brouillons pour une compétition PAYANTE : au moins un pays,
/// chaque pays avec au moins un opérateur, chaque opérateur avec un nom ET
/// un code non vides.
bool paymentDraftsValid(List<PaymentDraftCountry> countries) {
  if (countries.isEmpty) return false;
  for (final country in countries) {
    if (country.operators.isEmpty) return false;
    for (final op in country.operators) {
      if (op.labelCtrl.text.trim().isEmpty) return false;
      if (op.codeCtrl.text.trim().isEmpty) return false;
    }
  }
  return true;
}

/// Premier pays de [kSupportedCountries] pas encore présent dans
/// [countries] — pour pré-sélectionner un pays neuf à l'ajout. Repli sur
/// le 1er pays si tous sont déjà utilisés.
String firstUnusedCountry(List<PaymentDraftCountry> countries) {
  final used = countries.map((c) => c.countryCode).toSet();
  for (final c in kSupportedCountries) {
    if (!used.contains(c.code)) return c.code;
  }
  return kSupportedCountries.first.code;
}
