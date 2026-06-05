// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'أرينا';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonConfirm => 'تأكيد';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonNext => 'التالي';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonStart => 'ابدأ';

  @override
  String get commonSkip => 'تخطّي';

  @override
  String get commonLoading => 'جارٍ التحميل…';

  @override
  String get commonError => 'حدث خطأ';

  @override
  String get onboardingSlide1Title => 'بطولات الرياضات الإلكترونية الأفريقية';

  @override
  String get onboardingSlide1Body =>
      'مرحبًا بك في أرينا، المنصة رقم 1 لبطولات eFootball وFIFA Mobile وFC Mobile في أفريقيا.';

  @override
  String get onboardingSlide2Title => 'أقواس إقصاء، مواجهات حقيقية';

  @override
  String get onboardingSlide2Body =>
      'إقصاء مباشر أو دور المجموعات: تسلّق شجرة البطولة واهزم كل خصومك للفوز بالجائزة.';

  @override
  String get onboardingSlide3Title => 'رمز غرفة مشترك';

  @override
  String get onboardingSlide3Body =>
      'شارك رمز غرفتك داخل اللعبة، تواجها، ثم أكّدا النتيجة معًا في أرينا.';

  @override
  String get onboardingSlide4Title => 'مكافآت تُدفع مباشرة';

  @override
  String get onboardingSlide4Body =>
      'احصل على مكافآت حتى في المسابقات المجانية واستمتع.';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingStart => 'ابدأ';

  @override
  String get onboardingSkip => 'تخطّي';

  @override
  String get onboardingExitTitle => 'الخروج من المقدمة؟';

  @override
  String get onboardingExitBody =>
      'يمكنك إعادة مشاهدتها لاحقًا من الملف الشخصي ← إعادة المقدمة.';

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authEmailHint => 'joueur@arena.app';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get authOr => 'أو';

  @override
  String get authContinueGoogle => 'المتابعة بحساب Google';

  @override
  String get authSignUp => 'إنشاء حساب';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'تابع رحلتك على أرينا.';

  @override
  String get loginSubmit => 'تسجيل الدخول';

  @override
  String get loginNoAccount => 'ليس لديك حساب؟ ';

  @override
  String get forgotPasswordTitle => 'نسيت كلمة المرور';

  @override
  String get forgotPasswordSubtitle =>
      'أدخل البريد الإلكتروني المرتبط بحسابك، وسنرسل إليك رمزًا من 6 أرقام لإعادة تعيين كلمة المرور.';

  @override
  String get forgotPasswordSubmit => 'إرسال الرمز';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String currencyFormatPositive(String amount, String symbol) {
    return '$amount $symbol';
  }
}
