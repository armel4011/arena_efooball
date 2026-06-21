# Site vitrine ARENA — source statique propre

Site **statique, sans build** (aucun npm/Next.js requis). Le HTML est la **source unique de vérité** : on édite le texte directement dedans, et on déploie les fichiers tels quels.

> Reconstruit le 2026-06-21 à partir du build Next.js exporté (le source Next d'origine ayant été perdu). Le rendu est identique à l'ancien site.

## Structure

```
index.html              ← page d'accueil (hero, jeux, vidéos, téléchargement)
conditions/index.html   ← /conditions
confidentialite/index.html ← /confidentialite
404.html
css/styles.css          ← styles compilés (Tailwind) + règles de reveal
js/site.js              ← reveal au scroll + lecture des vidéos (vanilla, sans framework)
fonts/                  ← polices .woff2 (référencées par styles.css en /fonts/…)
shots/                  ← captures d'écran de l'app
videos/                 ← vidéos d'installation + posters
downloads/              ← APK (NON versionnés ; viennent du build Flutter)
arena-icon.png, icon.png
```

Tous les chemins sont **absolus depuis la racine** (`/css/…`, `/fonts/…`, `/shots/…`) → à déployer à la **racine du domaine**.

## Modifier le contenu

Ouvre le `.html` voulu et édite le texte entre les balises. Pas de build, pas d'hydratation : ce que tu écris est ce qui s'affiche. Les classes (ex. `text-gradient-gold`, `uppercase`) sont du Tailwind compilé — ne pas y toucher sauf besoin de style.

- Slogan / hero : `index.html`, balise `<h1>`.
- Couleurs / espacements : `css/styles.css` (utilitaires Tailwind) ou les classes dans le HTML.
- Animations d'apparition : éléments marqués `data-reveal` (gérés par `js/site.js` + `css/styles.css`).

## Déployer (cPanel / FTP)

1. Uploade **tout le dossier** (sauf `downloads/` si trop lourd) à la racine web (`public_html/`).
2. Uploade séparément les 3 APK dans `public_html/downloads/`.

Ou via le zip : voir `../landing/upload-site.ps1` (uploade le zip HTML + les APK).

## Régénérer depuis un nouveau build (si jamais nécessaire)

Le source actuel a été produit par `../landing/build-clean-source.mjs` à partir de `../landing/out/`. À ne relancer que si un nouveau build Next.js exporté devait être reconverti — sinon, **édite directement ce dossier**.
