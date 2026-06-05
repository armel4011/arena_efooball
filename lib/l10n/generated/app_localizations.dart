import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// App name shown in titles.
  ///
  /// In fr, this message translates to:
  /// **'ARENA'**
  String get appName;

  /// Generic continue CTA.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get commonContinue;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get commonConfirm;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @commonNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @commonStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get commonStart;

  /// No description provided for @commonSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get commonSkip;

  /// No description provided for @commonLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get commonError;

  /// Onboarding slide 1 title.
  ///
  /// In fr, this message translates to:
  /// **'TOURNOIS E-SPORT PANAFRICAINS'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Body.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur ARENA, la plateforme #1 de tournois eFootball, FIFA Mobile et FC Mobile en Afrique.'**
  String get onboardingSlide1Body;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In fr, this message translates to:
  /// **'DES BRACKETS, DE VRAIS DUELS'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Body.
  ///
  /// In fr, this message translates to:
  /// **'Élimination directe ou phase de groupes : grimpe l\'arbre du tournoi et bats tous tes adversaires pour la récompense.'**
  String get onboardingSlide2Body;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In fr, this message translates to:
  /// **'CODE DE ROOM PARTAGÉ'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Body.
  ///
  /// In fr, this message translates to:
  /// **'Tu partages ton code de room dans le jeu, vous vous affrontez, puis vous validez le score à deux dans ARENA.'**
  String get onboardingSlide3Body;

  /// No description provided for @onboardingSlide4Title.
  ///
  /// In fr, this message translates to:
  /// **'RÉCOMPENSES VERSÉES DIRECT'**
  String get onboardingSlide4Title;

  /// No description provided for @onboardingSlide4Body.
  ///
  /// In fr, this message translates to:
  /// **'Obtenez des récompenses même dans des compétitions à inscription gratuite et divertissez-vous.'**
  String get onboardingSlide4Body;

  /// No description provided for @onboardingNext.
  ///
  /// In fr, this message translates to:
  /// **'SUIVANT'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'COMMENCER'**
  String get onboardingStart;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get onboardingSkip;

  /// No description provided for @onboardingExitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quitter l\'introduction ?'**
  String get onboardingExitTitle;

  /// No description provided for @onboardingExitBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux la revoir plus tard depuis Profil > Revoir l\'introduction.'**
  String get onboardingExitBody;

  /// No description provided for @authEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'EMAIL'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'joueur@arena.app'**
  String get authEmailHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'MOT DE PASSE'**
  String get authPasswordLabel;

  /// No description provided for @authForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get authForgotPassword;

  /// No description provided for @authOr.
  ///
  /// In fr, this message translates to:
  /// **'OU'**
  String get authOr;

  /// No description provided for @authContinueGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get authContinueGoogle;

  /// No description provided for @authSignUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get authSignUp;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'CONNEXION'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Continue ton parcours sur ARENA.'**
  String get loginSubtitle;

  /// No description provided for @loginSubmit.
  ///
  /// In fr, this message translates to:
  /// **'SE CONNECTER'**
  String get loginSubmit;

  /// No description provided for @loginNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore inscrit ? '**
  String get loginNoAccount;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'MOT DE PASSE OUBLIÉ'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entre l\'adresse e-mail liée à ton compte, on t\'envoie un code à 6 chiffres pour réinitialiser ton mot de passe.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In fr, this message translates to:
  /// **'ENVOYER LE CODE'**
  String get forgotPasswordSubmit;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// How to compose a positive currency amount.
  ///
  /// In fr, this message translates to:
  /// **'{amount} {symbol}'**
  String currencyFormatPositive(String amount, String symbol);

  /// No description provided for @bannedMinLengthError.
  ///
  /// In fr, this message translates to:
  /// **'Détaillez votre requête (10 caractères minimum).'**
  String get bannedMinLengthError;

  /// No description provided for @bannedSendError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi. Vérifiez votre connexion et réessayez.'**
  String get bannedSendError;

  /// No description provided for @bannedAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte suspendu'**
  String get bannedAppBarTitle;

  /// No description provided for @bannedSignOut.
  ///
  /// In fr, this message translates to:
  /// **'SE DÉCONNECTER'**
  String get bannedSignOut;

  /// No description provided for @bannedArenaRequestTitle.
  ///
  /// In fr, this message translates to:
  /// **'📨 ARENA REQUÊTE'**
  String get bannedArenaRequestTitle;

  /// No description provided for @bannedArenaRequestIntro.
  ///
  /// In fr, this message translates to:
  /// **'Explique pourquoi tu penses que ton bannissement devrait être reconsidéré. L\'équipe Arena Requête analyse chaque demande sous 48 heures.'**
  String get bannedArenaRequestIntro;

  /// No description provided for @bannedMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Décris ton cas (10 caractères minimum)…'**
  String get bannedMessageHint;

  /// No description provided for @bannedSendingLabel.
  ///
  /// In fr, this message translates to:
  /// **'ENVOI…'**
  String get bannedSendingLabel;

  /// No description provided for @bannedSendRequestLabel.
  ///
  /// In fr, this message translates to:
  /// **'✉️ ENVOYER MA REQUÊTE'**
  String get bannedSendRequestLabel;

  /// No description provided for @bannedPermanentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte définitivement banni'**
  String get bannedPermanentTitle;

  /// No description provided for @bannedPermanentBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu as été reconnu coupable d\'un litige à 3 reprises. Conformément à la règle ARENA, ton compte est désactivé.'**
  String get bannedPermanentBody;

  /// No description provided for @bannedOverdueTitle.
  ///
  /// In fr, this message translates to:
  /// **'Analyse en retard (> 48h)'**
  String get bannedOverdueTitle;

  /// No description provided for @bannedPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Requête en cours d\'analyse'**
  String get bannedPendingTitle;

  /// No description provided for @bannedOverdueBody.
  ///
  /// In fr, this message translates to:
  /// **'Ta requête est ouverte depuis plus de 48 heures. L\'équipe Arena Requête est notifiée — merci pour ta patience.'**
  String get bannedOverdueBody;

  /// No description provided for @bannedPendingBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe Arena Requête a 48 heures pour analyser ta demande. Tu seras notifié dès qu\'une décision est prise.'**
  String get bannedPendingBody;

  /// No description provided for @bannedYourMessageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ton message'**
  String get bannedYourMessageLabel;

  /// No description provided for @bannedRejectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'❌ Requête précédente refusée'**
  String get bannedRejectedTitle;

  /// No description provided for @bannedReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get bannedReasonLabel;

  /// No description provided for @bannedRejectedBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux soumettre une nouvelle requête avec des éléments supplémentaires ci-dessous.'**
  String get bannedRejectedBody;

  /// No description provided for @bannedApprovedTitle.
  ///
  /// In fr, this message translates to:
  /// **'✅ Réintégration approuvée'**
  String get bannedApprovedTitle;

  /// No description provided for @bannedApprovedBody.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour sur ARENA ! Reconnecte-toi pour accéder à ton compte.'**
  String get bannedApprovedBody;

  /// No description provided for @cguCompleteProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'COMPLÈTE TON\nPROFIL'**
  String get cguCompleteProfileTitle;

  /// No description provided for @cguCompleteProfileSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelques infos manquantes avant de pouvoir jouer.'**
  String get cguCompleteProfileSubtitle;

  /// No description provided for @cguWhatsappHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 07 07 07 07 07'**
  String get cguWhatsappHint;

  /// No description provided for @cguWhatsappInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro WhatsApp invalide.'**
  String get cguWhatsappInvalid;

  /// No description provided for @cguReadTermsLink.
  ///
  /// In fr, this message translates to:
  /// **'Lire les Conditions Générales d\'Utilisation'**
  String get cguReadTermsLink;

  /// No description provided for @cguReadPrivacyLink.
  ///
  /// In fr, this message translates to:
  /// **'Lire la politique de confidentialité'**
  String get cguReadPrivacyLink;

  /// No description provided for @cguAcceptTermsConsent.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les CGU et la politique de confidentialité'**
  String get cguAcceptTermsConsent;

  /// No description provided for @cguMarketingConsent.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte de recevoir des informations sur les nouveaux tournois (optionnel)'**
  String get cguMarketingConsent;

  /// No description provided for @cguContinueButton.
  ///
  /// In fr, this message translates to:
  /// **'CONTINUER'**
  String get cguContinueButton;

  /// No description provided for @cguRefuseSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Refuser et se déconnecter'**
  String get cguRefuseSignOut;

  /// No description provided for @cguDocPlaceholderBody.
  ///
  /// In fr, this message translates to:
  /// **'La version complète sera affichée ici (PHASE 9 — AboutPage + WebView vers les docs hébergés).'**
  String get cguDocPlaceholderBody;

  /// No description provided for @cguDialogOk.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get cguDialogOk;

  /// No description provided for @cguCountryLabel.
  ///
  /// In fr, this message translates to:
  /// **'PAYS'**
  String get cguCountryLabel;

  /// No description provided for @linkAccountDefaultProvider.
  ///
  /// In fr, this message translates to:
  /// **'Google'**
  String get linkAccountDefaultProvider;

  /// No description provided for @linkAccountAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lier les comptes'**
  String get linkAccountAppBarTitle;

  /// No description provided for @linkAccountExistsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte déjà existant'**
  String get linkAccountExistsTitle;

  /// No description provided for @linkAccountExistingMethodsLabel.
  ///
  /// In fr, this message translates to:
  /// **'MÉTHODES EXISTANTES'**
  String get linkAccountExistingMethodsLabel;

  /// No description provided for @linkAccountEmailPasswordMethod.
  ///
  /// In fr, this message translates to:
  /// **'Email + mot de passe'**
  String get linkAccountEmailPasswordMethod;

  /// No description provided for @linkAccountChooseContinue.
  ///
  /// In fr, this message translates to:
  /// **'Choisis comment continuer ci-dessous.'**
  String get linkAccountChooseContinue;

  /// No description provided for @linkAccountLinkBothButton.
  ///
  /// In fr, this message translates to:
  /// **'🔗 LIER LES DEUX COMPTES'**
  String get linkAccountLinkBothButton;

  /// No description provided for @linkAccountPhaseSnack.
  ///
  /// In fr, this message translates to:
  /// **'Disponible en PHASE 2.3 (social login Google/Apple).'**
  String get linkAccountPhaseSnack;

  /// No description provided for @linkAccountLoginPasswordButton.
  ///
  /// In fr, this message translates to:
  /// **'ME CONNECTER AVEC MOT DE PASSE'**
  String get linkAccountLoginPasswordButton;

  /// No description provided for @linkAccountCancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get linkAccountCancelButton;

  /// No description provided for @registerEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Email requis.'**
  String get registerEmailRequired;

  /// No description provided for @registerEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Format email invalide.'**
  String get registerEmailInvalid;

  /// No description provided for @registerPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum.'**
  String get registerPasswordTooShort;

  /// No description provided for @registerPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get registerPasswordMismatch;

  /// No description provided for @registerAccountStepTitle.
  ///
  /// In fr, this message translates to:
  /// **'CRÉE\nTON COMPTE'**
  String get registerAccountStepTitle;

  /// No description provided for @registerAccountStepSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Email + mot de passe (8 caractères minimum).'**
  String get registerAccountStepSubtitle;

  /// No description provided for @registerGoogleSignUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire avec Google'**
  String get registerGoogleSignUp;

  /// No description provided for @registerEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'EMAIL'**
  String get registerEmailLabel;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'MOT DE PASSE'**
  String get registerPasswordLabel;

  /// No description provided for @registerPasswordConfirmLabel.
  ///
  /// In fr, this message translates to:
  /// **'CONFIRMER LE MOT DE PASSE'**
  String get registerPasswordConfirmLabel;

  /// No description provided for @registerAccountContinueButton.
  ///
  /// In fr, this message translates to:
  /// **'CONTINUER'**
  String get registerAccountContinueButton;

  /// No description provided for @registerProfileStepTitle.
  ///
  /// In fr, this message translates to:
  /// **'TON\nPROFIL'**
  String get registerProfileStepTitle;

  /// No description provided for @registerProfileStepSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo + pays + acceptation des CGU.'**
  String get registerProfileStepSubtitle;

  /// No description provided for @registerUsernameLabel.
  ///
  /// In fr, this message translates to:
  /// **'PSEUDO'**
  String get registerUsernameLabel;

  /// No description provided for @registerUsernameHint.
  ///
  /// In fr, this message translates to:
  /// **'3 à 20 caractères'**
  String get registerUsernameHint;

  /// No description provided for @registerWhatsappHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 07 07 07 07 07'**
  String get registerWhatsappHint;

  /// No description provided for @registerWhatsappInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro WhatsApp invalide.'**
  String get registerWhatsappInvalid;

  /// No description provided for @registerAvatarColorLabel.
  ///
  /// In fr, this message translates to:
  /// **'COULEUR D\'AVATAR'**
  String get registerAvatarColorLabel;

  /// No description provided for @registerReferralCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'CODE DE PARRAINAGE (OPTIONNEL)'**
  String get registerReferralCodeLabel;

  /// No description provided for @registerReferralCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. ARN-3F9A'**
  String get registerReferralCodeHint;

  /// No description provided for @registerReferralCodeHelper.
  ///
  /// In fr, this message translates to:
  /// **'Le code d\'un ami ARENA. Te permet d\'apparaître dans ses parrainages — laisser vide si tu n\'en as pas.'**
  String get registerReferralCodeHelper;

  /// No description provided for @registerCguConsent.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les Conditions Générales d\'Utilisation'**
  String get registerCguConsent;

  /// No description provided for @registerPrivacyConsent.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte la Politique de Confidentialité'**
  String get registerPrivacyConsent;

  /// No description provided for @registerMarketingConsent.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte de recevoir les communications marketing (optionnel)'**
  String get registerMarketingConsent;

  /// No description provided for @registerCreateAccountButton.
  ///
  /// In fr, this message translates to:
  /// **'CRÉER MON COMPTE'**
  String get registerCreateAccountButton;

  /// No description provided for @registerCountryLabel.
  ///
  /// In fr, this message translates to:
  /// **'PAYS'**
  String get registerCountryLabel;

  /// No description provided for @registerSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'COMPTE\nCRÉÉ'**
  String get registerSuccessTitle;

  /// No description provided for @registerSuccessSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur ARENA. Tu es prêt à rejoindre les tournois.'**
  String get registerSuccessSubtitle;

  /// No description provided for @registerSuccessContinueButton.
  ///
  /// In fr, this message translates to:
  /// **'CONTINUER'**
  String get registerSuccessContinueButton;

  /// No description provided for @registerOrDivider.
  ///
  /// In fr, this message translates to:
  /// **'OU'**
  String get registerOrDivider;

  /// No description provided for @resetCodeNewCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code envoyé.'**
  String get resetCodeNewCodeSent;

  /// No description provided for @resetCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'VÉRIFICATION'**
  String get resetCodeTitle;

  /// No description provided for @resetCodeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisis le code à 6 chiffres envoyé à'**
  String get resetCodeSubtitle;

  /// No description provided for @resetCodeFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'CODE'**
  String get resetCodeFieldLabel;

  /// No description provided for @resetCodeVerifyButton.
  ///
  /// In fr, this message translates to:
  /// **'VÉRIFIER'**
  String get resetCodeVerifyButton;

  /// No description provided for @resetCodeResending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours…'**
  String get resetCodeResending;

  /// No description provided for @resetCodeResendButton.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resetCodeResendButton;

  /// No description provided for @resetPwPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis'**
  String get resetPwPasswordRequired;

  /// No description provided for @resetPwMinChars.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 8 caractères'**
  String get resetPwMinChars;

  /// No description provided for @resetPwPasswordsDontMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get resetPwPasswordsDontMatch;

  /// No description provided for @resetPwTitle.
  ///
  /// In fr, this message translates to:
  /// **'NOUVEAU MOT DE PASSE'**
  String get resetPwTitle;

  /// No description provided for @resetPwSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un mot de passe solide. Il sera utilisé pour ta prochaine connexion.'**
  String get resetPwSubtitle;

  /// No description provided for @resetPwNewPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'NOUVEAU MOT DE PASSE'**
  String get resetPwNewPasswordLabel;

  /// No description provided for @resetPwNewPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 caractères'**
  String get resetPwNewPasswordHint;

  /// No description provided for @resetPwConfirmLabel.
  ///
  /// In fr, this message translates to:
  /// **'CONFIRMER'**
  String get resetPwConfirmLabel;

  /// No description provided for @resetPwConfirmHint.
  ///
  /// In fr, this message translates to:
  /// **'Retape ton mot de passe'**
  String get resetPwConfirmHint;

  /// No description provided for @resetPwUpdateButton.
  ///
  /// In fr, this message translates to:
  /// **'METTRE À JOUR'**
  String get resetPwUpdateButton;

  /// No description provided for @resetPwSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'MOT DE PASSE MIS À JOUR'**
  String get resetPwSuccessTitle;

  /// No description provided for @resetPwSuccessSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux maintenant te connecter avec ton nouveau mot de passe.'**
  String get resetPwSuccessSubtitle;

  /// No description provided for @resetPwLoginButton.
  ///
  /// In fr, this message translates to:
  /// **'SE CONNECTER'**
  String get resetPwLoginButton;

  /// No description provided for @splashTagline.
  ///
  /// In fr, this message translates to:
  /// **'e-sport panafricain'**
  String get splashTagline;

  /// No description provided for @splashLoginButton.
  ///
  /// In fr, this message translates to:
  /// **'SE CONNECTER'**
  String get splashLoginButton;

  /// No description provided for @splashCreateAccountButton.
  ///
  /// In fr, this message translates to:
  /// **'CRÉER UN COMPTE'**
  String get splashCreateAccountButton;

  /// No description provided for @splashVersionLabel.
  ///
  /// In fr, this message translates to:
  /// **'v1.0 — ARENA Cameroun'**
  String get splashVersionLabel;

  /// No description provided for @splashStatPlayers.
  ///
  /// In fr, this message translates to:
  /// **'joueurs'**
  String get splashStatPlayers;

  /// No description provided for @splashStatTournaments.
  ///
  /// In fr, this message translates to:
  /// **'tournois'**
  String get splashStatTournaments;

  /// No description provided for @splashStatXaf.
  ///
  /// In fr, this message translates to:
  /// **'XAF'**
  String get splashStatXaf;

  /// No description provided for @bracketEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bracket pas encore généré'**
  String get bracketEmptyTitle;

  /// No description provided for @bracketEmptyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Le bracket s\'affichera ici dès que l\'admin aura clôturé les inscriptions et lancé le tirage.'**
  String get bracketEmptyDescription;

  /// No description provided for @bracketZoomHint.
  ///
  /// In fr, this message translates to:
  /// **'↔ pince pour zoomer · glisse pour naviguer'**
  String get bracketZoomHint;

  /// No description provided for @groupStandingsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de classement'**
  String get groupStandingsEmptyTitle;

  /// No description provided for @groupStandingsEmptyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Le classement s\'affichera dès que les premières rencontres seront jouées.'**
  String get groupStandingsEmptyDescription;

  /// No description provided for @groupStandingsColPlayer.
  ///
  /// In fr, this message translates to:
  /// **'JOUEUR'**
  String get groupStandingsColPlayer;

  /// No description provided for @groupStandingsColPlayed.
  ///
  /// In fr, this message translates to:
  /// **'J'**
  String get groupStandingsColPlayed;

  /// No description provided for @groupStandingsColWins.
  ///
  /// In fr, this message translates to:
  /// **'V'**
  String get groupStandingsColWins;

  /// No description provided for @groupStandingsColDraws.
  ///
  /// In fr, this message translates to:
  /// **'N'**
  String get groupStandingsColDraws;

  /// No description provided for @groupStandingsColLosses.
  ///
  /// In fr, this message translates to:
  /// **'D'**
  String get groupStandingsColLosses;

  /// No description provided for @groupStandingsColGoalsFor.
  ///
  /// In fr, this message translates to:
  /// **'BP'**
  String get groupStandingsColGoalsFor;

  /// No description provided for @groupStandingsColGoalsAgainst.
  ///
  /// In fr, this message translates to:
  /// **'BC'**
  String get groupStandingsColGoalsAgainst;

  /// No description provided for @groupStandingsColDiff.
  ///
  /// In fr, this message translates to:
  /// **'Diff'**
  String get groupStandingsColDiff;

  /// No description provided for @groupStandingsColPoints.
  ///
  /// In fr, this message translates to:
  /// **'Pts'**
  String get groupStandingsColPoints;

  /// No description provided for @groupStandingsPlayerFallback.
  ///
  /// In fr, this message translates to:
  /// **'Joueur '**
  String get groupStandingsPlayerFallback;

  /// No description provided for @callPlaceCallFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer l\'appel.'**
  String get callPlaceCallFailed;

  /// No description provided for @callNoAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Pas de réponse.'**
  String get callNoAnswer;

  /// No description provided for @callDeclined.
  ///
  /// In fr, this message translates to:
  /// **'Appel refusé.'**
  String get callDeclined;

  /// No description provided for @callEnded.
  ///
  /// In fr, this message translates to:
  /// **'Appel terminé.'**
  String get callEnded;

  /// No description provided for @callStatusConnecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion en cours…'**
  String get callStatusConnecting;

  /// No description provided for @callStatusRinging.
  ///
  /// In fr, this message translates to:
  /// **'Sonnerie…'**
  String get callStatusRinging;

  /// No description provided for @callStatusConnected.
  ///
  /// In fr, this message translates to:
  /// **'En appel'**
  String get callStatusConnected;

  /// No description provided for @callStatusEnded.
  ///
  /// In fr, this message translates to:
  /// **'Appel terminé'**
  String get callStatusEnded;

  /// No description provided for @callStatusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'appel'**
  String get callStatusFailed;

  /// No description provided for @callControlUnmute.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver'**
  String get callControlUnmute;

  /// No description provided for @callControlMute.
  ///
  /// In fr, this message translates to:
  /// **'Couper'**
  String get callControlMute;

  /// No description provided for @callControlSpeaker.
  ///
  /// In fr, this message translates to:
  /// **'Haut-parleur'**
  String get callControlSpeaker;

  /// No description provided for @callControlEarpiece.
  ///
  /// In fr, this message translates to:
  /// **'Écouteur'**
  String get callControlEarpiece;

  /// No description provided for @callControlClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get callControlClose;

  /// No description provided for @chatOfflineQueued.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne — message envoyé à la reconnexion.'**
  String get chatOfflineQueued;

  /// No description provided for @chatSendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer : '**
  String get chatSendFailed;

  /// No description provided for @chatPickerUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Picker indisponible : '**
  String get chatPickerUnavailable;

  /// No description provided for @chatUploadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec upload : '**
  String get chatUploadFailed;

  /// No description provided for @chatAttachGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get chatAttachGallery;

  /// No description provided for @chatAttachCamera.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get chatAttachCamera;

  /// No description provided for @chatDeleteDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce message ?'**
  String get chatDeleteDialogTitle;

  /// No description provided for @chatDeleteDialogContent.
  ///
  /// In fr, this message translates to:
  /// **'Ce message sera marqué comme supprimé. L\'autre joueur verra \"Message supprimé\" à la place.'**
  String get chatDeleteDialogContent;

  /// No description provided for @chatDeleteDialogCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get chatDeleteDialogCancel;

  /// No description provided for @chatDeleteDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get chatDeleteDialogConfirm;

  /// No description provided for @chatGenericFailure.
  ///
  /// In fr, this message translates to:
  /// **'Échec : '**
  String get chatGenericFailure;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de message'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Sois le premier à écrire ici.'**
  String get chatEmptyDescription;

  /// No description provided for @chatAppBarUsernameFallback.
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get chatAppBarUsernameFallback;

  /// No description provided for @chatAppBarTyping.
  ///
  /// In fr, this message translates to:
  /// **'typing…'**
  String get chatAppBarTyping;

  /// No description provided for @chatAppBarOnline.
  ///
  /// In fr, this message translates to:
  /// **'en ligne'**
  String get chatAppBarOnline;

  /// No description provided for @chatAppBarOffline.
  ///
  /// In fr, this message translates to:
  /// **'hors ligne'**
  String get chatAppBarOffline;

  /// No description provided for @chatMessageDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Message supprimé'**
  String get chatMessageDeleted;

  /// No description provided for @chatMediaUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Media: '**
  String get chatMediaUnsupported;

  /// No description provided for @chatRoomCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié'**
  String get chatRoomCodeCopied;

  /// No description provided for @chatRoomCodeTapToCopy.
  ///
  /// In fr, this message translates to:
  /// **'tap pour copier'**
  String get chatRoomCodeTapToCopy;

  /// No description provided for @chatInputTooltipKeyboard.
  ///
  /// In fr, this message translates to:
  /// **'Clavier'**
  String get chatInputTooltipKeyboard;

  /// No description provided for @chatInputTooltipEmoji.
  ///
  /// In fr, this message translates to:
  /// **'Emoji'**
  String get chatInputTooltipEmoji;

  /// No description provided for @chatInputTooltipAttach.
  ///
  /// In fr, this message translates to:
  /// **'Joindre une image'**
  String get chatInputTooltipAttach;

  /// No description provided for @chatInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Message…'**
  String get chatInputHint;

  /// No description provided for @friendChatOfflineQueued.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne — message envoyé à la reconnexion.'**
  String get friendChatOfflineQueued;

  /// No description provided for @friendChatSendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible : '**
  String get friendChatSendFailed;

  /// No description provided for @friendChatPickerFailed.
  ///
  /// In fr, this message translates to:
  /// **'Picker : '**
  String get friendChatPickerFailed;

  /// No description provided for @friendChatGenericFailure.
  ///
  /// In fr, this message translates to:
  /// **'Échec : '**
  String get friendChatGenericFailure;

  /// No description provided for @friendChatAttachGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get friendChatAttachGallery;

  /// No description provided for @friendChatAttachCamera.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get friendChatAttachCamera;

  /// No description provided for @friendChatDeleteDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce message ?'**
  String get friendChatDeleteDialogTitle;

  /// No description provided for @friendChatDeleteDialogContent.
  ///
  /// In fr, this message translates to:
  /// **'Ton ami verra «Message supprimé» à la place.'**
  String get friendChatDeleteDialogContent;

  /// No description provided for @friendChatDeleteDialogCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get friendChatDeleteDialogCancel;

  /// No description provided for @friendChatDeleteDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get friendChatDeleteDialogConfirm;

  /// No description provided for @friendChatEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Démarre la conversation'**
  String get friendChatEmptyTitle;

  /// No description provided for @friendChatEmptyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Envoie un premier message à ton ami.'**
  String get friendChatEmptyDescription;

  /// No description provided for @friendChatUsernameFallback.
  ///
  /// In fr, this message translates to:
  /// **'Ami'**
  String get friendChatUsernameFallback;

  /// No description provided for @friendChatSubtitleFriend.
  ///
  /// In fr, this message translates to:
  /// **'Ami'**
  String get friendChatSubtitleFriend;

  /// No description provided for @inboxAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'MESSAGES'**
  String get inboxAppBarTitle;

  /// No description provided for @inboxComposeTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un joueur'**
  String get inboxComposeTooltip;

  /// No description provided for @inboxTabDirect.
  ///
  /// In fr, this message translates to:
  /// **'DIRECT'**
  String get inboxTabDirect;

  /// No description provided for @inboxTabTournaments.
  ///
  /// In fr, this message translates to:
  /// **'TOURNOIS'**
  String get inboxTabTournaments;

  /// No description provided for @inboxNoConversationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune conversation'**
  String get inboxNoConversationsTitle;

  /// No description provided for @inboxNoConversationsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Reconnecte-toi pour voir tes conversations.'**
  String get inboxNoConversationsDesc;

  /// No description provided for @inboxSectionFriends.
  ///
  /// In fr, this message translates to:
  /// **'AMIS'**
  String get inboxSectionFriends;

  /// No description provided for @inboxSectionMatches.
  ///
  /// In fr, this message translates to:
  /// **'MATCHS'**
  String get inboxSectionMatches;

  /// No description provided for @inboxEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Aucune conversation pour l\'instant.\nOuvre une discussion depuis la salle de match\nou depuis l\'onglet Amis.'**
  String get inboxEmptyHint;

  /// No description provided for @inboxDeleteDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette conversation ?'**
  String get inboxDeleteDialogTitle;

  /// No description provided for @inboxDeleteDialogContent.
  ///
  /// In fr, this message translates to:
  /// **'La conversation sera retirée de ton inbox. Tu peux la retrouver en rouvrant le chat plus tard.'**
  String get inboxDeleteDialogContent;

  /// No description provided for @inboxDeleteCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get inboxDeleteCancel;

  /// No description provided for @inboxDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get inboxDeleteConfirm;

  /// No description provided for @inboxDeleteFailure.
  ///
  /// In fr, this message translates to:
  /// **'Échec : '**
  String get inboxDeleteFailure;

  /// No description provided for @inboxOpponentWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get inboxOpponentWaiting;

  /// No description provided for @inboxMatchPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'adversaire'**
  String get inboxMatchPending;

  /// No description provided for @inboxMatchScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Match programmé'**
  String get inboxMatchScheduled;

  /// No description provided for @inboxMatchReady.
  ///
  /// In fr, this message translates to:
  /// **'Code de salon partagé'**
  String get inboxMatchReady;

  /// No description provided for @inboxMatchInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours — appuie pour discuter'**
  String get inboxMatchInProgress;

  /// No description provided for @inboxMatchScorePending.
  ///
  /// In fr, this message translates to:
  /// **'En attente du score'**
  String get inboxMatchScorePending;

  /// No description provided for @inboxMatchAwaitingValidation.
  ///
  /// In fr, this message translates to:
  /// **'Validation du score'**
  String get inboxMatchAwaitingValidation;

  /// No description provided for @inboxMatchDisputed.
  ///
  /// In fr, this message translates to:
  /// **'Score contesté — admin en cours'**
  String get inboxMatchDisputed;

  /// No description provided for @inboxMatchCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Match terminé'**
  String get inboxMatchCompleted;

  /// No description provided for @inboxMatchCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Match annulé'**
  String get inboxMatchCancelled;

  /// No description provided for @inboxMatchForfeited.
  ///
  /// In fr, this message translates to:
  /// **'Forfait'**
  String get inboxMatchForfeited;

  /// No description provided for @inboxTimeSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get inboxTimeSoon;

  /// No description provided for @inboxCompRegistrationOpen.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions ouvertes'**
  String get inboxCompRegistrationOpen;

  /// No description provided for @inboxCompRegistrationClosed.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions fermées'**
  String get inboxCompRegistrationClosed;

  /// No description provided for @inboxCompOngoing.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get inboxCompOngoing;

  /// No description provided for @inboxCompCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get inboxCompCompleted;

  /// No description provided for @inboxCompCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get inboxCompCancelled;

  /// No description provided for @inboxCompDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get inboxCompDraft;

  /// No description provided for @inboxNoActiveCompTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune compétition active'**
  String get inboxNoActiveCompTitle;

  /// No description provided for @inboxNoActiveCompDesc.
  ///
  /// In fr, this message translates to:
  /// **'Les fils de discussion liés à tes compétitions apparaîtront ici dès que tu rejoindras un tournoi.'**
  String get inboxNoActiveCompDesc;

  /// No description provided for @inboxWaitingTitle.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get inboxWaitingTitle;

  /// No description provided for @inboxWaitingDesc.
  ///
  /// In fr, this message translates to:
  /// **'Tu es inscrit mais les compétitions n\'ont pas encore été chargées.'**
  String get inboxWaitingDesc;

  /// No description provided for @inboxChatWithFriend.
  ///
  /// In fr, this message translates to:
  /// **'Discuter avec ton ami'**
  String get inboxChatWithFriend;

  /// No description provided for @inboxFriendDefaultName.
  ///
  /// In fr, this message translates to:
  /// **'Ami'**
  String get inboxFriendDefaultName;

  /// No description provided for @inboxArenaTeam.
  ///
  /// In fr, this message translates to:
  /// **'Équipe ARENA'**
  String get inboxArenaTeam;

  /// No description provided for @inboxArenaOfficialBadge.
  ///
  /// In fr, this message translates to:
  /// **'OFFICIEL'**
  String get inboxArenaOfficialBadge;

  /// No description provided for @inboxArenaPreviewDefault.
  ///
  /// In fr, this message translates to:
  /// **'Support, annonces et infos officielles'**
  String get inboxArenaPreviewDefault;

  /// No description provided for @inboxArenaPreviewImage.
  ///
  /// In fr, this message translates to:
  /// **'📷 Image'**
  String get inboxArenaPreviewImage;

  /// No description provided for @inboxTimeJustNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get inboxTimeJustNow;

  /// No description provided for @inboxErrorPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : '**
  String get inboxErrorPrefix;

  /// No description provided for @compDetailAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'COMPÉTITION'**
  String get compDetailAppBarTitle;

  /// No description provided for @compDetailNotFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compétition introuvable'**
  String get compDetailNotFoundTitle;

  /// No description provided for @compDetailNotFoundDesc.
  ///
  /// In fr, this message translates to:
  /// **'Elle a peut-être été supprimée par un admin.'**
  String get compDetailNotFoundDesc;

  /// No description provided for @compDetailStatusDraft.
  ///
  /// In fr, this message translates to:
  /// **'BROUILLON'**
  String get compDetailStatusDraft;

  /// No description provided for @compDetailStatusOpen.
  ///
  /// In fr, this message translates to:
  /// **'OUVERT'**
  String get compDetailStatusOpen;

  /// No description provided for @compDetailStatusFull.
  ///
  /// In fr, this message translates to:
  /// **'COMPLET'**
  String get compDetailStatusFull;

  /// No description provided for @compDetailStatusOngoing.
  ///
  /// In fr, this message translates to:
  /// **'EN COURS'**
  String get compDetailStatusOngoing;

  /// No description provided for @compDetailStatusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'TERMINÉ'**
  String get compDetailStatusCompleted;

  /// No description provided for @compDetailStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'ANNULÉ'**
  String get compDetailStatusCancelled;

  /// No description provided for @compDetailCtaRegisterFree.
  ///
  /// In fr, this message translates to:
  /// **'S\'INSCRIRE GRATUITEMENT'**
  String get compDetailCtaRegisterFree;

  /// No description provided for @compDetailCtaRegisterPaidPrefix.
  ///
  /// In fr, this message translates to:
  /// **'S\'INSCRIRE · '**
  String get compDetailCtaRegisterPaidPrefix;

  /// No description provided for @compDetailRegistrationsClosed.
  ///
  /// In fr, this message translates to:
  /// **'INSCRIPTIONS FERMÉES'**
  String get compDetailRegistrationsClosed;

  /// No description provided for @compDetailGatedLockNotice.
  ///
  /// In fr, this message translates to:
  /// **'🔒 Bracket, matches en direct et chat 1-on-1 sont réservés aux joueurs inscrits.'**
  String get compDetailGatedLockNotice;

  /// No description provided for @compDetailPrizeFree.
  ///
  /// In fr, this message translates to:
  /// **'GRATUIT'**
  String get compDetailPrizeFree;

  /// No description provided for @compDetailPrizeFreeLabel.
  ///
  /// In fr, this message translates to:
  /// **'INSCRIPTION LIBRE'**
  String get compDetailPrizeFreeLabel;

  /// No description provided for @compDetailPrizeToWinLabel.
  ///
  /// In fr, this message translates to:
  /// **'À GAGNER'**
  String get compDetailPrizeToWinLabel;

  /// No description provided for @compDetailTabInfos.
  ///
  /// In fr, this message translates to:
  /// **'INFOS'**
  String get compDetailTabInfos;

  /// No description provided for @compDetailTabParticipants.
  ///
  /// In fr, this message translates to:
  /// **'PARTICIP.'**
  String get compDetailTabParticipants;

  /// No description provided for @compDetailTabRanking.
  ///
  /// In fr, this message translates to:
  /// **'CLASSEMENT'**
  String get compDetailTabRanking;

  /// No description provided for @compDetailParticipantsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Liste des participants'**
  String get compDetailParticipantsTitle;

  /// No description provided for @compDetailParticipantsDesc.
  ///
  /// In fr, this message translates to:
  /// **'La liste des inscrits avec avatars et stats arrivera ici. Source : table `registrations`.'**
  String get compDetailParticipantsDesc;

  /// No description provided for @compDetailInfoPrizeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Récompense'**
  String get compDetailInfoPrizeLabel;

  /// No description provided for @compDetailInfoPrizeNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get compDetailInfoPrizeNone;

  /// No description provided for @compDetailInfoFeeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Frais d\'inscription'**
  String get compDetailInfoFeeLabel;

  /// No description provided for @compDetailInfoFeeFree.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get compDetailInfoFeeFree;

  /// No description provided for @compDetailInfoFormatLabel.
  ///
  /// In fr, this message translates to:
  /// **'Format'**
  String get compDetailInfoFormatLabel;

  /// No description provided for @compDetailInfoStartLabel.
  ///
  /// In fr, this message translates to:
  /// **'Démarrage'**
  String get compDetailInfoStartLabel;

  /// No description provided for @compDetailInfoCapacityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Capacité'**
  String get compDetailInfoCapacityLabel;

  /// No description provided for @compDetailInfoCapacitySuffix.
  ///
  /// In fr, this message translates to:
  /// **' joueurs'**
  String get compDetailInfoCapacitySuffix;

  /// No description provided for @compDetailDescriptionHeader.
  ///
  /// In fr, this message translates to:
  /// **'📝 DESCRIPTION'**
  String get compDetailDescriptionHeader;

  /// No description provided for @compDetailRankingNoParticipantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun participant'**
  String get compDetailRankingNoParticipantTitle;

  /// No description provided for @compDetailRankingNoParticipantDesc.
  ///
  /// In fr, this message translates to:
  /// **'Personne n\'est encore inscrit à cette compétition.'**
  String get compDetailRankingNoParticipantDesc;

  /// No description provided for @compDetailRankingNotPublishedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Classement pas encore publié'**
  String get compDetailRankingNotPublishedTitle;

  /// No description provided for @compDetailRankingNotPublishedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Les organisateurs publieront le classement final une fois la compétition terminée.'**
  String get compDetailRankingNotPublishedDesc;

  /// No description provided for @compDetailRankingUnranked.
  ///
  /// In fr, this message translates to:
  /// **'Non classé'**
  String get compDetailRankingUnranked;

  /// No description provided for @compDetailRankingPlaceSuffix.
  ///
  /// In fr, this message translates to:
  /// **' place'**
  String get compDetailRankingPlaceSuffix;

  /// No description provided for @compDetailFormatSingleElim.
  ///
  /// In fr, this message translates to:
  /// **'Élimination directe'**
  String get compDetailFormatSingleElim;

  /// No description provided for @compDetailFormatGroupsKnockout.
  ///
  /// In fr, this message translates to:
  /// **'Poules + élimination'**
  String get compDetailFormatGroupsKnockout;

  /// No description provided for @compDetailFormatRoundRobin.
  ///
  /// In fr, this message translates to:
  /// **'Round robin'**
  String get compDetailFormatRoundRobin;

  /// No description provided for @compDetailTabBracket.
  ///
  /// In fr, this message translates to:
  /// **'BRACKET'**
  String get compDetailTabBracket;

  /// No description provided for @compDetailTabGroups.
  ///
  /// In fr, this message translates to:
  /// **'POULES'**
  String get compDetailTabGroups;

  /// No description provided for @compListReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get compListReset;

  /// No description provided for @compListEmptyTitleAll.
  ///
  /// In fr, this message translates to:
  /// **'Aucune compétition'**
  String get compListEmptyTitleAll;

  /// No description provided for @compListEmptyTitleGamePrefix.
  ///
  /// In fr, this message translates to:
  /// **'Aucune compétition sur '**
  String get compListEmptyTitleGamePrefix;

  /// No description provided for @compListEmptyDesc.
  ///
  /// In fr, this message translates to:
  /// **'De nouveaux tournois sont publiés chaque semaine. Reviens bientôt !'**
  String get compListEmptyDesc;

  /// No description provided for @compListFilterGame.
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get compListFilterGame;

  /// No description provided for @compListFilterStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get compListFilterStatus;

  /// No description provided for @compListFilterPricing.
  ///
  /// In fr, this message translates to:
  /// **'Tarif'**
  String get compListFilterPricing;

  /// No description provided for @compListFormatSingleElim.
  ///
  /// In fr, this message translates to:
  /// **'Élimination directe'**
  String get compListFormatSingleElim;

  /// No description provided for @compListFormatGroupsKnockout.
  ///
  /// In fr, this message translates to:
  /// **'Poules + élimination'**
  String get compListFormatGroupsKnockout;

  /// No description provided for @compListFormatRoundRobin.
  ///
  /// In fr, this message translates to:
  /// **'Round robin'**
  String get compListFormatRoundRobin;

  /// No description provided for @regConfirmAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'CHECKOUT'**
  String get regConfirmAppBarTitle;

  /// No description provided for @regConfirmPrizeDistribution.
  ///
  /// In fr, this message translates to:
  /// **'RÉPARTITION DES GAINS'**
  String get regConfirmPrizeDistribution;

  /// No description provided for @regConfirmDownloadGame.
  ///
  /// In fr, this message translates to:
  /// **'TÉLÉCHARGER LE JEU'**
  String get regConfirmDownloadGame;

  /// No description provided for @regConfirmCtaReferralsInsufficient.
  ///
  /// In fr, this message translates to:
  /// **'👥 PARRAINAGES INSUFFISANTS'**
  String get regConfirmCtaReferralsInsufficient;

  /// No description provided for @regConfirmCtaRegisterFree.
  ///
  /// In fr, this message translates to:
  /// **'M\'INSCRIRE GRATUITEMENT'**
  String get regConfirmCtaRegisterFree;

  /// No description provided for @regConfirmCtaProceedPaymentPrefix.
  ///
  /// In fr, this message translates to:
  /// **'PROCÉDER AU PAIEMENT · '**
  String get regConfirmCtaProceedPaymentPrefix;

  /// No description provided for @regConfirmCtaXafSuffix.
  ///
  /// In fr, this message translates to:
  /// **' XAF'**
  String get regConfirmCtaXafSuffix;

  /// No description provided for @regConfirmCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get regConfirmCancel;

  /// No description provided for @regConfirmNoSession.
  ///
  /// In fr, this message translates to:
  /// **'Aucune session — inscription impossible.'**
  String get regConfirmNoSession;

  /// No description provided for @regConfirmOfflineQueued.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne — inscription enregistrée, confirmée à la reconnexion.'**
  String get regConfirmOfflineQueued;

  /// No description provided for @regConfirmConfirmedPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Inscription confirmée à '**
  String get regConfirmConfirmedPrefix;

  /// No description provided for @regConfirmErrorPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : '**
  String get regConfirmErrorPrefix;

  /// No description provided for @regConfirmDisplayTitleStart.
  ///
  /// In fr, this message translates to:
  /// **'Confirme '**
  String get regConfirmDisplayTitleStart;

  /// No description provided for @regConfirmDisplayTitleAccent.
  ///
  /// In fr, this message translates to:
  /// **'ton inscription.'**
  String get regConfirmDisplayTitleAccent;

  /// No description provided for @regConfirmPillFree.
  ///
  /// In fr, this message translates to:
  /// **'GRATUIT'**
  String get regConfirmPillFree;

  /// No description provided for @regConfirmPillPaid.
  ///
  /// In fr, this message translates to:
  /// **'PAYANTE'**
  String get regConfirmPillPaid;

  /// No description provided for @regConfirmBreakdownFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais d\'inscription'**
  String get regConfirmBreakdownFee;

  /// No description provided for @regConfirmBreakdownService.
  ///
  /// In fr, this message translates to:
  /// **'Frais de service'**
  String get regConfirmBreakdownService;

  /// No description provided for @regConfirmBreakdownServiceIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Inclus'**
  String get regConfirmBreakdownServiceIncluded;

  /// No description provided for @regConfirmBreakdownTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total à payer'**
  String get regConfirmBreakdownTotal;

  /// No description provided for @regConfirmRanksRewardedSingle.
  ///
  /// In fr, this message translates to:
  /// **'1 rang récompensé'**
  String get regConfirmRanksRewardedSingle;

  /// No description provided for @regConfirmRanksRewardedPluralSuffix.
  ///
  /// In fr, this message translates to:
  /// **' rangs récompensés'**
  String get regConfirmRanksRewardedPluralSuffix;

  /// No description provided for @regConfirmAckLabel.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les règles du tournoi et le règlement intérieur.'**
  String get regConfirmAckLabel;

  /// No description provided for @regConfirmStoreLinkError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le lien.'**
  String get regConfirmStoreLinkError;

  /// No description provided for @regConfirmPlayStore.
  ///
  /// In fr, this message translates to:
  /// **'Play Store'**
  String get regConfirmPlayStore;

  /// No description provided for @regConfirmAppStore.
  ///
  /// In fr, this message translates to:
  /// **'App Store'**
  String get regConfirmAppStore;

  /// No description provided for @referralCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Parrainage requis'**
  String get referralCardTitle;

  /// No description provided for @referralQuotaReached.
  ///
  /// In fr, this message translates to:
  /// **'✓ Quota atteint — tu peux t\'inscrire !'**
  String get referralQuotaReached;

  /// No description provided for @referralShareSubject.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins-moi sur ARENA'**
  String get referralShareSubject;

  /// No description provided for @referralYourCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'TON CODE'**
  String get referralYourCodeLabel;

  /// No description provided for @referralCopyButton.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get referralCopyButton;

  /// No description provided for @referralShareButton.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get referralShareButton;

  /// No description provided for @homeSectionNextMatch.
  ///
  /// In fr, this message translates to:
  /// **'⚡ PROCHAIN MATCH'**
  String get homeSectionNextMatch;

  /// No description provided for @homeSectionLive.
  ///
  /// In fr, this message translates to:
  /// **'EN DIRECT'**
  String get homeSectionLive;

  /// No description provided for @homeSectionActiveTournaments.
  ///
  /// In fr, this message translates to:
  /// **'★ TOURNOIS ACTIFS'**
  String get homeSectionActiveTournaments;

  /// No description provided for @homeSectionYourStats.
  ///
  /// In fr, this message translates to:
  /// **'📊 TES STATS'**
  String get homeSectionYourStats;

  /// No description provided for @homeViewAllLink.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get homeViewAllLink;

  /// No description provided for @mainLayoutExitConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Appuie encore pour quitter ARENA'**
  String get mainLayoutExitConfirm;

  /// No description provided for @mainLayoutTitleHome.
  ///
  /// In fr, this message translates to:
  /// **'ACCUEIL'**
  String get mainLayoutTitleHome;

  /// No description provided for @mainLayoutTitleCompetitions.
  ///
  /// In fr, this message translates to:
  /// **'COMPÉTITIONS'**
  String get mainLayoutTitleCompetitions;

  /// No description provided for @mainLayoutTitleMessages.
  ///
  /// In fr, this message translates to:
  /// **'MESSAGES'**
  String get mainLayoutTitleMessages;

  /// No description provided for @mainLayoutTitleProfile.
  ///
  /// In fr, this message translates to:
  /// **'PROFIL'**
  String get mainLayoutTitleProfile;

  /// No description provided for @mainLayoutNavHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get mainLayoutNavHome;

  /// No description provided for @mainLayoutNavCompetitions.
  ///
  /// In fr, this message translates to:
  /// **'Compétitions'**
  String get mainLayoutNavCompetitions;

  /// No description provided for @mainLayoutNavChat.
  ///
  /// In fr, this message translates to:
  /// **'Chat'**
  String get mainLayoutNavChat;

  /// No description provided for @mainLayoutNavProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get mainLayoutNavProfile;

  /// No description provided for @homeHeaderDefaultUsername.
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get homeHeaderDefaultUsername;

  /// No description provided for @homeHeaderTierBronze.
  ///
  /// In fr, this message translates to:
  /// **'🥉 BRONZE'**
  String get homeHeaderTierBronze;

  /// No description provided for @homeHeaderSearchTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un joueur'**
  String get homeHeaderSearchTooltip;

  /// No description provided for @liveStreamsErrorPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : '**
  String get liveStreamsErrorPrefix;

  /// No description provided for @liveStreamsBadgeLive.
  ///
  /// In fr, this message translates to:
  /// **'LIVE'**
  String get liveStreamsBadgeLive;

  /// No description provided for @liveStreamsTapToWatch.
  ///
  /// In fr, this message translates to:
  /// **'Tape pour regarder en direct'**
  String get liveStreamsTapToWatch;

  /// No description provided for @liveStreamsEmptyState.
  ///
  /// In fr, this message translates to:
  /// **'Aucun live en cours'**
  String get liveStreamsEmptyState;

  /// No description provided for @pendingPaymentCompetitionFallback.
  ///
  /// In fr, this message translates to:
  /// **'Compétition'**
  String get pendingPaymentCompetitionFallback;

  /// No description provided for @pendingPaymentSingleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en attente de validation'**
  String get pendingPaymentSingleTitle;

  /// No description provided for @pendingPaymentTapToCheck.
  ///
  /// In fr, this message translates to:
  /// **'Tape pour vérifier le statut'**
  String get pendingPaymentTapToCheck;

  /// No description provided for @promoBannerLinkOpenError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le lien.'**
  String get promoBannerLinkOpenError;

  /// No description provided for @statGridMatchesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Matchs'**
  String get statGridMatchesLabel;

  /// No description provided for @statGridWdlLabel.
  ///
  /// In fr, this message translates to:
  /// **'V/D/N'**
  String get statGridWdlLabel;

  /// No description provided for @statGridWinRateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Win rate'**
  String get statGridWinRateLabel;

  /// No description provided for @upcomingMatchesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match programmé'**
  String get upcomingMatchesEmpty;

  /// No description provided for @upcomingMatchOpponentWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get upcomingMatchOpponentWaiting;

  /// No description provided for @upcomingMatchLive.
  ///
  /// In fr, this message translates to:
  /// **'LIVE'**
  String get upcomingMatchLive;

  /// No description provided for @upcomingBadgeInProgress.
  ///
  /// In fr, this message translates to:
  /// **'EN COURS'**
  String get upcomingBadgeInProgress;

  /// No description provided for @upcomingBadgeToSchedule.
  ///
  /// In fr, this message translates to:
  /// **'À PLANIFIER'**
  String get upcomingBadgeToSchedule;

  /// No description provided for @upcomingBadgeReady.
  ///
  /// In fr, this message translates to:
  /// **'PRÊT'**
  String get upcomingBadgeReady;

  /// No description provided for @upcomingBadgeTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'DEMAIN'**
  String get upcomingBadgeTomorrow;

  /// No description provided for @upcomingPhaseMatch.
  ///
  /// In fr, this message translates to:
  /// **'Match'**
  String get upcomingPhaseMatch;

  /// No description provided for @upcomingPhaseFinal.
  ///
  /// In fr, this message translates to:
  /// **'Finale'**
  String get upcomingPhaseFinal;

  /// No description provided for @upcomingPhaseSemiFinal.
  ///
  /// In fr, this message translates to:
  /// **'Demi-finale'**
  String get upcomingPhaseSemiFinal;

  /// No description provided for @upcomingPhaseQuarterFinal.
  ///
  /// In fr, this message translates to:
  /// **'Quart de finale'**
  String get upcomingPhaseQuarterFinal;

  /// No description provided for @upcomingPhaseRoundOf16.
  ///
  /// In fr, this message translates to:
  /// **'8e de finale'**
  String get upcomingPhaseRoundOf16;

  /// No description provided for @upcomingPhaseRoundOf32.
  ///
  /// In fr, this message translates to:
  /// **'16e de finale'**
  String get upcomingPhaseRoundOf32;

  /// No description provided for @matchRoomTitleDefault.
  ///
  /// In fr, this message translates to:
  /// **'MATCH'**
  String get matchRoomTitleDefault;

  /// No description provided for @matchRoomChatTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Chat avec ton adversaire'**
  String get matchRoomChatTooltip;

  /// No description provided for @matchRoomNotFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Match introuvable'**
  String get matchRoomNotFoundTitle;

  /// No description provided for @matchRoomNotFoundDescription.
  ///
  /// In fr, this message translates to:
  /// **'Le match a peut-être été annulé par un admin.'**
  String get matchRoomNotFoundDescription;

  /// No description provided for @manualUploadButtonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une vidéo de preuve'**
  String get manualUploadButtonLabel;

  /// No description provided for @manualUploadSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo envoyée. Merci !'**
  String get manualUploadSuccess;

  /// No description provided for @outcomeFinalScore.
  ///
  /// In fr, this message translates to:
  /// **'SCORE FINAL'**
  String get outcomeFinalScore;

  /// No description provided for @outcomeDraw.
  ///
  /// In fr, this message translates to:
  /// **'Match nul.'**
  String get outcomeDraw;

  /// No description provided for @outcomeEditMyScore.
  ///
  /// In fr, this message translates to:
  /// **'MODIFIER MON SCORE'**
  String get outcomeEditMyScore;

  /// No description provided for @outcomeDisputeInProgress.
  ///
  /// In fr, this message translates to:
  /// **'LITIGE EN COURS'**
  String get outcomeDisputeInProgress;

  /// No description provided for @outcomeDisputeExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Vos scores ne concordent pas. Si tu t\'es trompé, corrige-le ; sinon attends que ton adversaire corrige le sien. Sans accord, un admin tranchera à partir des preuves.'**
  String get outcomeDisputeExplanation;

  /// No description provided for @outcomeScoreCardYou.
  ///
  /// In fr, this message translates to:
  /// **'TOI'**
  String get outcomeScoreCardYou;

  /// No description provided for @outcomeScoreCardPlayer1.
  ///
  /// In fr, this message translates to:
  /// **'JOUEUR 1'**
  String get outcomeScoreCardPlayer1;

  /// No description provided for @outcomeScoreCardPlayer2.
  ///
  /// In fr, this message translates to:
  /// **'JOUEUR 2'**
  String get outcomeScoreCardPlayer2;

  /// No description provided for @matchHeaderPlayer1.
  ///
  /// In fr, this message translates to:
  /// **'Joueur 1'**
  String get matchHeaderPlayer1;

  /// No description provided for @matchHeaderPlayer2.
  ///
  /// In fr, this message translates to:
  /// **'Joueur 2'**
  String get matchHeaderPlayer2;

  /// No description provided for @matchHeaderBadgeHome.
  ///
  /// In fr, this message translates to:
  /// **'HOME'**
  String get matchHeaderBadgeHome;

  /// No description provided for @matchHeaderBadgeAway.
  ///
  /// In fr, this message translates to:
  /// **'AWAY'**
  String get matchHeaderBadgeAway;

  /// No description provided for @recordingActionResume.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get recordingActionResume;

  /// No description provided for @recordingActionPause.
  ///
  /// In fr, this message translates to:
  /// **'Pause (max 2 min)'**
  String get recordingActionPause;

  /// No description provided for @recordingActionSaveStop.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer et arrêter'**
  String get recordingActionSaveStop;

  /// No description provided for @recordingActionForfeit.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter (forfait)'**
  String get recordingActionForfeit;

  /// No description provided for @recordingNoRecordingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enregistrement en cours.'**
  String get recordingNoRecordingInProgress;

  /// No description provided for @recordingStateRecording.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement en cours'**
  String get recordingStateRecording;

  /// No description provided for @recordingStatePaused.
  ///
  /// In fr, this message translates to:
  /// **'En pause — reprends sous 2 min'**
  String get recordingStatePaused;

  /// No description provided for @recordingStateForfeited.
  ///
  /// In fr, this message translates to:
  /// **'Forfait déclaré'**
  String get recordingStateForfeited;

  /// No description provided for @recordingStateStopped.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement arrêté'**
  String get recordingStateStopped;

  /// No description provided for @recordingStateIdle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enregistrement'**
  String get recordingStateIdle;

  /// No description provided for @recordingLiveStreamStarted.
  ///
  /// In fr, this message translates to:
  /// **'Diffusion live démarrée.'**
  String get recordingLiveStreamStarted;

  /// No description provided for @recordingReplaySavedDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Replay enregistré dans Téléchargements › ARENA'**
  String get recordingReplaySavedDownloads;

  /// No description provided for @recordingReplayInCache.
  ///
  /// In fr, this message translates to:
  /// **'Replay disponible dans le cache de l\'app'**
  String get recordingReplayInCache;

  /// No description provided for @recordingPermMissingMic.
  ///
  /// In fr, this message translates to:
  /// **'micro'**
  String get recordingPermMissingMic;

  /// No description provided for @recordingPermMissingNotifications.
  ///
  /// In fr, this message translates to:
  /// **'notifications'**
  String get recordingPermMissingNotifications;

  /// No description provided for @recordingPermOverlayNeedsSettings.
  ///
  /// In fr, this message translates to:
  /// **'Active \"Afficher au-dessus des autres apps\" pour ARENA dans Paramètres > Apps > Accès spécial'**
  String get recordingPermOverlayNeedsSettings;

  /// No description provided for @recordingPermOverlayDenied.
  ///
  /// In fr, this message translates to:
  /// **'Overlay refusé — retape JE SUIS DANS LA ROOM après activation'**
  String get recordingPermOverlayDenied;

  /// No description provided for @recordingBannerRecording.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement anti-triche en cours\nTape pour les actions'**
  String get recordingBannerRecording;

  /// No description provided for @recordingBannerPaused.
  ///
  /// In fr, this message translates to:
  /// **'Match en pause — tape pour reprendre ou arrêter'**
  String get recordingBannerPaused;

  /// No description provided for @recordingBannerForfeitPauseExpired.
  ///
  /// In fr, this message translates to:
  /// **'Forfait : pause dépassée'**
  String get recordingBannerForfeitPauseExpired;

  /// No description provided for @recordingBannerForfeitDeclared.
  ///
  /// In fr, this message translates to:
  /// **'Forfait déclaré'**
  String get recordingBannerForfeitDeclared;

  /// No description provided for @stepBodyMatchInProgressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Match en cours'**
  String get stepBodyMatchInProgressTitle;

  /// No description provided for @stepBodyMatchInProgressDesc.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs sont en train de jouer ou de valider le score.'**
  String get stepBodyMatchInProgressDesc;

  /// No description provided for @stepBodyMatchCancelledTitle.
  ///
  /// In fr, this message translates to:
  /// **'MATCH ANNULÉ'**
  String get stepBodyMatchCancelledTitle;

  /// No description provided for @stepBodyMatchCancelledDesc.
  ///
  /// In fr, this message translates to:
  /// **'L\'admin a annulé ce match.'**
  String get stepBodyMatchCancelledDesc;

  /// No description provided for @stepBodyForfeitTitle.
  ///
  /// In fr, this message translates to:
  /// **'FORFAIT'**
  String get stepBodyForfeitTitle;

  /// No description provided for @stepBodyForfeitDesc.
  ///
  /// In fr, this message translates to:
  /// **'L\'un des joueurs n\'a pas démarré à temps.'**
  String get stepBodyForfeitDesc;

  /// No description provided for @stepBodyAwaitRoomCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'En attente du code room'**
  String get stepBodyAwaitRoomCodeTitle;

  /// No description provided for @stepBodyAwaitRoomCodeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs vont créer une room dans le jeu et partager le code ici.'**
  String get stepBodyAwaitRoomCodeDesc;

  /// No description provided for @stepBodyAwaitHomeCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'En attente du code de HOME'**
  String get stepBodyAwaitHomeCodeTitle;

  /// No description provided for @stepBodyAwaitHomeCodeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Tu es AWAY sur ce match. Le joueur à domicile crée la room dans le jeu et t\'enverra le code ici dès qu\'il l\'aura partagé.'**
  String get stepBodyAwaitHomeCodeDesc;

  /// No description provided for @openChatButton.
  ///
  /// In fr, this message translates to:
  /// **'OUVRIR LE CHAT'**
  String get openChatButton;

  /// No description provided for @roomReadyMarkStartedError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de marquer démarré : '**
  String get roomReadyMarkStartedError;

  /// No description provided for @roomReadyCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié dans le presse-papier'**
  String get roomReadyCodeCopied;

  /// No description provided for @roomReadyHintObserver.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs vont rejoindre la room et démarrer le match.'**
  String get roomReadyHintObserver;

  /// No description provided for @roomReadyHintHome.
  ///
  /// In fr, this message translates to:
  /// **'Tu as partagé le code. En attente que ton adversaire rejoigne, puis confirmez le démarrage.'**
  String get roomReadyHintHome;

  /// No description provided for @roomReadyHintAway.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins la room dans le jeu avec ce code, puis confirme une fois que les deux joueurs sont dedans.'**
  String get roomReadyHintAway;

  /// No description provided for @roomReadyCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'CODE DE LA ROOM'**
  String get roomReadyCodeLabel;

  /// No description provided for @roomReadyCopyTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get roomReadyCopyTooltip;

  /// No description provided for @roomReadyTeamNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'NOM DE TON ÉQUIPE'**
  String get roomReadyTeamNameLabel;

  /// No description provided for @roomReadyTeamNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Real Madrid, FC Barcelone…'**
  String get roomReadyTeamNameHint;

  /// No description provided for @roomReadyTeamNameHelper.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire — l\'équipe que tu utilises pour ce match. Visible par l\'admin en cas de litige anti-triche.'**
  String get roomReadyTeamNameHelper;

  /// No description provided for @roomReadyInRoomButton.
  ///
  /// In fr, this message translates to:
  /// **'JE SUIS DANS LA ROOM'**
  String get roomReadyInRoomButton;

  /// No description provided for @roomReadyCodeSharedBadge.
  ///
  /// In fr, this message translates to:
  /// **'CODE PARTAGÉ'**
  String get roomReadyCodeSharedBadge;

  /// No description provided for @roomReadySyncingHint.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation avec ton adversaire…'**
  String get roomReadySyncingHint;

  /// No description provided for @scoreEditErrorRange.
  ///
  /// In fr, this message translates to:
  /// **'Scores attendus entre 0 et 99.'**
  String get scoreEditErrorRange;

  /// No description provided for @scoreEditErrorTieBeforePens.
  ///
  /// In fr, this message translates to:
  /// **'Score réglementaire à égalité avant les tirs au but.'**
  String get scoreEditErrorTieBeforePens;

  /// No description provided for @scoreEditErrorPensRange.
  ///
  /// In fr, this message translates to:
  /// **'Tirs au but attendus entre 0 et 30.'**
  String get scoreEditErrorPensRange;

  /// No description provided for @scoreEditErrorPensTie.
  ///
  /// In fr, this message translates to:
  /// **'Les tirs au but ne peuvent pas finir à égalité.'**
  String get scoreEditErrorPensTie;

  /// No description provided for @scoreEditDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Corriger ton score'**
  String get scoreEditDialogTitle;

  /// No description provided for @scoreEditMyScoreLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mon score'**
  String get scoreEditMyScoreLabel;

  /// No description provided for @scoreEditOpponentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adversaire'**
  String get scoreEditOpponentLabel;

  /// No description provided for @scoreEditViaPenaltiesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Décidé aux tirs au but'**
  String get scoreEditViaPenaltiesLabel;

  /// No description provided for @scoreEditMyPenLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mes TAB'**
  String get scoreEditMyPenLabel;

  /// No description provided for @scoreEditOppPenLabel.
  ///
  /// In fr, this message translates to:
  /// **'TAB adv.'**
  String get scoreEditOppPenLabel;

  /// No description provided for @scoreEditCancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get scoreEditCancelButton;

  /// No description provided for @scoreEditResendButton.
  ///
  /// In fr, this message translates to:
  /// **'RENVOYER'**
  String get scoreEditResendButton;

  /// No description provided for @scoreFlowErrorRange.
  ///
  /// In fr, this message translates to:
  /// **'Scores attendus entre 0 et 99.'**
  String get scoreFlowErrorRange;

  /// No description provided for @scoreFlowErrorTieBeforePens.
  ///
  /// In fr, this message translates to:
  /// **'Le score réglementaire doit être à égalité avant les tirs au but.'**
  String get scoreFlowErrorTieBeforePens;

  /// No description provided for @scoreFlowErrorPensRange.
  ///
  /// In fr, this message translates to:
  /// **'Tirs au but attendus entre 0 et 30.'**
  String get scoreFlowErrorPensRange;

  /// No description provided for @scoreFlowErrorPensTie.
  ///
  /// In fr, this message translates to:
  /// **'Les tirs au but ne peuvent pas finir à égalité.'**
  String get scoreFlowErrorPensTie;

  /// No description provided for @scoreFlowSubmitError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de soumettre : '**
  String get scoreFlowSubmitError;

  /// No description provided for @scoreFlowProofUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Upload impossible : '**
  String get scoreFlowProofUploadError;

  /// No description provided for @scoreFlowResolutionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de résolution : '**
  String get scoreFlowResolutionError;

  /// No description provided for @scoreFlowSessionExpiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée'**
  String get scoreFlowSessionExpiredTitle;

  /// No description provided for @scoreFlowSessionExpiredDescription.
  ///
  /// In fr, this message translates to:
  /// **'Reconnecte-toi pour saisir un score.'**
  String get scoreFlowSessionExpiredDescription;

  /// No description provided for @scoreFlowEnterFinalScoreLabel.
  ///
  /// In fr, this message translates to:
  /// **'SAISIS LE SCORE FINAL'**
  String get scoreFlowEnterFinalScoreLabel;

  /// No description provided for @scoreFlowEnterFinalScoreHint.
  ///
  /// In fr, this message translates to:
  /// **'Entre les buts de chaque côté. Si vos deux saisies concordent, le match est validé automatiquement.'**
  String get scoreFlowEnterFinalScoreHint;

  /// No description provided for @scoreFlowMyScoreLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mon score'**
  String get scoreFlowMyScoreLabel;

  /// No description provided for @scoreFlowOppScoreLabel.
  ///
  /// In fr, this message translates to:
  /// **'Score adversaire'**
  String get scoreFlowOppScoreLabel;

  /// No description provided for @scoreFlowViaPenaltiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Match décidé aux tirs au but'**
  String get scoreFlowViaPenaltiesTitle;

  /// No description provided for @scoreFlowViaPenaltiesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'À cocher uniquement si le score réglementaire est à égalité.'**
  String get scoreFlowViaPenaltiesSubtitle;

  /// No description provided for @scoreFlowMyPenLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mes tirs au but'**
  String get scoreFlowMyPenLabel;

  /// No description provided for @scoreFlowOppPenLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tirs adversaire'**
  String get scoreFlowOppPenLabel;

  /// No description provided for @scoreFlowSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'SOUMETTRE LE SCORE'**
  String get scoreFlowSubmitButton;

  /// No description provided for @scoreFlowValidationInProgress.
  ///
  /// In fr, this message translates to:
  /// **'VALIDATION EN COURS'**
  String get scoreFlowValidationInProgress;

  /// No description provided for @scoreFlowWaitingOpponent.
  ///
  /// In fr, this message translates to:
  /// **'EN ATTENTE DE TON ADVERSAIRE'**
  String get scoreFlowWaitingOpponent;

  /// No description provided for @scoreFlowYouSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Tu as soumis : '**
  String get scoreFlowYouSubmitted;

  /// No description provided for @scoreFlowOnPenalties.
  ///
  /// In fr, this message translates to:
  /// **'Aux tirs au but : '**
  String get scoreFlowOnPenalties;

  /// No description provided for @scoreFlowComparingScores.
  ///
  /// In fr, this message translates to:
  /// **'On compare les scores des deux joueurs…'**
  String get scoreFlowComparingScores;

  /// No description provided for @scoreFlowOpponentNotSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Ton adversaire n\'a pas encore saisi son score.'**
  String get scoreFlowOpponentNotSubmitted;

  /// No description provided for @scoreFlowProofAttached.
  ///
  /// In fr, this message translates to:
  /// **'Preuve attachée'**
  String get scoreFlowProofAttached;

  /// No description provided for @scoreFlowProofPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Joins une photo ou vidéo (recommandé)'**
  String get scoreFlowProofPrompt;

  /// No description provided for @scoreFlowProofHelper.
  ///
  /// In fr, this message translates to:
  /// **'Capture d\'écran de l\'écran de fin du match ou clip de la dernière action — utile en cas de litige.'**
  String get scoreFlowProofHelper;

  /// No description provided for @scoreFlowUploading.
  ///
  /// In fr, this message translates to:
  /// **'Upload en cours…'**
  String get scoreFlowUploading;

  /// No description provided for @scoreFlowReplaceButton.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get scoreFlowReplaceButton;

  /// No description provided for @scoreFlowRemoveProofTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la preuve'**
  String get scoreFlowRemoveProofTooltip;

  /// No description provided for @scoreFlowChooseFileButton.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get scoreFlowChooseFileButton;

  /// No description provided for @shareCodeErrorLength.
  ///
  /// In fr, this message translates to:
  /// **'Le code doit faire entre 4 et 12 caractères.'**
  String get shareCodeErrorLength;

  /// No description provided for @shareCodeErrorSendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de partager le code : '**
  String get shareCodeErrorSendFailed;

  /// No description provided for @shareCodeRoomLabel.
  ///
  /// In fr, this message translates to:
  /// **'CODE ROOM (HOME CRÉE)'**
  String get shareCodeRoomLabel;

  /// No description provided for @shareCodeEnterPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Saisis ton code eFootball :'**
  String get shareCodeEnterPrompt;

  /// No description provided for @shareCodeOpponentWillReceive.
  ///
  /// In fr, this message translates to:
  /// **'Ton adversaire recevra ce code au chat dès envoi.'**
  String get shareCodeOpponentWillReceive;

  /// No description provided for @shareCodeOpponentReceives.
  ///
  /// In fr, this message translates to:
  /// **'Ton adversaire reçoit ce code au chat dès envoi.'**
  String get shareCodeOpponentReceives;

  /// No description provided for @shareCodeSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'ENVOYER LE CODE'**
  String get shareCodeSubmitButton;

  /// No description provided for @shareCodeInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 8K3-TZ9'**
  String get shareCodeInputHint;

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllReadTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Marquer tout comme lu'**
  String get notificationsMarkAllReadTooltip;

  /// No description provided for @notificationsMarkAllReadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de tout marquer comme lu.'**
  String get notificationsMarkAllReadError;

  /// No description provided for @notificationsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement.\n'**
  String get notificationsLoadError;

  /// No description provided for @notificationsSignedOut.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour voir tes notifications.'**
  String get notificationsSignedOut;

  /// No description provided for @notificationsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification pour le moment.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get notificationsFilterAll;

  /// No description provided for @notificationsFilterMatch.
  ///
  /// In fr, this message translates to:
  /// **'Matchs'**
  String get notificationsFilterMatch;

  /// No description provided for @notificationsFilterEarning.
  ///
  /// In fr, this message translates to:
  /// **'Gains'**
  String get notificationsFilterEarning;

  /// No description provided for @notificationsFilterSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get notificationsFilterSystem;

  /// No description provided for @notificationsTimeJustNow.
  ///
  /// In fr, this message translates to:
  /// **'À l\'instant'**
  String get notificationsTimeJustNow;

  /// No description provided for @notificationsTimeYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get notificationsTimeYesterday;

  /// No description provided for @mobileMoneyDefaultCountry.
  ///
  /// In fr, this message translates to:
  /// **'🇨🇲 Cameroun'**
  String get mobileMoneyDefaultCountry;

  /// No description provided for @mobileMoneyCountryLabel.
  ///
  /// In fr, this message translates to:
  /// **'PAYS'**
  String get mobileMoneyCountryLabel;

  /// No description provided for @mobileMoneyNumberLabel.
  ///
  /// In fr, this message translates to:
  /// **'NUMÉRO '**
  String get mobileMoneyNumberLabel;

  /// No description provided for @mobileMoneyNumberHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro depuis lequel tu vas payer (utile au super-admin pour retrouver ta transaction).'**
  String get mobileMoneyNumberHelp;

  /// No description provided for @mobileMoneyPhoneValid.
  ///
  /// In fr, this message translates to:
  /// **'✓ Numéro valide '**
  String get mobileMoneyPhoneValid;

  /// No description provided for @mobileMoneySubmitSending.
  ///
  /// In fr, this message translates to:
  /// **'ENVOI…'**
  String get mobileMoneySubmitSending;

  /// No description provided for @mobileMoneySubmitPaid.
  ///
  /// In fr, this message translates to:
  /// **'J\'AI PAYÉ '**
  String get mobileMoneySubmitPaid;

  /// No description provided for @mobileMoneyCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code marchand copié.'**
  String get mobileMoneyCodeCopied;

  /// No description provided for @mobileMoneyDialerError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le composeur. Copie le code et compose-le à la main.'**
  String get mobileMoneyDialerError;

  /// No description provided for @mobileMoneySubmitError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'envoi : '**
  String get mobileMoneySubmitError;

  /// No description provided for @mobileMoneyNoConnection.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion : '**
  String get mobileMoneyNoConnection;

  /// No description provided for @mobileMoneyHeroPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement '**
  String get mobileMoneyHeroPayment;

  /// No description provided for @mobileMoneyHeroForAmount.
  ///
  /// In fr, this message translates to:
  /// **'Pour '**
  String get mobileMoneyHeroForAmount;

  /// No description provided for @mobileMoneyMerchantCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code marchand'**
  String get mobileMoneyMerchantCodeTitle;

  /// No description provided for @mobileMoneyCopyButton.
  ///
  /// In fr, this message translates to:
  /// **'📋 COPIER'**
  String get mobileMoneyCopyButton;

  /// No description provided for @mobileMoneyExecuteButton.
  ///
  /// In fr, this message translates to:
  /// **'📞 EXÉCUTER'**
  String get mobileMoneyExecuteButton;

  /// No description provided for @mobileMoneyMissingCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'⚠ Code marchand manquant'**
  String get mobileMoneyMissingCodeTitle;

  /// No description provided for @mobileMoneyMissingCodeBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'admin n\'a pas encore configuré de code marchand pour cette méthode sur cette compétition. Choisis une autre méthode ou contacte le support.'**
  String get mobileMoneyMissingCodeBody;

  /// No description provided for @mobileMoneyDisclaimerExactAmount.
  ///
  /// In fr, this message translates to:
  /// **'Paie le montant EXACT — sinon le super-admin refusera'**
  String get mobileMoneyDisclaimerExactAmount;

  /// No description provided for @mobileMoneyDisclaimerKeepSms.
  ///
  /// In fr, this message translates to:
  /// **'Garde le SMS de confirmation Mobile Money en preuve'**
  String get mobileMoneyDisclaimerKeepSms;

  /// No description provided for @mobileMoneyDisclaimerManualValidation.
  ///
  /// In fr, this message translates to:
  /// **'L\'admin valide manuellement ton paiement après réception'**
  String get mobileMoneyDisclaimerManualValidation;

  /// No description provided for @mobileMoneyDisclaimerTitle.
  ///
  /// In fr, this message translates to:
  /// **'⚠ Avant de continuer'**
  String get mobileMoneyDisclaimerTitle;

  /// No description provided for @paymentFailedRejectedWithReason.
  ///
  /// In fr, this message translates to:
  /// **'Le super-admin a refusé ton paiement : '**
  String get paymentFailedRejectedWithReason;

  /// No description provided for @paymentFailedRejectedGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Le super-admin a refusé ton paiement (montant incorrect ou transaction introuvable sur le compte marchand).'**
  String get paymentFailedRejectedGeneric;

  /// No description provided for @paymentFailedNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Problème réseau pendant l\'envoi. Aucun débit n\'a été effectué côté ARENA.'**
  String get paymentFailedNetwork;

  /// No description provided for @paymentFailedUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement n\'a pas pu être confirmé. Réessaie ou contacte le support.'**
  String get paymentFailedUnknown;

  /// No description provided for @paymentFailedSolutionCheckAmount.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie le montant exact + le code marchand'**
  String get paymentFailedSolutionCheckAmount;

  /// No description provided for @paymentFailedSolutionRetryFromSignup.
  ///
  /// In fr, this message translates to:
  /// **'Recommence depuis la page Inscription'**
  String get paymentFailedSolutionRetryFromSignup;

  /// No description provided for @paymentFailedSolutionContactIfError.
  ///
  /// In fr, this message translates to:
  /// **'Contacte le support si tu penses que c\'est une erreur'**
  String get paymentFailedSolutionContactIfError;

  /// No description provided for @paymentFailedSolutionCheckInternet.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta connexion Internet'**
  String get paymentFailedSolutionCheckInternet;

  /// No description provided for @paymentFailedSolutionContactSupport.
  ///
  /// In fr, this message translates to:
  /// **'Contacte le support ARENA'**
  String get paymentFailedSolutionContactSupport;

  /// No description provided for @paymentFailedAccountNotRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte n\'a pas été inscrit.'**
  String get paymentFailedAccountNotRegistered;

  /// No description provided for @paymentFailedRetryButton.
  ///
  /// In fr, this message translates to:
  /// **'↻ RECOMMENCER'**
  String get paymentFailedRetryButton;

  /// No description provided for @paymentFailedContactSupportLink.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support ARENA'**
  String get paymentFailedContactSupportLink;

  /// No description provided for @paymentFailedTitleRejected.
  ///
  /// In fr, this message translates to:
  /// **'PAIEMENT REFUSÉ'**
  String get paymentFailedTitleRejected;

  /// No description provided for @paymentFailedTitleFailed.
  ///
  /// In fr, this message translates to:
  /// **'PAIEMENT ÉCHOUÉ'**
  String get paymentFailedTitleFailed;

  /// No description provided for @paymentFailedCauseTitle.
  ///
  /// In fr, this message translates to:
  /// **'⚠ Cause'**
  String get paymentFailedCauseTitle;

  /// No description provided for @paymentFailedErrorCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code erreur : '**
  String get paymentFailedErrorCodeLabel;

  /// No description provided for @paymentFailedSolutionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'💡 Solutions'**
  String get paymentFailedSolutionsTitle;

  /// No description provided for @paymentHistoryAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'HISTORIQUE'**
  String get paymentHistoryAppBarTitle;

  /// No description provided for @paymentHistoryErrorPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : '**
  String get paymentHistoryErrorPrefix;

  /// No description provided for @paymentHistoryTabPayments.
  ///
  /// In fr, this message translates to:
  /// **'PAIEMENTS'**
  String get paymentHistoryTabPayments;

  /// No description provided for @paymentHistoryTabGains.
  ///
  /// In fr, this message translates to:
  /// **'GAINS'**
  String get paymentHistoryTabGains;

  /// No description provided for @paymentHistoryGainsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun gain pour le moment. Remporte une compétition pour recevoir un versement !'**
  String get paymentHistoryGainsEmpty;

  /// No description provided for @paymentHistoryBadgePaid.
  ///
  /// In fr, this message translates to:
  /// **'VERSÉ'**
  String get paymentHistoryBadgePaid;

  /// No description provided for @paymentHistoryBadgePending.
  ///
  /// In fr, this message translates to:
  /// **'EN ATTENTE'**
  String get paymentHistoryBadgePending;

  /// No description provided for @paymentHistoryBadgeToClaim.
  ///
  /// In fr, this message translates to:
  /// **'À RÉCLAMER'**
  String get paymentHistoryBadgeToClaim;

  /// No description provided for @paymentHistoryGainRanked.
  ///
  /// In fr, this message translates to:
  /// **'Gain · rang '**
  String get paymentHistoryGainRanked;

  /// No description provided for @paymentHistoryGainGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Gain de compétition'**
  String get paymentHistoryGainGeneric;

  /// No description provided for @paymentHistoryClaimButton.
  ///
  /// In fr, this message translates to:
  /// **'RÉCLAMER MON GAIN'**
  String get paymentHistoryClaimButton;

  /// No description provided for @paymentHistoryClaimSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Gain réclamé — le staff va procéder au versement.'**
  String get paymentHistoryClaimSuccess;

  /// No description provided for @paymentHistoryClaimFailPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Échec : '**
  String get paymentHistoryClaimFailPrefix;

  /// No description provided for @paymentHistoryClaimSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réclamer mon gain'**
  String get paymentHistoryClaimSheetTitle;

  /// No description provided for @paymentHistoryClaimSheetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Indique le numéro Mobile Money sur lequel recevoir ton versement.'**
  String get paymentHistoryClaimSheetSubtitle;

  /// No description provided for @paymentHistoryClaimMethodMtn.
  ///
  /// In fr, this message translates to:
  /// **'MTN MoMo'**
  String get paymentHistoryClaimMethodMtn;

  /// No description provided for @paymentHistoryClaimMethodOrange.
  ///
  /// In fr, this message translates to:
  /// **'Orange Money'**
  String get paymentHistoryClaimMethodOrange;

  /// No description provided for @paymentHistoryClaimPhoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Numéro Mobile Money (ex. +237 6XX XX XX XX)'**
  String get paymentHistoryClaimPhoneHint;

  /// No description provided for @paymentHistoryClaimConfirm.
  ///
  /// In fr, this message translates to:
  /// **'CONFIRMER'**
  String get paymentHistoryClaimConfirm;

  /// No description provided for @paymentHistoryClaimPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Numéro requis.'**
  String get paymentHistoryClaimPhoneRequired;

  /// No description provided for @paymentHistoryEmptyPayments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement pour le moment.'**
  String get paymentHistoryEmptyPayments;

  /// No description provided for @paymentHistoryNetBalanceLabel.
  ///
  /// In fr, this message translates to:
  /// **'SOLDE NET'**
  String get paymentHistoryNetBalanceLabel;

  /// No description provided for @paymentHistoryTxTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscription compétition'**
  String get paymentHistoryTxTitle;

  /// No description provided for @paymentHistoryTxBadgePaid.
  ///
  /// In fr, this message translates to:
  /// **'PAYÉ'**
  String get paymentHistoryTxBadgePaid;

  /// No description provided for @paymentHistoryTxBadgePending.
  ///
  /// In fr, this message translates to:
  /// **'EN ATTENTE'**
  String get paymentHistoryTxBadgePending;

  /// No description provided for @paymentHistoryTxBadgeRefund.
  ///
  /// In fr, this message translates to:
  /// **'REMBOURSEMENT'**
  String get paymentHistoryTxBadgeRefund;

  /// No description provided for @paymentHistoryTxBadgeRefunded.
  ///
  /// In fr, this message translates to:
  /// **'REMBOURSÉ'**
  String get paymentHistoryTxBadgeRefunded;

  /// No description provided for @paymentHistoryTxBadgeFailed.
  ///
  /// In fr, this message translates to:
  /// **'ÉCHEC'**
  String get paymentHistoryTxBadgeFailed;

  /// No description provided for @paymentHistoryResumeCompetition.
  ///
  /// In fr, this message translates to:
  /// **'Compétition'**
  String get paymentHistoryResumeCompetition;

  /// No description provided for @paymentMethodMtnLabel.
  ///
  /// In fr, this message translates to:
  /// **'MTN Mobile Money'**
  String get paymentMethodMtnLabel;

  /// No description provided for @paymentMethodMtnCountries.
  ///
  /// In fr, this message translates to:
  /// **'Cameroun, Côte d\'Ivoire, Bénin'**
  String get paymentMethodMtnCountries;

  /// No description provided for @paymentMethodOrangeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Orange Money'**
  String get paymentMethodOrangeLabel;

  /// No description provided for @paymentMethodOrangeCountries.
  ///
  /// In fr, this message translates to:
  /// **'Cameroun, Sénégal, Mali'**
  String get paymentMethodOrangeCountries;

  /// No description provided for @paymentPickerAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'PAIEMENT'**
  String get paymentPickerAppBarTitle;

  /// No description provided for @paymentPickerMobileMoneySection.
  ///
  /// In fr, this message translates to:
  /// **'📱 MOBILE MONEY'**
  String get paymentPickerMobileMoneySection;

  /// No description provided for @paymentPickerV2Notice.
  ///
  /// In fr, this message translates to:
  /// **'₿ Crypto + Wave + Moov disponibles en V2 (passerelles automatiques CinetPay / NowPayments).'**
  String get paymentPickerV2Notice;

  /// No description provided for @paymentPickerContinueButton.
  ///
  /// In fr, this message translates to:
  /// **'CONTINUER →'**
  String get paymentPickerContinueButton;

  /// No description provided for @paymentPickerAmountLabel.
  ///
  /// In fr, this message translates to:
  /// **'MONTANT À PAYER'**
  String get paymentPickerAmountLabel;

  /// No description provided for @paymentProcessingAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'STATUT PAIEMENT'**
  String get paymentProcessingAppBarTitle;

  /// No description provided for @paymentProcessingWaitingTitle.
  ///
  /// In fr, this message translates to:
  /// **'EN ATTENTE DE VALIDATION'**
  String get paymentProcessingWaitingTitle;

  /// No description provided for @paymentProcessingWaitingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le super-admin vérifie la réception du paiement sur son compte '**
  String get paymentProcessingWaitingSubtitle;

  /// No description provided for @paymentProcessingWaitingSubtitleSuffix.
  ///
  /// In fr, this message translates to:
  /// **' account.'**
  String get paymentProcessingWaitingSubtitleSuffix;

  /// No description provided for @paymentProcessingInfoNote.
  ///
  /// In fr, this message translates to:
  /// **'💡 Tu peux fermer cette page : la transaction reste en attente côté admin. Tu reviendras vérifier le statut depuis \"Historique paiements\" ou la bannière sur la home.'**
  String get paymentProcessingInfoNote;

  /// No description provided for @paymentProcessingLeaveButton.
  ///
  /// In fr, this message translates to:
  /// **'QUITTER (LA TRANSACTION CONTINUE)'**
  String get paymentProcessingLeaveButton;

  /// No description provided for @paymentProcessingCancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la transaction'**
  String get paymentProcessingCancelButton;

  /// No description provided for @paymentProcessingCancelDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le paiement ?'**
  String get paymentProcessingCancelDialogTitle;

  /// No description provided for @paymentProcessingCancelDialogBody.
  ///
  /// In fr, this message translates to:
  /// **'Si tu as déjà payé sur Mobile Money, attends la validation plutôt que d\'annuler ici (sinon l\'admin n\'inscrira pas ton compte).'**
  String get paymentProcessingCancelDialogBody;

  /// No description provided for @paymentProcessingCancelDialogStay.
  ///
  /// In fr, this message translates to:
  /// **'Rester'**
  String get paymentProcessingCancelDialogStay;

  /// No description provided for @paymentProcessingCancelDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Annuler quand même'**
  String get paymentProcessingCancelDialogConfirm;

  /// No description provided for @paymentProcessingRecapCompetition.
  ///
  /// In fr, this message translates to:
  /// **'Compétition'**
  String get paymentProcessingRecapCompetition;

  /// No description provided for @paymentProcessingRecapAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get paymentProcessingRecapAmount;

  /// No description provided for @paymentProcessingRecapMethod.
  ///
  /// In fr, this message translates to:
  /// **'Méthode'**
  String get paymentProcessingRecapMethod;

  /// No description provided for @paymentProcessingRecapPhone.
  ///
  /// In fr, this message translates to:
  /// **'Ton numéro'**
  String get paymentProcessingRecapPhone;

  /// No description provided for @paymentProcessingRecapReference.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get paymentProcessingRecapReference;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'PAIEMENT RÉUSSI !'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton inscription est confirmée.'**
  String get paymentSuccessSubtitle;

  /// No description provided for @paymentSuccessSeeCompetition.
  ///
  /// In fr, this message translates to:
  /// **'🏆 VOIR LA COMPÉTITION'**
  String get paymentSuccessSeeCompetition;

  /// No description provided for @paymentSuccessBackHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get paymentSuccessBackHome;

  /// No description provided for @paymentSuccessReceiptAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get paymentSuccessReceiptAmount;

  /// No description provided for @paymentSuccessReceiptMethod.
  ///
  /// In fr, this message translates to:
  /// **'Méthode'**
  String get paymentSuccessReceiptMethod;

  /// No description provided for @paymentSuccessReceiptTransaction.
  ///
  /// In fr, this message translates to:
  /// **'N° transaction'**
  String get paymentSuccessReceiptTransaction;

  /// No description provided for @paymentSuccessReceiptDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get paymentSuccessReceiptDate;

  /// No description provided for @paymentSuccessRegisteredLabel.
  ///
  /// In fr, this message translates to:
  /// **'🏆 Tu es inscrit à'**
  String get paymentSuccessRegisteredLabel;

  /// No description provided for @payoutKycStepIdRecto.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité (recto)'**
  String get payoutKycStepIdRecto;

  /// No description provided for @payoutKycStepIdVerso.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité (verso)'**
  String get payoutKycStepIdVerso;

  /// No description provided for @payoutKycStepSelfie.
  ///
  /// In fr, this message translates to:
  /// **'Selfie de vérification'**
  String get payoutKycStepSelfie;

  /// No description provided for @payoutKycAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'VÉRIFIER'**
  String get payoutKycAppBarTitle;

  /// No description provided for @payoutKycAcceptedDocsLabel.
  ///
  /// In fr, this message translates to:
  /// **'DOCUMENTS ACCEPTÉS'**
  String get payoutKycAcceptedDocsLabel;

  /// No description provided for @payoutKycSubmitForReview.
  ///
  /// In fr, this message translates to:
  /// **'ENVOYER POUR VÉRIFICATION'**
  String get payoutKycSubmitForReview;

  /// No description provided for @payoutKycNextRectoRequired.
  ///
  /// In fr, this message translates to:
  /// **'SUIVANT (recto requis)'**
  String get payoutKycNextRectoRequired;

  /// No description provided for @payoutKycPendingGain.
  ///
  /// In fr, this message translates to:
  /// **'💰 Gain de {amount} XAF'**
  String payoutKycPendingGain(Object amount);

  /// No description provided for @payoutKycPendingExplain.
  ///
  /// In fr, this message translates to:
  /// **'Pour ce montant, on doit vérifier ton identité avant le payout. C\'est rapide (sous 24h).'**
  String get payoutKycPendingExplain;

  /// No description provided for @payoutKycDocNationalId.
  ///
  /// In fr, this message translates to:
  /// **'Carte d\'identité nationale'**
  String get payoutKycDocNationalId;

  /// No description provided for @payoutKycDocPassport.
  ///
  /// In fr, this message translates to:
  /// **'Passeport'**
  String get payoutKycDocPassport;

  /// No description provided for @payoutKycDocDriverLicense.
  ///
  /// In fr, this message translates to:
  /// **'Permis de conduire'**
  String get payoutKycDocDriverLicense;

  /// No description provided for @payoutKycPhotoCaptured.
  ///
  /// In fr, this message translates to:
  /// **'Photo capturée'**
  String get payoutKycPhotoCaptured;

  /// No description provided for @payoutKycRetake.
  ///
  /// In fr, this message translates to:
  /// **'REPRENDRE'**
  String get payoutKycRetake;

  /// No description provided for @payoutKycPhotographFront.
  ///
  /// In fr, this message translates to:
  /// **'Photographier le recto'**
  String get payoutKycPhotographFront;

  /// No description provided for @payoutKycCaptureHint.
  ///
  /// In fr, this message translates to:
  /// **'Bonne lumière, photo nette, pas de reflets'**
  String get payoutKycCaptureHint;

  /// No description provided for @payoutKycTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'📸 PRENDRE EN PHOTO'**
  String get payoutKycTakePhoto;

  /// No description provided for @payoutKycSecurityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité : '**
  String get payoutKycSecurityLabel;

  /// No description provided for @payoutKycSecurityNote.
  ///
  /// In fr, this message translates to:
  /// **'tes documents sont chiffrés et utilisés uniquement pour la vérification réglementaire.'**
  String get payoutKycSecurityNote;

  /// No description provided for @aboutLinkCgu.
  ///
  /// In fr, this message translates to:
  /// **'CGU'**
  String get aboutLinkCgu;

  /// No description provided for @aboutLinkPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Privacy Policy'**
  String get aboutLinkPrivacy;

  /// No description provided for @aboutLinkCookies.
  ///
  /// In fr, this message translates to:
  /// **'Cookies'**
  String get aboutLinkCookies;

  /// No description provided for @aboutLinkSupport.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get aboutLinkSupport;

  /// No description provided for @aboutLinkSite.
  ///
  /// In fr, this message translates to:
  /// **'Site arena.app'**
  String get aboutLinkSite;

  /// No description provided for @aboutAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'À PROPOS'**
  String get aboutAppBarTitle;

  /// No description provided for @aboutMadeInCameroon.
  ///
  /// In fr, this message translates to:
  /// **'Made in Cameroon 🇨🇲'**
  String get aboutMadeInCameroon;

  /// No description provided for @aboutLinksLabel.
  ///
  /// In fr, this message translates to:
  /// **'LIENS'**
  String get aboutLinksLabel;

  /// No description provided for @aboutBuiltWith.
  ///
  /// In fr, this message translates to:
  /// **'Built with'**
  String get aboutBuiltWith;

  /// No description provided for @aboutMissionTitle.
  ///
  /// In fr, this message translates to:
  /// **'📜 Notre mission'**
  String get aboutMissionTitle;

  /// No description provided for @aboutMissionBody.
  ///
  /// In fr, this message translates to:
  /// **'ARENA démocratise l\'e-sport mobile en Afrique en offrant des tournois équitables, des gains en mobile money, et une expérience premium aux passionnés de football virtuel.'**
  String get aboutMissionBody;

  /// No description provided for @aboutLinkComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'{label} arrive en PHASE 12.5'**
  String aboutLinkComingSoon(Object label);

  /// No description provided for @adminMessagesAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Messages ARENA'**
  String get adminMessagesAppBarTitle;

  /// No description provided for @adminMessagesError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String adminMessagesError(Object error);

  /// No description provided for @adminMessagesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun message de la part d\'ARENA.'**
  String get adminMessagesEmpty;

  /// No description provided for @deleteAccountStepWarning.
  ///
  /// In fr, this message translates to:
  /// **'AVERTISSEMENT'**
  String get deleteAccountStepWarning;

  /// No description provided for @deleteAccountStepPendingEarnings.
  ///
  /// In fr, this message translates to:
  /// **'GAINS EN ATTENTE'**
  String get deleteAccountStepPendingEarnings;

  /// No description provided for @deleteAccountStepConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'CONFIRMATION'**
  String get deleteAccountStepConfirmation;

  /// No description provided for @deleteAccountStepDone.
  ///
  /// In fr, this message translates to:
  /// **'TERMINÉ'**
  String get deleteAccountStepDone;

  /// No description provided for @deleteAccountAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get deleteAccountAppBarTitle;

  /// No description provided for @deleteAccountLossHistory.
  ///
  /// In fr, this message translates to:
  /// **'Tout ton historique de matchs et de tournois'**
  String get deleteAccountLossHistory;

  /// No description provided for @deleteAccountLossBadges.
  ///
  /// In fr, this message translates to:
  /// **'Tes badges et accomplissements'**
  String get deleteAccountLossBadges;

  /// No description provided for @deleteAccountLossChats.
  ///
  /// In fr, this message translates to:
  /// **'Tes conversations et chats de match'**
  String get deleteAccountLossChats;

  /// No description provided for @deleteAccountLossPaymentMethods.
  ///
  /// In fr, this message translates to:
  /// **'Tes méthodes de paiement enregistrées'**
  String get deleteAccountLossPaymentMethods;

  /// No description provided for @deleteAccountIrreversibleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible'**
  String get deleteAccountIrreversibleTitle;

  /// No description provided for @deleteAccountLossIntro.
  ///
  /// In fr, this message translates to:
  /// **'En supprimant ton compte, tu vas perdre :'**
  String get deleteAccountLossIntro;

  /// No description provided for @deleteAccountRetentionNotice.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte sera désactivé immédiatement, puis anonymisé (données personnelles effacées) sous 30 jours. Les pièces comptables légales (paiements) sont conservées sous forme anonymisée. Pendant ce délai, tu peux contacter le support pour annuler.'**
  String get deleteAccountRetentionNotice;

  /// No description provided for @deleteAccountUnderstandContinue.
  ///
  /// In fr, this message translates to:
  /// **'JE COMPRENDS, CONTINUER'**
  String get deleteAccountUnderstandContinue;

  /// No description provided for @deleteAccountHasPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu as des gains en attente'**
  String get deleteAccountHasPendingTitle;

  /// No description provided for @deleteAccountHasPendingBody.
  ///
  /// In fr, this message translates to:
  /// **'Récupère tes paiements en attente avant de supprimer ton compte. Une fois supprimé, ces fonds ne pourront plus t\'être envoyés.'**
  String get deleteAccountHasPendingBody;

  /// No description provided for @deleteAccountBack.
  ///
  /// In fr, this message translates to:
  /// **'RETOUR'**
  String get deleteAccountBack;

  /// No description provided for @deleteAccountNoPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun gain en attente'**
  String get deleteAccountNoPendingTitle;

  /// No description provided for @deleteAccountNoPendingBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux poursuivre la suppression sans risque de perdre des paiements en cours.'**
  String get deleteAccountNoPendingBody;

  /// No description provided for @deleteAccountContinue.
  ///
  /// In fr, this message translates to:
  /// **'CONTINUER'**
  String get deleteAccountContinue;

  /// No description provided for @deleteAccountConfirmWord.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get deleteAccountConfirmWord;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirme la suppression'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get deleteAccountPasswordLabel;

  /// No description provided for @deleteAccountReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Raison (optionnel)'**
  String get deleteAccountReasonLabel;

  /// No description provided for @deleteAccountDeletePermanently.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER DÉFINITIVEMENT'**
  String get deleteAccountDeletePermanently;

  /// No description provided for @deleteAccountDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte désactivé'**
  String get deleteAccountDoneTitle;

  /// No description provided for @deleteAccountDoneBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte sera anonymisé (données personnelles effacées) sous 30 jours. Contacte le support si tu changes d\'avis.'**
  String get deleteAccountDoneBody;

  /// No description provided for @deleteAccountBackToHome.
  ///
  /// In fr, this message translates to:
  /// **'RETOUR À L\'ACCUEIL'**
  String get deleteAccountBackToHome;

  /// No description provided for @editProfileWhatsappInvalidError.
  ///
  /// In fr, this message translates to:
  /// **'Numéro WhatsApp invalide.'**
  String get editProfileWhatsappInvalidError;

  /// No description provided for @editProfileUpdatedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour.'**
  String get editProfileUpdatedSnack;

  /// No description provided for @editProfileAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'MODIFIER'**
  String get editProfileAppBarTitle;

  /// No description provided for @editProfileSaveTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get editProfileSaveTooltip;

  /// No description provided for @editProfileColorEditableHint.
  ///
  /// In fr, this message translates to:
  /// **'Couleur modifiable ci-dessous'**
  String get editProfileColorEditableHint;

  /// No description provided for @editProfileUsernameCaption.
  ///
  /// In fr, this message translates to:
  /// **'NOM D\'UTILISATEUR'**
  String get editProfileUsernameCaption;

  /// No description provided for @editProfileUsernameMinError.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 3 caractères'**
  String get editProfileUsernameMinError;

  /// No description provided for @editProfileUsernameMaxError.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 20 caractères'**
  String get editProfileUsernameMaxError;

  /// No description provided for @editProfileCountryCaption.
  ///
  /// In fr, this message translates to:
  /// **'PAYS'**
  String get editProfileCountryCaption;

  /// No description provided for @editProfileAvatarColorCaption.
  ///
  /// In fr, this message translates to:
  /// **'COULEUR AVATAR'**
  String get editProfileAvatarColorCaption;

  /// No description provided for @editProfileWhatsappHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 07 07 07 07 07'**
  String get editProfileWhatsappHint;

  /// No description provided for @editProfileWhatsappInvalidErrorText.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide.'**
  String get editProfileWhatsappInvalidErrorText;

  /// No description provided for @editProfileSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'ENREGISTRER'**
  String get editProfileSaveButton;

  /// No description provided for @friendsAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes amis'**
  String get friendsAppBarTitle;

  /// No description provided for @friendsSearchTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get friendsSearchTooltip;

  /// No description provided for @friendsTabFriends.
  ///
  /// In fr, this message translates to:
  /// **'Amis'**
  String get friendsTabFriends;

  /// No description provided for @friendsTabRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get friendsTabRequests;

  /// No description provided for @friendsTabBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Bloqués'**
  String get friendsTabBlocked;

  /// No description provided for @friendsEmptyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ami pour le moment.'**
  String get friendsEmptyLabel;

  /// No description provided for @friendsEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Touche la loupe en haut pour en rechercher.'**
  String get friendsEmptyHint;

  /// No description provided for @friendsRemoveCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get friendsRemoveCancel;

  /// No description provided for @friendsRemoveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get friendsRemoveConfirm;

  /// No description provided for @friendsSectionReceived.
  ///
  /// In fr, this message translates to:
  /// **'REÇUES'**
  String get friendsSectionReceived;

  /// No description provided for @friendsSectionSent.
  ///
  /// In fr, this message translates to:
  /// **'ENVOYÉES'**
  String get friendsSectionSent;

  /// No description provided for @friendsNoRequests.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande.'**
  String get friendsNoRequests;

  /// No description provided for @friendsNoPendingRequests.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en attente.'**
  String get friendsNoPendingRequests;

  /// No description provided for @friendsCancelRequest.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get friendsCancelRequest;

  /// No description provided for @friendsBlockedEmptyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur bloqué.'**
  String get friendsBlockedEmptyLabel;

  /// No description provided for @friendsUnblockAction.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer'**
  String get friendsUnblockAction;

  /// No description provided for @friendsSearchAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get friendsSearchAppBarTitle;

  /// No description provided for @friendsSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get friendsSearchHint;

  /// No description provided for @friendsSearchPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Tape au moins 2 caractères pour chercher.'**
  String get friendsSearchPrompt;

  /// No description provided for @matchHistoryAppBarLoadingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get matchHistoryAppBarLoadingTitle;

  /// No description provided for @matchHistoryAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'HISTORIQUE'**
  String get matchHistoryAppBarTitle;

  /// No description provided for @matchHistoryError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ton historique. Vérifie ta connexion.'**
  String get matchHistoryError;

  /// No description provided for @matchHistoryFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get matchHistoryFilterAll;

  /// No description provided for @matchHistoryFilterWins.
  ///
  /// In fr, this message translates to:
  /// **'V'**
  String get matchHistoryFilterWins;

  /// No description provided for @matchHistoryFilterLosses.
  ///
  /// In fr, this message translates to:
  /// **'D'**
  String get matchHistoryFilterLosses;

  /// No description provided for @matchHistoryFilterOngoing.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get matchHistoryFilterOngoing;

  /// No description provided for @matchHistoryEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match'**
  String get matchHistoryEmptyTitle;

  /// No description provided for @matchHistoryEmptyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Tes matchs apparaîtront ici dès la première compétition.'**
  String get matchHistoryEmptyDescription;

  /// No description provided for @matchHistoryOpponentFallback.
  ///
  /// In fr, this message translates to:
  /// **'Adversaire'**
  String get matchHistoryOpponentFallback;

  /// No description provided for @playerProfileUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Profil indisponible. Reconnecte-toi.'**
  String get playerProfileUnavailable;

  /// No description provided for @playerProfileSuccessHeader.
  ///
  /// In fr, this message translates to:
  /// **'🏆 SUCCÈS'**
  String get playerProfileSuccessHeader;

  /// No description provided for @playerProfileRecentMatchesHeader.
  ///
  /// In fr, this message translates to:
  /// **'MATCHS RÉCENTS'**
  String get playerProfileRecentMatchesHeader;

  /// No description provided for @playerProfileSettingsButton.
  ///
  /// In fr, this message translates to:
  /// **'PARAMÈTRES'**
  String get playerProfileSettingsButton;

  /// No description provided for @playerProfileSignOutButton.
  ///
  /// In fr, this message translates to:
  /// **'SE DÉCONNECTER'**
  String get playerProfileSignOutButton;

  /// No description provided for @playerProfileJoinedPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Inscrit en'**
  String get playerProfileJoinedPrefix;

  /// No description provided for @playerProfileTierBronze.
  ///
  /// In fr, this message translates to:
  /// **'🥉 BRONZE'**
  String get playerProfileTierBronze;

  /// No description provided for @playerProfileEditTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get playerProfileEditTooltip;

  /// No description provided for @playerProfileStatWins.
  ///
  /// In fr, this message translates to:
  /// **'Victoires'**
  String get playerProfileStatWins;

  /// No description provided for @playerProfileStatLosses.
  ///
  /// In fr, this message translates to:
  /// **'Défaites'**
  String get playerProfileStatLosses;

  /// No description provided for @playerProfileStatWinRate.
  ///
  /// In fr, this message translates to:
  /// **'Win rate'**
  String get playerProfileStatWinRate;

  /// No description provided for @playerProfileNoCompletedMatches.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match complété pour le moment.'**
  String get playerProfileNoCompletedMatches;

  /// No description provided for @playerProfileFriendsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes amis'**
  String get playerProfileFriendsTitle;

  /// No description provided for @playerProfileNoFriends.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ami pour le moment'**
  String get playerProfileNoFriends;

  /// No description provided for @playerProfileReferralTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon parrainage'**
  String get playerProfileReferralTitle;

  /// No description provided for @playerProfileReferralCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code parrainage copié'**
  String get playerProfileReferralCodeCopied;

  /// No description provided for @playerProfileReferralCodeGenerating.
  ///
  /// In fr, this message translates to:
  /// **'Génération du code en cours…'**
  String get playerProfileReferralCodeGenerating;

  /// No description provided for @playerProfileReferralExplainer.
  ///
  /// In fr, this message translates to:
  /// **'Partage ton code pour parrainer des amis. Une fois ton quota atteint, tu accèdes automatiquement aux compétitions gratuites avec récompense conditionnée.'**
  String get playerProfileReferralExplainer;

  /// No description provided for @playerProfileResultWin.
  ///
  /// In fr, this message translates to:
  /// **'V'**
  String get playerProfileResultWin;

  /// No description provided for @playerProfileResultLoss.
  ///
  /// In fr, this message translates to:
  /// **'D'**
  String get playerProfileResultLoss;

  /// No description provided for @playerProfileResultDraw.
  ///
  /// In fr, this message translates to:
  /// **'N'**
  String get playerProfileResultDraw;

  /// No description provided for @publicProfileAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get publicProfileAppBarTitle;

  /// No description provided for @publicProfilePlayerNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Joueur introuvable.'**
  String get publicProfilePlayerNotFound;

  /// No description provided for @publicProfileRecentMatchesHeader.
  ///
  /// In fr, this message translates to:
  /// **'MATCHS RÉCENTS'**
  String get publicProfileRecentMatchesHeader;

  /// No description provided for @publicProfileCtaAddFriend.
  ///
  /// In fr, this message translates to:
  /// **'AJOUTER EN AMI'**
  String get publicProfileCtaAddFriend;

  /// No description provided for @publicProfileCtaRequestSent.
  ///
  /// In fr, this message translates to:
  /// **'DEMANDE ENVOYÉE'**
  String get publicProfileCtaRequestSent;

  /// No description provided for @publicProfileCtaCancel.
  ///
  /// In fr, this message translates to:
  /// **'ANNULER'**
  String get publicProfileCtaCancel;

  /// No description provided for @publicProfileRequestCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Demande annulée'**
  String get publicProfileRequestCancelled;

  /// No description provided for @publicProfileCtaAccept.
  ///
  /// In fr, this message translates to:
  /// **'ACCEPTER'**
  String get publicProfileCtaAccept;

  /// No description provided for @publicProfileCtaDecline.
  ///
  /// In fr, this message translates to:
  /// **'REFUSER'**
  String get publicProfileCtaDecline;

  /// No description provided for @publicProfileRequestDeclined.
  ///
  /// In fr, this message translates to:
  /// **'Demande refusée'**
  String get publicProfileRequestDeclined;

  /// No description provided for @publicProfileCtaFriend.
  ///
  /// In fr, this message translates to:
  /// **'AMI'**
  String get publicProfileCtaFriend;

  /// No description provided for @publicProfileCtaRemove.
  ///
  /// In fr, this message translates to:
  /// **'RETIRER'**
  String get publicProfileCtaRemove;

  /// No description provided for @publicProfileFriendRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Ami retiré'**
  String get publicProfileFriendRemoved;

  /// No description provided for @publicProfileCtaBlock.
  ///
  /// In fr, this message translates to:
  /// **'BLOQUER'**
  String get publicProfileCtaBlock;

  /// No description provided for @publicProfileBlockConfirmDetail.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pourrez plus échanger en chat de match.'**
  String get publicProfileBlockConfirmDetail;

  /// No description provided for @publicProfilePlayerBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Joueur bloqué'**
  String get publicProfilePlayerBlocked;

  /// No description provided for @publicProfileCtaUnblock.
  ///
  /// In fr, this message translates to:
  /// **'DÉBLOQUER'**
  String get publicProfileCtaUnblock;

  /// No description provided for @publicProfilePlayerUnblocked.
  ///
  /// In fr, this message translates to:
  /// **'Joueur débloqué'**
  String get publicProfilePlayerUnblocked;

  /// No description provided for @publicProfileCtaUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'INDISPONIBLE'**
  String get publicProfileCtaUnavailable;

  /// No description provided for @publicProfileDialogCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get publicProfileDialogCancel;

  /// No description provided for @publicProfileDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get publicProfileDialogConfirm;

  /// No description provided for @publicProfileStatsHeader.
  ///
  /// In fr, this message translates to:
  /// **'STATS'**
  String get publicProfileStatsHeader;

  /// No description provided for @publicProfileStatWin.
  ///
  /// In fr, this message translates to:
  /// **'V'**
  String get publicProfileStatWin;

  /// No description provided for @publicProfileStatLoss.
  ///
  /// In fr, this message translates to:
  /// **'D'**
  String get publicProfileStatLoss;

  /// No description provided for @publicProfileStatDraw.
  ///
  /// In fr, this message translates to:
  /// **'N'**
  String get publicProfileStatDraw;

  /// No description provided for @publicProfileWinRateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Taux de victoire'**
  String get publicProfileWinRateLabel;

  /// No description provided for @publicProfileGoalsScored.
  ///
  /// In fr, this message translates to:
  /// **'Buts marqués'**
  String get publicProfileGoalsScored;

  /// No description provided for @publicProfileGoalsConceded.
  ///
  /// In fr, this message translates to:
  /// **'Buts encaissés'**
  String get publicProfileGoalsConceded;

  /// No description provided for @publicProfileNoCompletedMatches.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match complété pour le moment.'**
  String get publicProfileNoCompletedMatches;

  /// No description provided for @publicProfileResultWin.
  ///
  /// In fr, this message translates to:
  /// **'V'**
  String get publicProfileResultWin;

  /// No description provided for @publicProfileResultLoss.
  ///
  /// In fr, this message translates to:
  /// **'D'**
  String get publicProfileResultLoss;

  /// No description provided for @publicProfileResultDraw.
  ///
  /// In fr, this message translates to:
  /// **'N'**
  String get publicProfileResultDraw;

  /// No description provided for @settingsAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'PARAMÈTRES'**
  String get settingsAppBarTitle;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In fr, this message translates to:
  /// **'PRÉFÉRENCES'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In fr, this message translates to:
  /// **'COMPTE'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'CONFIDENTIALITÉ'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsSectionHelp.
  ///
  /// In fr, this message translates to:
  /// **'AIDE & INFOS'**
  String get settingsSectionHelp;

  /// No description provided for @settingsVersionFooter.
  ///
  /// In fr, this message translates to:
  /// **'v1.0.0 · build 12'**
  String get settingsVersionFooter;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsCurrencyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get settingsCurrencyLabel;

  /// No description provided for @settingsMarketingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications marketing'**
  String get settingsMarketingTitle;

  /// No description provided for @settingsMarketingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseils, nouveaux tournois, promotions'**
  String get settingsMarketingSubtitle;

  /// No description provided for @settingsChangeEmailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer l\'email'**
  String get settingsChangeEmailTitle;

  /// No description provided for @settingsChangePasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get settingsChangePasswordTitle;

  /// No description provided for @settingsLoginMethodsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Méthodes de connexion'**
  String get settingsLoginMethodsTitle;

  /// No description provided for @settingsLoginMethodsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Google / Apple — bientôt disponible'**
  String get settingsLoginMethodsSubtitle;

  /// No description provided for @settingsNewEmailDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel email'**
  String get settingsNewEmailDialogTitle;

  /// No description provided for @settingsNewEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'nom@example.com'**
  String get settingsNewEmailHint;

  /// No description provided for @settingsDialogCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get settingsDialogCancel;

  /// No description provided for @settingsDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get settingsDialogConfirm;

  /// No description provided for @settingsEmailChangeConfirmSnack.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta boîte mail pour confirmer le changement.'**
  String get settingsEmailChangeConfirmSnack;

  /// No description provided for @settingsNewPasswordDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get settingsNewPasswordDialogTitle;

  /// No description provided for @settingsNewPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum'**
  String get settingsNewPasswordHint;

  /// No description provided for @settingsPasswordUpdatedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour.'**
  String get settingsPasswordUpdatedSnack;

  /// No description provided for @settingsDownloadDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger mes données'**
  String get settingsDownloadDataTitle;

  /// No description provided for @settingsDownloadDataExporting.
  ///
  /// In fr, this message translates to:
  /// **'Export en cours…'**
  String get settingsDownloadDataExporting;

  /// No description provided for @settingsDownloadDataSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Génère un fichier JSON de toutes tes données'**
  String get settingsDownloadDataSubtitle;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsExportSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Export réussi'**
  String get settingsExportSuccessTitle;

  /// No description provided for @settingsExportPathCopied.
  ///
  /// In fr, this message translates to:
  /// **'Chemin copié dans le presse-papier.'**
  String get settingsExportPathCopied;

  /// No description provided for @settingsExportContentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Contenu :'**
  String get settingsExportContentLabel;

  /// No description provided for @settingsDialogOk.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get settingsDialogOk;

  /// No description provided for @settingsReplayIntroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Revoir l\'introduction'**
  String get settingsReplayIntroTitle;

  /// No description provided for @settingsSupportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get settingsSupportTitle;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'ARENA V1.0 — Plateforme de tournois e-sport mobile'**
  String get settingsAboutSubtitle;

  /// No description provided for @matchOverlayContinue.
  ///
  /// In fr, this message translates to:
  /// **'▶ Continuer'**
  String get matchOverlayContinue;

  /// No description provided for @matchOverlayPauseRecording.
  ///
  /// In fr, this message translates to:
  /// **'⏸ Pause recording'**
  String get matchOverlayPauseRecording;

  /// No description provided for @matchOverlayStopForfeit.
  ///
  /// In fr, this message translates to:
  /// **'🛑 Arrêter (forfait)'**
  String get matchOverlayStopForfeit;

  /// No description provided for @recordingErrorSolutionStep1.
  ///
  /// In fr, this message translates to:
  /// **'Va dans Paramètres → Apps → ARENA'**
  String get recordingErrorSolutionStep1;

  /// No description provided for @recordingErrorSolutionStep2.
  ///
  /// In fr, this message translates to:
  /// **'Active \"Affichage par-dessus les autres apps\"'**
  String get recordingErrorSolutionStep2;

  /// No description provided for @recordingErrorSolutionStep3.
  ///
  /// In fr, this message translates to:
  /// **'Désactive le Battery Saver pour ARENA'**
  String get recordingErrorSolutionStep3;

  /// No description provided for @recordingErrorSolutionStep4.
  ///
  /// In fr, this message translates to:
  /// **'Autorise ARENA en arrière-plan'**
  String get recordingErrorSolutionStep4;

  /// No description provided for @recordingErrorAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur enregistrement'**
  String get recordingErrorAppBarTitle;

  /// No description provided for @recordingErrorHeadline.
  ///
  /// In fr, this message translates to:
  /// **'RECORDING IMPOSSIBLE'**
  String get recordingErrorHeadline;

  /// No description provided for @recordingErrorAntiCheatNotice.
  ///
  /// In fr, this message translates to:
  /// **'Sans recording, le match ne peut pas démarrer (anti-cheat).'**
  String get recordingErrorAntiCheatNotice;

  /// No description provided for @recordingErrorSolutionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'SOLUTIONS'**
  String get recordingErrorSolutionsLabel;

  /// No description provided for @recordingErrorRetryButton.
  ///
  /// In fr, this message translates to:
  /// **'↻ RÉESSAYER'**
  String get recordingErrorRetryButton;

  /// No description provided for @recordingErrorForfeitButton.
  ///
  /// In fr, this message translates to:
  /// **'🏳 FORFAIT (perdre)'**
  String get recordingErrorForfeitButton;

  /// No description provided for @recordingErrorContactSupport.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get recordingErrorContactSupport;

  /// No description provided for @recordingErrorCauseTitle.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ Cause détectée'**
  String get recordingErrorCauseTitle;

  /// No description provided for @recordingErrorCausePermissionPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Permission '**
  String get recordingErrorCausePermissionPrefix;

  /// No description provided for @recordingErrorCausePermissionSuffix.
  ///
  /// In fr, this message translates to:
  /// **' manquante.'**
  String get recordingErrorCausePermissionSuffix;

  /// No description provided for @liveStreamsAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'LIVE NOW'**
  String get liveStreamsAppBarTitle;

  /// No description provided for @liveStreamsErrorPrefixV2.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: '**
  String get liveStreamsErrorPrefixV2;

  /// No description provided for @liveStreamsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match en direct'**
  String get liveStreamsEmptyTitle;

  /// No description provided for @liveStreamsEmptyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Les diffusions live apparaissent ici dès qu\'un admin sélectionne un match pour la diffusion.'**
  String get liveStreamsEmptyDescription;

  /// No description provided for @liveStreamsBroadcastByPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Diffusé par '**
  String get liveStreamsBroadcastByPrefix;

  /// No description provided for @startStreamingAlreadyLive.
  ///
  /// In fr, this message translates to:
  /// **'Tu diffuses ce match en direct'**
  String get startStreamingAlreadyLive;

  /// No description provided for @startStreamingSelected.
  ///
  /// In fr, this message translates to:
  /// **'Ce match est sélectionné pour la diffusion live'**
  String get startStreamingSelected;

  /// No description provided for @startStreamingOpponentLive.
  ///
  /// In fr, this message translates to:
  /// **'Match diffusé en direct'**
  String get startStreamingOpponentLive;

  /// No description provided for @startStreamingStartButton.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer'**
  String get startStreamingStartButton;

  /// No description provided for @startStreamingStartedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Diffusion démarrée.'**
  String get startStreamingStartedSnack;

  /// No description provided for @watchStreamConnecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion en cours…'**
  String get watchStreamConnecting;

  /// No description provided for @watchStreamWaitingBroadcaster.
  ///
  /// In fr, this message translates to:
  /// **'En attente du diffuseur…'**
  String get watchStreamWaitingBroadcaster;

  /// No description provided for @watchStreamSpectatorChat.
  ///
  /// In fr, this message translates to:
  /// **'SPECTATOR CHAT'**
  String get watchStreamSpectatorChat;

  /// No description provided for @watchStreamChatUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Chat indisponible'**
  String get watchStreamChatUnavailable;

  /// No description provided for @watchStreamChatEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Sois le premier à commenter !'**
  String get watchStreamChatEmpty;

  /// No description provided for @watchStreamChatHint.
  ///
  /// In fr, this message translates to:
  /// **'Envoie un message…'**
  String get watchStreamChatHint;

  /// No description provided for @watchStreamLiveBadge.
  ///
  /// In fr, this message translates to:
  /// **'LIVE'**
  String get watchStreamLiveBadge;

  /// No description provided for @bannedLoadStateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'état de la requête : {error}'**
  String bannedLoadStateError(Object error);

  /// No description provided for @cguWhatsappLabel.
  ///
  /// In fr, this message translates to:
  /// **'WHATSAPP ({dialCode})'**
  String cguWhatsappLabel(Object dialCode);

  /// No description provided for @cguWhatsappHelper.
  ///
  /// In fr, this message translates to:
  /// **'Le code pays {dialCode} est ajouté automatiquement.'**
  String cguWhatsappHelper(Object dialCode);

  /// No description provided for @cguConsentRequiredSuffix.
  ///
  /// In fr, this message translates to:
  /// **'{title} *'**
  String cguConsentRequiredSuffix(Object title);

  /// No description provided for @linkAccountEmailLineNoEmail.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse e-mail de ce compte {providerLabel} est déjà utilisée par un compte ARENA.'**
  String linkAccountEmailLineNoEmail(Object providerLabel);

  /// No description provided for @linkAccountEmailLineWithEmail.
  ///
  /// In fr, this message translates to:
  /// **'{email} est déjà utilisé par un compte ARENA (mot de passe).'**
  String linkAccountEmailLineWithEmail(Object email);

  /// No description provided for @registerStepperTitle.
  ///
  /// In fr, this message translates to:
  /// **'Étape {step} / 3'**
  String registerStepperTitle(Object step);

  /// No description provided for @registerWhatsappLabel.
  ///
  /// In fr, this message translates to:
  /// **'WHATSAPP ({dialCode})'**
  String registerWhatsappLabel(Object dialCode);

  /// No description provided for @registerWhatsappHelper.
  ///
  /// In fr, this message translates to:
  /// **'Le code pays {dialCode} est ajouté automatiquement.'**
  String registerWhatsappHelper(Object dialCode);

  /// No description provided for @bracketCaption.
  ///
  /// In fr, this message translates to:
  /// **'ÉLIMINATION DIRECTE · {playerCount} JOUEURS'**
  String bracketCaption(Object playerCount);

  /// No description provided for @referralCardDescription.
  ///
  /// In fr, this message translates to:
  /// **'Tu dois parrainer {referralQuota} ami(s) pour t\'inscrire à cette compétition gratuite. Partage ton code avec eux pour qu\'ils créent leur compte ARENA.'**
  String referralCardDescription(Object referralQuota);

  /// No description provided for @referralProgressError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vérifier ta progression : {error}'**
  String referralProgressError(Object error);

  /// No description provided for @referralFriendsRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Encore {count} ami(s) à parrainer'**
  String referralFriendsRemaining(Object count);

  /// No description provided for @referralCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code {code} copié dans le presse-papier'**
  String referralCodeCopied(Object code);

  /// No description provided for @referralShareMessage.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins-moi sur ARENA ! Tournois d\'e-sport mobile gratuits avec récompenses. Utilise mon code de parrainage à l\'inscription : {code}'**
  String referralShareMessage(Object code);

  /// No description provided for @liveStreamsOthersCount.
  ///
  /// In fr, this message translates to:
  /// **'+{count} autres'**
  String liveStreamsOthersCount(Object count);

  /// No description provided for @pendingPaymentMultipleTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count} paiements en attente'**
  String pendingPaymentMultipleTitle(Object count);

  /// No description provided for @upcomingMatchesError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String upcomingMatchesError(Object error);

  /// No description provided for @upcomingMatchVsOpponent.
  ///
  /// In fr, this message translates to:
  /// **'vs {opponentName}'**
  String upcomingMatchVsOpponent(Object opponentName);

  /// No description provided for @upcomingBadgeInHours.
  ///
  /// In fr, this message translates to:
  /// **'DANS {hours}H'**
  String upcomingBadgeInHours(Object hours);

  /// No description provided for @upcomingBadgeInDays.
  ///
  /// In fr, this message translates to:
  /// **'DANS {days}J'**
  String upcomingBadgeInDays(Object days);

  /// No description provided for @upcomingPhaseRound.
  ///
  /// In fr, this message translates to:
  /// **'Round {round}'**
  String upcomingPhaseRound(Object round);

  /// No description provided for @matchRoomTitleNumbered.
  ///
  /// In fr, this message translates to:
  /// **'MATCH #{number}'**
  String matchRoomTitleNumbered(Object number);

  /// No description provided for @manualUploadFailure.
  ///
  /// In fr, this message translates to:
  /// **'Échec : {message}'**
  String manualUploadFailure(Object message);

  /// No description provided for @manualUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String manualUploadError(Object error);

  /// No description provided for @outcomeWinner.
  ///
  /// In fr, this message translates to:
  /// **'Gagnant : Joueur {winner}…'**
  String outcomeWinner(Object winner);

  /// No description provided for @outcomeResubmitError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de renvoyer : {error}'**
  String outcomeResubmitError(Object error);

  /// No description provided for @outcomeScoreShootout.
  ///
  /// In fr, this message translates to:
  /// **'TAB {pen1} — {pen2}'**
  String outcomeScoreShootout(Object pen1, Object pen2);

  /// No description provided for @matchHeaderSelfSuffix.
  ///
  /// In fr, this message translates to:
  /// **'{username} · TOI'**
  String matchHeaderSelfSuffix(Object username);

  /// No description provided for @recordingLiveStreamError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de démarrer la diffusion : {error}'**
  String recordingLiveStreamError(Object error);

  /// No description provided for @recordingPermBundleNeedsSettings.
  ///
  /// In fr, this message translates to:
  /// **'Autorise {list} dans Paramètres > Apps > ARENA'**
  String recordingPermBundleNeedsSettings(Object list);

  /// No description provided for @recordingPermBundleDenied.
  ///
  /// In fr, this message translates to:
  /// **'Autorisation {list} refusée — retape JE SUIS DANS LA ROOM'**
  String recordingPermBundleDenied(Object list);

  /// No description provided for @recordingBannerUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Recording indisponible — {error}\nTape ici pour réessayer.'**
  String recordingBannerUnavailable(Object error);

  /// No description provided for @notificationsTimeMinutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {minutes} min'**
  String notificationsTimeMinutesAgo(Object minutes);

  /// No description provided for @notificationsTimeHoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {hours} h'**
  String notificationsTimeHoursAgo(Object hours);

  /// No description provided for @mobileMoneyDialHelp.
  ///
  /// In fr, this message translates to:
  /// **'Compose ce code sur ton {method}, paie le montant exact, puis reviens ici cliquer \"J\'AI PAYÉ\".'**
  String mobileMoneyDialHelp(Object method);

  /// No description provided for @deleteAccountStepCaption.
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE {stepNum}/04 · {stepLabel}'**
  String deleteAccountStepCaption(Object stepNum, Object stepLabel);

  /// No description provided for @deleteAccountCheckErrorNote.
  ///
  /// In fr, this message translates to:
  /// **'Note: vérification non concluante (table indisponible). Détail: {checkError}'**
  String deleteAccountCheckErrorNote(Object checkError);

  /// No description provided for @deleteAccountTypeToConfirmLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tape \"{confirmWord}\" pour confirmer'**
  String deleteAccountTypeToConfirmLabel(Object confirmWord);

  /// No description provided for @editProfileWhatsappCaption.
  ///
  /// In fr, this message translates to:
  /// **'WHATSAPP ({dialCode})'**
  String editProfileWhatsappCaption(Object dialCode);

  /// No description provided for @editProfileWhatsappHelper.
  ///
  /// In fr, this message translates to:
  /// **'Le code pays {dialCode} est ajouté automatiquement.'**
  String editProfileWhatsappHelper(Object dialCode);

  /// No description provided for @friendsErrorMessage.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String friendsErrorMessage(Object error);

  /// No description provided for @friendsRemoveDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {username} ?'**
  String friendsRemoveDialogTitle(Object username);

  /// No description provided for @friendsAcceptedSnack.
  ///
  /// In fr, this message translates to:
  /// **'{username} est maintenant ton ami'**
  String friendsAcceptedSnack(Object username);

  /// No description provided for @friendsUnblockedSnack.
  ///
  /// In fr, this message translates to:
  /// **'{username} débloqué'**
  String friendsUnblockedSnack(Object username);

  /// No description provided for @friendsSearchErrorMessage.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String friendsSearchErrorMessage(Object error);

  /// No description provided for @playerProfileError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String playerProfileError(Object error);

  /// No description provided for @playerProfileStatsError.
  ///
  /// In fr, this message translates to:
  /// **'Stats indisponibles ({error})'**
  String playerProfileStatsError(Object error);

  /// No description provided for @playerProfileMatchRowError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String playerProfileMatchRowError(Object error);

  /// No description provided for @playerProfileFriendsCountSingular.
  ///
  /// In fr, this message translates to:
  /// **'{friendsCount} ami'**
  String playerProfileFriendsCountSingular(Object friendsCount);

  /// No description provided for @playerProfileFriendsCountPlural.
  ///
  /// In fr, this message translates to:
  /// **'{friendsCount} amis'**
  String playerProfileFriendsCountPlural(Object friendsCount);

  /// No description provided for @playerProfileReferralCountSingular.
  ///
  /// In fr, this message translates to:
  /// **'{count} invité'**
  String playerProfileReferralCountSingular(Object count);

  /// No description provided for @playerProfileReferralCountPlural.
  ///
  /// In fr, this message translates to:
  /// **'{count} invités'**
  String playerProfileReferralCountPlural(Object count);

  /// No description provided for @publicProfileError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String publicProfileError(Object error);

  /// No description provided for @publicProfileRequestSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée à {username}'**
  String publicProfileRequestSent(Object username);

  /// No description provided for @publicProfileNowFriend.
  ///
  /// In fr, this message translates to:
  /// **'{username} est maintenant ton ami'**
  String publicProfileNowFriend(Object username);

  /// No description provided for @publicProfileRemoveConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {username} ?'**
  String publicProfileRemoveConfirmTitle(Object username);

  /// No description provided for @publicProfileBlockConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer {username} ?'**
  String publicProfileBlockConfirmTitle(Object username);

  /// No description provided for @publicProfileWinRateValue.
  ///
  /// In fr, this message translates to:
  /// **'{pct}% ({total} matchs)'**
  String publicProfileWinRateValue(Object pct, Object total);

  /// No description provided for @publicProfileMatchRowError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String publicProfileMatchRowError(Object error);

  /// No description provided for @settingsMarketingError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String settingsMarketingError(Object error);

  /// No description provided for @settingsEmailChangeError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String settingsEmailChangeError(Object error);

  /// No description provided for @settingsPasswordChangeError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String settingsPasswordChangeError(Object error);

  /// No description provided for @settingsExportError.
  ///
  /// In fr, this message translates to:
  /// **'Export impossible : {error}'**
  String settingsExportError(Object error);

  /// No description provided for @settingsExportFileLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fichier ({sizeKb} Ko) :'**
  String settingsExportFileLabel(Object sizeKb);

  /// No description provided for @startStreamingErrorSnack.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String startStreamingErrorSnack(Object error);

  /// No description provided for @watchStreamFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec : {reason}'**
  String watchStreamFailed(Object reason);

  /// No description provided for @watchStreamChatSendError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur envoi : {error}'**
  String watchStreamChatSendError(Object error);

  /// No description provided for @watchStreamViewersWatching.
  ///
  /// In fr, this message translates to:
  /// **'{viewers} watching'**
  String watchStreamViewersWatching(Object viewers);

  /// No description provided for @authErrInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect.'**
  String get authErrInvalidCredentials;

  /// No description provided for @authErrEmailAlreadyRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cet email.'**
  String get authErrEmailAlreadyRegistered;

  /// No description provided for @authErrWeakPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop faible : 8 caractères minimum.'**
  String get authErrWeakPassword;

  /// No description provided for @authErrEmailNotConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre inscription via le lien reçu par email.'**
  String get authErrEmailNotConfirmed;

  /// No description provided for @authErrUserBanned.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est suspendu. Contactez le support.'**
  String get authErrUserBanned;

  /// No description provided for @authErrWrongApp.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est administrateur. Utilisez l\'application ARENA Admin.'**
  String get authErrWrongApp;

  /// No description provided for @authErrNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet. Vérifiez votre réseau et réessayez.'**
  String get authErrNetwork;

  /// No description provided for @authErrRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessayez dans quelques minutes.'**
  String get authErrRateLimited;

  /// No description provided for @authErrInvalidInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation invalide, expiré ou déjà utilisé.'**
  String get authErrInvalidInvitation;

  /// No description provided for @authErrInvalidTotp.
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres incorrect.'**
  String get authErrInvalidTotp;

  /// No description provided for @authErrTotpReplay.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a déjà été utilisé. Attendez le suivant.'**
  String get authErrTotpReplay;

  /// No description provided for @authErrAdminLocked.
  ///
  /// In fr, this message translates to:
  /// **'Compte verrouillé après 3 tentatives. Réessayez dans 30 minutes.'**
  String get authErrAdminLocked;

  /// No description provided for @authErrBackendUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Service momentanément indisponible. Réessayez plus tard.'**
  String get authErrBackendUnavailable;

  /// No description provided for @authErrUsernameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce pseudo est déjà utilisé. Choisissez-en un autre.'**
  String get authErrUsernameTaken;

  /// No description provided for @authErrSsoCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Connexion annulée.'**
  String get authErrSsoCancelled;

  /// No description provided for @authErrSsoIdToken.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre réseau et réessayez.'**
  String get authErrSsoIdToken;

  /// No description provided for @authErrSsoConfig.
  ///
  /// In fr, this message translates to:
  /// **'Connexion indisponible pour le moment. Contactez le support.'**
  String get authErrSsoConfig;

  /// No description provided for @authErrInvalidResetCode.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect. Vérifiez votre email.'**
  String get authErrInvalidResetCode;

  /// No description provided for @authErrExpiredResetCode.
  ///
  /// In fr, this message translates to:
  /// **'Code expiré. Demandez un nouveau code.'**
  String get authErrExpiredResetCode;

  /// No description provided for @authErrUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get authErrUnknown;

  /// No description provided for @matchStepCodeRoom.
  ///
  /// In fr, this message translates to:
  /// **'Code room'**
  String get matchStepCodeRoom;

  /// No description provided for @matchStepOpponentJoining.
  ///
  /// In fr, this message translates to:
  /// **'Adversaire rejoint'**
  String get matchStepOpponentJoining;

  /// No description provided for @matchStepInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Match en cours'**
  String get matchStepInProgress;

  /// No description provided for @matchStepResult.
  ///
  /// In fr, this message translates to:
  /// **'Résultat'**
  String get matchStepResult;

  /// No description provided for @activeCompetitionsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune compétition active pour ce filtre.'**
  String get activeCompetitionsEmpty;

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get filterAll;

  /// No description provided for @filterFree.
  ///
  /// In fr, this message translates to:
  /// **'Gratuites'**
  String get filterFree;

  /// No description provided for @filterPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payantes'**
  String get filterPaid;

  /// No description provided for @filterUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get filterUpcoming;

  /// No description provided for @filterOngoing.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get filterOngoing;

  /// No description provided for @filterCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get filterCompleted;

  /// No description provided for @compFormatSingleElim.
  ///
  /// In fr, this message translates to:
  /// **'Élimination directe'**
  String get compFormatSingleElim;

  /// No description provided for @compFormatGroupsKnockout.
  ///
  /// In fr, this message translates to:
  /// **'Poules + élimination'**
  String get compFormatGroupsKnockout;

  /// No description provided for @compFormatRoundRobin.
  ///
  /// In fr, this message translates to:
  /// **'Round robin'**
  String get compFormatRoundRobin;

  /// No description provided for @matchStepWord.
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE'**
  String get matchStepWord;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
