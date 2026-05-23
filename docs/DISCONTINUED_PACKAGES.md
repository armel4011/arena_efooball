# Discontinued packages — Tracking (audit 2026-05-23)

`flutter pub outdated` signale **2 packages discontinued**, tous deux
**deps transitives** de `build_runner` (codegen Freezed / JsonSerializable) :

| Package | Version actuelle | Statut | Source |
|---|---|---|---|
| `build_resolvers` | 2.5.4 | ⚠️ discontinued | dart-lang/build (mono-repo) |
| `build_runner_core` | 9.1.2 | ⚠️ discontinued | dart-lang/build (mono-repo) |

## Diagnostic

Ces 2 packages ne sont **pas** dans nos `dependencies` directes. Ils
sont tirés indirectement par :
- `build_runner: ^2.4.13` → `build_runner_core` → `build_resolvers`

L'écosystème `dart-lang/build` est en cours de consolidation chez
Google : ces sous-packages fusionneront dans `build` / `build_runner`
dans une version future. Aucune action côté repo pour le moment —
on ne peut pas remplacer une dep transitive sans forker.

## Décision

**Statu quo** jusqu'à un bump majeur de `build_runner`. À surveiller :
- Annonce de Google sur le mono-repo `dart-lang/build`
- Sortie de `build_runner 3.x` (probable intégration)
- Compatibilité avec `analyzer 7.x` (notre contrainte actuelle)

## Autres limitations pubspec liées à la chaîne codegen

Voir commentaires dans `pubspec.yaml` :
- `custom_lint` / `riverpod_lint` désactivés (analyzer_plugin pin)
- `riverpod_generator` retiré (custom_lint_core incompatible analyzer 7.6)

**Aucun risque sécurité** (codegen ne tourne qu'en dev), **aucun
impact fonctionnel** (build CI vert).
