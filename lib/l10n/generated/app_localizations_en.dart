// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ARENA';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSave => 'Save';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonStart => 'Start';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get onboardingSlide1Title => 'WELCOME\nTO ARENA';

  @override
  String get onboardingSlide1Body =>
      'Africa\'s mobile e-sport tournament platform for eFootball, FIFA Mobile and EA SPORTS FC Mobile.';

  @override
  String get onboardingSlide2Title => 'AUTOMATIC\nBRACKETS';

  @override
  String get onboardingSlide2Body =>
      'Single elimination, group stage, round robin — the app handles seeding and progression.';

  @override
  String get onboardingSlide3Title => 'SHARED\nROOM CODE';

  @override
  String get onboardingSlide3Body =>
      'Share your eFootball room code, play the match, then both confirm the score.';

  @override
  String get onboardingSlide4Title => 'TOP 4\nPRIZES';

  @override
  String get onboardingSlide4Body =>
      'Direct payout to MTN MoMo, Orange Money or Wave as soon as the tournament ends.';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String currencyFormatPositive(String amount, String symbol) {
    return '$symbol$amount';
  }
}
