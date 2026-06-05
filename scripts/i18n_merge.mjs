// One-shot : fusionne les clés extraites (workflow) dans les ARB fr/en/ar +
// produit un manifeste de câblage. Usage : node scripts/i18n_merge.mjs <outputJsonPath>
import { readFileSync, writeFileSync } from 'node:fs';

const outPath = process.argv[2];
const data = JSON.parse(readFileSync(outPath, 'utf8'));
const files = data.result.files;

const ARB = {
  fr: 'lib/l10n/app_fr.arb',
  en: 'lib/l10n/app_en.arb',
  ar: 'lib/l10n/app_ar.arb',
};
const arb = Object.fromEntries(
  Object.entries(ARB).map(([k, p]) => [k, JSON.parse(readFileSync(p, 'utf8'))]),
);
const existingFr = arb.fr; // pour détecter collisions de clés existantes

function clean(s) {
  return s
    .replaceAll('&gt;', '>')
    .replaceAll('&lt;', '<')
    .replaceAll('&amp;', '&')
    .replaceAll('&#39;', "'")
    .replaceAll('&apos;', "'")
    .replaceAll('&quot;', '"')
    .replaceAll('&nbsp;', ' ');
}

const addFr = {}, addEn = {}, addAr = {};
const manifest = {}; // { filePath: [{key, fr}] }
let skippedInterp = 0, skippedEmpty = 0, renamed = 0, reusedExisting = 0, added = 0;

function isInterpolated(s) {
  return /\$\{?[a-zA-Z_]/.test(s); // $x ou ${...}
}

for (const f of files) {
  const list = [];
  for (const s of f.strings || []) {
    const fr = clean(s.fr), en = clean(s.en), ar = clean(s.ar);
    if (!fr.trim()) { skippedEmpty++; continue; }
    if (isInterpolated(fr)) { skippedInterp++; continue; } // ICU à faire plus tard

    let key = s.key;
    const taken = (k) => k in existingFr || k in addFr;
    const valueFor = (k) => (k in existingFr ? existingFr[k] : addFr[k]);

    if (taken(key)) {
      if (valueFor(key) === fr) {
        // même clé, même texte → réutilisation directe (clé partagée).
        if (key in existingFr) reusedExisting++;
        list.push({ key, fr });
        continue;
      }
      // collision de clé avec un AUTRE texte → on rend la clé unique.
      let n = 2, k2 = key + 'V' + n;
      while (taken(k2)) { n++; k2 = key + 'V' + n; }
      key = k2;
      renamed++;
    }
    addFr[key] = fr; addEn[key] = en; addAr[key] = ar;
    added++;
    list.push({ key, fr });
  }
  if (list.length) manifest[f.path] = list;
}

// Écrit les ARB : clés existantes + nouvelles (append).
for (const [loc, obj] of Object.entries(arb)) {
  const add = loc === 'fr' ? addFr : loc === 'en' ? addEn : addAr;
  for (const [k, v] of Object.entries(add)) obj[k] = v;
  writeFileSync(ARB[loc], JSON.stringify(obj, null, 2) + '\n');
}

writeFileSync('scripts/i18n_wiring_manifest.json', JSON.stringify(manifest, null, 2));

console.log(JSON.stringify({
  totalStrings: files.reduce((n, f) => n + (f.strings?.length || 0), 0),
  added, reusedExisting, renamedForCollision: renamed,
  skippedInterpolation: skippedInterp, skippedEmpty,
  filesWithWiring: Object.keys(manifest).length,
}, null, 2));
