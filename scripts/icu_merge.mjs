// Fusionne les specs ICU (workflow phase 1) dans les ARB fr/en/ar avec
// metadata placeholders, et produit le manifeste de câblage.
// Usage : node scripts/icu_merge.mjs <phase1OutputPath>
import { readFileSync, writeFileSync } from 'node:fs';

const data = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const entries = data.result.entries;

const ARB = { fr: 'lib/l10n/app_fr.arb', en: 'lib/l10n/app_en.arb', ar: 'lib/l10n/app_ar.arb' };
const arb = Object.fromEntries(
  Object.entries(ARB).map(([k, p]) => [k, JSON.parse(readFileSync(p, 'utf8'))]),
);

const wiring = {}; // file -> [{key, originalFr, call}]
let added = 0, skippedExisting = 0, skippedBad = 0;
const seen = new Set();

for (const e of entries) {
  if (!e.key || !e.icuFr) { skippedBad++; continue; }
  if (e.key in arb.fr || seen.has(e.key)) { skippedExisting++; continue; }
  // Cohérence : tous les placeholders cités dans icuFr doivent etre déclarés.
  const used = [...e.icuFr.matchAll(/\{([a-zA-Z][a-zA-Z0-9]*)\}/g)].map((m) => m[1]);
  const ph = (e.placeholders && e.placeholders.length) ? e.placeholders : used;
  seen.add(e.key);

  // gen-l10n a use-escaping=false => apostrophes littérales. Les agents en ont
  // doublé certaines (échappement ICU) : on dédouble pour éviter l'affichage ''.
  const unesc = (s) => s.replaceAll("''", "'");
  arb.fr[e.key] = unesc(e.icuFr);
  arb.en[e.key] = unesc(e.icuEn || e.icuFr);
  arb.ar[e.key] = unesc(e.icuAr || e.icuFr);
  // Metadata placeholders (type Object = accepte tout, zéro mismatch).
  const meta = { placeholders: {} };
  for (const name of ph) meta.placeholders[name] = { type: 'Object' };
  arb.fr['@' + e.key] = meta;
  added++;

  (wiring[e.file] ??= []).push({ key: e.key, originalFr: e.originalFr, call: e.call });
}

for (const [loc, obj] of Object.entries(arb)) {
  writeFileSync(ARB[loc], JSON.stringify(obj, null, 2) + '\n');
}
writeFileSync('scripts/icu_wiring.json', JSON.stringify(wiring, null, 2));

console.log(JSON.stringify({
  totalEntries: entries.length, added, skippedExisting, skippedBad,
  wiringFiles: Object.keys(wiring).length,
}, null, 2));
