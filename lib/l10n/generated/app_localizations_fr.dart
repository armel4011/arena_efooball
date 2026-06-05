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
  String get onboardingSlide1Title => 'TOURNOIS E-SPORT PANAFRICAINS';

  @override
  String get onboardingSlide1Body =>
      'Bienvenue sur ARENA, la plateforme #1 de tournois eFootball, FIFA Mobile et FC Mobile en Afrique.';

  @override
  String get onboardingSlide2Title => 'DES BRACKETS, DE VRAIS DUELS';

  @override
  String get onboardingSlide2Body =>
      'Élimination directe ou phase de groupes : grimpe l\'arbre du tournoi et bats tous tes adversaires pour la récompense.';

  @override
  String get onboardingSlide3Title => 'CODE DE ROOM PARTAGÉ';

  @override
  String get onboardingSlide3Body =>
      'Tu partages ton code de room dans le jeu, vous vous affrontez, puis vous validez le score à deux dans ARENA.';

  @override
  String get onboardingSlide4Title => 'RÉCOMPENSES VERSÉES DIRECT';

  @override
  String get onboardingSlide4Body =>
      'Obtenez des récompenses même dans des compétitions à inscription gratuite et divertissez-vous.';

  @override
  String get onboardingNext => 'SUIVANT';

  @override
  String get onboardingStart => 'COMMENCER';

  @override
  String get onboardingSkip => 'Ignorer';

  @override
  String get onboardingExitTitle => 'Quitter l\'introduction ?';

  @override
  String get onboardingExitBody =>
      'Tu peux la revoir plus tard depuis Profil > Revoir l\'introduction.';

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
