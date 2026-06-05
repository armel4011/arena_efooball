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

## Restant
~85 écrans à migrer (l'onboarding est fait). Avancer par lots cohérents
(auth, profil, compétitions, paiements/gains, chat, admin…). Chaque écran suit
les 5 étapes ci-dessus — c'est mécanique, pas de décision.

## Fait
- ✅ **onboarding** (`onboarding_page.dart`) : 4 slides + CTA + dialogue de
  sortie, fr/en/ar.
