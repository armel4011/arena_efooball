# i18n — migration progressive (fr / en / ar)

> Décision produit (2026-06-05) : **traduire** l'app (fr/en/ar), pas rester fr-only.
> Le pipeline était déjà en place mais **0 écran ne consommait les traductions**
> (tout en français codé en dur). On migre **écran par écran**. Premier pilote :
> l'onboarding (`onboarding_page.dart`).

## Pipeline (déjà configuré, ne pas re-créer)
- `l10n.yaml` : arb-dir `lib/l10n`, template `app_fr.arb`, sortie
  `lib/l10n/generated/`, classe `AppLocalizations`, `nullable-getter: false`.
- `pubspec.yaml` : `flutter_localizations`, `intl`, `generate: true`.
- `main_user.dart` : `supportedLocales: SupportedLocale.allFlutterLocales`,
  `localizationsDelegates: AppLocalizations.localizationsDelegates`, `locale`
  piloté par le sélecteur de langue. **fr/en/ar** sont les locales cibles.

## Procédure pour migrer un écran (mécanique)
1. **Repérer** toutes les chaînes en dur de l'écran (titres, boutons, dialogues,
   snackbars, hints…).
2. **Ajouter les clés** dans `app_fr.arb` (= texte ACTUEL affiché, source de
   vérité), puis traduire la même clé dans `app_en.arb` et `app_ar.arb`.
   - Nommage : `screenfeatureElement` (camelCase), ex. `onboardingNext`,
     `paymentRefundConfirmTitle`. Réutiliser les `common*` quand pertinent.
   - Pluriels / variables → placeholders ICU (`{count}`, `{symbol}{amount}`).
3. **Régénérer** : `flutter gen-l10n` (lit `l10n.yaml`). Committer les fichiers
   `lib/l10n/generated/*.dart` mis à jour.
4. **Consommer** dans l'écran : `final l10n = AppLocalizations.of(context);`
   puis `l10n.maCle`. Importer
   `package:arena/l10n/generated/app_localizations.dart`.
   - Les `const` widgets contenant du texte doivent devenir non-const (le texte
     dépend du `context`). Sortir les listes statiques de chaînes en méthodes
     `_xFor(AppLocalizations l10n)` (cf. `OnboardingPage._slidesFor`).
5. `flutter analyze` → 0 issue, puis tester le switch de langue (RTL auto pour ar).

## Fait
- ✅ **onboarding** + **flux connexion** (pilotes manuels, PR #50/#51).
- ✅ **TOUT `features_user`** (~62 écrans) migré en masse via run multi-agents
  (extraction → fusion ARB centralisée → câblage) : **789 clés** fr/en/ar,
  **718 chaînes câblées**. Outil de fusion : `scripts/i18n_merge.mjs`.

## Fait (suite)
- ✅ **résidus statiques** : 56/58 câblés par refactor (threading `l10n`,
  `labelOf(l10n)`, defaults nullables). PR #53.
- ✅ **interpolations → ICU** : 69/69 converties en placeholders (`{count}`,
  `{error}`…) + câblage `l10n.key(arg)`. Outils : `scripts/icu_merge.mjs`.
  Note : gen-l10n `use-escaping:false` → apostrophes littérales (pas de `''`).

## Hors scope (décidé)
- **Admin** (`features_admin` + `features_admin_desktop`, ~68 écrans) : **ne sera
  PAS traduit** — outils internes staff, le français reste la langue de travail
  (décision produit 2026-06-05). Ne pas relancer d'extraction dessus.

## Fait (fin)
- ✅ **fichiers manqués par l'extraction** : `auth_failure_message.dart`
  (20 messages d'erreur d'auth — `l10n` optionnel pour que l'admin reste FR) +
  enums `MatchStep` / `PricingBucket` / `StatusBucket` / `TournamentFormat`
  (`labelOf(l10n)`) + empty-state home. `scripts/i18n_missed.mjs`.

## Restant
1. **Relecture humaine** des traductions auto en/ar (surtout arabe) avant prod —
   **seul vrai préalable** avant une publication multilingue.

➡️ **`features_user` est traduit à ~100 %** (statique + dynamique). Le chantier
i18n côté utilisateur est **clos** ; il ne reste que la relecture linguistique.
