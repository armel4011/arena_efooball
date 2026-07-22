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
      'Bienvenue sur ARENA, la plateforme #1 de tournois eFootball, Jeu de Dames et FC Mobile en Afrique.';

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
  String get authEmailLabel => 'EMAIL';

  @override
  String get authEmailHint => 'joueur@arena.app';

  @override
  String get authPasswordLabel => 'MOT DE PASSE';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authOr => 'OU';

  @override
  String get authContinueGoogle => 'Continuer avec Google';

  @override
  String get authSignUp => 'S\'inscrire';

  @override
  String get loginTitle => 'CONNEXION';

  @override
  String get loginSubtitle => 'Continue ton parcours sur ARENA.';

  @override
  String get loginSubmit => 'SE CONNECTER';

  @override
  String get loginNoAccount => 'Pas encore inscrit ? ';

  @override
  String get forgotPasswordTitle => 'MOT DE PASSE OUBLIÉ';

  @override
  String get forgotPasswordSubtitle =>
      'Entre l\'adresse e-mail liée à ton compte, on t\'envoie un code à 6 chiffres pour réinitialiser ton mot de passe.';

  @override
  String get forgotPasswordSubmit => 'ENVOYER LE CODE';

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

  @override
  String get bannedMinLengthError =>
      'Détaillez votre requête (10 caractères minimum).';

  @override
  String get bannedSendError =>
      'Échec de l\'envoi. Vérifiez votre connexion et réessayez.';

  @override
  String get bannedAppBarTitle => 'Compte suspendu';

  @override
  String get bannedSignOut => 'SE DÉCONNECTER';

  @override
  String get bannedArenaRequestTitle => '📨 ARENA REQUÊTE';

  @override
  String get bannedArenaRequestIntro =>
      'Explique pourquoi tu penses que ton bannissement devrait être reconsidéré. L\'équipe Arena Requête analyse chaque demande sous 48 heures.';

  @override
  String get bannedMessageHint => 'Décris ton cas (10 caractères minimum)…';

  @override
  String get bannedSendingLabel => 'ENVOI…';

  @override
  String get bannedSendRequestLabel => '✉️ ENVOYER MA REQUÊTE';

  @override
  String get bannedPermanentTitle => 'Compte définitivement banni';

  @override
  String get bannedPermanentBody =>
      'Tu as été reconnu coupable d\'un litige à 3 reprises. Conformément à la règle ARENA, ton compte est désactivé.';

  @override
  String get bannedOverdueTitle => 'Analyse en retard (> 48h)';

  @override
  String get bannedPendingTitle => 'Requête en cours d\'analyse';

  @override
  String get bannedOverdueBody =>
      'Ta requête est ouverte depuis plus de 48 heures. L\'équipe Arena Requête est notifiée — merci pour ta patience.';

  @override
  String get bannedPendingBody =>
      'L\'équipe Arena Requête a 48 heures pour analyser ta demande. Tu seras notifié dès qu\'une décision est prise.';

  @override
  String get bannedYourMessageLabel => 'Ton message';

  @override
  String get bannedRejectedTitle => '❌ Requête précédente refusée';

  @override
  String get bannedReasonLabel => 'Motif';

  @override
  String get bannedRejectedBody =>
      'Tu peux soumettre une nouvelle requête avec des éléments supplémentaires ci-dessous.';

  @override
  String get bannedApprovedTitle => '✅ Réintégration approuvée';

  @override
  String get bannedApprovedBody =>
      'Bon retour sur ARENA ! Reconnecte-toi pour accéder à ton compte.';

  @override
  String get cguCompleteProfileTitle => 'COMPLÈTE TON\nPROFIL';

  @override
  String get cguCompleteProfileSubtitle =>
      'Quelques infos manquantes avant de pouvoir jouer.';

  @override
  String get cguWhatsappHint => 'Ex. 07 07 07 07 07';

  @override
  String get cguWhatsappInvalid => 'Numéro WhatsApp invalide.';

  @override
  String get cguReadTermsLink => 'Lire les Conditions Générales d\'Utilisation';

  @override
  String get cguReadPrivacyLink => 'Lire la politique de confidentialité';

  @override
  String get cguAcceptTermsConsent =>
      'J\'accepte les CGU et la politique de confidentialité';

  @override
  String get cguMarketingConsent =>
      'J\'accepte de recevoir des informations sur les nouveaux tournois (optionnel)';

  @override
  String get cguContinueButton => 'CONTINUER';

  @override
  String get cguRefuseSignOut => 'Refuser et se déconnecter';

  @override
  String get cguDocPlaceholderBody =>
      'La version complète sera affichée ici (PHASE 9 — AboutPage + WebView vers les docs hébergés).';

  @override
  String get cguDialogOk => 'OK';

  @override
  String get cguCountryLabel => 'PAYS';

  @override
  String get linkAccountDefaultProvider => 'Google';

  @override
  String get linkAccountAppBarTitle => 'Lier les comptes';

  @override
  String get linkAccountExistsTitle => 'Compte déjà existant';

  @override
  String get linkAccountExistingMethodsLabel => 'MÉTHODES EXISTANTES';

  @override
  String get linkAccountEmailPasswordMethod => 'Email + mot de passe';

  @override
  String get linkAccountChooseContinue =>
      'Choisis comment continuer ci-dessous.';

  @override
  String get linkAccountLinkBothButton => '🔗 LIER LES DEUX COMPTES';

  @override
  String get linkAccountPhaseSnack =>
      'Disponible en PHASE 2.3 (social login Google/Apple).';

  @override
  String get linkAccountLoginPasswordButton => 'ME CONNECTER AVEC MOT DE PASSE';

  @override
  String get linkAccountCancelButton => 'Annuler';

  @override
  String get registerEmailRequired => 'Email requis.';

  @override
  String get registerEmailInvalid => 'Format email invalide.';

  @override
  String get registerPasswordTooShort => '8 caractères minimum.';

  @override
  String get registerPasswordMismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get registerAccountStepTitle => 'CRÉE\nTON COMPTE';

  @override
  String get registerAccountStepSubtitle =>
      'Email + mot de passe (8 caractères minimum).';

  @override
  String get registerGoogleSignUp => 'S\'inscrire avec Google';

  @override
  String get registerEmailLabel => 'EMAIL';

  @override
  String get registerPasswordLabel => 'MOT DE PASSE';

  @override
  String get registerPasswordConfirmLabel => 'CONFIRMER LE MOT DE PASSE';

  @override
  String get registerAccountContinueButton => 'CONTINUER';

  @override
  String get registerProfileStepTitle => 'TON\nPROFIL';

  @override
  String get registerProfileStepSubtitle =>
      'Pseudo + pays + acceptation des CGU.';

  @override
  String get registerUsernameLabel => 'PSEUDO';

  @override
  String get registerUsernameHint => '3 à 20 caractères';

  @override
  String get registerWhatsappHint => 'Ex. 07 07 07 07 07';

  @override
  String get registerWhatsappInvalid => 'Numéro WhatsApp invalide.';

  @override
  String get registerAvatarColorLabel => 'COULEUR D\'AVATAR';

  @override
  String get registerReferralCodeLabel => 'CODE DE PARRAINAGE (OPTIONNEL)';

  @override
  String get registerReferralCodeHint => 'Ex. ARN-3F9A';

  @override
  String get registerReferralCodeHelper =>
      'Le code d\'un ami ARENA. Te permet d\'apparaître dans ses parrainages — laisser vide si tu n\'en as pas.';

  @override
  String get registerCguConsent =>
      'J\'accepte les Conditions Générales d\'Utilisation';

  @override
  String get registerPrivacyConsent =>
      'J\'accepte la Politique de Confidentialité';

  @override
  String get registerMarketingConsent =>
      'J\'accepte de recevoir les communications marketing (optionnel)';

  @override
  String get registerCreateAccountButton => 'CRÉER MON COMPTE';

  @override
  String get registerCountryLabel => 'PAYS';

  @override
  String get registerCountryHint => 'Choisis ton pays';

  @override
  String get registerSuccessTitle => 'COMPTE\nCRÉÉ';

  @override
  String get registerSuccessSubtitle =>
      'Bienvenue sur ARENA. Tu es prêt à rejoindre les tournois.';

  @override
  String get registerSuccessContinueButton => 'CONTINUER';

  @override
  String get registerOrDivider => 'OU';

  @override
  String get resetCodeNewCodeSent => 'Nouveau code envoyé.';

  @override
  String get resetCodeTitle => 'VÉRIFICATION';

  @override
  String get resetCodeSubtitle => 'Saisis le code à 6 chiffres envoyé à';

  @override
  String get resetCodeFieldLabel => 'CODE';

  @override
  String get resetCodeVerifyButton => 'VÉRIFIER';

  @override
  String get resetCodeResending => 'Envoi en cours…';

  @override
  String get resetCodeResendButton => 'Renvoyer le code';

  @override
  String get resetPwPasswordRequired => 'Mot de passe requis';

  @override
  String get resetPwMinChars => 'Minimum 8 caractères';

  @override
  String get resetPwPasswordsDontMatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get resetPwTitle => 'NOUVEAU MOT DE PASSE';

  @override
  String get resetPwSubtitle =>
      'Choisis un mot de passe solide. Il sera utilisé pour ta prochaine connexion.';

  @override
  String get resetPwNewPasswordLabel => 'NOUVEAU MOT DE PASSE';

  @override
  String get resetPwNewPasswordHint => 'Au moins 8 caractères';

  @override
  String get resetPwConfirmLabel => 'CONFIRMER';

  @override
  String get resetPwConfirmHint => 'Retape ton mot de passe';

  @override
  String get resetPwUpdateButton => 'METTRE À JOUR';

  @override
  String get resetPwSuccessTitle => 'MOT DE PASSE MIS À JOUR';

  @override
  String get resetPwSuccessSubtitle =>
      'Tu peux maintenant te connecter avec ton nouveau mot de passe.';

  @override
  String get resetPwLoginButton => 'SE CONNECTER';

  @override
  String get splashTagline => 'e-sport panafricain';

  @override
  String get splashLoginButton => 'SE CONNECTER';

  @override
  String get splashCreateAccountButton => 'CRÉER UN COMPTE';

  @override
  String get splashVersionLabel => 'v1.0 — ARENA Cameroun';

  @override
  String get splashStatPlayers => 'joueurs';

  @override
  String get splashStatTournaments => 'tournois';

  @override
  String get splashStatXaf => 'XAF';

  @override
  String get bracketEmptyTitle => 'Bracket pas encore généré';

  @override
  String get bracketEmptyDescription =>
      'Le bracket s\'affichera ici dès que l\'admin aura clôturé les inscriptions et lancé le tirage.';

  @override
  String get bracketZoomHint => '↔ pince pour zoomer · glisse pour naviguer';

  @override
  String get groupStandingsEmptyTitle => 'Pas encore de classement';

  @override
  String get groupStandingsEmptyDescription =>
      'Le classement s\'affichera dès que les premières rencontres seront jouées.';

  @override
  String get groupStandingsColPlayer => 'JOUEUR';

  @override
  String get groupStandingsColPlayed => 'J';

  @override
  String get groupStandingsColWins => 'V';

  @override
  String get groupStandingsColDraws => 'N';

  @override
  String get groupStandingsColLosses => 'D';

  @override
  String get groupStandingsColGoalsFor => 'BP';

  @override
  String get groupStandingsColGoalsAgainst => 'BC';

  @override
  String get groupStandingsColDiff => 'Diff';

  @override
  String get groupStandingsColPoints => 'Pts';

  @override
  String get groupStandingsPlayerFallback => 'Joueur ';

  @override
  String get callPlaceCallFailed => 'Impossible de lancer l\'appel.';

  @override
  String get callNoAnswer => 'Pas de réponse.';

  @override
  String get callDeclined => 'Appel refusé.';

  @override
  String get callEnded => 'Appel terminé.';

  @override
  String get callStatusConnecting => 'Connexion en cours…';

  @override
  String get callStatusRinging => 'Sonnerie…';

  @override
  String get callStatusConnected => 'En appel';

  @override
  String get callStatusEnded => 'Appel terminé';

  @override
  String get callStatusFailed => 'Échec de l\'appel';

  @override
  String get callControlUnmute => 'Réactiver';

  @override
  String get callControlMute => 'Couper';

  @override
  String get callControlSpeaker => 'Haut-parleur';

  @override
  String get callControlEarpiece => 'Écouteur';

  @override
  String get callControlClose => 'Fermer';

  @override
  String get chatOfflineQueued =>
      'Hors ligne — message envoyé à la reconnexion.';

  @override
  String get chatSendFailed => 'Impossible d\'envoyer : ';

  @override
  String get chatPickerUnavailable => 'Picker indisponible : ';

  @override
  String get chatUploadFailed => 'Échec upload : ';

  @override
  String get chatAttachGallery => 'Choisir dans la galerie';

  @override
  String get chatAttachCamera => 'Prendre une photo';

  @override
  String get chatDeleteDialogTitle => 'Supprimer ce message ?';

  @override
  String get chatDeleteDialogContent =>
      'Ce message sera marqué comme supprimé. L\'autre joueur verra \"Message supprimé\" à la place.';

  @override
  String get chatDeleteDialogCancel => 'Annuler';

  @override
  String get chatDeleteDialogConfirm => 'SUPPRIMER';

  @override
  String get chatGenericFailure => 'Échec : ';

  @override
  String get chatEmptyTitle => 'Pas encore de message';

  @override
  String get chatEmptyDescription => 'Sois le premier à écrire ici.';

  @override
  String get chatAppBarUsernameFallback => 'Joueur';

  @override
  String get chatAppBarTyping => 'typing…';

  @override
  String get chatAppBarOnline => 'en ligne';

  @override
  String get chatAppBarOffline => 'hors ligne';

  @override
  String get chatMessageDeleted => 'Message supprimé';

  @override
  String get chatMediaUnsupported => 'Media: ';

  @override
  String get chatRoomCodeCopied => 'Code copié';

  @override
  String get chatRoomCodeTapToCopy => 'tap pour copier';

  @override
  String get chatInputTooltipKeyboard => 'Clavier';

  @override
  String get chatInputTooltipEmoji => 'Emoji';

  @override
  String get chatInputTooltipAttach => 'Joindre une image';

  @override
  String get chatInputHint => 'Message…';

  @override
  String get friendChatOfflineQueued =>
      'Hors ligne — message envoyé à la reconnexion.';

  @override
  String get friendChatSendFailed => 'Impossible : ';

  @override
  String get friendChatPickerFailed => 'Picker : ';

  @override
  String get friendChatGenericFailure => 'Échec : ';

  @override
  String get friendChatAttachGallery => 'Choisir dans la galerie';

  @override
  String get friendChatAttachCamera => 'Prendre une photo';

  @override
  String get friendChatDeleteDialogTitle => 'Supprimer ce message ?';

  @override
  String get friendChatDeleteDialogContent =>
      'Ton ami verra «Message supprimé» à la place.';

  @override
  String get friendChatDeleteDialogCancel => 'Annuler';

  @override
  String get friendChatDeleteDialogConfirm => 'SUPPRIMER';

  @override
  String get friendChatEmptyTitle => 'Démarre la conversation';

  @override
  String get friendChatEmptyDescription =>
      'Envoie un premier message à ton ami.';

  @override
  String get friendChatUsernameFallback => 'Ami';

  @override
  String get friendChatSubtitleFriend => 'Ami';

  @override
  String get inboxAppBarTitle => 'MESSAGES';

  @override
  String get inboxComposeTooltip => 'Rechercher un joueur';

  @override
  String get inboxTabDirect => 'DIRECT';

  @override
  String get inboxTabTournaments => 'TOURNOIS';

  @override
  String get inboxNoConversationsTitle => 'Aucune conversation';

  @override
  String get inboxNoConversationsDesc =>
      'Reconnecte-toi pour voir tes conversations.';

  @override
  String get inboxSectionFriends => 'AMIS';

  @override
  String get inboxSectionMatches => 'MATCHS';

  @override
  String get inboxEmptyHint =>
      'Aucune conversation pour l\'instant.\nOuvre une discussion depuis la salle de match\nou depuis l\'onglet Amis.';

  @override
  String get inboxDeleteDialogTitle => 'Supprimer cette conversation ?';

  @override
  String get inboxDeleteDialogContent =>
      'La conversation sera retirée de ton inbox. Tu peux la retrouver en rouvrant le chat plus tard.';

  @override
  String get inboxDeleteCancel => 'Annuler';

  @override
  String get inboxDeleteConfirm => 'SUPPRIMER';

  @override
  String get inboxDeleteFailure => 'Échec : ';

  @override
  String get inboxOpponentWaiting => 'En attente';

  @override
  String get inboxMatchPending => 'En attente d\'adversaire';

  @override
  String get inboxMatchScheduled => 'Match programmé';

  @override
  String get inboxMatchReady => 'Code de salon partagé';

  @override
  String get inboxMatchInProgress => 'En cours — appuie pour discuter';

  @override
  String get inboxMatchScorePending => 'En attente du score';

  @override
  String get inboxMatchAwaitingValidation => 'Validation du score';

  @override
  String get inboxMatchDisputed => 'Score contesté — admin en cours';

  @override
  String get inboxMatchCompleted => 'Match terminé';

  @override
  String get inboxMatchCancelled => 'Match annulé';

  @override
  String get inboxMatchForfeited => 'Forfait';

  @override
  String get inboxTimeSoon => 'Bientôt';

  @override
  String get inboxCompRegistrationOpen => 'Inscriptions ouvertes';

  @override
  String get inboxCompRegistrationClosed => 'Inscriptions fermées';

  @override
  String get inboxCompOngoing => 'En cours';

  @override
  String get inboxCompCompleted => 'Terminée';

  @override
  String get inboxCompCancelled => 'Annulée';

  @override
  String get inboxCompDraft => 'Brouillon';

  @override
  String get inboxNoActiveCompTitle => 'Aucune compétition active';

  @override
  String get inboxNoActiveCompDesc =>
      'Les fils de discussion liés à tes compétitions apparaîtront ici dès que tu rejoindras un tournoi.';

  @override
  String get inboxWaitingTitle => 'En attente';

  @override
  String get inboxWaitingDesc =>
      'Tu es inscrit mais les compétitions n\'ont pas encore été chargées.';

  @override
  String get inboxChatWithFriend => 'Discuter avec ton ami';

  @override
  String get inboxFriendDefaultName => 'Ami';

  @override
  String get inboxArenaTeam => 'Équipe ARENA';

  @override
  String get inboxArenaOfficialBadge => 'OFFICIEL';

  @override
  String get inboxArenaPreviewDefault =>
      'Support, annonces et infos officielles';

  @override
  String get inboxArenaPreviewImage => '📷 Image';

  @override
  String get inboxTimeJustNow => 'à l\'instant';

  @override
  String get inboxErrorPrefix => 'Erreur : ';

  @override
  String get compDetailAppBarTitle => 'COMPÉTITION';

  @override
  String get compDetailNotFoundTitle => 'Compétition introuvable';

  @override
  String get compDetailNotFoundDesc =>
      'Elle a peut-être été supprimée par un admin.';

  @override
  String get compDetailStatusDraft => 'BROUILLON';

  @override
  String get compDetailStatusOpen => 'OUVERT';

  @override
  String get compDetailStatusFull => 'INSCRIPTIONS CLOSES';

  @override
  String get compDetailStatusOngoing => 'EN COURS';

  @override
  String get compDetailStatusCompleted => 'TERMINÉ';

  @override
  String get compDetailStatusCancelled => 'ANNULÉ';

  @override
  String get compDetailCtaRegisterFree => 'S\'INSCRIRE GRATUITEMENT';

  @override
  String get compDetailCtaRegisterPaidPrefix => 'S\'INSCRIRE · ';

  @override
  String get compDetailRegistrationsClosed => 'INSCRIPTIONS FERMÉES';

  @override
  String get compDetailGatedLockNotice =>
      '🔒 Bracket, matches en direct et chat 1-on-1 sont réservés aux joueurs inscrits.';

  @override
  String get compDetailPrizeFree => 'GRATUIT';

  @override
  String get compDetailPrizeFreeLabel => 'INSCRIPTION LIBRE';

  @override
  String get compDetailPrizeToWinLabel => 'À GAGNER';

  @override
  String get compDetailTabInfos => 'INFOS';

  @override
  String get compDetailTabParticipants => 'PARTICIP.';

  @override
  String get compDetailTabNextMatch => 'PROCHAIN MATCH';

  @override
  String get compDetailTabCalendar => 'CALENDRIER';

  @override
  String get compDetailTabRanking => 'CLASSEMENT';

  @override
  String get compScheduleEmptyTitle => 'Aucun match programmé';

  @override
  String get compScheduleEmptyDescription =>
      'Le calendrier apparaîtra dès que l\'organisateur aura généré le tableau.';

  @override
  String get compScheduleUnscheduled => 'À programmer';

  @override
  String get compDetailParticipantsTitle => 'Liste des participants';

  @override
  String get compDetailParticipantsDesc =>
      'La liste des inscrits avec avatars et stats arrivera ici. Source : table `registrations`.';

  @override
  String get compDetailInfoPrizeLabel => 'Récompense';

  @override
  String get compDetailInfoPrizeNone => 'Aucune';

  @override
  String get compDetailInfoFeeLabel => 'Frais d\'inscription';

  @override
  String get compDetailInfoFeeFree => 'Gratuit';

  @override
  String get compDetailInfoFormatLabel => 'Format';

  @override
  String get compDetailInfoStartLabel => 'Démarrage';

  @override
  String get compDetailInfoCapacityLabel => 'Capacité';

  @override
  String get compDetailInfoCapacitySuffix => ' joueurs';

  @override
  String get compDetailDescriptionHeader => '📝 DESCRIPTION';

  @override
  String get compDetailRankingNoParticipantTitle => 'Aucun participant';

  @override
  String get compDetailRankingNoParticipantDesc =>
      'Personne n\'est encore inscrit à cette compétition.';

  @override
  String get compDetailRankingNotPublishedTitle =>
      'Classement pas encore publié';

  @override
  String get compDetailRankingNotPublishedDesc =>
      'Les organisateurs publieront le classement final une fois la compétition terminée.';

  @override
  String get compDetailRankingUnranked => 'Non classé';

  @override
  String get compDetailRankingPlaceSuffix => ' place';

  @override
  String get compDetailFormatSingleElim => 'Élimination directe';

  @override
  String get compDetailFormatGroupsKnockout => 'Poules + élimination';

  @override
  String get compDetailFormatRoundRobin => 'Round robin';

  @override
  String get compDetailTabBracket => 'BRACKET';

  @override
  String get compDetailTabGroups => 'POULES';

  @override
  String get compListReset => 'Réinitialiser';

  @override
  String get compListEmptyTitleAll => 'Aucune compétition';

  @override
  String get compListEmptyTitleGamePrefix => 'Aucune compétition sur ';

  @override
  String get compListEmptyDesc =>
      'De nouveaux tournois sont publiés chaque semaine. Reviens bientôt !';

  @override
  String get compListFilterStatus => 'Statut';

  @override
  String get compListFilterPricing => 'Tarif';

  @override
  String get compListFormatSingleElim => 'Élimination directe';

  @override
  String get compListFormatGroupsKnockout => 'Poules + élimination';

  @override
  String get compListFormatRoundRobin => 'Round robin';

  @override
  String get regConfirmAppBarTitle => 'CHECKOUT';

  @override
  String get regConfirmPrizeDistribution => 'RÉPARTITION DES GAINS';

  @override
  String get regConfirmDownloadGame => 'TÉLÉCHARGER LE JEU';

  @override
  String get regConfirmCtaReferralsInsufficient =>
      '👥 PARRAINAGES INSUFFISANTS';

  @override
  String get regConfirmCtaRegisterFree => 'M\'INSCRIRE GRATUITEMENT';

  @override
  String get regConfirmCtaProceedPaymentPrefix => 'PROCÉDER AU PAIEMENT · ';

  @override
  String get regConfirmCtaXafSuffix => ' XAF';

  @override
  String get regConfirmCancel => 'Annuler';

  @override
  String get regConfirmNoSession => 'Aucune session — inscription impossible.';

  @override
  String get regConfirmOfflineQueued =>
      'Hors ligne — inscription enregistrée, confirmée à la reconnexion.';

  @override
  String get regConfirmConfirmedPrefix => 'Inscription confirmée à ';

  @override
  String get regConfirmErrorPrefix => 'Erreur : ';

  @override
  String get regConfirmDisplayTitleStart => 'Confirme ';

  @override
  String get regConfirmDisplayTitleAccent => 'ton inscription.';

  @override
  String get regConfirmPillFree => 'GRATUIT';

  @override
  String get regConfirmPillPaid => 'PAYANTE';

  @override
  String get regConfirmBreakdownFee => 'Frais d\'inscription';

  @override
  String get regConfirmBreakdownService => 'Frais de service';

  @override
  String get regConfirmBreakdownServiceIncluded => 'Inclus';

  @override
  String get regConfirmBreakdownTotal => 'Total à payer';

  @override
  String get regConfirmRanksRewardedSingle => '1 rang récompensé';

  @override
  String get regConfirmRanksRewardedPluralSuffix => ' rangs récompensés';

  @override
  String get regConfirmAckLabel =>
      'J\'accepte les règles du tournoi et le règlement intérieur.';

  @override
  String get regConfirmStoreLinkError => 'Impossible d\'ouvrir le lien.';

  @override
  String get regConfirmPlayStore => 'Play Store';

  @override
  String get regConfirmAppStore => 'App Store';

  @override
  String get referralCardTitle => 'Parrainage requis';

  @override
  String get referralQuotaReached => '✓ Quota atteint — tu peux t\'inscrire !';

  @override
  String get referralShareSubject => 'Rejoins-moi sur ARENA';

  @override
  String get referralYourCodeLabel => 'TON CODE';

  @override
  String get referralCopyButton => 'Copier';

  @override
  String get referralShareButton => 'Partager';

  @override
  String get homeSectionNextMatch => '⚡ PROCHAIN MATCH';

  @override
  String get homeSectionLive => 'EN DIRECT';

  @override
  String get homeSectionActiveTournaments => '★ MES TOURNOIS';

  @override
  String get homeSectionYourStats => '📊 TES STATS';

  @override
  String get homeViewAllLink => 'Tout voir';

  @override
  String get mainLayoutExitConfirm => 'Appuie encore pour quitter ARENA';

  @override
  String get mainLayoutTitleHome => 'ACCUEIL';

  @override
  String get mainLayoutTitleCompetitions => 'COMPÉTITIONS';

  @override
  String get mainLayoutTitleMessages => 'MESSAGES';

  @override
  String get mainLayoutTitleProfile => 'PROFIL';

  @override
  String get mainLayoutNavHome => 'Accueil';

  @override
  String get mainLayoutNavCompetitions => 'Compétitions';

  @override
  String get mainLayoutNavChat => 'Chat';

  @override
  String get mainLayoutNavProfile => 'Profil';

  @override
  String get homeHeaderDefaultUsername => 'Joueur';

  @override
  String get homeHeaderTierBronze => '🥉 BRONZE';

  @override
  String get homeHeaderSearchTooltip => 'Rechercher un joueur';

  @override
  String get liveStreamsErrorPrefix => 'Erreur : ';

  @override
  String get liveStreamsBadgeLive => 'LIVE';

  @override
  String get liveStreamsTapToWatch => 'Tape pour regarder en direct';

  @override
  String get liveStreamsEmptyState => 'Aucun live en cours';

  @override
  String get pendingPaymentCompetitionFallback => 'Compétition';

  @override
  String get pendingPaymentSingleTitle => 'Paiement en attente de validation';

  @override
  String get pendingPaymentTapToCheck => 'Tape pour vérifier le statut';

  @override
  String get promoBannerLinkOpenError => 'Impossible d\'ouvrir le lien.';

  @override
  String get tutorialWatchCta => 'Regarder le tutoriel';

  @override
  String get statGridMatchesLabel => 'Matchs';

  @override
  String get statGridWdlLabel => 'V/D/N';

  @override
  String get statGridWinRateLabel => 'Win rate';

  @override
  String get upcomingMatchesEmpty => 'Aucun match programmé';

  @override
  String get upcomingMatchOpponentWaiting => 'En attente';

  @override
  String get upcomingMatchLive => 'LIVE';

  @override
  String get upcomingBadgeInProgress => 'EN COURS';

  @override
  String get upcomingBadgeToSchedule => 'À PLANIFIER';

  @override
  String get upcomingBadgeReady => 'PRÊT';

  @override
  String get upcomingBadgeTomorrow => 'DEMAIN';

  @override
  String get upcomingPhaseMatch => 'Match';

  @override
  String get upcomingPhaseFinal => 'Finale';

  @override
  String get upcomingPhaseSemiFinal => 'Demi-finale';

  @override
  String get upcomingPhaseQuarterFinal => 'Quart de finale';

  @override
  String get upcomingPhaseRoundOf16 => '8e de finale';

  @override
  String get upcomingPhaseRoundOf32 => '16e de finale';

  @override
  String get matchRoomTitleDefault => 'MATCH';

  @override
  String get matchRoomChatTooltip => 'Chat avec ton adversaire';

  @override
  String get matchRoomNotFoundTitle => 'Match introuvable';

  @override
  String get matchRoomNotFoundDescription =>
      'Le match a peut-être été annulé par un admin.';

  @override
  String get matchLockedTitle => 'Salle verrouillée';

  @override
  String get matchLockedBody =>
      'L\'accès à ce match ouvre 5 minutes avant le coup d\'envoi.';

  @override
  String matchLockedScheduled(String scheduled) {
    return 'Coup d\'envoi : $scheduled';
  }

  @override
  String get matchLockedNoScheduleTitle => 'Horaire à venir';

  @override
  String get matchLockedNoScheduleBody =>
      'Ce match n\'a pas encore d\'horaire planifié. Tu seras notifié dès qu\'il sera programmé.';

  @override
  String get matchRulesSectionTitle => 'Règles du jeu';

  @override
  String get matchRulesVideoTitle => 'À regarder avant de jouer';

  @override
  String get roleIntroHomeTitle => 'TU ES LE JOUEUR À DOMICILE';

  @override
  String get roleIntroAwayTitle => 'TU ES LE JOUEUR À L\'EXTÉRIEUR';

  @override
  String roleIntroHomeBody(String game) {
    return 'En tant que joueur à DOMICILE, tu dois recevoir le joueur EXTÉRIEUR : c\'est à toi de créer le code de la salle.\n\nÉtape 1 : démarre $game jusqu\'au menu principal et sélectionne ton équipe.\nÉtape 2 : reviens sur ton match dans Arena et saisis le nom de ton équipe.\nÉtape 3 : lance l\'enregistrement du match depuis Arena en sélectionnant $game.\nNB : L\'ENREGISTREMENT DU MATCH EST OBLIGATOIRE.\nÉtape 4 : une fois l\'enregistrement lancé, crée le code de la salle et envoie-le au joueur EXTÉRIEUR via le bouton flottant rouge ou la notification Arena, puis patiente qu\'il rejoigne la salle sans quitter $game.\nÉtape 5 : faites le match. À la fin de la rencontre, saisis le score via le bouton rouge ou la notification Arena, sans sortir de $game.\n\n⚠️ LE NON-RESPECT DES DIFFÉRENTES ÉTAPES PEUT CONDUIRE À UNE DÉFAITE PAR FORFAIT ET À L\'ATTRIBUTION DE LA VICTOIRE SUR TAPIS VERT AU JOUEUR EXTÉRIEUR.';
  }

  @override
  String roleIntroAwayBody(String game) {
    return 'En tant que joueur à l\'EXTÉRIEUR, tu seras reçu par le joueur DOMICILE : il t\'enverra un code de salle.\n\nÉtape 1 : démarre $game jusqu\'au menu principal et sélectionne ton équipe.\nÉtape 2 : reviens sur ton match dans Arena, copie le code de la salle et saisis le nom de ton équipe.\nÉtape 3 : lance l\'enregistrement du match depuis Arena en sélectionnant $game.\nNB : L\'ENREGISTREMENT DU MATCH EST OBLIGATOIRE.\nÉtape 4 : une fois l\'enregistrement lancé, rejoins le joueur DOMICILE dans la salle avec le code qu\'il t\'a envoyé (tu peux retrouver ce code à tout moment dans le bouton flottant rouge).\nÉtape 5 : faites le match. À la fin de la rencontre, saisis le score via le bouton rouge ou la notification Arena, sans sortir de $game.\n\n⚠️ LE NON-RESPECT DES DIFFÉRENTES ÉTAPES PEUT CONDUIRE À UNE DÉFAITE PAR FORFAIT ET À L\'ATTRIBUTION DE LA VICTOIRE SUR TAPIS VERT AU JOUEUR DOMICILE.';
  }

  @override
  String roleIntroConfirmLaunched(String game) {
    return 'Je confirme avoir déjà lancé $game et être arrivé au menu principal.';
  }

  @override
  String get roleIntroGotIt => 'J\'ai compris';

  @override
  String get manualUploadButtonLabel => 'Envoyer une vidéo de preuve';

  @override
  String get manualUploadSuccess => 'Vidéo envoyée. Merci !';

  @override
  String get outcomeFinalScore => 'SCORE FINAL';

  @override
  String get outcomeDraw => 'Match nul.';

  @override
  String get outcomeEditMyScore => 'MODIFIER MON SCORE';

  @override
  String get outcomeDisputeInProgress => 'LITIGE EN COURS';

  @override
  String get outcomeDisputeExplanation =>
      'Vos scores ne concordent pas. Si tu t\'es trompé, corrige-le ; sinon attends que ton adversaire corrige le sien. Sans accord, un admin tranchera à partir des preuves.';

  @override
  String get outcomeScoreCardYou => 'TOI';

  @override
  String get outcomeScoreCardPlayer1 => 'JOUEUR 1';

  @override
  String get outcomeScoreCardPlayer2 => 'JOUEUR 2';

  @override
  String get matchHeaderPlayer1 => 'Joueur 1';

  @override
  String get matchHeaderPlayer2 => 'Joueur 2';

  @override
  String get matchHeaderBadgeHome => 'DOMICILE';

  @override
  String get matchHeaderBadgeAway => 'EXTÉRIEUR';

  @override
  String get recordingActionResume => 'Continuer';

  @override
  String get recordingActionPause => 'Pause (max 2 min)';

  @override
  String get recordingActionSaveStop => 'Enregistrer et arrêter';

  @override
  String get recordingActionForfeit => 'Arrêter (forfait)';

  @override
  String get recordingNoRecordingInProgress => 'Aucun enregistrement en cours.';

  @override
  String get recordingStateRecording => 'Enregistrement en cours';

  @override
  String get recordingStatePaused => 'En pause — reprends sous 2 min';

  @override
  String get recordingStateForfeited => 'Forfait déclaré';

  @override
  String get recordingStateStopped => 'Enregistrement arrêté';

  @override
  String get recordingStateIdle => 'Aucun enregistrement';

  @override
  String get recordingLiveStreamStarted => 'Diffusion live démarrée.';

  @override
  String get recordingReplaySavedDownloads =>
      'Replay enregistré dans Téléchargements › ARENA';

  @override
  String get recordingReplayInCache =>
      'Replay disponible dans le cache de l\'app';

  @override
  String get recordingPermMissingMic => 'micro';

  @override
  String get recordingPermMissingNotifications => 'notifications';

  @override
  String get recordingPermOverlayNeedsSettings =>
      'Active \"Afficher au-dessus des autres apps\" pour ARENA dans Paramètres > Apps > Accès spécial';

  @override
  String get recordingPermOverlayDenied =>
      'Overlay refusé — retape JE SUIS DANS LA ROOM après activation';

  @override
  String get recordingBannerRecording =>
      'Enregistrement anti-triche en cours\nTape pour les actions';

  @override
  String get recordingBannerPaused =>
      'Match en pause — tape pour reprendre ou arrêter';

  @override
  String get recordingBannerForfeitPauseExpired => 'Forfait : pause dépassée';

  @override
  String get recordingBannerForfeitDeclared => 'Forfait déclaré';

  @override
  String get stepBodyMatchInProgressTitle => 'Match en cours';

  @override
  String get stepBodyMatchInProgressDesc =>
      'Les joueurs sont en train de jouer ou de valider le score.';

  @override
  String get stepBodyMatchCancelledTitle => 'MATCH ANNULÉ';

  @override
  String get stepBodyMatchCancelledDesc => 'L\'admin a annulé ce match.';

  @override
  String get stepBodyForfeitTitle => 'FORFAIT';

  @override
  String get stepBodyForfeitDesc =>
      'L\'un des joueurs n\'a pas démarré à temps.';

  @override
  String get stepBodyAwaitRoomCodeTitle => 'En attente du code room';

  @override
  String get stepBodyAwaitRoomCodeDesc =>
      'Les joueurs vont créer une room dans le jeu et partager le code ici.';

  @override
  String get stepBodyAwaitHomeCodeTitle =>
      'En attente du code du joueur à domicile';

  @override
  String get stepBodyAwaitHomeCodeDesc =>
      'Tu joues à l\'extérieur sur ce match. Le joueur à domicile crée la room dans le jeu et t\'enverra le code ici dès qu\'il l\'aura partagé.';

  @override
  String get openChatButton => 'OUVRIR LE CHAT';

  @override
  String get roomReadyMarkStartedError => 'Impossible de marquer démarré : ';

  @override
  String get roomReadyCodeCopied => 'Code copié dans le presse-papier';

  @override
  String get roomReadyHintObserver =>
      'Les joueurs vont rejoindre la room et démarrer le match.';

  @override
  String get roomReadyHintHome =>
      'Tu as partagé le code. En attente que ton adversaire rejoigne, puis confirmez le démarrage.';

  @override
  String get roomReadyHintAway =>
      'Rejoins la room dans le jeu avec ce code, puis confirme une fois que les deux joueurs sont dedans.';

  @override
  String get roomReadyCodeLabel => 'CODE DE LA ROOM';

  @override
  String get roomReadyCopyTooltip => 'Copier le code';

  @override
  String get roomReadyTeamNameLabel => 'NOM DE TON ÉQUIPE';

  @override
  String get roomReadyTeamNameHint => 'Ex. Real Madrid, FC Barcelone…';

  @override
  String get roomReadyTeamNameHelper =>
      'Obligatoire — l\'équipe que tu utilises pour ce match. Visible par l\'admin en cas de litige anti-triche.';

  @override
  String get roomReadyInRoomButton => 'JE SUIS DANS LA ROOM';

  @override
  String get roomReadyJoinedButton => 'J\'AI REJOINT LA ROOM';

  @override
  String get startRecordingTitle => 'Prépare ton match';

  @override
  String get startRecordingDesc =>
      'Saisis ton nom d\'équipe, puis démarre l\'enregistrement. Tu créeras ensuite ta room dans eFootball et enverras le code à ton adversaire depuis le bouton flottant, sans quitter le jeu.';

  @override
  String get startRecordingButton => 'DÉMARRER L\'ENREGISTREMENT';

  @override
  String get startRecordingTeamStepTitle => 'Ton nom d\'équipe';

  @override
  String get startRecordingTeamStepDesc =>
      'Saisis le nom de l\'équipe que tu utilises pour ce match, puis continue.';

  @override
  String get startRecordingActivateTitle => 'Active ton enregistrement';

  @override
  String get startRecordingActivateDesc =>
      'L\'enregistrement anti-triche va démarrer. Autorise la capture d\'écran, puis crée ta room dans eFootball et envoie le code depuis le bouton flottant.';

  @override
  String get stepBodyHostPreparingTitle => 'L\'hôte prépare la room';

  @override
  String get stepBodyHostPreparingDesc =>
      'Le joueur à domicile démarre son enregistrement et crée la room. Le code arrivera ici sous peu.';

  @override
  String get stepBodyHomeAwaitCreateRoomTitle => 'Enregistrement en cours';

  @override
  String get stepBodyHomeAwaitCreateRoomDesc =>
      'Crée ta room dans eFootball, puis envoie le code à ton adversaire depuis le bouton flottant rouge (mini « clé »).';

  @override
  String get stepBodyAwayAwaitCodeTitle => 'En attente du code';

  @override
  String get stepBodyAwayAwaitCodeDesc =>
      'L\'hôte crée sa room. Le code room arrivera ici — tu pourras alors rejoindre.';

  @override
  String get roomReadyCodeSharedBadge => 'CODE PARTAGÉ';

  @override
  String get roomReadySyncingHint => 'Synchronisation avec ton adversaire…';

  @override
  String get scoreEditErrorRange => 'Scores attendus entre 0 et 99.';

  @override
  String get scoreEditErrorTieBeforePens =>
      'Score réglementaire à égalité avant les tirs au but.';

  @override
  String get scoreEditErrorPensRange => 'Tirs au but attendus entre 0 et 30.';

  @override
  String get scoreEditErrorPensTie =>
      'Les tirs au but ne peuvent pas finir à égalité.';

  @override
  String get scoreEditDialogTitle => 'Corriger ton score';

  @override
  String get scoreEditMyScoreLabel => 'Mon score';

  @override
  String get scoreEditOpponentLabel => 'Adversaire';

  @override
  String get scoreEditViaPenaltiesLabel => 'Décidé aux tirs au but';

  @override
  String get scoreEditMyPenLabel => 'Mes TAB';

  @override
  String get scoreEditOppPenLabel => 'TAB adv.';

  @override
  String get scoreEditCancelButton => 'Annuler';

  @override
  String get scoreEditResendButton => 'RENVOYER';

  @override
  String get scoreFlowErrorRange => 'Scores attendus entre 0 et 99.';

  @override
  String get scoreFlowErrorTieBeforePens =>
      'Le score réglementaire doit être à égalité avant les tirs au but.';

  @override
  String get scoreFlowErrorPensRange => 'Tirs au but attendus entre 0 et 30.';

  @override
  String get scoreFlowErrorPensTie =>
      'Les tirs au but ne peuvent pas finir à égalité.';

  @override
  String get scoreFlowSubmitError => 'Impossible de soumettre : ';

  @override
  String get scoreFlowProofUploadError => 'Upload impossible : ';

  @override
  String get scoreFlowResolutionError => 'Erreur de résolution : ';

  @override
  String get scoreFlowSessionExpiredTitle => 'Session expirée';

  @override
  String get scoreFlowSessionExpiredDescription =>
      'Reconnecte-toi pour saisir un score.';

  @override
  String get scoreFlowEnterFinalScoreLabel => 'SAISIS LE SCORE FINAL';

  @override
  String get scoreFlowEnterFinalScoreHint =>
      'Entre les buts de chaque côté. Si vos deux saisies concordent, le match est validé automatiquement.';

  @override
  String get scoreFlowMyScoreLabel => 'Mon score';

  @override
  String get scoreFlowOppScoreLabel => 'Score adversaire';

  @override
  String get scoreFlowViaPenaltiesTitle => 'Match décidé aux tirs au but';

  @override
  String get scoreFlowViaPenaltiesSubtitle =>
      'À cocher uniquement si le score réglementaire est à égalité.';

  @override
  String get scoreFlowMyPenLabel => 'Mes tirs au but';

  @override
  String get scoreFlowOppPenLabel => 'Tirs adversaire';

  @override
  String get scoreFlowSubmitButton => 'SOUMETTRE LE SCORE';

  @override
  String get scoreFlowValidationInProgress => 'VALIDATION EN COURS';

  @override
  String get scoreFlowWaitingOpponent => 'EN ATTENTE DE TON ADVERSAIRE';

  @override
  String get scoreFlowYouSubmitted => 'Tu as soumis : ';

  @override
  String get scoreFlowOnPenalties => 'Aux tirs au but : ';

  @override
  String get scoreFlowComparingScores =>
      'On compare les scores des deux joueurs…';

  @override
  String get scoreFlowOpponentNotSubmitted =>
      'Ton adversaire n\'a pas encore saisi son score.';

  @override
  String get scoreFlowProofAttached => 'Preuve attachée';

  @override
  String get scoreFlowProofPrompt => 'Joins une photo ou vidéo (recommandé)';

  @override
  String get scoreFlowProofHelper =>
      'Capture d\'écran de l\'écran de fin du match ou clip de la dernière action — utile en cas de litige.';

  @override
  String get scoreFlowUploading => 'Upload en cours…';

  @override
  String get scoreFlowReplaceButton => 'Remplacer';

  @override
  String get scoreFlowRemoveProofTooltip => 'Retirer la preuve';

  @override
  String get scoreFlowChooseFileButton => 'Choisir un fichier';

  @override
  String get shareCodeErrorLength =>
      'Le code doit faire entre 4 et 12 caractères.';

  @override
  String get shareCodeErrorSendFailed => 'Impossible de partager le code : ';

  @override
  String get shareCodeRoomLabel => 'CODE ROOM (CRÉÉ PAR LE DOMICILE)';

  @override
  String get shareCodeEnterPrompt => 'Saisis ton code eFootball :';

  @override
  String get shareCodeOpponentWillReceive =>
      'Ton adversaire recevra ce code au chat dès envoi.';

  @override
  String get shareCodeOpponentReceives =>
      'Ton adversaire reçoit ce code au chat dès envoi.';

  @override
  String get shareCodeSubmitButton => 'ENVOYER LE CODE';

  @override
  String get shareCodeOverlayButton => 'ENVOYER SANS QUITTER EFOOTBALL';

  @override
  String get shareCodeOverlayHint =>
      'Crée ta room dans eFootball, puis envoie le code depuis un bouton flottant — sans quitter le jeu, la room reste active.';

  @override
  String get shareCodeInputHint => 'Ex: 8K3-TZ9';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllReadTooltip => 'Marquer tout comme lu';

  @override
  String get notificationsMarkAllReadError =>
      'Impossible de tout marquer comme lu.';

  @override
  String get notificationsLoadError => 'Erreur de chargement.\n';

  @override
  String get notificationsSignedOut =>
      'Connecte-toi pour voir tes notifications.';

  @override
  String get notificationsEmpty => 'Aucune notification pour le moment.';

  @override
  String get notificationsFilterAll => 'Toutes';

  @override
  String get notificationsFilterMatch => 'Matchs';

  @override
  String get notificationsFilterEarning => 'Gains';

  @override
  String get notificationsFilterSystem => 'Système';

  @override
  String get notificationsTimeJustNow => 'À l\'instant';

  @override
  String get notificationsTimeYesterday => 'Hier';

  @override
  String get mobileMoneyDefaultCountry => '🇨🇲 Cameroun';

  @override
  String get mobileMoneyCountryLabel => 'PAYS';

  @override
  String get mobileMoneyNumberLabel => 'NUMÉRO ';

  @override
  String get mobileMoneyNumberHelp =>
      'Le numéro depuis lequel tu vas payer (utile au super-admin pour retrouver ta transaction).';

  @override
  String get mobileMoneyPhoneValid => '✓ Numéro valide ';

  @override
  String get mobileMoneySubmitSending => 'ENVOI…';

  @override
  String get mobileMoneySubmitPaid => 'J\'AI PAYÉ ';

  @override
  String get mobileMoneyCodeCopied => 'Code marchand copié.';

  @override
  String get mobileMoneyDialerError =>
      'Impossible d\'ouvrir le composeur. Copie le code et compose-le à la main.';

  @override
  String get mobileMoneySubmitError => 'Erreur lors de l\'envoi : ';

  @override
  String get mobileMoneyNoConnection => 'Pas de connexion : ';

  @override
  String get mobileMoneyHeroPayment => 'Paiement ';

  @override
  String get mobileMoneyHeroForAmount => 'Pour ';

  @override
  String get mobileMoneyMerchantCodeTitle => 'Code marchand';

  @override
  String get mobileMoneyCopyButton => '📋 COPIER';

  @override
  String get mobileMoneyExecuteButton => '📞 EXÉCUTER';

  @override
  String get mobileMoneyMissingCodeTitle => '⚠ Code marchand manquant';

  @override
  String get mobileMoneyMissingCodeBody =>
      'L\'admin n\'a pas encore configuré de code marchand pour cette méthode sur cette compétition. Choisis une autre méthode ou contacte le support.';

  @override
  String get mobileMoneyDisclaimerExactAmount =>
      'Paie le montant EXACT — sinon le super-admin refusera';

  @override
  String get mobileMoneyDisclaimerKeepSms =>
      'Garde le SMS de confirmation Mobile Money en preuve';

  @override
  String get mobileMoneyDisclaimerManualValidation =>
      'L\'admin valide manuellement ton paiement après réception';

  @override
  String get mobileMoneyDisclaimerTitle => '⚠ Avant de continuer';

  @override
  String get paymentFailedRejectedWithReason =>
      'Le super-admin a refusé ton paiement : ';

  @override
  String get paymentFailedRejectedGeneric =>
      'Le super-admin a refusé ton paiement (montant incorrect ou transaction introuvable sur le compte marchand).';

  @override
  String get paymentFailedNetwork =>
      'Problème réseau pendant l\'envoi. Aucun débit n\'a été effectué côté ARENA.';

  @override
  String get paymentFailedUnknown =>
      'Le paiement n\'a pas pu être confirmé. Réessaie ou contacte le support.';

  @override
  String get paymentFailedSolutionCheckAmount =>
      'Vérifie le montant exact + le code marchand';

  @override
  String get paymentFailedSolutionRetryFromSignup =>
      'Recommence depuis la page Inscription';

  @override
  String get paymentFailedSolutionContactIfError =>
      'Contacte le support si tu penses que c\'est une erreur';

  @override
  String get paymentFailedSolutionCheckInternet =>
      'Vérifie ta connexion Internet';

  @override
  String get paymentFailedSolutionContactSupport => 'Contacte le support ARENA';

  @override
  String get paymentFailedAccountNotRegistered =>
      'Ton compte n\'a pas été inscrit.';

  @override
  String get paymentFailedRetryButton => '↻ RECOMMENCER';

  @override
  String get paymentFailedContactSupportLink => 'Contacter le support ARENA';

  @override
  String get paymentFailedTitleRejected => 'PAIEMENT REFUSÉ';

  @override
  String get paymentFailedTitleFailed => 'PAIEMENT ÉCHOUÉ';

  @override
  String get paymentFailedCauseTitle => '⚠ Cause';

  @override
  String get paymentFailedErrorCodeLabel => 'Code erreur : ';

  @override
  String get paymentFailedSolutionsTitle => '💡 Solutions';

  @override
  String get paymentHistoryAppBarTitle => 'HISTORIQUE';

  @override
  String get paymentHistoryErrorPrefix => 'Erreur : ';

  @override
  String get paymentHistoryTabPayments => 'PAIEMENTS';

  @override
  String get paymentHistoryTabGains => 'GAINS';

  @override
  String get paymentHistoryGainsEmpty =>
      'Aucun gain pour le moment. Remporte une compétition pour recevoir un versement !';

  @override
  String get paymentHistoryBadgePaid => 'VERSÉ';

  @override
  String get paymentHistoryBadgePending => 'EN ATTENTE';

  @override
  String get paymentHistoryBadgeToClaim => 'À RÉCLAMER';

  @override
  String get paymentHistoryGainRanked => 'Gain · rang ';

  @override
  String get paymentHistoryGainGeneric => 'Gain de compétition';

  @override
  String get paymentHistoryClaimButton => 'RÉCLAMER MON GAIN';

  @override
  String get paymentHistoryClaimSuccess =>
      'Gain réclamé — le staff va procéder au versement.';

  @override
  String get paymentHistoryClaimFailPrefix => 'Échec : ';

  @override
  String get paymentHistoryClaimSheetTitle => 'Réclamer mon gain';

  @override
  String get paymentHistoryClaimSheetSubtitle =>
      'Indique le numéro Mobile Money sur lequel recevoir ton versement.';

  @override
  String get paymentHistoryClaimMethodMtn => 'MTN MoMo';

  @override
  String get paymentHistoryClaimMethodOrange => 'Orange Money';

  @override
  String get paymentHistoryClaimPhoneHint =>
      'Numéro Mobile Money (ex. +237 6XX XX XX XX)';

  @override
  String get paymentHistoryClaimConfirm => 'CONFIRMER';

  @override
  String get paymentHistoryClaimPhoneRequired => 'Numéro requis.';

  @override
  String get paymentHistoryClaimOperatorHint =>
      'Opérateur (ex. Wave, MTN MoMo, Orange Money)';

  @override
  String get paymentHistoryClaimOperatorRequired => 'Opérateur requis.';

  @override
  String get paymentHistoryEmptyPayments => 'Aucun paiement pour le moment.';

  @override
  String get paymentHistoryNetBalanceLabel => 'SOLDE NET';

  @override
  String get paymentHistoryTxTitle => 'Inscription compétition';

  @override
  String get paymentHistoryTxBadgePaid => 'PAYÉ';

  @override
  String get paymentHistoryTxBadgePending => 'EN ATTENTE';

  @override
  String get paymentHistoryTxBadgeRefund => 'REMBOURSEMENT';

  @override
  String get paymentHistoryTxBadgeRefunded => 'REMBOURSÉ';

  @override
  String get paymentHistoryTxBadgeFailed => 'ÉCHEC';

  @override
  String get paymentHistoryResumeCompetition => 'Compétition';

  @override
  String get paymentMethodMtnLabel => 'MTN Mobile Money';

  @override
  String get paymentMethodMtnCountries => 'Cameroun, Côte d\'Ivoire, Bénin';

  @override
  String get paymentMethodOrangeLabel => 'Orange Money';

  @override
  String get paymentMethodOrangeCountries => 'Cameroun, Sénégal, Mali';

  @override
  String get paymentPickerAppBarTitle => 'PAIEMENT';

  @override
  String get paymentPickerMobileMoneySection => '📱 MOBILE MONEY';

  @override
  String get paymentPickerV2Notice =>
      '₿ Crypto + Wave + Moov disponibles en V2 (passerelles automatiques CinetPay / NowPayments).';

  @override
  String get paymentPickerContinueButton => 'CONTINUER →';

  @override
  String get paymentPickerAmountLabel => 'MONTANT À PAYER';

  @override
  String get paymentProcessingAppBarTitle => 'STATUT PAIEMENT';

  @override
  String get paymentProcessingWaitingTitle => 'EN ATTENTE DE VALIDATION';

  @override
  String get paymentProcessingWaitingSubtitle =>
      'Le super-admin vérifie la réception du paiement sur son compte ';

  @override
  String get paymentProcessingWaitingSubtitleSuffix => ' account.';

  @override
  String get paymentProcessingInfoNote =>
      '💡 Tu peux fermer cette page : la transaction reste en attente côté admin. Tu reviendras vérifier le statut depuis \"Historique paiements\" ou la bannière sur la home.';

  @override
  String get paymentProcessingLeaveButton =>
      'QUITTER (LA TRANSACTION CONTINUE)';

  @override
  String get paymentProcessingCancelButton => 'Annuler la transaction';

  @override
  String get paymentProcessingCancelDialogTitle => 'Annuler le paiement ?';

  @override
  String get paymentProcessingCancelDialogBody =>
      'Si tu as déjà payé sur Mobile Money, attends la validation plutôt que d\'annuler ici (sinon l\'admin n\'inscrira pas ton compte).';

  @override
  String get paymentProcessingCancelDialogStay => 'Rester';

  @override
  String get paymentProcessingCancelDialogConfirm => 'Annuler quand même';

  @override
  String get paymentProcessingRecapCompetition => 'Compétition';

  @override
  String get paymentProcessingRecapAmount => 'Montant';

  @override
  String get paymentProcessingRecapMethod => 'Méthode';

  @override
  String get paymentProcessingRecapPhone => 'Ton numéro';

  @override
  String get paymentProcessingRecapReference => 'Référence';

  @override
  String get paymentSuccessTitle => 'PAIEMENT RÉUSSI !';

  @override
  String get paymentSuccessSubtitle => 'Ton inscription est confirmée.';

  @override
  String get paymentSuccessSeeCompetition => '🏆 VOIR LA COMPÉTITION';

  @override
  String get paymentSuccessBackHome => 'Retour à l\'accueil';

  @override
  String get paymentSuccessReceiptAmount => 'Montant';

  @override
  String get paymentSuccessReceiptMethod => 'Méthode';

  @override
  String get paymentSuccessReceiptTransaction => 'N° transaction';

  @override
  String get paymentSuccessReceiptDate => 'Date';

  @override
  String get paymentSuccessRegisteredLabel => '🏆 Tu es inscrit à';

  @override
  String get payoutKycStepIdRecto => 'Pièce d\'identité (recto)';

  @override
  String get payoutKycStepIdVerso => 'Pièce d\'identité (verso)';

  @override
  String get payoutKycStepSelfie => 'Selfie de vérification';

  @override
  String get payoutKycAppBarTitle => 'VÉRIFIER';

  @override
  String get payoutKycAcceptedDocsLabel => 'DOCUMENTS ACCEPTÉS';

  @override
  String get payoutKycSubmitForReview => 'ENVOYER POUR VÉRIFICATION';

  @override
  String get payoutKycNextRectoRequired => 'SUIVANT (recto requis)';

  @override
  String payoutKycPendingGain(Object amount) {
    return '💰 Gain de $amount XAF';
  }

  @override
  String get payoutKycPendingExplain =>
      'Pour ce montant, on doit vérifier ton identité avant le payout. C\'est rapide (sous 24h).';

  @override
  String get payoutKycDocNationalId => 'Carte d\'identité nationale';

  @override
  String get payoutKycDocPassport => 'Passeport';

  @override
  String get payoutKycDocDriverLicense => 'Permis de conduire';

  @override
  String get payoutKycPhotoCaptured => 'Photo capturée';

  @override
  String get payoutKycRetake => 'REPRENDRE';

  @override
  String get payoutKycPhotographFront => 'Photographier le recto';

  @override
  String get payoutKycCaptureHint =>
      'Bonne lumière, photo nette, pas de reflets';

  @override
  String get payoutKycTakePhoto => '📸 PRENDRE EN PHOTO';

  @override
  String get payoutKycSecurityLabel => 'Sécurité : ';

  @override
  String get payoutKycSecurityNote =>
      'tes documents sont chiffrés et utilisés uniquement pour la vérification réglementaire.';

  @override
  String get aboutLinkCgu => 'CGU';

  @override
  String get aboutLinkPrivacy => 'Privacy Policy';

  @override
  String get aboutLinkCookies => 'Cookies';

  @override
  String get aboutLinkSupport => 'Support';

  @override
  String get aboutLinkSite => 'Site arena.app';

  @override
  String get aboutAppBarTitle => 'À PROPOS';

  @override
  String get aboutMadeInCameroon => 'Made in Cameroon 🇨🇲';

  @override
  String get aboutLinksLabel => 'LIENS';

  @override
  String get aboutBuiltWith => 'Built with';

  @override
  String get aboutMissionTitle => '📜 Notre mission';

  @override
  String get aboutMissionBody =>
      'ARENA démocratise l\'e-sport mobile en Afrique en offrant des tournois équitables, des gains en mobile money, et une expérience premium aux passionnés de football virtuel.';

  @override
  String aboutLinkComingSoon(Object label) {
    return '$label arrive en PHASE 12.5';
  }

  @override
  String get adminMessagesAppBarTitle => 'Messages ARENA';

  @override
  String adminMessagesError(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get adminMessagesEmpty => 'Aucun message de la part d\'ARENA.';

  @override
  String get deleteAccountStepWarning => 'AVERTISSEMENT';

  @override
  String get deleteAccountStepPendingEarnings => 'GAINS EN ATTENTE';

  @override
  String get deleteAccountStepConfirmation => 'CONFIRMATION';

  @override
  String get deleteAccountStepDone => 'TERMINÉ';

  @override
  String get deleteAccountAppBarTitle => 'SUPPRIMER';

  @override
  String get deleteAccountLossHistory =>
      'Tout ton historique de matchs et de tournois';

  @override
  String get deleteAccountLossBadges => 'Tes badges et accomplissements';

  @override
  String get deleteAccountLossChats => 'Tes conversations et chats de match';

  @override
  String get deleteAccountLossPaymentMethods =>
      'Tes méthodes de paiement enregistrées';

  @override
  String get deleteAccountIrreversibleTitle => 'Cette action est irréversible';

  @override
  String get deleteAccountLossIntro =>
      'En supprimant ton compte, tu vas perdre :';

  @override
  String get deleteAccountRetentionNotice =>
      'Ton compte sera désactivé immédiatement, puis anonymisé (données personnelles effacées) sous 30 jours. Les pièces comptables légales (paiements) sont conservées sous forme anonymisée. Pendant ce délai, tu peux contacter le support pour annuler.';

  @override
  String get deleteAccountUnderstandContinue => 'JE COMPRENDS, CONTINUER';

  @override
  String get deleteAccountHasPendingTitle => 'Tu as des gains en attente';

  @override
  String get deleteAccountHasPendingBody =>
      'Récupère tes paiements en attente avant de supprimer ton compte. Une fois supprimé, ces fonds ne pourront plus t\'être envoyés.';

  @override
  String get deleteAccountBack => 'RETOUR';

  @override
  String get deleteAccountNoPendingTitle => 'Aucun gain en attente';

  @override
  String get deleteAccountNoPendingBody =>
      'Tu peux poursuivre la suppression sans risque de perdre des paiements en cours.';

  @override
  String get deleteAccountContinue => 'CONTINUER';

  @override
  String get deleteAccountConfirmWord => 'SUPPRIMER';

  @override
  String get deleteAccountConfirmTitle => 'Confirme la suppression';

  @override
  String get deleteAccountPasswordLabel => 'Mot de passe';

  @override
  String get deleteAccountReasonLabel => 'Raison (optionnel)';

  @override
  String get deleteAccountDeletePermanently => 'SUPPRIMER DÉFINITIVEMENT';

  @override
  String get deleteAccountDoneTitle => 'Compte désactivé';

  @override
  String get deleteAccountDoneBody =>
      'Ton compte sera anonymisé (données personnelles effacées) sous 30 jours. Contacte le support si tu changes d\'avis.';

  @override
  String get deleteAccountBackToHome => 'RETOUR À L\'ACCUEIL';

  @override
  String get editProfileWhatsappInvalidError => 'Numéro WhatsApp invalide.';

  @override
  String get editProfileUpdatedSnack => 'Profil mis à jour.';

  @override
  String get editProfileAppBarTitle => 'MODIFIER';

  @override
  String get editProfileSaveTooltip => 'Enregistrer';

  @override
  String get editProfileColorEditableHint => 'Couleur modifiable ci-dessous';

  @override
  String get editProfileAvatarChangeHint => 'Modifier la photo';

  @override
  String get editProfileAvatarFromGallery => 'Choisir dans la galerie';

  @override
  String get editProfileAvatarFromCamera => 'Prendre une photo';

  @override
  String get editProfileAvatarRemove => 'Retirer la photo';

  @override
  String get editProfileAvatarUpdatedSnack => 'Photo de profil mise à jour.';

  @override
  String get editProfileUsernameCaption => 'NOM D\'UTILISATEUR';

  @override
  String get editProfileUsernameMinError => 'Minimum 3 caractères';

  @override
  String get editProfileUsernameMaxError => 'Maximum 20 caractères';

  @override
  String get editProfileCountryCaption => 'PAYS';

  @override
  String get editProfileAvatarColorCaption => 'COULEUR AVATAR';

  @override
  String get editProfileWhatsappHint => 'Ex. 07 07 07 07 07';

  @override
  String get editProfileWhatsappInvalidErrorText => 'Numéro invalide.';

  @override
  String get editProfileSaveButton => 'ENREGISTRER';

  @override
  String get friendsAppBarTitle => 'Mes amis';

  @override
  String get friendsSearchTooltip => 'Rechercher';

  @override
  String get friendsTabFriends => 'Amis';

  @override
  String get friendsTabRequests => 'Demandes';

  @override
  String get friendsTabBlocked => 'Bloqués';

  @override
  String get friendsEmptyLabel => 'Aucun ami pour le moment.';

  @override
  String get friendsEmptyHint => 'Touche la loupe en haut pour en rechercher.';

  @override
  String get friendsRemoveCancel => 'Annuler';

  @override
  String get friendsRemoveConfirm => 'Confirmer';

  @override
  String get friendsSectionReceived => 'REÇUES';

  @override
  String get friendsSectionSent => 'ENVOYÉES';

  @override
  String get friendsNoRequests => 'Aucune demande.';

  @override
  String get friendsNoPendingRequests => 'Aucune demande en attente.';

  @override
  String get friendsCancelRequest => 'Annuler';

  @override
  String get friendsBlockedEmptyLabel => 'Aucun joueur bloqué.';

  @override
  String get friendsUnblockAction => 'Débloquer';

  @override
  String get friendsSearchAppBarTitle => 'Rechercher';

  @override
  String get friendsSearchHint => 'Nom d\'utilisateur';

  @override
  String get friendsSearchPrompt => 'Tape au moins 2 caractères pour chercher.';

  @override
  String get matchHistoryAppBarLoadingTitle => 'Historique';

  @override
  String get matchHistoryAppBarTitle => 'HISTORIQUE';

  @override
  String get matchHistoryError =>
      'Impossible de charger ton historique. Vérifie ta connexion.';

  @override
  String get matchHistoryFilterAll => 'Tous';

  @override
  String get matchHistoryFilterWins => 'V';

  @override
  String get matchHistoryFilterLosses => 'D';

  @override
  String get matchHistoryFilterOngoing => 'En cours';

  @override
  String get matchHistoryEmptyTitle => 'Aucun match';

  @override
  String get matchHistoryEmptyDescription =>
      'Tes matchs apparaîtront ici dès la première compétition.';

  @override
  String get matchHistoryOpponentFallback => 'Adversaire';

  @override
  String get playerProfileUnavailable => 'Profil indisponible. Reconnecte-toi.';

  @override
  String get playerProfileSuccessHeader => '🏆 SUCCÈS';

  @override
  String get playerProfileRecentMatchesHeader => 'MATCHS RÉCENTS';

  @override
  String get playerProfilePaymentsButton => 'RÉCLAMATION DE GAINS';

  @override
  String get playerProfileSettingsButton => 'PARAMÈTRES';

  @override
  String get playerProfileSignOutButton => 'SE DÉCONNECTER';

  @override
  String get playerProfileJoinedPrefix => 'Inscrit en';

  @override
  String get playerProfileTierBronze => '🥉 BRONZE';

  @override
  String get playerProfileTierSilver => '🥈 ARGENT';

  @override
  String get playerProfileTierGold => '🥇 OR';

  @override
  String get playerProfileTierElite => '💎 ÉLITE';

  @override
  String get playerProfileEditTooltip => 'Modifier';

  @override
  String get playerProfileEditAvatarTooltip => 'Modifier l\'avatar';

  @override
  String get playerProfileStatWins => 'Victoires';

  @override
  String get playerProfileStatLosses => 'Défaites';

  @override
  String get playerProfileStatWinRate => 'Win rate';

  @override
  String get playerProfileNoCompletedMatches =>
      'Aucun match complété pour le moment.';

  @override
  String get playerProfileFriendsTitle => 'Mes amis';

  @override
  String get playerProfileNoFriends => 'Aucun ami pour le moment';

  @override
  String get playerProfileReferralTitle => 'Mon parrainage';

  @override
  String get playerProfileReferralCodeCopied => 'Code parrainage copié';

  @override
  String get playerProfileReferralCodeGenerating =>
      'Génération du code en cours…';

  @override
  String get playerProfileReferralExplainer =>
      'Partage ton code pour parrainer des amis. Une fois ton quota atteint, tu accèdes automatiquement aux compétitions gratuites avec récompense conditionnée.';

  @override
  String get playerProfileResultWin => 'V';

  @override
  String get playerProfileResultLoss => 'D';

  @override
  String get playerProfileResultDraw => 'N';

  @override
  String get publicProfileAppBarTitle => 'Profil';

  @override
  String get publicProfilePlayerNotFound => 'Joueur introuvable.';

  @override
  String get publicProfileRecentMatchesHeader => 'MATCHS RÉCENTS';

  @override
  String get publicProfileCtaAddFriend => 'AJOUTER EN AMI';

  @override
  String get publicProfileCtaRequestSent => 'DEMANDE ENVOYÉE';

  @override
  String get publicProfileCtaCancel => 'ANNULER';

  @override
  String get publicProfileRequestCancelled => 'Demande annulée';

  @override
  String get publicProfileCtaAccept => 'ACCEPTER';

  @override
  String get publicProfileCtaDecline => 'REFUSER';

  @override
  String get publicProfileRequestDeclined => 'Demande refusée';

  @override
  String get publicProfileCtaFriend => 'AMI';

  @override
  String get publicProfileCtaRemove => 'RETIRER';

  @override
  String get publicProfileFriendRemoved => 'Ami retiré';

  @override
  String get publicProfileCtaBlock => 'BLOQUER';

  @override
  String get publicProfileBlockConfirmDetail =>
      'Vous ne pourrez plus échanger en chat de match.';

  @override
  String get publicProfilePlayerBlocked => 'Joueur bloqué';

  @override
  String get publicProfileCtaUnblock => 'DÉBLOQUER';

  @override
  String get publicProfilePlayerUnblocked => 'Joueur débloqué';

  @override
  String get publicProfileCtaUnavailable => 'INDISPONIBLE';

  @override
  String get publicProfileDialogCancel => 'Annuler';

  @override
  String get publicProfileDialogConfirm => 'Confirmer';

  @override
  String get publicProfileStatsHeader => 'STATS';

  @override
  String get publicProfileStatWin => 'V';

  @override
  String get publicProfileStatLoss => 'D';

  @override
  String get publicProfileStatDraw => 'N';

  @override
  String get publicProfileWinRateLabel => 'Taux de victoire';

  @override
  String get publicProfileGoalsScored => 'Buts marqués';

  @override
  String get publicProfileGoalsConceded => 'Buts encaissés';

  @override
  String get publicProfileNoCompletedMatches =>
      'Aucun match complété pour le moment.';

  @override
  String get publicProfileResultWin => 'V';

  @override
  String get publicProfileResultLoss => 'D';

  @override
  String get publicProfileResultDraw => 'N';

  @override
  String get settingsAppBarTitle => 'PARAMÈTRES';

  @override
  String get settingsSectionPreferences => 'PRÉFÉRENCES';

  @override
  String get settingsSectionAccount => 'COMPTE';

  @override
  String get settingsSectionPrivacy => 'CONFIDENTIALITÉ';

  @override
  String get settingsSectionHelp => 'AIDE & INFOS';

  @override
  String get settingsVersionFooter => 'v1.0.0 · build 12';

  @override
  String get settingsLanguageLabel => 'Langue';

  @override
  String get settingsCurrencyLabel => 'Devise';

  @override
  String get settingsMarketingTitle => 'Notifications marketing';

  @override
  String get settingsMarketingSubtitle =>
      'Conseils, nouveaux tournois, promotions';

  @override
  String get settingsChangeEmailTitle => 'Changer l\'email';

  @override
  String get settingsChangePasswordTitle => 'Changer le mot de passe';

  @override
  String get settingsLoginMethodsTitle => 'Méthodes de connexion';

  @override
  String get settingsLoginMethodsSubtitle =>
      'Google / Apple — bientôt disponible';

  @override
  String get settingsNewEmailDialogTitle => 'Nouvel email';

  @override
  String get settingsNewEmailHint => 'nom@example.com';

  @override
  String get settingsDialogCancel => 'Annuler';

  @override
  String get settingsDialogConfirm => 'Confirmer';

  @override
  String get settingsEmailChangeConfirmSnack =>
      'Vérifie ta boîte mail pour confirmer le changement.';

  @override
  String get settingsNewPasswordDialogTitle => 'Nouveau mot de passe';

  @override
  String get settingsNewPasswordHint => '8 caractères minimum';

  @override
  String get settingsPasswordUpdatedSnack => 'Mot de passe mis à jour.';

  @override
  String get settingsDownloadDataTitle => 'Télécharger mes données';

  @override
  String get settingsDownloadDataExporting => 'Export en cours…';

  @override
  String get settingsDownloadDataSubtitle =>
      'Génère un fichier JSON de toutes tes données';

  @override
  String get settingsDeleteAccountTitle => 'Supprimer mon compte';

  @override
  String get settingsExportSuccessTitle => 'Export réussi';

  @override
  String get settingsExportPathCopied => 'Chemin copié dans le presse-papier.';

  @override
  String get settingsExportContentLabel => 'Contenu :';

  @override
  String get settingsDialogOk => 'OK';

  @override
  String get settingsReplayIntroTitle => 'Revoir l\'introduction';

  @override
  String get settingsSupportTitle => 'Support';

  @override
  String get settingsContactSupportSubtitle => 'Discuter avec l\'équipe ARENA';

  @override
  String get supportChatTitle => 'Contact / Aide';

  @override
  String get supportChatHeaderSubtitle => 'Équipe ARENA';

  @override
  String get supportChatEmptyTitle => 'Une question ? Écrivez-nous';

  @override
  String get supportChatEmptyDescription =>
      'L\'équipe ARENA vous répond ici. Décrivez votre souci, nous revenons vers vous au plus vite.';

  @override
  String get supportOptionsTitle => 'Contacter le support';

  @override
  String get supportOptionChat => 'Discuter avec l\'équipe';

  @override
  String get supportOptionChatSubtitle =>
      'Réponse dans l\'app, on revient vite';

  @override
  String get supportOptionEmail => 'Écrire un e-mail';

  @override
  String get updateTitle => 'Mise à jour disponible';

  @override
  String updateMessage(Object version) {
    return 'La version $version est disponible.';
  }

  @override
  String get updateChangelogLabel => 'Nouveautés';

  @override
  String get updateDownloading => 'Téléchargement…';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get updateNow => 'Mettre à jour';

  @override
  String get updateFailed => 'Échec de la mise à jour. Réessaie plus tard.';

  @override
  String get settingsAboutTitle => 'À propos';

  @override
  String get settingsAboutSubtitle =>
      'ARENA V1.0 — Plateforme de tournois e-sport mobile';

  @override
  String get matchOverlayContinue => '▶ Continuer';

  @override
  String get matchOverlayPauseRecording => '⏸ Pause recording';

  @override
  String get matchOverlayStopForfeit => '🛑 Arrêter (forfait)';

  @override
  String get recordingErrorSolutionStep1 => 'Va dans Paramètres → Apps → ARENA';

  @override
  String get recordingErrorSolutionStep2 =>
      'Active \"Affichage par-dessus les autres apps\"';

  @override
  String get recordingErrorSolutionStep3 =>
      'Désactive le Battery Saver pour ARENA';

  @override
  String get recordingErrorSolutionStep4 => 'Autorise ARENA en arrière-plan';

  @override
  String get recordingErrorAppBarTitle => 'Erreur enregistrement';

  @override
  String get recordingErrorHeadline => 'RECORDING IMPOSSIBLE';

  @override
  String get recordingErrorAntiCheatNotice =>
      'Sans recording, le match ne peut pas démarrer (anti-cheat).';

  @override
  String get recordingErrorSolutionsLabel => 'SOLUTIONS';

  @override
  String get recordingErrorRetryButton => '↻ RÉESSAYER';

  @override
  String get recordingErrorForfeitButton => '🏳 FORFAIT (perdre)';

  @override
  String get recordingErrorContactSupport => 'Contacter le support';

  @override
  String get recordingErrorCauseTitle => '⚠️ Cause détectée';

  @override
  String get recordingErrorCausePermissionPrefix => 'Permission ';

  @override
  String get recordingErrorCausePermissionSuffix => ' manquante.';

  @override
  String get liveStreamsAppBarTitle => 'LIVE NOW';

  @override
  String get liveStreamsErrorPrefixV2 => 'Erreur: ';

  @override
  String get liveStreamsEmptyTitle => 'Aucun match en direct';

  @override
  String get liveStreamsEmptyDescription =>
      'Les diffusions live apparaissent ici dès qu\'un admin sélectionne un match pour la diffusion.';

  @override
  String get liveStreamsBroadcastByPrefix => 'Diffusé par ';

  @override
  String get startStreamingAlreadyLive => 'Tu diffuses ce match en direct';

  @override
  String get startStreamingSelected =>
      'Ce match est sélectionné pour la diffusion live';

  @override
  String get startStreamingOpponentLive => 'Match diffusé en direct';

  @override
  String get startStreamingStartButton => 'Démarrer';

  @override
  String get startStreamingStartedSnack => 'Diffusion démarrée.';

  @override
  String get watchStreamConnecting => 'Connexion en cours…';

  @override
  String get watchStreamWaitingBroadcaster => 'En attente du diffuseur…';

  @override
  String get watchStreamSpectatorChat => 'SPECTATOR CHAT';

  @override
  String get watchStreamChatUnavailable => 'Chat indisponible';

  @override
  String get watchStreamChatEmpty => 'Sois le premier à commenter !';

  @override
  String get watchStreamChatHint => 'Envoie un message…';

  @override
  String get watchStreamLiveBadge => 'LIVE';

  @override
  String bannedLoadStateError(Object error) {
    return 'Impossible de charger l\'état de la requête : $error';
  }

  @override
  String cguWhatsappLabel(Object dialCode) {
    return 'WHATSAPP ($dialCode)';
  }

  @override
  String cguWhatsappHelper(Object dialCode) {
    return 'Le code pays $dialCode est ajouté automatiquement.';
  }

  @override
  String cguConsentRequiredSuffix(Object title) {
    return '$title *';
  }

  @override
  String linkAccountEmailLineNoEmail(Object providerLabel) {
    return 'L\'adresse e-mail de ce compte $providerLabel est déjà utilisée par un compte ARENA.';
  }

  @override
  String linkAccountEmailLineWithEmail(Object email) {
    return '$email est déjà utilisé par un compte ARENA (mot de passe).';
  }

  @override
  String registerStepperTitle(Object step) {
    return 'Étape $step / 3';
  }

  @override
  String registerWhatsappLabel(Object dialCode) {
    return 'WHATSAPP ($dialCode)';
  }

  @override
  String registerWhatsappHelper(Object dialCode) {
    return 'Le code pays $dialCode est ajouté automatiquement.';
  }

  @override
  String bracketCaption(Object playerCount) {
    return 'ÉLIMINATION DIRECTE · $playerCount JOUEURS';
  }

  @override
  String referralCardDescription(Object referralQuota) {
    return 'Tu dois parrainer $referralQuota ami(s) pour t\'inscrire à cette compétition gratuite. Partage ton code avec eux pour qu\'ils créent leur compte ARENA.';
  }

  @override
  String referralProgressError(Object error) {
    return 'Impossible de vérifier ta progression : $error';
  }

  @override
  String referralFriendsRemaining(Object count) {
    return 'Encore $count ami(s) à parrainer';
  }

  @override
  String referralCodeCopied(Object code) {
    return 'Code $code copié dans le presse-papier';
  }

  @override
  String referralShareMessage(Object code) {
    return 'Rejoins-moi sur ARENA ! Tournois d\'e-sport mobile gratuits avec récompenses. Utilise mon code de parrainage à l\'inscription : $code';
  }

  @override
  String liveStreamsOthersCount(Object count) {
    return '+$count autres';
  }

  @override
  String pendingPaymentMultipleTitle(Object count) {
    return '$count paiements en attente';
  }

  @override
  String upcomingMatchesError(Object error) {
    return 'Erreur : $error';
  }

  @override
  String upcomingMatchVsOpponent(Object opponentName) {
    return 'vs $opponentName';
  }

  @override
  String upcomingBadgeInHours(Object hours) {
    return 'DANS ${hours}H';
  }

  @override
  String upcomingBadgeInDays(Object days) {
    return 'DANS ${days}J';
  }

  @override
  String upcomingPhaseRound(Object round) {
    return 'Round $round';
  }

  @override
  String matchRoomTitleNumbered(Object number) {
    return 'MATCH #$number';
  }

  @override
  String manualUploadFailure(Object message) {
    return 'Échec : $message';
  }

  @override
  String manualUploadError(Object error) {
    return 'Erreur : $error';
  }

  @override
  String outcomeWinner(Object winner) {
    return 'Gagnant : Joueur $winner…';
  }

  @override
  String outcomeResubmitError(Object error) {
    return 'Impossible de renvoyer : $error';
  }

  @override
  String outcomeScoreShootout(Object pen1, Object pen2) {
    return 'TAB $pen1 — $pen2';
  }

  @override
  String matchHeaderSelfSuffix(Object username) {
    return '$username · TOI';
  }

  @override
  String recordingLiveStreamError(Object error) {
    return 'Impossible de démarrer la diffusion : $error';
  }

  @override
  String recordingPermBundleNeedsSettings(Object list) {
    return 'Autorise $list dans Paramètres > Apps > ARENA';
  }

  @override
  String recordingPermBundleDenied(Object list) {
    return 'Autorisation $list refusée — retape JE SUIS DANS LA ROOM';
  }

  @override
  String recordingBannerUnavailable(Object error) {
    return 'Recording indisponible — $error\nTape ici pour réessayer.';
  }

  @override
  String notificationsTimeMinutesAgo(Object minutes) {
    return 'Il y a $minutes min';
  }

  @override
  String notificationsTimeHoursAgo(Object hours) {
    return 'Il y a $hours h';
  }

  @override
  String mobileMoneyDialHelp(Object method) {
    return 'Compose ce code sur ton $method, paie le montant exact, puis reviens ici cliquer \"J\'AI PAYÉ\".';
  }

  @override
  String deleteAccountStepCaption(Object stepNum, Object stepLabel) {
    return 'ÉTAPE $stepNum/04 · $stepLabel';
  }

  @override
  String deleteAccountCheckErrorNote(Object checkError) {
    return 'Note: vérification non concluante (table indisponible). Détail: $checkError';
  }

  @override
  String deleteAccountTypeToConfirmLabel(Object confirmWord) {
    return 'Tape \"$confirmWord\" pour confirmer';
  }

  @override
  String editProfileWhatsappCaption(Object dialCode) {
    return 'WHATSAPP ($dialCode)';
  }

  @override
  String editProfileWhatsappHelper(Object dialCode) {
    return 'Le code pays $dialCode est ajouté automatiquement.';
  }

  @override
  String friendsErrorMessage(Object error) {
    return 'Erreur : $error';
  }

  @override
  String friendsRemoveDialogTitle(Object username) {
    return 'Retirer $username ?';
  }

  @override
  String friendsAcceptedSnack(Object username) {
    return '$username est maintenant ton ami';
  }

  @override
  String friendsUnblockedSnack(Object username) {
    return '$username débloqué';
  }

  @override
  String friendsSearchErrorMessage(Object error) {
    return 'Erreur : $error';
  }

  @override
  String playerProfileError(Object error) {
    return 'Erreur: $error';
  }

  @override
  String playerProfileStatsError(Object error) {
    return 'Stats indisponibles ($error)';
  }

  @override
  String playerProfileMatchRowError(Object error) {
    return 'Erreur: $error';
  }

  @override
  String playerProfileFriendsCountSingular(Object friendsCount) {
    return '$friendsCount ami';
  }

  @override
  String playerProfileFriendsCountPlural(Object friendsCount) {
    return '$friendsCount amis';
  }

  @override
  String playerProfileReferralCountSingular(Object count) {
    return '$count invité';
  }

  @override
  String playerProfileReferralCountPlural(Object count) {
    return '$count invités';
  }

  @override
  String publicProfileError(Object error) {
    return 'Erreur : $error';
  }

  @override
  String publicProfileRequestSent(Object username) {
    return 'Demande envoyée à $username';
  }

  @override
  String publicProfileNowFriend(Object username) {
    return '$username est maintenant ton ami';
  }

  @override
  String publicProfileRemoveConfirmTitle(Object username) {
    return 'Retirer $username ?';
  }

  @override
  String publicProfileBlockConfirmTitle(Object username) {
    return 'Bloquer $username ?';
  }

  @override
  String publicProfileWinRateValue(Object pct, Object total) {
    return '$pct% ($total matchs)';
  }

  @override
  String publicProfileMatchRowError(Object error) {
    return 'Erreur: $error';
  }

  @override
  String settingsMarketingError(Object error) {
    return 'Erreur: $error';
  }

  @override
  String settingsEmailChangeError(Object error) {
    return 'Erreur: $error';
  }

  @override
  String settingsPasswordChangeError(Object error) {
    return 'Erreur: $error';
  }

  @override
  String settingsExportError(Object error) {
    return 'Export impossible : $error';
  }

  @override
  String settingsExportFileLabel(Object sizeKb) {
    return 'Fichier ($sizeKb Ko) :';
  }

  @override
  String startStreamingErrorSnack(Object error) {
    return 'Erreur: $error';
  }

  @override
  String watchStreamFailed(Object reason) {
    return 'Échec : $reason';
  }

  @override
  String watchStreamChatSendError(Object error) {
    return 'Erreur envoi : $error';
  }

  @override
  String watchStreamViewersWatching(Object viewers) {
    return '$viewers watching';
  }

  @override
  String get authErrInvalidCredentials => 'Email ou mot de passe incorrect.';

  @override
  String get authErrEmailAlreadyRegistered =>
      'Un compte existe déjà avec cet email.';

  @override
  String get authErrWeakPassword =>
      'Mot de passe trop faible : 8 caractères minimum.';

  @override
  String get authErrEmailNotConfirmed =>
      'Confirmez votre inscription via le lien reçu par email.';

  @override
  String get authErrUserBanned =>
      'Ce compte est suspendu. Contactez le support.';

  @override
  String get authErrWrongApp =>
      'Ce compte est administrateur. Utilisez l\'application ARENA Admin.';

  @override
  String get authErrNetwork =>
      'Pas de connexion internet. Vérifiez votre réseau et réessayez.';

  @override
  String get authErrRateLimited =>
      'Trop de tentatives. Réessayez dans quelques minutes.';

  @override
  String get authErrInvalidInvitation =>
      'Code d\'invitation invalide, expiré ou déjà utilisé.';

  @override
  String get authErrInvalidTotp => 'Code à 6 chiffres incorrect.';

  @override
  String get authErrTotpReplay =>
      'Ce code a déjà été utilisé. Attendez le suivant.';

  @override
  String get authErrAdminLocked =>
      'Compte verrouillé après 3 tentatives. Réessayez dans 30 minutes.';

  @override
  String get authErrBackendUnavailable =>
      'Service momentanément indisponible. Réessayez plus tard.';

  @override
  String get authErrUsernameTaken =>
      'Ce pseudo est déjà utilisé. Choisissez-en un autre.';

  @override
  String get authErrSsoCancelled => 'Connexion annulée.';

  @override
  String get authErrSsoIdToken =>
      'Connexion impossible. Vérifiez votre réseau et réessayez.';

  @override
  String get authErrSsoConfig =>
      'Connexion indisponible pour le moment. Contactez le support.';

  @override
  String get authErrInvalidResetCode => 'Code incorrect. Vérifiez votre email.';

  @override
  String get authErrExpiredResetCode =>
      'Code expiré. Demandez un nouveau code.';

  @override
  String get authErrUnknown => 'Une erreur est survenue. Réessayez.';

  @override
  String get matchStepCodeRoom => 'Code room';

  @override
  String get matchStepOpponentJoining => 'Adversaire rejoint';

  @override
  String get matchStepInProgress => 'Match en cours';

  @override
  String get matchStepResult => 'Résultat';

  @override
  String get activeCompetitionsEmpty =>
      'Aucune compétition active pour ce filtre.';

  @override
  String get myTournamentsEmpty =>
      'Tu n\'es inscrit à aucun tournoi pour l\'instant.';

  @override
  String get myTournamentsBrowseCta => 'Parcourir les tournois';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterFree => 'Gratuites';

  @override
  String get filterPaid => 'Payantes';

  @override
  String get filterUpcoming => 'À venir';

  @override
  String get filterOngoing => 'En cours';

  @override
  String get filterCompleted => 'Terminés';

  @override
  String get statusToReprogram => 'À reprogrammer';

  @override
  String get compFormatSingleElim => 'Élimination directe';

  @override
  String get compFormatGroupsKnockout => 'Poules + élimination';

  @override
  String get compFormatRoundRobin => 'Round robin';

  @override
  String get matchStepWord => 'ÉTAPE';

  @override
  String get paymentOptionsMissing =>
      'Le paiement n\'est pas encore configuré pour cette compétition. Contacte l\'organisateur.';

  @override
  String get countryPickTitle => 'Choisis ton pays';

  @override
  String get countryPickSubtitle =>
      'Sélectionne le pays depuis lequel tu vas payer.';

  @override
  String get countryPickConfirm => 'CONTINUER';

  @override
  String get countryPickCancel => 'Annuler';

  @override
  String get countryStepTitle => 'Pays';

  @override
  String get countryOrganizerLabel => 'Pays organisateur';

  @override
  String get countryOrganizerHint =>
      'Sert au périmètre admin par pays. N\'affecte pas les pays autorisés au paiement.';

  @override
  String get countryPaymentSectionTitle => 'Options de paiement par pays';

  @override
  String get countryPaymentSectionHint =>
      'Pour chaque pays autorisé, ajoute un ou plusieurs opérateurs (Orange Money, MTN MoMo, Wave…) avec leur code de transfert. Le joueur choisit son pays puis un opérateur au moment de payer.';

  @override
  String get countryFreeNote =>
      'Compétition gratuite — aucune configuration de paiement nécessaire. Seul le pays organisateur est requis.';

  @override
  String get countryOperatorNameLabel => 'Nom de l\'opérateur';

  @override
  String get countryOperatorNameHint => 'ex. Orange Money';

  @override
  String get countryTransferCodeLabel => 'Code de transfert';

  @override
  String get countryTransferCodeHint => 'ex. *126*1*001234#';

  @override
  String get countryAddOperator => 'Ajouter un opérateur';

  @override
  String get countryRemoveOperator => 'Supprimer l\'opérateur';

  @override
  String get countryAddCountry => 'Ajouter un pays';

  @override
  String get countryRemoveCountry => 'Supprimer ce pays';

  @override
  String get countryChooseCountry => 'Choisir un pays';

  @override
  String get countrySaveOperator => 'Enregistrer cet opérateur';

  @override
  String countryOperatorTemplatesButton(int count) {
    return 'Mes opérateurs ($count)';
  }

  @override
  String get countryOperatorSavedToast => 'Opérateur enregistré comme modèle.';

  @override
  String get countryOperatorEmptyToast =>
      'Renseigne le nom et le code de l\'opérateur avant d\'enregistrer.';

  @override
  String get countryValidationNeedOne =>
      'Active au moins un pays et complète chaque opérateur (nom + code).';

  @override
  String get adminScopeRestrictionsTitle => 'RESTRICTIONS (optionnel)';

  @override
  String get adminScopeRestrictionsHint =>
      'Limite ce futur admin à certains pays et/ou sections. Laisse vide pour un accès complet.';

  @override
  String get adminScopeCountriesLabel => 'Pays autorisés';

  @override
  String get adminScopeSectionsLabel => 'Sections autorisées';

  @override
  String get adminScopeAllCountries => 'Tous les pays';

  @override
  String get adminScopeAllSections => 'Toutes les sections';

  @override
  String adminScopePerimeterBanner(String countries) {
    return 'Périmètre : $countries';
  }

  @override
  String get adminScopeOutOfPerimeter => 'Action hors de votre périmètre.';
}
