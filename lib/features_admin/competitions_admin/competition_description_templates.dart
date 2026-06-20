import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modèles de description réutilisables pour la création de compétitions.
///
/// Deux niveaux :
///  1. [kDefaultDescriptionTemplates] — un pitch **standard** par type de
///     jeu, proposé d'office et toujours modifiable. C'est le repli quand
///     l'admin n'a rien personnalisé.
///  2. Overrides persistés — quand l'admin clique « Enregistrer comme
///     modèle », son texte remplace le standard pour ce jeu et sera
///     pré-rempli aux prochaines créations. Stocké en local via
///     [PersistentCache] (SharedPreferences).
///
/// La pré-saisie n'écrase jamais un texte que l'admin a tapé à la main :
/// le wizard ne remplace la description que si elle est vide ou strictement
/// égale au modèle précédemment appliqué (cf. `create_competition_page`).

/// Descriptions standard par jeu, éditables à chaque création.
const Map<GameType, String> kDefaultDescriptionTemplates = {
  GameType.efootball: '🏆 Tournoi eFootball ARENA\n'
      '\n'
      'Affronte les meilleurs joueurs du Cameroun sur eFootball ! '
      'Inscris-toi, rejoins le bracket et grimpe match après match '
      "jusqu'à la finale.\n"
      '\n'
      '📋 Règles : matchs en 1v1, durée standard, fair-play obligatoire. '
      'Toute déconnexion volontaire est comptée comme une défaite.\n'
      '⏱️ Sois prêt 5 minutes avant ton match — le système te prévient. '
      'Bonne chance à tous !',
  GameType.draughts: '♟️ Tournoi de Dames ARENA\n'
      '\n'
      'Montre ta maîtrise du damier 10×10 ! Les parties se jouent '
      "directement dans l'application, en temps réel contre ton "
      'adversaire.\n'
      '\n'
      '📋 Règles : prise obligatoire, dame volante, victoire au blocage '
      'ou à la capture de tous les pions adverses.\n'
      '🧠 Réfléchis, anticipe, et que le meilleur stratège gagne !',
  GameType.eaSportsFc: '⚽ Tournoi EA SPORTS FC Mobile ARENA\n'
      '\n'
      "La compétition mobile ultime t'attend ! Compose ton équipe, "
      'enchaîne les victoires et vise le titre.\n'
      '\n'
      '📋 Règles : matchs en 1v1, fair-play obligatoire, capture '
      "d'écran du score demandée en cas de litige.\n"
      '⏱️ Sois connecté 5 minutes avant ton match. À toi de jouer !',
};

/// État chargé : les overrides admin par jeu. Le repli standard reste
/// [kDefaultDescriptionTemplates].
class CompetitionDescTemplates {
  const CompetitionDescTemplates(this.overrides);

  /// Modèles personnalisés enregistrés par l'admin (game → texte).
  final Map<GameType, String> overrides;

  /// Modèle à proposer pour [game] : l'override admin s'il existe, sinon
  /// le standard, sinon chaîne vide.
  String templateFor(GameType game) =>
      overrides[game] ?? kDefaultDescriptionTemplates[game] ?? '';

  /// `true` si l'admin a enregistré son propre modèle pour [game].
  bool hasCustom(GameType game) => overrides.containsKey(game);
}

/// Charge / enregistre les modèles de description. Source de vérité locale,
/// pas de table serveur (préférence purement admin, par appareil).
class CompetitionDescTemplatesNotifier
    extends AsyncNotifier<CompetitionDescTemplates> {
  static const _ns = 'admin.competition_desc_templates';

  @override
  Future<CompetitionDescTemplates> build() async {
    final cache = await ref.watch(persistentCacheProvider.future);
    final raw = cache.readObject<Map<String, String>>(
      _ns,
      (json) => json.map((k, v) => MapEntry(k, v.toString())),
    );
    final overrides = <GameType, String>{};
    if (raw != null) {
      for (final entry in raw.entries) {
        for (final g in GameType.values) {
          if (g.value == entry.key) {
            overrides[g] = entry.value;
            break;
          }
        }
      }
    }
    return CompetitionDescTemplates(overrides);
  }

  Future<void> _persist(Map<GameType, String> overrides) async {
    final cache = await ref.read(persistentCacheProvider.future);
    await cache.writeObject<Map<String, dynamic>>(
      _ns,
      {for (final e in overrides.entries) e.key.value: e.value},
      (m) => m,
    );
    state = AsyncData(CompetitionDescTemplates(overrides));
  }

  /// Enregistre [text] comme modèle personnel pour [game].
  Future<void> save(GameType game, String text) async {
    final current = state.valueOrNull?.overrides ?? const {};
    await _persist({...current, game: text});
  }

  /// Supprime le modèle personnel de [game] (retour au standard).
  Future<void> reset(GameType game) async {
    final current = {...?state.valueOrNull?.overrides}..remove(game);
    await _persist(current);
  }
}

final competitionDescTemplatesProvider = AsyncNotifierProvider<
    CompetitionDescTemplatesNotifier, CompetitionDescTemplates>(
  CompetitionDescTemplatesNotifier.new,
);
