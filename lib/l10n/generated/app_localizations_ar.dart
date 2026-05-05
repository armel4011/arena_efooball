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
  String get onboardingSlide1Title => 'مرحبًا\nبك في أرينا';

  @override
  String get onboardingSlide1Body =>
      'منصة بطولات الرياضات الإلكترونية المتنقلة في أفريقيا لـ eFootball وFIFA Mobile وEA SPORTS FC Mobile.';

  @override
  String get onboardingSlide2Title => 'أقواس\nتلقائية';

  @override
  String get onboardingSlide2Body =>
      'إقصائي، دور المجموعات، دوري — التطبيق يتكفّل بالقرعة والتقدّم.';

  @override
  String get onboardingSlide3Title => 'رمز غرفة\nمشترك';

  @override
  String get onboardingSlide3Body =>
      'تشارك رمز غرفتك، تلعبان المباراة، ثم تؤكدان النتيجة معًا.';

  @override
  String get onboardingSlide4Title => 'جوائز\nالأربعة الأوائل';

  @override
  String get onboardingSlide4Body =>
      'تحويل مباشر إلى MTN MoMo أو Orange Money أو Wave فور انتهاء البطولة.';

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
