# 🚀 ARENA — Kit Single-Session pour Claude Code

> **Pour reproduire les 54 écrans de la preview HTML en code Flutter avec fidélité maximale, sur du code Phase 9 existant.**

---

## 📦 Contenu du kit

| Fichier | Où le placer dans ton repo | Rôle |
|---|---|---|
| `arena_theme.dart` | `lib/core/theme/arena_theme.dart` | Tokens design (couleurs, polices, animations) |
| `arena_v2.html` | `docs/arena_v2.html` | Preview visuelle des 54 écrans |
| `ARENA_54_ECRANS.md` | `docs/ARENA_54_ECRANS.md` | Spec fonctionnelle de chaque écran |
| `screens_manifest.json` | `docs/screens_manifest.json` | Plan d'exécution en 4 vagues |
| `PROMPT_MASTER_v2.md` | _(à coller dans Claude Code)_ | Le prompt que tu donnes à Claude Code |
| `README_KIT.md` (ce fichier) | _(garde-le sous la main)_ | Vue d'ensemble |

---

## 🎬 Procédure en 5 étapes

### Étape 1 — Backup ton code Phase 9

```bash
cd ton-repo-arena
git status                                # doit être clean
git tag pre-arena-v2-rebuild
git push origin pre-arena-v2-rebuild
```

Si quelque chose tourne mal, tu reviens en arrière en 1 commande :
```bash
git reset --hard pre-arena-v2-rebuild
```

### Étape 2 — Place les 4 fichiers dans le repo

```bash
mkdir -p docs lib/core/theme
cp arena_theme.dart       lib/core/theme/
cp arena_v2.html          docs/
cp ARENA_54_ECRANS.md     docs/
cp screens_manifest.json  docs/
```

### Étape 3 — Mets à jour `pubspec.yaml`

Ajoute ces 2 dépendances si elles n'y sont pas :
```yaml
dependencies:
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0    # pour les animations pulse, fade, etc.
```

Puis :
```bash
flutter pub get
```

### Étape 4 — Lance Claude Code en mode Opus

```bash
cd ton-repo-arena
claude --model opus
```

> **Pourquoi Opus** : 54 écrans avec fidélité pixel-perfect demandent beaucoup d'analyse visuelle. Sonnet est plus rapide mais dérive plus vite sur ce type de tâche longue.

### Étape 5 — Colle `PROMPT_MASTER_v2.md` en entier dans Claude Code

Une fois Claude Code lancé, copie tout le contenu de `PROMPT_MASTER_v2.md` (tout ce qui est entre les triple backticks ```) et colle-le.

Claude Code va :
1. Confirmer qu'il a lu et compris
2. Lancer une **Phase 0 d'audit** de ton code existant
3. Te produire un rapport (écrans existants vs à créer)
4. Attendre ton GO avant de toucher quoi que ce soit
5. Procéder par vagues de ~14 écrans avec checkpoints git

---

## 🛡️ Les 4 vagues d'implémentation

| Vague | Écrans | Durée estimée | Contenu |
|---|---|---|---|
| **Phase 0-1** | _Foundations_ | ~2h | Audit + 17 widgets partagés + gallery dev |
| **Wave 1** | 14 (#1-#14) | ~2h30 | Onboarding + Auth + Core 1/2 |
| **Wave 2** | 14 (#15-#28) | ~3h | Core 2/2 + Bracket + Streaming + Profil |
| **Wave 3** | 12 (P1-P7, A1-A5) | ~2h30 | Paiements + Admin Auth |
| **Wave 4** | 14 (A6-A15, SA1-SA4) | ~3h30 | Admin Core + Ops + Super + Audit |
| **TOTAL** | **54 écrans** | **~13h** | À étaler sur 2-3 jours |

---

## 🚦 Comment Claude Code doit réagir aux situations

| Situation | Action attendue |
|---|---|
| Écran existant Phase 9 avec logique métier | Refacto UI uniquement, garder providers/repos |
| Couleur ambiguë | Consulter HTML d'abord, MD ensuite, demander si toujours ambigu |
| Composant absent du HTML | Demander avant d'inventer |
| Contexte à 50% | Annoncer + proposer `/compact` + sauvegarder progression |
| `flutter analyze` warnings | Stop, corriger immédiatement |
| Animation manquante | Ajouter et signaler explicitement |

Si jamais Claude Code dérive, le `PROMPT_MASTER_v2.md` contient une section "Si Claude Code dérive" avec 5 phrases prêtes à copier-coller pour le remettre en ligne.

---

## ⚡ Le scénario optimal — sur 3 jours

> Plus réaliste qu'une session marathon de 13h.

### Jour 1 (~5h) — Foundations + Wave 1
- 30 min : Phase 0 audit
- 90 min : Phase 1 widgets partagés
- 2h30 : Wave 1 (14 écrans)
- 30 min : checkpoint git + validation simulateur

À la fin du jour 1 : tu peux **lancer l'app et naviguer login → home → competitions → details**. Si ça marche, le reste suivra.

### Jour 2 (~6h) — Wave 2 + Wave 3
- 3h : Wave 2 (14 écrans)
- 2h30 : Wave 3 (12 écrans paiements + admin auth)
- 30 min : checkpoint + validation

À la fin du jour 2 : **toute l'app USER fonctionne, plus l'admin auth**. Tu peux livrer une beta interne.

### Jour 3 (~4h) — Wave 4 + audit final
- 3h30 : Wave 4 (14 écrans admin)
- 30 min : audit final visuel + git tag arena-v2-complete

---

## 🎯 Critères de succès

À la fin du processus, tu dois avoir :

- [ ] 54 écrans Flutter aux bons emplacements
- [ ] 17 widgets partagés réutilisables dans `lib/shared/widgets/`
- [ ] `flutter analyze` à 0 warnings
- [ ] Toutes les routes câblées dans `user_router.dart` + `admin_router.dart`
- [ ] La logique métier Phase 9 préservée
- [ ] Comparaison visuelle simulateur ↔ preview HTML : > 90% fidélité
- [ ] `screens_progress.json` à 54/54 done
- [ ] `git log` propre avec 5 commits (1 par phase/wave)

---

## ❓ FAQ

**Q : Je peux skipper Opus et utiliser Sonnet ?**
R : Oui mais tu vas devoir corriger plus de dérives. Compte +30% de temps total.

**Q : Si je veux faire 1 wave par jour au lieu de 2 ?**
R : Parfait aussi. Le `PROMPT_MASTER_v2.md` a des `/compact` entre vagues, donc Claude Code peut reprendre proprement après pause.

**Q : Mon code Phase 9 a une architecture différente (clean architecture, BLoC, etc.) ?**
R : Indique-le explicitement dans le prompt avant de coller le master :
> "Mon repo utilise BLoC pas Riverpod. Adapte les références "providers" en "blocs/cubits"."

**Q : Si Claude Code casse ma logique Phase 9 ?**
R : `git reset --hard pre-arena-v2-rebuild`. Tu reviens à zéro. Puis tu redémarres en insistant sur la règle R5.

**Q : Et la base Supabase, les Edge Functions, le schéma DB ?**
R : Hors scope de ce kit (qui couvre l'UI Flutter). Si tu veux que Claude Code génère/aligne aussi le backend, demande-lui en ouvrant une session séparée avec ARENA_MASTER_PROMPT.md.

---

## 🆘 En cas de problème

1. **Claude Code freeze ou ne répond plus** : Ctrl+C, relance, dis-lui "Reprends à la wave X écran Y selon screens_progress.json"

2. **Fidélité visuelle insuffisante** : à la fin, demande à Claude Code :
   > "Pour les 5 écrans les plus visibles (#9 Home, #13 MatchRoom, A6 AdminDashboard, A13 Payouts, P1 PaymentMethodPicker), génère un screenshot du simulateur et compare-le côte à côte avec arena_v2.html. Liste les écarts et corrige-les."

3. **Le repo devient incohérent** : reviens au tag `pre-arena-v2-rebuild` et redémarre proprement.

---

Bonne chance pour la mise en œuvre ! Tu as maintenant tout ce qu'il faut pour transformer la preview HTML en code Flutter de qualité production.
