// Validation IA des findings de relecture : harmonise la marque (أرينا→ARENA,
// 22 vs 12 en faveur du latin) + applique les corrections OBJECTIVES (cohérence
// terminologique, code devise, grammaire MSA clairement fautive). Laisse les
// 5 findings vraiment subjectifs (style/accord de nombre) au relecteur natif.
import { readFileSync, writeFileSync } from 'node:fs';

const EN = 'lib/l10n/app_en.arb';
const AR = 'lib/l10n/app_ar.arb';
const en = JSON.parse(readFileSync(EN, 'utf8'));
const ar = JSON.parse(readFileSync(AR, 'utf8'));

// 1. Harmonisation de marque dans toutes les valeurs arabes.
let brand = 0;
for (const [k, v] of Object.entries(ar)) {
  if (typeof v === 'string' && v.includes('أرينا')) {
    ar[k] = v.replaceAll('أرينا', 'ARENA');
    brand++;
  }
}

// 2. Corrections objectives (cohérence / grammaire MSA sûre).
const FIX_AR = {
  activeCompetitionsEmpty: 'لا توجد منافسة نشطة لهذا الفلتر.',
  editProfileWhatsappHelper: 'تتم إضافة رمز الدولة {dialCode} تلقائيًا.',
  mobileMoneyCountryLabel: 'الدولة',
  onboardingSlide1Title: 'بطولات الرياضات الإلكترونية لعموم أفريقيا',
  onboardingSlide2Title: 'جداول الإقصاء، مواجهات حقيقية',
  payoutKycPendingGain: '💰 أرباح بقيمة {amount} XAF',
  splashStatXaf: 'XAF',
  settingsLoginMethodsSubtitle: 'Google / Apple — قريبًا',
  watchStreamWaitingBroadcaster: 'في انتظار الباث…',
  scoreEditMyPenLabel: 'ركلات ترجيحي',
  registerReferralCodeHelper:
      'رمز صديق في ARENA. يتيح لك الظهور ضمن قائمة إحالاته — اتركه فارغًا إذا لم يكن لديك واحد.',
  playerProfileReferralCountPlural: '{count} مدعوّين',
  regConfirmRanksRewardedPluralSuffix: ' مراكز تحصل على مكافأة',
  regConfirmRanksRewardedSingle: 'مركز واحد يحصل على مكافأة',
};
const FIX_EN = {
  authEmailHint: 'player@arena.app',
  friendChatSendFailed: 'Couldn\'t send: ',
};
let applied = 0;
for (const [k, v] of Object.entries(FIX_AR)) { ar[k] = v; applied++; }
for (const [k, v] of Object.entries(FIX_EN)) { en[k] = v; applied++; }

writeFileSync(AR, JSON.stringify(ar, null, 2) + '\n');
writeFileSync(EN, JSON.stringify(en, null, 2) + '\n');

// 3. Rapport régénéré : ne reste QUE le résidu subjectif pour un natif.
const remaining = [
  ['paymentPickerMobileMoneySection', 'ar', 'Garder « MOBILE MONEY » tel quel (marque) vs traduire — choix éditorial.'],
  ['payoutKycPendingGain', 'en', '« Earnings of {amount} XAF » vs « {amount} XAF in winnings » — style, pas une erreur.'],
  ['recordingErrorHeadline', 'ar', 'Ton du titre d\'erreur (تعذّر التسجيل vs التسجيل غير ممكن) — emphase, subjectif.'],
  ['referralFriendsRemaining', 'ar', 'Accord nombre/nom variable {count} en arabe — dépend de la valeur, jugement natif.'],
  ['compDetailRankingPlaceSuffix', 'ar', 'Suffixe « المركز » concaténé après un chiffre — limite structurelle (article AVANT le chiffre en arabe). Idéalement repenser en ICU select.'],
];
let md = '# Relecture traductions en/ar — rapport\n\n';
md += `Validé IA (objectif : cohérence, marque, code devise, grammaire MSA sûre) : **${applied} corrections + harmonisation marque sur ${brand} entrées**.\n`;
md += `Reste à trancher par un relecteur NATIF (subjectif / accord de nombre) : **${remaining.length}**.\n\n`;
md += '## Résidu pour relecteur natif\n\n';
md += '| clé | langue | point à trancher |\n|---|---|---|\n';
for (const [k, l, note] of remaining) md += `| ${k} | ${l} | ${note} |\n`;
writeFileSync('docs/i18n-review-report.md', md);

console.log(JSON.stringify({ brandHarmonized: brand, appliedFixes: applied, remainingForNative: remaining.length }, null, 2));
