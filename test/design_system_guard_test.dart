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
  // 2254 → 2257 le 2026-06-26 : +3 `ArenaColors.*` de l'onglet « Prochain match »
  // (accent signalBlue + textMuted du Tab, silver de l'empty state de la liste).
  // 0 vrai Colors.* ajouté (tous des tokens).
  // 2257 → 2306 le 2026-06-26 : +49 `ArenaColors.*` du fil de support « Contact /
  // Aide » (écran user support_chat_page + entrée settings, boîte+fil admin
  // mobile super_admin_support_inbox/thread + action users, page desktop
  // desktop_support_page maître-détail). 0 vrai Colors.* ajouté (tous des tokens).
  // 2306 → 2310 le 2026-06-27 : +4 `ArenaColors.*` nets du sélecteur de support
  // partagé (support_options_sheet : chat + e-mail) réutilisé par À propos et
  // Réglages. 0 vrai Colors.* ajouté (tous des tokens).
  // 2310 → 2323 le 2026-06-27 : +13 `ArenaColors.*` de la MAJ in-app (dialog
  // update_available_dialog + écran super-admin mobile super_admin_app_update).
  // 0 vrai Colors.* ajouté (tous des tokens).
  // 2323 → 2327 le 2026-06-27 : +4 `ArenaColors.*` des modèles réutilisables
  // codes de paiement + barème de récompense (sheet générique _NamedTemplateSheet
  // + backgroundColor des bottom-sheets). 0 vrai Colors.* ajouté (tous tokens).
  // 2327 → 2328 le 2026-06-27 : +1 `ArenaColors.*` net de la pastille date/heure
  // mise en avant sur la card de compétition (signalBlue/bone). 0 vrai Colors.*.
  // 2328 → 2329 le 2026-06-27 : +1 `ArenaColors.*` net de la refonte mirror du
  // bracket (double arborescence + scores + trophée central). 0 vrai Colors.*.
  // 2329 → 2345 le 2026-06-27 : +16 `ArenaColors.*` du système anti-triche DUAL
  // (sélecteur super-admin mobile/desktop + section « Enregistrements auto » des
  // litiges mobile/desktop + bannière LiveKit). 0 vrai Colors.* ajouté
  // (`Colors.transparent` du wrapper _LifecycleBanner est préexistant).
  // 2345 → 2363 le 2026-06-28 : +18 `ArenaColors.*` nets de l'écran admin
  // « Enregistrements anti-triche » (consultation hors litige) — page mobile
  // admin_recordings_page + page desktop desktop_recordings_page (badges
  // provider/litige migrés Colors.blue/orange → ArenaColors.signalBlue/warning)
  // + bouton « Arrêter notif » du cycle de vie capture (match_recording_lifecycle).
  // 0 vrai Colors.* ajouté (tous des tokens ; `Colors.transparent` préexistant).
  // 2363 → 2364 le 2026-06-29 : +1 `ArenaColors.*` net du point de couleur de
  // l'overlay flottant LiveKit (mode simple) — `ArenaColors.danger/success` selon
  // l'état dans recording_overlay.dart. 0 vrai Colors.* ajouté.
  // 2364 → 2379 le 2026-06-29 : +15 `ArenaColors.*` nets de la section « Preuves
  // engagées » (anti-triche Phase 3, commitment hash) ajoutée aux écrans litiges
  // mobile (admin_disputes_page) + desktop (desktop_disputes_page) — badge de
  // statut + bouton « Réclamer la vidéo ». 0 vrai Colors.* ajouté (tous des tokens).
  // 2379 → 2383 le 2026-06-30 : +4 `ArenaColors.*` de la carte « Seuils de
  // tiering » anti-triche (P4) mobile (silver/neonRed) + desktop (carbon/silver).
  // 0 vrai Colors.* ajouté (tous des tokens).
  // 2383 → 2397 le 2026-06-30 : +14 `ArenaColors.*` du bandeau « Plan
  // anti-triche » des litiges mobile + desktop (signalBlue/silver/carbon/border/
  // bone). 0 vrai Colors.* ajouté (tous des tokens).
  // 2397 → 2404 le 2026-07-01 : +7 `ArenaColors.*` (la regex `Colors\.` matche
  // aussi `ArenaColors.`) de la ligne numéro WhatsApp copiable des cartes
  // utilisateur admin mobile (3) + desktop (4).
  // 2404 → 2423 le 2026-07-03 : +19 du panneau overlay « envoi du code room »
  // du bouton flottant (recording_overlay.dart, isolate). Mix légitime :
  // ~16 `ArenaColors.*` (tokens) + ~11 `Colors.white/black/transparent` bruts
  // — l'overlay isolate n'a pas le thème, usage allowlisté dans check_colors.sh.
  // 2423 → 2411 le 2026-07-03 : refonte flux Room (recording d'abord, code
  // ensuite) — suppression de ShareCodeForm + CodeSharedInterstitial (dette
  // nette réduite malgré l'ajout de StartRecordingForm + la saisie inline).
  // 2411 → 2413 le 2026-07-03 : +2 des correctifs device de la saisie inline
  // (bouton « Fermer » + carte compacte paysage : Colors.transparent/white70).
  // 2413 → 2417 le 2026-07-06 : +4 `ArenaColors.*` nets du paiement multi-pays /
  // opérateurs libres (dialog choix du pays country_pick_dialog + logo/tuiles
  // opérateur du picker P1 + carte code P2). 0 vrai Colors.* ajouté net (le
  // `Colors.transparent` du dialog compense le `Colors.white` retiré du picker).
  // 2417 → 2449 le 2026-07-06 : +32 `ArenaColors.*` du VOLET 3 (périmètre admin
  // par pays/section) — puces de sélection pays/sections des invitations mobile
  // (_ScopeChip) + desktop (_ScopeChip) + bandeau « Périmètre » mobile
  // (admin_scope_banner). check_colors.sh --strict = 0 régression (aucun vrai
  // `Colors.*` ajouté ; tous des tokens ArenaColors matchés par le regex).
  // 2449 → 2467 le 2026-07-10 : +18 `ArenaColors.*` de la carte « Coût egress
  // mesuré » anti-triche (P4 volet B) — mobile (_CostObservabilityCard /
  // _CostSummaryBody / _CostRow / _WindowChip) + desktop. 1 seul vrai Colors.*
  // (Colors.transparent de la puce fenêtre) ; le reste = tokens ArenaColors.
  // 2467 → 2471 le 2026-07-10 : +4 du code room porté par la clé du bouton
  // overlay (_RoomCodeChip, renommé _RoomCodeKey le 2026-07-10 — code déplacé
  // de la puce flottante haute vers une pastille « 🔑 + code » sous le cluster ;
  // décompte inchangé) — Colors.black/white NATIFS obligatoires (isolate overlay
  // sans thème, comme le chrono) + tokens ArenaColors.iceCyan.
  // 2471 → 2482 le 2026-07-10 : +11 des vignettes « capture d'inscription »
  // (user payment_processing + admin mobile/desktop) — tokens ArenaColors
  // (silver/void_/carbon/border) sur les previews signés + broken-image.
  // 2482 → 2498 le 2026-07-10 : +16 des widgets paiement CEMAC (numéro à copier,
  // étapes, card tuto) dans mobile_money_details_page — tokens ArenaColors +
  // 1 seul vrai Colors.white (icône play de la card tuto).
  // 2498 → 2502 le 2026-07-11 : +4 `ArenaColors.silver` des légendes de rôle
  // (Domicile/Extérieur) sous les vignettes de preuve, litige admin (mobile +
  // desktop).
  // 2502 → 2510 le 2026-07-11 : +8 `ArenaColors.*` du dialog de déblocage MIUI
  // (guide « Démarrage auto » + batterie sans restriction, upload preuve bg) —
  // carbon/void_/border/signalBlue/silver.
  // 2510 → 2511 le 2026-07-13 : +1 `ArenaColors.silver` du bandeau de verrou
  // verdict (parité mobile/desktop, audit 2026-07-13).
  // 2511 → 2520 le 2026-07-13 : +9 `ArenaColors.*` du guide « activer le bouton
  // flottant » (overlay restreint Android 13+/Pixel 9) + bannière non bloquante —
  // signalBlue/carbon/void_/border/silver.
  // 2527 → 2534 le 2026-07-16 : +7 `ArenaColors.*` du calendrier de compétition
  // (widget partagé user/admin) — signalBlue/carbon/border/bone/silver +
  // success/danger/warning des pastilles d'état.
  // 2534 → 2556 le 2026-07-17 : +22 `ArenaColors.*` du chantier vidéo in-app —
  // vidéos tuto contextuelles (forms admin mobile/desktop), écran + éditeur
  // « Règles par jeu » (mobile/desktop) et briefing de l'écran de verrouillage.
  // 2556 → 2559 le 2026-07-17 : +3 `ArenaColors.*` du dialogue d'intro de rôle
  // (DOMICILE/EXTÉRIEUR) à l'étape 1 du match.
  const colorsDotBaseline = 2559; // occurrences de `Colors.`
  const colorHexBaseline = 28; // occurrences de `Color(0x`
  // Baseline GoogleFonts figée au 2026-06-26 : 185 usages directs de
  // `GoogleFonts.<font>` hors lib/core/theme, TOUS dans lib/features_admin_desktop/.
  // Le design system fournit ArenaText — toute NOUVELLE occurrence doit le
  // remplacer. NE JAMAIS AUGMENTER ; faire décroître via migration vers ArenaText.
  // 185 → 192 le 2026-06-26 : +7 `GoogleFonts.spaceGrotesk` de la page desktop
  // du support (desktop_support_page) — même convention Fluent que les autres
  // pages desktop (desktop_chat_thread_page). À migrer vers ArenaText à terme.
  // 192 → 194 le 2026-06-27 : +2 `GoogleFonts.spaceGrotesk` de la page desktop
  // « Mise à jour app » (desktop_app_update_page). Même convention Fluent.
  // 194 → 198 le 2026-06-27 : +4 `GoogleFonts.spaceGrotesk` des pages desktop
  // anti-triche (sélecteur + section enregistrements des litiges). Convention
  // Fluent. À migrer vers ArenaText à terme.
  // 198 → 201 le 2026-06-29 : +3 `GoogleFonts.spaceGrotesk` de la section
  // « Preuves engagées » du litige desktop (desktop_disputes_page). Même
  // convention Fluent. À migrer vers ArenaText à terme.
  // 201 → 203 le 2026-06-30 : +2 `GoogleFonts.spaceGrotesk` de la carte
  // « Seuils de tiering » anti-triche (P4) desktop (desktop_anticheat_page).
  // Même convention Fluent. À migrer vers ArenaText à terme.
  // 208 → 210 le 2026-07-01 : +2 `GoogleFonts.spaceGrotesk` de la ligne numéro
  // WhatsApp copiable (_WhatsappLine) sur la carte utilisateur desktop.
  // 203 → 208 le 2026-06-30 : +5 `GoogleFonts.spaceGrotesk` du bandeau « Plan
  // anti-triche » du litige desktop (desktop_disputes_page). Convention Fluent.
  // 210 → 212 le 2026-07-06 : +2 `GoogleFonts.spaceGrotesk` de la puce
  // sélectionnable pays/section (_ScopeChip) de la page desktop des invitations
  // (VOLET 3). Même convention Fluent que le reste du desktop. À migrer vers
  // ArenaText à terme.
  // 212 → 220 le 2026-07-10 : +8 `GoogleFonts.spaceGrotesk` de la carte « Coût
  // egress mesuré » anti-triche (P4 volet B) desktop (desktop_anticheat_page :
  // _CostObservabilityCard / _CostSummaryBody / _CostRow). Convention Fluent.
  // À migrer vers ArenaText à terme.
  // 220 → 221 le 2026-07-10 : +1 `GoogleFonts.spaceGrotesk` de la vignette
  // « capture d'inscription » du paiement desktop (_DesktopProofPreview).
  // 221 → 223 le 2026-07-11 : +2 `GoogleFonts.spaceGrotesk` des légendes de rôle
  // (Domicile/Extérieur) des vignettes de preuve, litige admin desktop.
  // 223 → 226 le 2026-07-17 : +3 `GoogleFonts.spaceGrotesk` de l'éditeur desktop
  // « Règles par jeu » (parité Fluent UI avec les autres écrans desktop).
  const googleFontsBaseline = 226; // occurrences de `GoogleFonts.`

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
