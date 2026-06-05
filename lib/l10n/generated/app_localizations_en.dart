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
  String get onboardingSlide1Title => 'PAN-AFRICAN E-SPORT TOURNAMENTS';

  @override
  String get onboardingSlide1Body =>
      'Welcome to ARENA, the #1 platform for eFootball, FIFA Mobile and FC Mobile tournaments in Africa.';

  @override
  String get onboardingSlide2Title => 'BRACKETS, REAL DUELS';

  @override
  String get onboardingSlide2Body =>
      'Single elimination or group stage: climb the tournament tree and beat every opponent for the prize.';

  @override
  String get onboardingSlide3Title => 'SHARED ROOM CODE';

  @override
  String get onboardingSlide3Body =>
      'Share your in-game room code, face off, then both confirm the score in ARENA.';

  @override
  String get onboardingSlide4Title => 'REWARDS PAID DIRECTLY';

  @override
  String get onboardingSlide4Body =>
      'Earn rewards even in free-entry competitions and have fun.';

  @override
  String get onboardingNext => 'NEXT';

  @override
  String get onboardingStart => 'START';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingExitTitle => 'Exit the intro?';

  @override
  String get onboardingExitBody =>
      'You can replay it later from Profile > Replay intro.';

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
