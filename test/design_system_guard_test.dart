// Garde "ratchet" du design system ARENA.
//
// Le design system (ArenaColors / ArenaText) est centralisé dans
// `lib/core/theme/`, mais l'audit du 2026-06-14 a relevé ~2092 usages directs
// de `Colors.*` / `Color(0x...)` ailleurs dans `lib/` — le design system y est
// contourné. Résorber tout d'un coup est un gros chantier ; en attendant, ce
// test fige la dette : il ÉCHOUE si le nombre d'usages directs AUGMENTE.
//
// Règle pour le nouveau code : utiliser `ArenaColors.<nom>` (et `ArenaText`)
// plutôt que `Colors.*` ou `Color(0x...)` hors de `lib/core/theme/`.
//
// Quand tu remplaces des usages directs par le design system, fais DESCENDRE
// les baselines ci-dessous (idéalement jusqu'à 0). Ne les remonte jamais.
//
// Exécuté par le job CI "Analyze & Test" (`flutter test`) — aucune
// configuration de workflow nécessaire.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Baselines figées au 2026-06-14 (hors lib/core/theme, fichiers générés, l10n).
  // NE JAMAIS AUGMENTER pour de VRAIS `Colors.*`. Le regex `Colors\.` matche
  // aussi `ArenaColors.` (tokens légitimes) → un ajout net de tokens fait
  // monter le compte sans vraie régression. 2179 → 2182 le 2026-06-14 : +3
  // `ArenaColors.*` de la page d'entrée des litiges (check_colors.sh --strict
  // = 0 régression). À faire décroître via migration vers tokens.
  // 2182 → 2187 le 2026-06-14 : +5 `ArenaColors.*` du tier badge dérivé des
  // victoires (helper player_tier.dart + badges profil perso/public, gradients
  // bronze/argent/or/élite). check_colors.sh --strict = 0 régression (aucun
  // vrai `Colors.*` ajouté). À faire décroître via migration vers tokens.
  // 2187 → 2191 le 2026-06-15 : +4 `ArenaColors.*` du podium top-3 du classement
  // final (gold / silver / tierBronze / statusOk dans `_PodiumPlace`).
  // check_colors.sh --strict = 0 régression. À faire décroître via tokens.
  // 2191 → 2192 le 2026-06-15 : +1 `ArenaColors.tierGoldWarm` de l'icône notif
  // `competition_result` (feed). check_colors.sh --strict = 0 régression.
  // 2192 → 2203 le 2026-06-19 : +11 `ArenaColors.*` de la feature photos
  // d'avatar (pastille caméra signalBlue, bordures bone/carbon/surface, retrait
  // danger, repli initiales dans arena_avatar / edit_profile / profils / amis).
  // check_colors.sh --strict = 0 régression (aucun vrai `Colors.*` ajouté ;
  // les 3 `Colors.white` déplacés sont compensés par 3 retraits).
  // 2203 → 2211 le 2026-06-19 : +8 `ArenaColors.*` des chips de filtre directs
  // de la liste des compétitions (statut signalBlue/statusWarn/silver, tarif
  // signalBlue/statusOk/tierGoldWarm, fond carbon + border dans _FilterPill).
  // check_colors.sh --strict = 0 régression (aucun vrai `Colors.*` ajouté).
  // 2211 → 2215 le 2026-06-20 : +4 `ArenaColors.*` de l'écran de verrou de la
  // salle de match (signalBlue de l'icône + rebours, silver des textes).
  // check_colors.sh --strict = 0 régression (aucun vrai `Colors.*` ajouté).
  // 2215 → 2220 le 2026-06-20 : +5 `ArenaColors.*` de la bibliothèque de
  // modèles de description (surface/neonRed du dialog de nom, surface/carbon/
  // danger du bottom sheet). check_colors.sh --strict = 0 (aucun vrai Colors.*).
  // 2220 → 2231 le 2026-06-20 : +11 `ArenaColors.*` du flux finance desktop
  // (page Versements génération/markPaid + volet Remboursements). 0 vrai Colors.*.
  // 2231 → 2238 le 2026-06-20 : +7 `ArenaColors.*` des graphes mensuels du
  // super-dashboard desktop (fl_chart inscriptions/revenus). 0 vrai Colors.*.
  // 2238 → 2246 le 2026-06-21 : +8 `ArenaColors.*` de la parité desktop restante
  // (filtres audience partagés users/broadcast, icône épinglage + flyout actions
  // rapides compétitions, carte sécurité profil + reset 2FA, liens login↔
  // inscription par code). 0 vrai Colors.* ajouté (tous des tokens).
  // 2246 → 2253 le 2026-06-22 : +7 `ArenaColors.*` du statut « à reprogrammer »
  // (helpers status-aware label/couleur user, badges admin mobile/desktop/header,
  // glow card, bloc 3 actions admin). 0 vrai Colors.* ajouté (tous des tokens).
  // 2253 → 2254 le 2026-06-22 : +1 `ArenaColors.statusWarn` de la puce de filtre
  // « à reprogrammer » de la liste user. 0 vrai Colors.* ajouté (token).
  // 2254 → 2260 le 2026-06-26 : +6 `ArenaColors.*` (carbon/danger/surface) des
  // bibliothèques de configs de récompense + codes marchands réutilisables
  // (create_competition). 0 vrai Colors.* ajouté (tous des tokens).
  const colorsDotBaseline = 2260; // occurrences de `Colors.`
  const colorHexBaseline = 28; // occurrences de `Color(0x`
  // Baseline GoogleFonts figée au 2026-06-26 : 185 usages directs de
  // `GoogleFonts.<font>` hors lib/core/theme, TOUS dans lib/features_admin_desktop/.
  // Le design system fournit ArenaText — toute NOUVELLE occurrence doit le
  // remplacer. NE JAMAIS AUGMENTER ; faire décroître via migration vers ArenaText.
  const googleFontsBaseline = 185; // occurrences de `GoogleFonts.`

  final colorsDotRe = RegExp(r'Colors\.');
  final colorHexRe = RegExp(r'Color\(0x');
  final googleFontsRe = RegExp(r'GoogleFonts\.');

  bool isExcluded(String path) {
    final p = path.replaceAll(r'\', '/');
    return p.contains('lib/core/theme/') ||
        p.contains('lib/l10n/') ||
        p.endsWith('.g.dart') ||
        p.endsWith('.freezed.dart');
  }

  ({int colorsDot, int colorHex, int googleFonts, int files}) scan() {
    var colorsDot = 0;
    var colorHex = 0;
    var googleFonts = 0;
    var files = 0;
    final libDir = Directory('lib');
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (isExcluded(entity.path)) continue;
      files++;
      final content = entity.readAsStringSync();
      colorsDot += colorsDotRe.allMatches(content).length;
      colorHex += colorHexRe.allMatches(content).length;
      googleFonts += googleFontsRe.allMatches(content).length;
    }
    return (
      colorsDot: colorsDot,
      colorHex: colorHex,
      googleFonts: googleFonts,
      files: files,
    );
  }

  test('design system : pas de nouveaux usages directs de Colors.* (ratchet)', () {
    final r = scan();
    expect(
      r.colorsDot,
      lessThanOrEqualTo(colorsDotBaseline),
      reason:
          'Usages directs de `Colors.*` hors lib/core/theme : ${r.colorsDot} '
          '> baseline $colorsDotBaseline. Utilise `ArenaColors.<nom>` dans le '
          'nouveau code. Si tu as VRAIMENT réduit la dette, baisse la baseline.',
    );
  });

  test('design system : pas de nouveaux Color(0x...) en dur (ratchet)', () {
    final r = scan();
    expect(
      r.colorHex,
      lessThanOrEqualTo(colorHexBaseline),
      reason:
          'Couleurs hexadécimales en dur `Color(0x...)` hors lib/core/theme : '
          '${r.colorHex} > baseline $colorHexBaseline. Déclare la couleur dans '
          '`ArenaColors` et référence-la. Si tu as réduit la dette, baisse la baseline.',
    );
  });

  test('design system : pas de nouveaux GoogleFonts.* inline (ratchet)', () {
    final r = scan();
    expect(
      r.googleFonts,
      lessThanOrEqualTo(googleFontsBaseline),
      reason:
          'Usages directs de `GoogleFonts.*` hors lib/core/theme : '
          '${r.googleFonts} > baseline $googleFontsBaseline. Utilise `ArenaText` '
          '(centralisé dans lib/core/theme/) plutôt que GoogleFonts inline. '
          'Si tu as VRAIMENT réduit la dette, baisse la baseline.',
    );
  });
}
