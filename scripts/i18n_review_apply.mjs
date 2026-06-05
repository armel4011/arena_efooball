// Applique les corrections high-confidence 'error' aux ARB en/ar (en validant
// l'integrite des placeholders ICU) et genere un rapport de relecture humaine.
// Usage : node scripts/i18n_review_apply.mjs <workflowOutputPath>
import { readFileSync, writeFileSync } from 'node:fs';

const data = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const findings = data.result.findings;
const all = JSON.parse(readFileSync('scripts/i18n_all.json', 'utf8'));
const frByKey = Object.fromEntries(all.map((r) => [r.key, r.fr]));
const curByKey = Object.fromEntries(all.map((r) => [r.key, { en: r.en, ar: r.ar }]));

const ARB = { en: 'lib/l10n/app_en.arb', ar: 'lib/l10n/app_ar.arb' };
const arb = Object.fromEntries(
  Object.entries(ARB).map(([k, p]) => [k, JSON.parse(readFileSync(p, 'utf8'))]),
);

const ph = (s) => [...String(s).matchAll(/\{([a-zA-Z][a-zA-Z0-9]*)\}/g)]
  .map((m) => m[1]).sort().join(',');

let applied = 0, skippedPh = 0, flagged = 0;
const report = [];

for (const f of findings) {
  const fr = frByKey[f.key] ?? '';
  const phOk = ph(f.suggestedFix) === ph(fr);
  const apply = f.severity === 'error' && f.confidence === 'high' && phOk &&
    f.suggestedFix.trim() !== '' && (f.lang === 'en' || f.lang === 'ar');
  if (f.severity === 'error' && f.confidence === 'high' && !phOk) skippedPh++;

  if (apply) {
    arb[f.lang][f.key] = f.suggestedFix;
    applied++;
  } else {
    flagged++;
  }
  report.push({
    key: f.key,
    lang: f.lang,
    severity: f.severity,
    confidence: f.confidence,
    fr,
    current: (curByKey[f.key] ?? {})[f.lang] ?? '',
    suggested: f.suggestedFix,
    issue: f.issue,
    status: apply ? 'APPLIQUE' : (phOk ? 'A_CONFIRMER' : 'PLACEHOLDER_KO'),
  });
}

for (const [loc, obj] of Object.entries(arb)) {
  writeFileSync(ARB[loc], JSON.stringify(obj, null, 2) + '\n');
}

// Rapport markdown trie : a confirmer d'abord.
const order = { A_CONFIRMER: 0, PLACEHOLDER_KO: 1, APPLIQUE: 2 };
report.sort((a, b) =>
  (order[a.status] - order[b.status]) || a.key.localeCompare(b.key));
let md = '# Relecture traductions en/ar — rapport\n\n';
md += `Corrections appliquees automatiquement (error + high-confidence + placeholders OK) : **${applied}**.\n`;
md += `A confirmer par un relecteur natif : **${flagged}**. Placeholders incompatibles (non appliques) : **${skippedPh}**.\n\n`;
md += '| statut | cle | langue | sev | conf | fr | actuel | suggere | souci |\n';
md += '|---|---|---|---|---|---|---|---|---|\n';
for (const r of report) {
  const esc = (s) => String(s).replaceAll('|', '\\|').replaceAll('\n', ' ');
  md += `| ${r.status} | ${r.key} | ${r.lang} | ${r.severity} | ${r.confidence} | ${esc(r.fr)} | ${esc(r.current)} | ${esc(r.suggested)} | ${esc(r.issue)} |\n`;
}
writeFileSync('docs/i18n-review-report.md', md);

console.log(JSON.stringify({
  totalFindings: findings.length, applied, flaggedForHuman: flagged, skippedPlaceholder: skippedPh,
}, null, 2));
