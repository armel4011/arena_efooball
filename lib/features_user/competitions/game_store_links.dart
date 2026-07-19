import 'package:arena/data/models/competition_enums.dart';

/// Liens de téléchargement (Play Store) par jeu EXTERNE, pour le bouton
/// « Store » du dialogue de contrôle d'installation avant inscription.
///
/// ⚠️ Liens fixes (décision produit 2026-07-19). Les package names eFootball
/// et Mobile FC proviennent de `target_game.dart` (anti-triche) ; Dream League
/// Soccer 2024 = `com.firsttouchgames.dls8`. À corriger ici si un store change.
/// Les Dames ([GameType.draughts]) se jouent in-app → pas de lien (`null`).
String? gameStoreUrl(GameType game) => switch (game) {
      GameType.efootball =>
        'https://play.google.com/store/apps/details?id=jp.konami.pesam',
      GameType.eaSportsFc =>
        'https://play.google.com/store/apps/details?id=com.ea.gp.fifamobile',
      GameType.dreamLeague =>
        'https://play.google.com/store/apps/details?id=com.firsttouchgames.dls8',
      GameType.draughts => null,
    };
