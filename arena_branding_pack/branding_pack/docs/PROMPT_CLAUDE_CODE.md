# 🤖 ARENA — Prompt MASTER pour Claude Code (v2 amélioré)

> **À COPIER-COLLER tel quel dans Claude Code.** Aucune adaptation nécessaire.
> Compatible avec n'importe quel projet Flutter ARENA (avec ou sans flavors).

---

## ⚡ Avant de coller : 1 étape de prep

1. **Dézippe `arena_branding_pack.zip`** à la racine de ton projet Flutter ARENA
2. **Vérifie** que tu as bien le dossier `arena_branding_pack/` à côté de `pubspec.yaml`
3. **Lance** Claude Code dans le dossier du projet : `claude --model opus`
4. **Colle** le prompt ci-dessous

---

## 📋 Prompt MASTER (copier tout ce qui est entre les `═══`)

```
═══════════════════════════════════════════════════════════════════════
ARENA — INTÉGRATION BRANDING PACK
═══════════════════════════════════════════════════════════════════════

Tu vas intégrer le BRANDING PACK ARENA (icônes Vector Strike F2 + splash 
cinématique D) dans le projet Flutter ARENA.

═══════════════════════════════════════════════════════════════════════
🎯 OBJECTIF FINAL
═══════════════════════════════════════════════════════════════════════

À la fin de cette tâche, le projet doit avoir :
✓ Icônes USER (bleu) + ADMIN (rouge) générées pour iOS/Android
✓ Adaptive Icons Android 8+ (foreground + background séparés)
✓ Splash screen animé cinématique 5.3s (5 phases) au 1er lancement
✓ Splash court 1.5s aux lancements suivants (détecté via SharedPreferences)
✓ pubspec.yaml mis à jour SANS perte des configs existantes
✓ main.dart câblé avec le SplashPage en home

═══════════════════════════════════════════════════════════════════════
🔍 PHASE 0 — DÉCOUVERTE (commence ici)
═══════════════════════════════════════════════════════════════════════

Avant de toucher à quoi que ce soit, fais cette ANALYSE :

0.1. Localise le pack :
     - Cherche le dossier "arena_branding_pack" depuis la racine
     - Si pas trouvé à la racine, cherche dans ~/Downloads ou Desktop
     - Si pas trouvé du tout, STOP et demande-moi où il est

0.2. Analyse le projet :
     - Lis pubspec.yaml entier
     - Lis lib/main.dart entier
     - Identifie : nom du projet, version Flutter, dépendances présentes
     - Détecte s'il y a déjà des flavors USER/ADMIN configurés (build.gradle, 
       AndroidManifest, Xcode schemes)
     - Détecte le système de routing (Navigator 1.0, GoRouter, AutoRoute...)
     - Vérifie si flutter_launcher_icons ou flutter_native_splash sont déjà 
       installés/configurés

0.3. Inventaire des risques :
     - Quels fichiers vais-je modifier ?
     - Quels fichiers vais-je créer ?
     - Y a-t-il des conflits potentiels avec l'existant ?

0.4. RAPPORT À ME FAIRE après la phase 0 :
     - Structure du projet trouvée
     - Présence/absence des flavors
     - Système de routing utilisé
     - Configs existantes susceptibles d'être impactées
     - Plan d'exécution proposé pour les phases 1-10
     - Risques identifiés

⛔ STOP ICI après phase 0. Attends mon "GO" avant phase 1.

═══════════════════════════════════════════════════════════════════════
🛡️ PHASE 1 — SAUVEGARDE
═══════════════════════════════════════════════════════════════════════

1.1. git status (vérifier état)
1.2. Si modifications non commitées → propose commit "WIP avant branding"
1.3. git tag pre-branding-pack (point de retour)
1.4. git checkout -b feature/branding-pack
1.5. Confirmer avant de continuer

═══════════════════════════════════════════════════════════════════════
📁 PHASE 2 — STRUCTURE DOSSIERS
═══════════════════════════════════════════════════════════════════════

2.1. Créer si manquant (NE PAS écraser si existant) :
     - assets/
     - assets/icons/
     - assets/icons/adaptive/user/
     - assets/icons/adaptive/admin/
     - assets/splash/
     - lib/features/splash/

2.2. Vérifier les permissions (les dossiers doivent être writable)

═══════════════════════════════════════════════════════════════════════
📋 PHASE 3 — COPIE DES ASSETS
═══════════════════════════════════════════════════════════════════════

3.1. Copier depuis arena_branding_pack/flutter_project/ vers le projet :
     
     ICÔNES :
     - arena_branding_pack/flutter_project/assets/icons/*.png 
       → assets/icons/
     - arena_branding_pack/flutter_project/assets/icons/adaptive/user/*.png
       → assets/icons/adaptive/user/
     - arena_branding_pack/flutter_project/assets/icons/adaptive/admin/*.png
       → assets/icons/adaptive/admin/
     
     SPLASH :
     - arena_branding_pack/flutter_project/assets/splash/*.png
       → assets/splash/
     
     CODE DART :
     - arena_branding_pack/flutter_project/lib/features/splash/splash_screen.dart
       → lib/features/splash/
     - arena_branding_pack/flutter_project/lib/features/splash/splash_router.dart
       → lib/features/splash/

3.2. Vérifier que TOUS les fichiers sont bien à leur place :
     - 4 fichiers dans assets/icons/
     - 3 fichiers dans assets/icons/adaptive/user/
     - 3 fichiers dans assets/icons/adaptive/admin/
     - 4 fichiers dans assets/splash/
     - 2 fichiers dans lib/features/splash/

═══════════════════════════════════════════════════════════════════════
⚙️ PHASE 4 — MISE À JOUR pubspec.yaml
═══════════════════════════════════════════════════════════════════════

⚠️ RÈGLE IMPORTANTE : NE JAMAIS remplacer le pubspec.yaml entier.
Seulement AJOUTER des sections manquantes ou COMPLÉTER des sections existantes.

4.1. Lire le pubspec.yaml actuel ENTIÈREMENT

4.2. Dans `dependencies:` ajouter SEULEMENT ce qui manque :
     - flutter_riverpod: ^2.4.10
     - shared_preferences: ^2.2.2
     - google_fonts: ^6.2.1

4.3. Dans `dev_dependencies:` ajouter SEULEMENT ce qui manque :
     - flutter_launcher_icons: ^0.13.1
     - flutter_native_splash: ^2.4.1

4.4. AU NIVEAU RACINE du pubspec, ajouter la section `flutter_launcher_icons:` :
     
     flutter_launcher_icons:
       android: "ic_launcher"
       ios: true
       image_path: "assets/icons/arena_user_1024.png"
       adaptive_icon_background: "assets/icons/adaptive/user/ic_launcher_background.png"
       adaptive_icon_foreground: "assets/icons/adaptive/user/ic_launcher_foreground.png"
       adaptive_icon_monochrome: "assets/icons/adaptive/user/ic_launcher_monochrome.png"
       remove_alpha_ios: true
     
     ⚠️ Si déjà existante, FUSIONNER et demander confirmation pour conflits.

4.5. AU NIVEAU RACINE du pubspec, ajouter `flutter_native_splash:` :
     
     flutter_native_splash:
       color: "#4C7AFF"
       image: "assets/splash/splash_user.png"
       android_12:
         image: "assets/splash/splash_icon_user.png"
         color: "#0A0A0F"
         icon_background_color: "#4C7AFF"
       ios: true
       ios_content_mode: scaleAspectFill
       android: true
       android_gravity: fill
       fullscreen: true

4.6. Dans `flutter:` → `assets:`, ajouter (sans dupliquer) :
     - assets/icons/
     - assets/icons/adaptive/user/
     - assets/icons/adaptive/admin/
     - assets/splash/

═══════════════════════════════════════════════════════════════════════
🔀 PHASE 5 — FICHIERS ADMIN
═══════════════════════════════════════════════════════════════════════

5.1. Créer à la racine `flutter_launcher_icons-admin.yaml`
     (image_path: arena_admin_1024.png, adaptive admin/)

5.2. Créer à la racine `flutter_native_splash-admin.yaml`
     (color: #FF2D55, image: splash_admin.png)

═══════════════════════════════════════════════════════════════════════
🚀 PHASE 6 — GÉNÉRATION DES ASSETS NATIFS
═══════════════════════════════════════════════════════════════════════

6.1. flutter pub get
6.2. flutter pub run flutter_launcher_icons
6.3. flutter pub run flutter_launcher_icons -f flutter_launcher_icons-admin.yaml
     ⚠️ Si flavors détectés, placer manuellement les icônes ADMIN dans 
     android/app/src/admin/res/ (pas dans main/res/)
6.4. flutter pub run flutter_native_splash:create
6.5. flutter pub run flutter_native_splash:create --path=flutter_native_splash-admin.yaml
6.6. Vérifier l'arborescence finale (mipmap-*/, AppIcon.appiconset/)

═══════════════════════════════════════════════════════════════════════
🔌 PHASE 7 — CÂBLAGE main.dart
═══════════════════════════════════════════════════════════════════════

7.1. Lire main.dart COMPLÈTEMENT

7.2. Identifier patterns existants :
     - WidgetsFlutterBinding.ensureInitialized() présent ?
     - Initialisations async (Supabase, Firebase) ?
     - ConsumerWidget (Riverpod) ?
     - home: ou route initiale ?

7.3. Modifier main.dart :
     a) Ajouter imports :
        import 'package:flutter/services.dart';
        import 'package:flutter_native_splash/flutter_native_splash.dart';
        import 'features/splash/splash_router.dart';
     
     b) Dans main() :
        - Capturer widgetsBinding de WidgetsFlutterBinding.ensureInitialized()
        - APRÈS : FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
        - Garder initialisations existantes (Supabase, etc.)
        - APRÈS runApp() : FlutterNativeSplash.remove();
     
     c) Dans MaterialApp :
        - home: const SplashPage(isAdmin: false, nextRoute: '/login')
        - ⚠️ Adapter nextRoute selon routing (GoRouter → context.go, etc.)

7.4. PRÉSERVER les anciennes routes/écrans existants.

7.5. Si flavors avec entry points séparés (main_user.dart, main_admin.dart) :
     - main_user.dart → isAdmin: false
     - main_admin.dart → isAdmin: true

═══════════════════════════════════════════════════════════════════════
✅ PHASE 8 — VÉRIFICATION
═══════════════════════════════════════════════════════════════════════

8.1. flutter analyze (0 erreurs requises)
8.2. flutter clean
8.3. flutter pub get
8.4. flutter build apk --debug
8.5. (optionnel) flutter build ios --no-codesign
8.6. Lister fichiers générés (mipmap-xxxhdpi/, AppIcon.appiconset/)

═══════════════════════════════════════════════════════════════════════
📝 PHASE 9 — DOCUMENTATION
═══════════════════════════════════════════════════════════════════════

9.1. Créer docs/BRANDING.md avec tokens + commandes regen
9.2. git add . && git commit -m "feat(branding): icônes Vector Strike F2 + splash D"
9.3. NE PAS pusher avant validation manuelle

═══════════════════════════════════════════════════════════════════════
🎯 PHASE 10 — RAPPORT FINAL
═══════════════════════════════════════════════════════════════════════

Format :

📊 FICHIERS MODIFIÉS : [liste]
📁 FICHIERS CRÉÉS : [liste]
⚡ COMMANDES EXÉCUTÉES : [avec timing]
✅ TESTS DE COMPILATION : [résultat]
⚠️ POINTS D'ATTENTION : [warnings, choix faits]
📱 TESTS MANUELS À FAIRE : [checklist]
🔄 PROCHAINES ÉTAPES : [suggestions]

═══════════════════════════════════════════════════════════════════════
⚠️ RÈGLES DE COMPORTEMENT
═══════════════════════════════════════════════════════════════════════

DO :
✅ Lire chaque fichier avant modification
✅ Préserver configs existantes
✅ Demander confirmation pour actions destructives
✅ Reporter chaque erreur en détail
✅ Tester compilation entre étapes critiques
✅ Respecter tokens DESIGN_KIT (pas de couleurs inventées)
✅ Suivre l'ordre des phases (0 → 1 → ... → 10)

DON'T :
❌ NE PAS remplacer pubspec.yaml entier
❌ NE PAS écraser main.dart sans préserver l'existant
❌ NE PAS supprimer de fichiers sans demander
❌ NE PAS pusher en main sans validation
❌ NE PAS modifier raw_sources/ (archive)
❌ NE PAS sauter la phase 0 (découverte)
❌ NE PAS continuer si erreur bloque

═══════════════════════════════════════════════════════════════════════
🚦 PROTOCOLE D'EXÉCUTION
═══════════════════════════════════════════════════════════════════════

1. Lance PHASE 0 immédiatement
2. Reporte état du projet + plan
3. ATTENDS mon "GO" avant phase 1
4. Exécute phases 1-10 séquentiellement
5. Mini-status entre phases critiques (4, 6, 7)
6. Si erreur → STOP + reporter
7. Rapport final en phase 10

GO pour PHASE 0.
```

---

## 🎓 Pourquoi ce prompt v2 vaut mieux que v1

### Améliorations apportées

1. **Phase 0 de découverte** : Claude Code analyse le projet AVANT d'agir
2. **Gestion intelligente des conflits** : fusion plutôt qu'écrasement
3. **Détection automatique du routing** : adaptation à GoRouter / AutoRoute
4. **Gestion des flavors** : logique conditionnelle USER/ADMIN
5. **Rapport final structuré** : format scannable avec emojis
6. **Règles DO/DON'T explicites** : Claude Code sait ce qu'il ne doit JAMAIS faire
7. **Stops obligatoires** : phase 0 attente validation, erreurs stoppent

## 🚀 Utilisation en 3 étapes

```bash
# 1. Préparation
cd ton-projet-arena
unzip ~/Downloads/arena_branding_pack.zip

# 2. Lancement
claude --model opus

# 3. Copier-coller le bloc entre ═══ ci-dessus
```

Claude Code :
1. **PHASE 0** : Analyse + rapport (2 min)
2. **Attend "GO"** explicite
3. **PHASES 1-10** : Exécute (15 min)
4. **Rapport final** détaillé

## ⏱ Timing total : ~20 minutes

## 💡 Réponses aux erreurs courantes

### "flutter pub get fails"
→ "Reporte l'erreur exacte. Si conflit dépendance, propose résolution."

### "flutter_launcher_icons fails"
→ "Vérifie que image_path existe : `ls -la assets/icons/`"

### "main.dart broken"
→ "Reverte avec `git checkout lib/main.dart` puis ré-applique prudemment."

### "build apk fails"
→ "Reporte les 20 dernières lignes. PNG corrompue ? Recopie depuis raw_sources/."

### "Conflit pubspec, sections existent"
→ "Liste les différences. Propose fusion. Attends validation."

## 🎯 Prêt à lancer

Tu as :
- ✅ ZIP `arena_branding_pack.zip` (sources + version copier-coller)
- ✅ Prompt MASTER v2 amélioré
- ✅ Guides de dépannage

Quand prêt, dis "j'ai lancé Claude Code" et je t'aide en temps réel.
