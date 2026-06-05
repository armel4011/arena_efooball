import 'package:freezed_annotation/freezed_annotation.dart';

part 'promo_banner.freezed.dart';
part 'promo_banner.g.dart';

/// Type de redirection d'une bannière publicitaire au tap.
enum PromoRedirectType {
  /// Une route interne de l'app (ex. `/streams`). Ouverte via `context.push`.
  @JsonValue('internal_page')
  internalPage,

  /// Une URL web externe (https://…). Ouverte via `url_launcher`.
  @JsonValue('web_link')
  webLink,

  /// Un numéro WhatsApp. On construit `https://wa.me/<digits>` au tap.
  @JsonValue('whatsapp')
  whatsapp,
}

/// Valeur "fil" (snake_case) attendue par la colonne `redirect_type` —
/// `.name` renvoie le camelCase Dart, inutilisable pour l'INSERT brut.
extension PromoRedirectTypeWire on PromoRedirectType {
  String get wire => switch (this) {
        PromoRedirectType.internalPage => 'internal_page',
        PromoRedirectType.webLink => 'web_link',
        PromoRedirectType.whatsapp => 'whatsapp',
      };
}

/// Miroir de la table `promo_banner`. Une seule bannière est active à la
/// fois côté produit (cf. index unique partiel + repo).
@Freezed(fromJson: true, toJson: true)
sealed class PromoBanner with _$PromoBanner {
  const factory PromoBanner({
    required String id,
    required String imageUrl,
    required PromoRedirectType redirectType,
    required String redirectTarget,
    @Default(true) bool isActive,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PromoBanner;

  factory PromoBanner.fromJson(Map<String, dynamic> json) =>
      _$PromoBannerFromJson(json);
}
