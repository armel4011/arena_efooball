// One-shot : ajoute les clés des fichiers manqués par l'extraction.
import { readFileSync, writeFileSync } from 'node:fs';
const K = [
  // [key, fr, en, ar]
  ['authErrInvalidCredentials', 'Email ou mot de passe incorrect.', 'Incorrect email or password.', 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'],
  ['authErrEmailAlreadyRegistered', 'Un compte existe déjà avec cet email.', 'An account already exists with this email.', 'يوجد حساب بالفعل بهذا البريد الإلكتروني.'],
  ['authErrWeakPassword', 'Mot de passe trop faible : 8 caractères minimum.', 'Password too weak: 8 characters minimum.', 'كلمة المرور ضعيفة جدًا: 8 أحرف كحد أدنى.'],
  ['authErrEmailNotConfirmed', 'Confirmez votre inscription via le lien reçu par email.', 'Confirm your registration via the link sent by email.', 'أكّد تسجيلك عبر الرابط المُرسل بالبريد الإلكتروني.'],
  ['authErrUserBanned', 'Ce compte est suspendu. Contactez le support.', 'This account is suspended. Contact support.', 'هذا الحساب موقوف. تواصل مع الدعم.'],
  ['authErrWrongApp', "Ce compte est administrateur. Utilisez l'application ARENA Admin.", 'This is an administrator account. Use the ARENA Admin app.', 'هذا حساب مسؤول. استخدم تطبيق ARENA Admin.'],
  ['authErrNetwork', 'Pas de connexion internet. Vérifiez votre réseau et réessayez.', 'No internet connection. Check your network and try again.', 'لا يوجد اتصال بالإنترنت. تحقق من شبكتك وحاول مرة أخرى.'],
  ['authErrRateLimited', 'Trop de tentatives. Réessayez dans quelques minutes.', 'Too many attempts. Try again in a few minutes.', 'محاولات كثيرة جدًا. حاول مرة أخرى بعد بضع دقائق.'],
  ['authErrInvalidInvitation', "Code d'invitation invalide, expiré ou déjà utilisé.", 'Invitation code invalid, expired or already used.', 'رمز الدعوة غير صالح أو منتهٍ أو مستخدم بالفعل.'],
  ['authErrInvalidTotp', 'Code à 6 chiffres incorrect.', 'Incorrect 6-digit code.', 'الرمز المكوّن من 6 أرقام غير صحيح.'],
  ['authErrTotpReplay', 'Ce code a déjà été utilisé. Attendez le suivant.', 'This code has already been used. Wait for the next one.', 'تم استخدام هذا الرمز بالفعل. انتظر الرمز التالي.'],
  ['authErrAdminLocked', 'Compte verrouillé après 3 tentatives. Réessayez dans 30 minutes.', 'Account locked after 3 attempts. Try again in 30 minutes.', 'تم قفل الحساب بعد 3 محاولات. حاول مرة أخرى بعد 30 دقيقة.'],
  ['authErrBackendUnavailable', 'Service momentanément indisponible. Réessayez plus tard.', 'Service temporarily unavailable. Try again later.', 'الخدمة غير متوفرة مؤقتًا. حاول مرة أخرى لاحقًا.'],
  ['authErrUsernameTaken', 'Ce pseudo est déjà utilisé. Choisissez-en un autre.', 'This username is already taken. Choose another one.', 'اسم المستخدم هذا مستخدم بالفعل. اختر اسمًا آخر.'],
  ['authErrSsoCancelled', 'Connexion annulée.', 'Sign-in cancelled.', 'تم إلغاء تسجيل الدخول.'],
  ['authErrSsoIdToken', 'Connexion impossible. Vérifiez votre réseau et réessayez.', 'Sign-in failed. Check your network and try again.', 'تعذّر تسجيل الدخول. تحقق من شبكتك وحاول مرة أخرى.'],
  ['authErrSsoConfig', 'Connexion indisponible pour le moment. Contactez le support.', 'Sign-in unavailable right now. Contact support.', 'تسجيل الدخول غير متاح حاليًا. تواصل مع الدعم.'],
  ['authErrInvalidResetCode', 'Code incorrect. Vérifiez votre email.', 'Incorrect code. Check your email.', 'رمز غير صحيح. تحقق من بريدك الإلكتروني.'],
  ['authErrExpiredResetCode', 'Code expiré. Demandez un nouveau code.', 'Code expired. Request a new code.', 'انتهت صلاحية الرمز. اطلب رمزًا جديدًا.'],
  ['authErrUnknown', 'Une erreur est survenue. Réessayez.', 'Something went wrong. Try again.', 'حدث خطأ ما. حاول مرة أخرى.'],
  ['matchStepCodeRoom', 'Code room', 'Room code', 'رمز الغرفة'],
  ['matchStepOpponentJoining', 'Adversaire rejoint', 'Opponent joining', 'الخصم ينضم'],
  ['matchStepInProgress', 'Match en cours', 'Match in progress', 'المباراة جارية'],
  ['matchStepResult', 'Résultat', 'Result', 'النتيجة'],
  ['activeCompetitionsEmpty', 'Aucune compétition active pour ce filtre.', 'No active competition for this filter.', 'لا توجد مسابقة نشطة لهذا الفلتر.'],
  ['filterAll', 'Toutes', 'All', 'الكل'],
  ['filterFree', 'Gratuites', 'Free', 'مجانية'],
  ['filterPaid', 'Payantes', 'Paid', 'مدفوعة'],
  ['filterUpcoming', 'À venir', 'Upcoming', 'قادمة'],
  ['filterOngoing', 'En cours', 'Ongoing', 'جارية'],
  ['filterCompleted', 'Terminés', 'Completed', 'منتهية'],
  ['compFormatSingleElim', 'Élimination directe', 'Single elimination', 'إقصاء مباشر'],
  ['compFormatGroupsKnockout', 'Poules + élimination', 'Groups + knockout', 'مجموعات + إقصاء'],
  ['compFormatRoundRobin', 'Round robin', 'Round robin', 'دوري'],
];
const ARB = { fr: 'lib/l10n/app_fr.arb', en: 'lib/l10n/app_en.arb', ar: 'lib/l10n/app_ar.arb' };
const arb = Object.fromEntries(Object.entries(ARB).map(([k, p]) => [k, JSON.parse(readFileSync(p, 'utf8'))]));
let added = 0, skip = 0;
for (const [key, fr, en, ar] of K) {
  if (key in arb.fr) { skip++; continue; }
  arb.fr[key] = fr; arb.en[key] = en; arb.ar[key] = ar; added++;
}
for (const [loc, obj] of Object.entries(arb)) writeFileSync(ARB[loc], JSON.stringify(obj, null, 2) + '\n');
console.log(JSON.stringify({ added, skip }));
