import 'package:freezed_annotation/freezed_annotation.dart';

part 'competition_payment_option.freezed.dart';
part 'competition_payment_option.g.dart';

/// Mirror of the `competition_payment_options` table.
///
/// Une option de paiement P2P manuel d'une compétition payante : pour un
/// pays donné, un opérateur (Orange Money, MTN MoMo, Wave…) et son code de
/// transfert Mobile Money. Les pays DISTINCTS d'une compétition = les pays
/// dont les résidents peuvent s'inscrire (le joueur choisit son pays, puis un
/// opérateur de ce pays, à l'étape paiement).
@Freezed(fromJson: true, toJson: true)
sealed class CompetitionPaymentOption with _$CompetitionPaymentOption {
  const factory CompetitionPaymentOption({
    required String id,
    required String competitionId,
    required String countryCode,
    required String operatorLabel,
    required String transferCode,

    /// Indicatif E.164 du pays (ex. `'+237'`) — pré-remplit le champ numéro
    /// côté joueur (P2). Peut être null (repli sur `dialCodeFor(countryCode)`).
    String? dialCode,
    @Default(0) int sortOrder,
    DateTime? createdAt,
  }) = _CompetitionPaymentOption;

  const CompetitionPaymentOption._();

  factory CompetitionPaymentOption.fromJson(Map<String, dynamic> json) =>
      _$CompetitionPaymentOptionFromJson(json);

  /// Payload JSON envoyé à la RPC `set_competition_payment_options`
  /// (l'id / competition_id sont posés côté serveur).
  Map<String, dynamic> toRpcJson() => <String, dynamic>{
        'country_code': countryCode,
        'operator_label': operatorLabel,
        'transfer_code': transferCode,
        if (dialCode != null && dialCode!.isNotEmpty) 'dial_code': dialCode,
        'sort_order': sortOrder,
      };
}
