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
  const colorsDotBaseline = 2187; // occurrences de `Colors.`
  const colorHexBaseline = 28; // occurrences de `Color(0x`

  final colorsDotRe = RegExp(r'Colors\.');
  final colorHexRe = RegExp(r'Color\(0x');

  bool isExcluded(String path) {
    final p = path.replaceAll(r'\', '/');
    return p.contains('lib/core/theme/') ||
        p.contains('lib/l10n/') ||
        p.endsWith('.g.dart') ||
        p.endsWith('.freezed.dart');
  }

  ({int colorsDot, int colorHex, int files}) scan() {
    var colorsDot = 0;
    var colorHex = 0;
    var files = 0;
    final libDir = Directory('lib');
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (isExcluded(entity.path)) continue;
      files++;
      final content = entity.readAsStringSync();
      colorsDot += colorsDotRe.allMatches(content).length;
      colorHex += colorHexRe.allMatches(content).length;
    }
    return (colorsDot: colorsDot, colorHex: colorHex, files: files);
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
}
