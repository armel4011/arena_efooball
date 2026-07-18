import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modèles de description pour la création de compétitions.
///
/// Deux mécanismes complémentaires :
///  1. [kDefaultDescriptionTemplates] — un pitch **standard** par type de jeu,
///     proposé d'office et toujours modifiable. C'est la pré-saisie quand le
///     champ est vide (à l'ouverture du wizard ou au changement de jeu).
///  2. Une **bibliothèque globale de modèles nommés** ([DescriptionTemplate]) —
///     l'admin enregistre autant de modèles qu'il veut (avec un nom), puis les
///     réinsère pour n'importe quel jeu. Persistée en local via [PersistentCache]
///     (SharedPreferences, namespace `admin.competition_desc_templates_v2`).

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
  GameType.eaSportsFc: '⚽ Tournoi Mobile FC ARENA\n'
      '\n'
      "La compétition mobile ultime t'attend ! Compose ton équipe, "
      'enchaîne les victoires et vise le titre.\n'
      '\n'
      '📋 Règles : matchs en 1v1, fair-play obligatoire, capture '
      "d'écran du score demandée en cas de litige.\n"
      '⏱️ Sois connecté 5 minutes avant ton match. À toi de jouer !',
  GameType.dreamLeague: '🥅 Tournoi Dream League Soccer ARENA\n'
      '\n'
      'Bâtis ton club de rêve et affronte les meilleurs managers ! '
      'Inscris-toi, gravis le bracket et vise le titre.\n'
      '\n'
      '📋 Règles : matchs en 1v1, fair-play obligatoire, capture '
      "d'écran du score demandée en cas de litige.\n"
      '⏱️ Sois connecté 5 minutes avant ton match. Bonne chance !',
};

/// Un modèle de description nommé, réutilisable pour n'importe quel jeu.
class DescriptionTemplate {
  const DescriptionTemplate({required this.name, required this.text});

  factory DescriptionTemplate.fromJson(Map<String, dynamic> json) =>
      DescriptionTemplate(
        name: (json['name'] ?? '').toString(),
        text: (json['text'] ?? '').toString(),
      );

  final String name;
  final String text;

  Map<String, dynamic> toJson() => {'name': name, 'text': text};
}

/// État chargé : la bibliothèque de modèles nommés de l'admin.
class CompetitionDescTemplates {
  const CompetitionDescTemplates(this.saved);

  /// Modèles nommés enregistrés par l'admin (ordre d'ajout).
  final List<DescriptionTemplate> saved;

  bool get hasSaved => saved.isNotEmpty;

  /// Pitch standard du jeu (repli quand le champ est vide).
  String standardFor(GameType game) => kDefaultDescriptionTemplates[game] ?? '';
}

/// Charge / enregistre la bibliothèque de modèles. Source de vérité locale
/// (préférence purement admin, par appareil) — pas de table serveur.
class CompetitionDescTemplatesNotifier
    extends AsyncNotifier<CompetitionDescTemplates> {
  static const _ns = 'admin.competition_desc_templates_v2';

  @override
  Future<CompetitionDescTemplates> build() async {
    final cache = await ref.watch(persistentCacheProvider.future);
    final list =
        cache.readList<DescriptionTemplate>(_ns, DescriptionTemplate.fromJson) ??
            const <DescriptionTemplate>[];
    return CompetitionDescTemplates(List.unmodifiable(list));
  }

  Future<void> _persist(List<DescriptionTemplate> list) async {
    final cache = await ref.read(persistentCacheProvider.future);
    await cache.writeList<DescriptionTemplate>(_ns, list, (t) => t.toJson());
    state = AsyncData(CompetitionDescTemplates(List.unmodifiable(list)));
  }

  /// Ajoute un modèle nommé [name] = [text]. Si un modèle du même nom
  /// (insensible à la casse) existe déjà, son texte est remplacé.
  Future<void> saveTemplate(String name, String text) async {
    final current = [...?state.valueOrNull?.saved];
    final tpl = DescriptionTemplate(name: name, text: text);
    final idx =
        current.indexWhere((t) => t.name.toLowerCase() == name.toLowerCase());
    if (idx >= 0) {
      current[idx] = tpl;
    } else {
      current.add(tpl);
    }
    await _persist(current);
  }

  /// Supprime le modèle nommé [name].
  Future<void> deleteTemplate(String name) async {
    final current = [...?state.valueOrNull?.saved]
      ..removeWhere((t) => t.name == name);
    await _persist(current);
  }
}

final competitionDescTemplatesProvider = AsyncNotifierProvider<
    CompetitionDescTemplatesNotifier, CompetitionDescTemplates>(
  CompetitionDescTemplatesNotifier.new,
);
