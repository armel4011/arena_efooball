// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'ARENA';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonStart => 'Commencer';

  @override
  String get commonSkip => 'Passer';

  @override
  String get commonLoading => 'Chargement…';

  @override
  String get commonError => 'Une erreur est survenue';

  @override
  String get onboardingSlide1Title => 'BIENVENUE\nSUR ARENA';

  @override
  String get onboardingSlide1Body =>
      'La plateforme africaine de tournois e-sport mobile sur eFootball, FIFA Mobile et EA SPORTS FC Mobile.';

  @override
  String get onboardingSlide2Title => 'BRACKETS\nAUTOMATIQUES';

  @override
  String get onboardingSlide2Body =>
      'Single élimination, phase de groupes, round robin — l’app gère le tirage et les avancées.';

  @override
  String get onboardingSlide3Title => 'CODE DE\nROOM PARTAGÉ';

  @override
  String get onboardingSlide3Body =>
      'Tu partages ton code eFootball, vous jouez le match, puis vous validez le score à deux.';

  @override
  String get onboardingSlide4Title => 'GAINS DU\nTOP 4';

  @override
  String get onboardingSlide4Body =>
      'Versement direct vers ton MTN MoMo, Orange Money ou Wave dès la fin du tournoi.';

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
