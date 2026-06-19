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
      'Welcome to ARENA, the #1 platform for eFootball, Draughts and FC Mobile tournaments in Africa.';

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
  String get authEmailLabel => 'EMAIL';

  @override
  String get authEmailHint => 'player@arena.app';

  @override
  String get authPasswordLabel => 'PASSWORD';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authOr => 'OR';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get loginTitle => 'LOG IN';

  @override
  String get loginSubtitle => 'Continue your journey on ARENA.';

  @override
  String get loginSubmit => 'LOG IN';

  @override
  String get loginNoAccount => 'No account yet? ';

  @override
  String get forgotPasswordTitle => 'FORGOT PASSWORD';

  @override
  String get forgotPasswordSubtitle =>
      'Enter the email linked to your account; we\'ll send a 6-digit code to reset your password.';

  @override
  String get forgotPasswordSubmit => 'SEND CODE';

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

  @override
  String get bannedMinLengthError =>
      'Please detail your request (10 characters minimum).';

  @override
  String get bannedSendError =>
      'Failed to send. Check your connection and try again.';

  @override
  String get bannedAppBarTitle => 'Account suspended';

  @override
  String get bannedSignOut => 'LOG OUT';

  @override
  String get bannedArenaRequestTitle => '📨 ARENA REQUEST';

  @override
  String get bannedArenaRequestIntro =>
      'Explain why you think your ban should be reconsidered. The Arena Request team reviews every request within 48 hours.';

  @override
  String get bannedMessageHint => 'Describe your case (10 characters minimum)…';

  @override
  String get bannedSendingLabel => 'SENDING…';

  @override
  String get bannedSendRequestLabel => '✉️ SEND MY REQUEST';

  @override
  String get bannedPermanentTitle => 'Account permanently banned';

  @override
  String get bannedPermanentBody =>
      'You have been found guilty in a dispute 3 times. In accordance with the ARENA rule, your account is deactivated.';

  @override
  String get bannedOverdueTitle => 'Review overdue (> 48h)';

  @override
  String get bannedPendingTitle => 'Request under review';

  @override
  String get bannedOverdueBody =>
      'Your request has been open for more than 48 hours. The Arena Request team has been notified — thank you for your patience.';

  @override
  String get bannedPendingBody =>
      'The Arena Request team has 48 hours to review your request. You will be notified as soon as a decision is made.';

  @override
  String get bannedYourMessageLabel => 'Your message';

  @override
  String get bannedRejectedTitle => '❌ Previous request rejected';

  @override
  String get bannedReasonLabel => 'Reason';

  @override
  String get bannedRejectedBody =>
      'You can submit a new request with additional details below.';

  @override
  String get bannedApprovedTitle => '✅ Reinstatement approved';

  @override
  String get bannedApprovedBody =>
      'Welcome back to ARENA! Sign in again to access your account.';

  @override
  String get cguCompleteProfileTitle => 'COMPLETE YOUR\nPROFILE';

  @override
  String get cguCompleteProfileSubtitle =>
      'A few details are missing before you can play.';

  @override
  String get cguWhatsappHint => 'E.g. 07 07 07 07 07';

  @override
  String get cguWhatsappInvalid => 'Invalid WhatsApp number.';

  @override
  String get cguReadTermsLink => 'Read the Terms of Service';

  @override
  String get cguReadPrivacyLink => 'Read the privacy policy';

  @override
  String get cguAcceptTermsConsent =>
      'I accept the Terms of Service and the privacy policy';

  @override
  String get cguMarketingConsent =>
      'I agree to receive information about new tournaments (optional)';

  @override
  String get cguContinueButton => 'CONTINUE';

  @override
  String get cguRefuseSignOut => 'Decline and log out';

  @override
  String get cguDocPlaceholderBody =>
      'The full version will be displayed here (PHASE 9 — AboutPage + WebView to the hosted docs).';

  @override
  String get cguDialogOk => 'OK';

  @override
  String get cguCountryLabel => 'COUNTRY';

  @override
  String get linkAccountDefaultProvider => 'Google';

  @override
  String get linkAccountAppBarTitle => 'Link accounts';

  @override
  String get linkAccountExistsTitle => 'Account already exists';

  @override
  String get linkAccountExistingMethodsLabel => 'EXISTING METHODS';

  @override
  String get linkAccountEmailPasswordMethod => 'Email + password';

  @override
  String get linkAccountChooseContinue => 'Choose how to continue below.';

  @override
  String get linkAccountLinkBothButton => '🔗 LINK BOTH ACCOUNTS';

  @override
  String get linkAccountPhaseSnack =>
      'Available in PHASE 2.3 (Google/Apple social login).';

  @override
  String get linkAccountLoginPasswordButton => 'SIGN IN WITH PASSWORD';

  @override
  String get linkAccountCancelButton => 'Cancel';

  @override
  String get registerEmailRequired => 'Email required.';

  @override
  String get registerEmailInvalid => 'Invalid email format.';

  @override
  String get registerPasswordTooShort => '8 characters minimum.';

  @override
  String get registerPasswordMismatch => 'Passwords do not match.';

  @override
  String get registerAccountStepTitle => 'CREATE\nYOUR ACCOUNT';

  @override
  String get registerAccountStepSubtitle =>
      'Email + password (8 characters minimum).';

  @override
  String get registerGoogleSignUp => 'Sign up with Google';

  @override
  String get registerEmailLabel => 'EMAIL';

  @override
  String get registerPasswordLabel => 'PASSWORD';

  @override
  String get registerPasswordConfirmLabel => 'CONFIRM PASSWORD';

  @override
  String get registerAccountContinueButton => 'CONTINUE';

  @override
  String get registerProfileStepTitle => 'YOUR\nPROFILE';

  @override
  String get registerProfileStepSubtitle =>
      'Username + country + acceptance of the Terms.';

  @override
  String get registerUsernameLabel => 'USERNAME';

  @override
  String get registerUsernameHint => '3 to 20 characters';

  @override
  String get registerWhatsappHint => 'E.g. 07 07 07 07 07';

  @override
  String get registerWhatsappInvalid => 'Invalid WhatsApp number.';

  @override
  String get registerAvatarColorLabel => 'AVATAR COLOR';

  @override
  String get registerReferralCodeLabel => 'REFERRAL CODE (OPTIONAL)';

  @override
  String get registerReferralCodeHint => 'E.g. ARN-3F9A';

  @override
  String get registerReferralCodeHelper =>
      'The code of an ARENA friend. Lets you appear in their referrals — leave empty if you don\'t have one.';

  @override
  String get registerCguConsent => 'I accept the Terms of Service';

  @override
  String get registerPrivacyConsent => 'I accept the Privacy Policy';

  @override
  String get registerMarketingConsent =>
      'I agree to receive marketing communications (optional)';

  @override
  String get registerCreateAccountButton => 'CREATE MY ACCOUNT';

  @override
  String get registerCountryLabel => 'COUNTRY';

  @override
  String get registerSuccessTitle => 'ACCOUNT\nCREATED';

  @override
  String get registerSuccessSubtitle =>
      'Welcome to ARENA. You\'re ready to join the tournaments.';

  @override
  String get registerSuccessContinueButton => 'CONTINUE';

  @override
  String get registerOrDivider => 'OR';

  @override
  String get resetCodeNewCodeSent => 'New code sent.';

  @override
  String get resetCodeTitle => 'VERIFICATION';

  @override
  String get resetCodeSubtitle => 'Enter the 6-digit code sent to';

  @override
  String get resetCodeFieldLabel => 'CODE';

  @override
  String get resetCodeVerifyButton => 'VERIFY';

  @override
  String get resetCodeResending => 'Sending…';

  @override
  String get resetCodeResendButton => 'Resend code';

  @override
  String get resetPwPasswordRequired => 'Password required';

  @override
  String get resetPwMinChars => 'Minimum 8 characters';

  @override
  String get resetPwPasswordsDontMatch => 'Passwords do not match';

  @override
  String get resetPwTitle => 'NEW PASSWORD';

  @override
  String get resetPwSubtitle =>
      'Choose a strong password. It will be used for your next login.';

  @override
  String get resetPwNewPasswordLabel => 'NEW PASSWORD';

  @override
  String get resetPwNewPasswordHint => 'At least 8 characters';

  @override
  String get resetPwConfirmLabel => 'CONFIRM';

  @override
  String get resetPwConfirmHint => 'Re-enter your password';

  @override
  String get resetPwUpdateButton => 'UPDATE';

  @override
  String get resetPwSuccessTitle => 'PASSWORD UPDATED';

  @override
  String get resetPwSuccessSubtitle =>
      'You can now log in with your new password.';

  @override
  String get resetPwLoginButton => 'LOG IN';

  @override
  String get splashTagline => 'Pan-African e-sports';

  @override
  String get splashLoginButton => 'LOG IN';

  @override
  String get splashCreateAccountButton => 'CREATE AN ACCOUNT';

  @override
  String get splashVersionLabel => 'v1.0 — ARENA Cameroon';

  @override
  String get splashStatPlayers => 'players';

  @override
  String get splashStatTournaments => 'tournaments';

  @override
  String get splashStatXaf => 'XAF';

  @override
  String get bracketEmptyTitle => 'Bracket not generated yet';

  @override
  String get bracketEmptyDescription =>
      'The bracket will appear here as soon as the admin closes registrations and launches the draw.';

  @override
  String get bracketZoomHint => '↔ pinch to zoom · drag to navigate';

  @override
  String get groupStandingsEmptyTitle => 'No standings yet';

  @override
  String get groupStandingsEmptyDescription =>
      'The standings will appear as soon as the first matches are played.';

  @override
  String get groupStandingsColPlayer => 'PLAYER';

  @override
  String get groupStandingsColPlayed => 'P';

  @override
  String get groupStandingsColWins => 'W';

  @override
  String get groupStandingsColDraws => 'D';

  @override
  String get groupStandingsColLosses => 'L';

  @override
  String get groupStandingsColGoalsFor => 'GF';

  @override
  String get groupStandingsColGoalsAgainst => 'GA';

  @override
  String get groupStandingsColDiff => 'Diff';

  @override
  String get groupStandingsColPoints => 'Pts';

  @override
  String get groupStandingsPlayerFallback => 'Player ';

  @override
  String get callPlaceCallFailed => 'Unable to start the call.';

  @override
  String get callNoAnswer => 'No answer.';

  @override
  String get callDeclined => 'Call declined.';

  @override
  String get callEnded => 'Call ended.';

  @override
  String get callStatusConnecting => 'Connecting…';

  @override
  String get callStatusRinging => 'Ringing…';

  @override
  String get callStatusConnected => 'In call';

  @override
  String get callStatusEnded => 'Call ended';

  @override
  String get callStatusFailed => 'Call failed';

  @override
  String get callControlUnmute => 'Unmute';

  @override
  String get callControlMute => 'Mute';

  @override
  String get callControlSpeaker => 'Speaker';

  @override
  String get callControlEarpiece => 'Earpiece';

  @override
  String get callControlClose => 'Close';

  @override
  String get chatOfflineQueued =>
      'Offline — message will be sent when you reconnect.';

  @override
  String get chatSendFailed => 'Unable to send: ';

  @override
  String get chatPickerUnavailable => 'Picker unavailable: ';

  @override
  String get chatUploadFailed => 'Upload failed: ';

  @override
  String get chatAttachGallery => 'Choose from gallery';

  @override
  String get chatAttachCamera => 'Take a photo';

  @override
  String get chatDeleteDialogTitle => 'Delete this message?';

  @override
  String get chatDeleteDialogContent =>
      'This message will be marked as deleted. The other player will see \"Message deleted\" instead.';

  @override
  String get chatDeleteDialogCancel => 'Cancel';

  @override
  String get chatDeleteDialogConfirm => 'DELETE';

  @override
  String get chatGenericFailure => 'Failed: ';

  @override
  String get chatEmptyTitle => 'No messages yet';

  @override
  String get chatEmptyDescription => 'Be the first to write here.';

  @override
  String get chatAppBarUsernameFallback => 'Player';

  @override
  String get chatAppBarTyping => 'typing…';

  @override
  String get chatAppBarOnline => 'online';

  @override
  String get chatAppBarOffline => 'offline';

  @override
  String get chatMessageDeleted => 'Message deleted';

  @override
  String get chatMediaUnsupported => 'Media: ';

  @override
  String get chatRoomCodeCopied => 'Code copied';

  @override
  String get chatRoomCodeTapToCopy => 'tap to copy';

  @override
  String get chatInputTooltipKeyboard => 'Keyboard';

  @override
  String get chatInputTooltipEmoji => 'Emoji';

  @override
  String get chatInputTooltipAttach => 'Attach an image';

  @override
  String get chatInputHint => 'Message…';

  @override
  String get friendChatOfflineQueued =>
      'Offline — message will be sent when you reconnect.';

  @override
  String get friendChatSendFailed => 'Couldn\'t send: ';

  @override
  String get friendChatPickerFailed => 'Picker: ';

  @override
  String get friendChatGenericFailure => 'Failed: ';

  @override
  String get friendChatAttachGallery => 'Choose from gallery';

  @override
  String get friendChatAttachCamera => 'Take a photo';

  @override
  String get friendChatDeleteDialogTitle => 'Delete this message?';

  @override
  String get friendChatDeleteDialogContent =>
      'Your friend will see «Message deleted» instead.';

  @override
  String get friendChatDeleteDialogCancel => 'Cancel';

  @override
  String get friendChatDeleteDialogConfirm => 'DELETE';

  @override
  String get friendChatEmptyTitle => 'Start the conversation';

  @override
  String get friendChatEmptyDescription =>
      'Send a first message to your friend.';

  @override
  String get friendChatUsernameFallback => 'Friend';

  @override
  String get friendChatSubtitleFriend => 'Friend';

  @override
  String get inboxAppBarTitle => 'MESSAGES';

  @override
  String get inboxComposeTooltip => 'Search for a player';

  @override
  String get inboxTabDirect => 'DIRECT';

  @override
  String get inboxTabTournaments => 'TOURNAMENTS';

  @override
  String get inboxNoConversationsTitle => 'No conversations';

  @override
  String get inboxNoConversationsDesc =>
      'Log back in to see your conversations.';

  @override
  String get inboxSectionFriends => 'FRIENDS';

  @override
  String get inboxSectionMatches => 'MATCHES';

  @override
  String get inboxEmptyHint =>
      'No conversations yet.\nStart a chat from the match room\nor from the Friends tab.';

  @override
  String get inboxDeleteDialogTitle => 'Delete this conversation?';

  @override
  String get inboxDeleteDialogContent =>
      'The conversation will be removed from your inbox. You can find it again by reopening the chat later.';

  @override
  String get inboxDeleteCancel => 'Cancel';

  @override
  String get inboxDeleteConfirm => 'DELETE';

  @override
  String get inboxDeleteFailure => 'Failed: ';

  @override
  String get inboxOpponentWaiting => 'Waiting';

  @override
  String get inboxMatchPending => 'Waiting for an opponent';

  @override
  String get inboxMatchScheduled => 'Match scheduled';

  @override
  String get inboxMatchReady => 'Room code shared';

  @override
  String get inboxMatchInProgress => 'In progress — tap to chat';

  @override
  String get inboxMatchScorePending => 'Awaiting the score';

  @override
  String get inboxMatchAwaitingValidation => 'Score validation';

  @override
  String get inboxMatchDisputed => 'Score disputed — admin reviewing';

  @override
  String get inboxMatchCompleted => 'Match completed';

  @override
  String get inboxMatchCancelled => 'Match cancelled';

  @override
  String get inboxMatchForfeited => 'Forfeit';

  @override
  String get inboxTimeSoon => 'Soon';

  @override
  String get inboxCompRegistrationOpen => 'Registration open';

  @override
  String get inboxCompRegistrationClosed => 'Registration closed';

  @override
  String get inboxCompOngoing => 'Ongoing';

  @override
  String get inboxCompCompleted => 'Completed';

  @override
  String get inboxCompCancelled => 'Cancelled';

  @override
  String get inboxCompDraft => 'Draft';

  @override
  String get inboxNoActiveCompTitle => 'No active competition';

  @override
  String get inboxNoActiveCompDesc =>
      'Discussion threads linked to your competitions will appear here as soon as you join a tournament.';

  @override
  String get inboxWaitingTitle => 'Waiting';

  @override
  String get inboxWaitingDesc =>
      'You are registered but the competitions haven\'t loaded yet.';

  @override
  String get inboxChatWithFriend => 'Chat with your friend';

  @override
  String get inboxFriendDefaultName => 'Friend';

  @override
  String get inboxArenaTeam => 'ARENA Team';

  @override
  String get inboxArenaOfficialBadge => 'OFFICIAL';

  @override
  String get inboxArenaPreviewDefault =>
      'Support, announcements and official info';

  @override
  String get inboxArenaPreviewImage => '📷 Image';

  @override
  String get inboxTimeJustNow => 'just now';

  @override
  String get inboxErrorPrefix => 'Error: ';

  @override
  String get compDetailAppBarTitle => 'COMPETITION';

  @override
  String get compDetailNotFoundTitle => 'Competition not found';

  @override
  String get compDetailNotFoundDesc => 'It may have been deleted by an admin.';

  @override
  String get compDetailStatusDraft => 'DRAFT';

  @override
  String get compDetailStatusOpen => 'OPEN';

  @override
  String get compDetailStatusFull => 'REGISTRATIONS CLOSED';

  @override
  String get compDetailStatusOngoing => 'ONGOING';

  @override
  String get compDetailStatusCompleted => 'COMPLETED';

  @override
  String get compDetailStatusCancelled => 'CANCELLED';

  @override
  String get compDetailCtaRegisterFree => 'REGISTER FOR FREE';

  @override
  String get compDetailCtaRegisterPaidPrefix => 'REGISTER · ';

  @override
  String get compDetailRegistrationsClosed => 'REGISTRATION CLOSED';

  @override
  String get compDetailGatedLockNotice =>
      '🔒 Bracket, live matches and 1-on-1 chat are reserved for registered players.';

  @override
  String get compDetailPrizeFree => 'FREE';

  @override
  String get compDetailPrizeFreeLabel => 'FREE ENTRY';

  @override
  String get compDetailPrizeToWinLabel => 'TO WIN';

  @override
  String get compDetailTabInfos => 'INFO';

  @override
  String get compDetailTabParticipants => 'PLAYERS';

  @override
  String get compDetailTabRanking => 'RANKING';

  @override
  String get compDetailParticipantsTitle => 'Participants list';

  @override
  String get compDetailParticipantsDesc =>
      'The list of registered players with avatars and stats will appear here. Source: `registrations` table.';

  @override
  String get compDetailInfoPrizeLabel => 'Reward';

  @override
  String get compDetailInfoPrizeNone => 'None';

  @override
  String get compDetailInfoFeeLabel => 'Entry fee';

  @override
  String get compDetailInfoFeeFree => 'Free';

  @override
  String get compDetailInfoFormatLabel => 'Format';

  @override
  String get compDetailInfoStartLabel => 'Start';

  @override
  String get compDetailInfoCapacityLabel => 'Capacity';

  @override
  String get compDetailInfoCapacitySuffix => ' players';

  @override
  String get compDetailDescriptionHeader => '📝 DESCRIPTION';

  @override
  String get compDetailRankingNoParticipantTitle => 'No participants';

  @override
  String get compDetailRankingNoParticipantDesc =>
      'No one has registered for this competition yet.';

  @override
  String get compDetailRankingNotPublishedTitle => 'Ranking not published yet';

  @override
  String get compDetailRankingNotPublishedDesc =>
      'The organizers will publish the final ranking once the competition is over.';

  @override
  String get compDetailRankingUnranked => 'Unranked';

  @override
  String get compDetailRankingPlaceSuffix => ' place';

  @override
  String get compDetailFormatSingleElim => 'Single elimination';

  @override
  String get compDetailFormatGroupsKnockout => 'Groups + knockout';

  @override
  String get compDetailFormatRoundRobin => 'Round robin';

  @override
  String get compDetailTabBracket => 'BRACKET';

  @override
  String get compDetailTabGroups => 'GROUPS';

  @override
  String get compListReset => 'Reset';

  @override
  String get compListEmptyTitleAll => 'No competitions';

  @override
  String get compListEmptyTitleGamePrefix => 'No competitions on ';

  @override
  String get compListEmptyDesc =>
      'New tournaments are published every week. Come back soon!';

  @override
  String get compListFilterStatus => 'Status';

  @override
  String get compListFilterPricing => 'Pricing';

  @override
  String get compListFormatSingleElim => 'Single elimination';

  @override
  String get compListFormatGroupsKnockout => 'Groups + knockout';

  @override
  String get compListFormatRoundRobin => 'Round robin';

  @override
  String get regConfirmAppBarTitle => 'CHECKOUT';

  @override
  String get regConfirmPrizeDistribution => 'PRIZE DISTRIBUTION';

  @override
  String get regConfirmDownloadGame => 'DOWNLOAD THE GAME';

  @override
  String get regConfirmCtaReferralsInsufficient => '👥 NOT ENOUGH REFERRALS';

  @override
  String get regConfirmCtaRegisterFree => 'REGISTER FOR FREE';

  @override
  String get regConfirmCtaProceedPaymentPrefix => 'PROCEED TO PAYMENT · ';

  @override
  String get regConfirmCtaXafSuffix => ' XAF';

  @override
  String get regConfirmCancel => 'Cancel';

  @override
  String get regConfirmNoSession => 'No session — registration unavailable.';

  @override
  String get regConfirmOfflineQueued =>
      'Offline — registration saved, confirmed once reconnected.';

  @override
  String get regConfirmConfirmedPrefix => 'Registration confirmed for ';

  @override
  String get regConfirmErrorPrefix => 'Error: ';

  @override
  String get regConfirmDisplayTitleStart => 'Confirm ';

  @override
  String get regConfirmDisplayTitleAccent => 'your registration.';

  @override
  String get regConfirmPillFree => 'FREE';

  @override
  String get regConfirmPillPaid => 'PAID';

  @override
  String get regConfirmBreakdownFee => 'Entry fee';

  @override
  String get regConfirmBreakdownService => 'Service fee';

  @override
  String get regConfirmBreakdownServiceIncluded => 'Included';

  @override
  String get regConfirmBreakdownTotal => 'Total to pay';

  @override
  String get regConfirmRanksRewardedSingle => '1 rank rewarded';

  @override
  String get regConfirmRanksRewardedPluralSuffix => ' ranks rewarded';

  @override
  String get regConfirmAckLabel =>
      'I accept the tournament rules and the internal regulations.';

  @override
  String get regConfirmStoreLinkError => 'Could not open the link.';

  @override
  String get regConfirmPlayStore => 'Play Store';

  @override
  String get regConfirmAppStore => 'App Store';

  @override
  String get referralCardTitle => 'Referral required';

  @override
  String get referralQuotaReached => '✓ Quota reached — you can register!';

  @override
  String get referralShareSubject => 'Join me on ARENA';

  @override
  String get referralYourCodeLabel => 'YOUR CODE';

  @override
  String get referralCopyButton => 'Copy';

  @override
  String get referralShareButton => 'Share';

  @override
  String get homeSectionNextMatch => '⚡ NEXT MATCH';

  @override
  String get homeSectionLive => 'LIVE NOW';

  @override
  String get homeSectionActiveTournaments => '★ MY TOURNAMENTS';

  @override
  String get homeSectionYourStats => '📊 YOUR STATS';

  @override
  String get homeViewAllLink => 'View all';

  @override
  String get mainLayoutExitConfirm => 'Tap again to exit ARENA';

  @override
  String get mainLayoutTitleHome => 'HOME';

  @override
  String get mainLayoutTitleCompetitions => 'COMPETITIONS';

  @override
  String get mainLayoutTitleMessages => 'MESSAGES';

  @override
  String get mainLayoutTitleProfile => 'PROFILE';

  @override
  String get mainLayoutNavHome => 'Home';

  @override
  String get mainLayoutNavCompetitions => 'Competitions';

  @override
  String get mainLayoutNavChat => 'Chat';

  @override
  String get mainLayoutNavProfile => 'Profile';

  @override
  String get homeHeaderDefaultUsername => 'Player';

  @override
  String get homeHeaderTierBronze => '🥉 BRONZE';

  @override
  String get homeHeaderSearchTooltip => 'Search for a player';

  @override
  String get liveStreamsErrorPrefix => 'Error: ';

  @override
  String get liveStreamsBadgeLive => 'LIVE';

  @override
  String get liveStreamsTapToWatch => 'Tap to watch live';

  @override
  String get liveStreamsEmptyState => 'No live stream right now';

  @override
  String get pendingPaymentCompetitionFallback => 'Competition';

  @override
  String get pendingPaymentSingleTitle => 'Payment awaiting validation';

  @override
  String get pendingPaymentTapToCheck => 'Tap to check the status';

  @override
  String get promoBannerLinkOpenError => 'Unable to open the link.';

  @override
  String get tutorialWatchCta => 'Watch the tutorial';

  @override
  String get statGridMatchesLabel => 'Matches';

  @override
  String get statGridWdlLabel => 'W/L/D';

  @override
  String get statGridWinRateLabel => 'Win rate';

  @override
  String get upcomingMatchesEmpty => 'No scheduled match';

  @override
  String get upcomingMatchOpponentWaiting => 'Waiting';

  @override
  String get upcomingMatchLive => 'LIVE';

  @override
  String get upcomingBadgeInProgress => 'IN PROGRESS';

  @override
  String get upcomingBadgeToSchedule => 'TO SCHEDULE';

  @override
  String get upcomingBadgeReady => 'READY';

  @override
  String get upcomingBadgeTomorrow => 'TOMORROW';

  @override
  String get upcomingPhaseMatch => 'Match';

  @override
  String get upcomingPhaseFinal => 'Final';

  @override
  String get upcomingPhaseSemiFinal => 'Semi-final';

  @override
  String get upcomingPhaseQuarterFinal => 'Quarter-final';

  @override
  String get upcomingPhaseRoundOf16 => 'Round of 16';

  @override
  String get upcomingPhaseRoundOf32 => 'Round of 32';

  @override
  String get matchRoomTitleDefault => 'MATCH';

  @override
  String get matchRoomChatTooltip => 'Chat with your opponent';

  @override
  String get matchRoomNotFoundTitle => 'Match not found';

  @override
  String get matchRoomNotFoundDescription =>
      'The match may have been cancelled by an admin.';

  @override
  String get manualUploadButtonLabel => 'Send a proof video';

  @override
  String get manualUploadSuccess => 'Video sent. Thank you!';

  @override
  String get outcomeFinalScore => 'FINAL SCORE';

  @override
  String get outcomeDraw => 'Draw.';

  @override
  String get outcomeEditMyScore => 'EDIT MY SCORE';

  @override
  String get outcomeDisputeInProgress => 'DISPUTE IN PROGRESS';

  @override
  String get outcomeDisputeExplanation =>
      'Your scores don\'t match. If you made a mistake, correct it; otherwise wait for your opponent to correct theirs. Without an agreement, an admin will decide based on the evidence.';

  @override
  String get outcomeScoreCardYou => 'YOU';

  @override
  String get outcomeScoreCardPlayer1 => 'PLAYER 1';

  @override
  String get outcomeScoreCardPlayer2 => 'PLAYER 2';

  @override
  String get matchHeaderPlayer1 => 'Player 1';

  @override
  String get matchHeaderPlayer2 => 'Player 2';

  @override
  String get matchHeaderBadgeHome => 'HOME';

  @override
  String get matchHeaderBadgeAway => 'AWAY';

  @override
  String get recordingActionResume => 'Resume';

  @override
  String get recordingActionPause => 'Pause (max 2 min)';

  @override
  String get recordingActionSaveStop => 'Save and stop';

  @override
  String get recordingActionForfeit => 'Stop (forfeit)';

  @override
  String get recordingNoRecordingInProgress => 'No recording in progress.';

  @override
  String get recordingStateRecording => 'Recording in progress';

  @override
  String get recordingStatePaused => 'Paused — resume within 2 min';

  @override
  String get recordingStateForfeited => 'Forfeit declared';

  @override
  String get recordingStateStopped => 'Recording stopped';

  @override
  String get recordingStateIdle => 'No recording';

  @override
  String get recordingLiveStreamStarted => 'Live broadcast started.';

  @override
  String get recordingReplaySavedDownloads =>
      'Replay saved in Downloads › ARENA';

  @override
  String get recordingReplayInCache => 'Replay available in the app cache';

  @override
  String get recordingPermMissingMic => 'microphone';

  @override
  String get recordingPermMissingNotifications => 'notifications';

  @override
  String get recordingPermOverlayNeedsSettings =>
      'Enable \"Display over other apps\" for ARENA in Settings > Apps > Special access';

  @override
  String get recordingPermOverlayDenied =>
      'Overlay denied — tap I\'M IN THE ROOM again after enabling';

  @override
  String get recordingBannerRecording =>
      'Anti-cheat recording in progress\nTap for actions';

  @override
  String get recordingBannerPaused => 'Match paused — tap to resume or stop';

  @override
  String get recordingBannerForfeitPauseExpired =>
      'Forfeit: pause time exceeded';

  @override
  String get recordingBannerForfeitDeclared => 'Forfeit declared';

  @override
  String get stepBodyMatchInProgressTitle => 'Match in progress';

  @override
  String get stepBodyMatchInProgressDesc =>
      'The players are currently playing or validating the score.';

  @override
  String get stepBodyMatchCancelledTitle => 'MATCH CANCELLED';

  @override
  String get stepBodyMatchCancelledDesc => 'The admin cancelled this match.';

  @override
  String get stepBodyForfeitTitle => 'FORFEIT';

  @override
  String get stepBodyForfeitDesc => 'One of the players did not start in time.';

  @override
  String get stepBodyAwaitRoomCodeTitle => 'Waiting for the room code';

  @override
  String get stepBodyAwaitRoomCodeDesc =>
      'The players will create a room in the game and share the code here.';

  @override
  String get stepBodyAwaitHomeCodeTitle => 'Waiting for the HOME code';

  @override
  String get stepBodyAwaitHomeCodeDesc =>
      'You are AWAY in this match. The home player creates the room in the game and will send you the code here as soon as they have shared it.';

  @override
  String get openChatButton => 'OPEN CHAT';

  @override
  String get roomReadyMarkStartedError => 'Unable to mark as started: ';

  @override
  String get roomReadyCodeCopied => 'Code copied to clipboard';

  @override
  String get roomReadyHintObserver =>
      'The players will join the room and start the match.';

  @override
  String get roomReadyHintHome =>
      'You shared the code. Waiting for your opponent to join, then confirm the start together.';

  @override
  String get roomReadyHintAway =>
      'Join the room in the game with this code, then confirm once both players are in.';

  @override
  String get roomReadyCodeLabel => 'ROOM CODE';

  @override
  String get roomReadyCopyTooltip => 'Copy code';

  @override
  String get roomReadyTeamNameLabel => 'YOUR TEAM NAME';

  @override
  String get roomReadyTeamNameHint => 'E.g. Real Madrid, FC Barcelona…';

  @override
  String get roomReadyTeamNameHelper =>
      'Required — the team you use for this match. Visible to the admin in case of an anti-cheat dispute.';

  @override
  String get roomReadyInRoomButton => 'I\'M IN THE ROOM';

  @override
  String get roomReadyCodeSharedBadge => 'CODE SHARED';

  @override
  String get roomReadySyncingHint => 'Syncing with your opponent…';

  @override
  String get scoreEditErrorRange => 'Scores must be between 0 and 99.';

  @override
  String get scoreEditErrorTieBeforePens =>
      'Regulation score must be tied before the penalty shootout.';

  @override
  String get scoreEditErrorPensRange => 'Penalties must be between 0 and 30.';

  @override
  String get scoreEditErrorPensTie =>
      'The penalty shootout cannot end in a tie.';

  @override
  String get scoreEditDialogTitle => 'Edit your score';

  @override
  String get scoreEditMyScoreLabel => 'My score';

  @override
  String get scoreEditOpponentLabel => 'Opponent';

  @override
  String get scoreEditViaPenaltiesLabel => 'Decided on penalties';

  @override
  String get scoreEditMyPenLabel => 'My pens';

  @override
  String get scoreEditOppPenLabel => 'Opp. pens';

  @override
  String get scoreEditCancelButton => 'Cancel';

  @override
  String get scoreEditResendButton => 'RESUBMIT';

  @override
  String get scoreFlowErrorRange => 'Scores must be between 0 and 99.';

  @override
  String get scoreFlowErrorTieBeforePens =>
      'The regulation score must be tied before the penalty shootout.';

  @override
  String get scoreFlowErrorPensRange => 'Penalties must be between 0 and 30.';

  @override
  String get scoreFlowErrorPensTie =>
      'The penalty shootout cannot end in a tie.';

  @override
  String get scoreFlowSubmitError => 'Unable to submit: ';

  @override
  String get scoreFlowProofUploadError => 'Upload failed: ';

  @override
  String get scoreFlowResolutionError => 'Resolution error: ';

  @override
  String get scoreFlowSessionExpiredTitle => 'Session expired';

  @override
  String get scoreFlowSessionExpiredDescription =>
      'Sign in again to enter a score.';

  @override
  String get scoreFlowEnterFinalScoreLabel => 'ENTER THE FINAL SCORE';

  @override
  String get scoreFlowEnterFinalScoreHint =>
      'Enter the goals for each side. If both your entries match, the match is validated automatically.';

  @override
  String get scoreFlowMyScoreLabel => 'My score';

  @override
  String get scoreFlowOppScoreLabel => 'Opponent score';

  @override
  String get scoreFlowViaPenaltiesTitle => 'Match decided on penalties';

  @override
  String get scoreFlowViaPenaltiesSubtitle =>
      'Only check this if the regulation score is tied.';

  @override
  String get scoreFlowMyPenLabel => 'My penalties';

  @override
  String get scoreFlowOppPenLabel => 'Opponent penalties';

  @override
  String get scoreFlowSubmitButton => 'SUBMIT SCORE';

  @override
  String get scoreFlowValidationInProgress => 'VALIDATION IN PROGRESS';

  @override
  String get scoreFlowWaitingOpponent => 'WAITING FOR YOUR OPPONENT';

  @override
  String get scoreFlowYouSubmitted => 'You submitted: ';

  @override
  String get scoreFlowOnPenalties => 'On penalties: ';

  @override
  String get scoreFlowComparingScores => 'Comparing both players\' scores…';

  @override
  String get scoreFlowOpponentNotSubmitted =>
      'Your opponent hasn\'t entered their score yet.';

  @override
  String get scoreFlowProofAttached => 'Proof attached';

  @override
  String get scoreFlowProofPrompt => 'Attach a photo or video (recommended)';

  @override
  String get scoreFlowProofHelper =>
      'Screenshot of the match end screen or a clip of the last action — useful in case of a dispute.';

  @override
  String get scoreFlowUploading => 'Uploading…';

  @override
  String get scoreFlowReplaceButton => 'Replace';

  @override
  String get scoreFlowRemoveProofTooltip => 'Remove proof';

  @override
  String get scoreFlowChooseFileButton => 'Choose a file';

  @override
  String get shareCodeErrorLength =>
      'The code must be between 4 and 12 characters.';

  @override
  String get shareCodeErrorSendFailed => 'Unable to share the code: ';

  @override
  String get shareCodeRoomLabel => 'ROOM CODE (HOST CREATES)';

  @override
  String get shareCodeEnterPrompt => 'Enter your eFootball code:';

  @override
  String get shareCodeOpponentWillReceive =>
      'Your opponent will receive this code in the chat as soon as you send it.';

  @override
  String get shareCodeOpponentReceives =>
      'Your opponent receives this code in the chat as soon as you send it.';

  @override
  String get shareCodeSubmitButton => 'SEND CODE';

  @override
  String get shareCodeInputHint => 'e.g. 8K3-TZ9';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllReadTooltip => 'Mark all as read';

  @override
  String get notificationsMarkAllReadError => 'Unable to mark all as read.';

  @override
  String get notificationsLoadError => 'Loading error.\n';

  @override
  String get notificationsSignedOut => 'Sign in to see your notifications.';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsFilterAll => 'All';

  @override
  String get notificationsFilterMatch => 'Matches';

  @override
  String get notificationsFilterEarning => 'Earnings';

  @override
  String get notificationsFilterSystem => 'System';

  @override
  String get notificationsTimeJustNow => 'Just now';

  @override
  String get notificationsTimeYesterday => 'Yesterday';

  @override
  String get mobileMoneyDefaultCountry => '🇨🇲 Cameroon';

  @override
  String get mobileMoneyCountryLabel => 'COUNTRY';

  @override
  String get mobileMoneyNumberLabel => 'NUMBER ';

  @override
  String get mobileMoneyNumberHelp =>
      'The number you will pay from (helps the super-admin locate your transaction).';

  @override
  String get mobileMoneyPhoneValid => '✓ Valid number ';

  @override
  String get mobileMoneySubmitSending => 'SENDING…';

  @override
  String get mobileMoneySubmitPaid => 'I HAVE PAID ';

  @override
  String get mobileMoneyCodeCopied => 'Merchant code copied.';

  @override
  String get mobileMoneyDialerError =>
      'Unable to open the dialer. Copy the code and dial it manually.';

  @override
  String get mobileMoneySubmitError => 'Error while sending: ';

  @override
  String get mobileMoneyNoConnection => 'No connection: ';

  @override
  String get mobileMoneyHeroPayment => 'Payment ';

  @override
  String get mobileMoneyHeroForAmount => 'For ';

  @override
  String get mobileMoneyMerchantCodeTitle => 'Merchant code';

  @override
  String get mobileMoneyCopyButton => '📋 COPY';

  @override
  String get mobileMoneyExecuteButton => '📞 EXECUTE';

  @override
  String get mobileMoneyMissingCodeTitle => '⚠ Merchant code missing';

  @override
  String get mobileMoneyMissingCodeBody =>
      'The admin has not yet set up a merchant code for this method on this competition. Choose another method or contact support.';

  @override
  String get mobileMoneyDisclaimerExactAmount =>
      'Pay the EXACT amount — otherwise the super-admin will reject it';

  @override
  String get mobileMoneyDisclaimerKeepSms =>
      'Keep the Mobile Money confirmation SMS as proof';

  @override
  String get mobileMoneyDisclaimerManualValidation =>
      'The admin manually validates your payment after receipt';

  @override
  String get mobileMoneyDisclaimerTitle => '⚠ Before you continue';

  @override
  String get paymentFailedRejectedWithReason =>
      'The super-admin rejected your payment: ';

  @override
  String get paymentFailedRejectedGeneric =>
      'The super-admin rejected your payment (incorrect amount or transaction not found on the merchant account).';

  @override
  String get paymentFailedNetwork =>
      'Network problem during sending. No charge was made on the ARENA side.';

  @override
  String get paymentFailedUnknown =>
      'The payment could not be confirmed. Try again or contact support.';

  @override
  String get paymentFailedSolutionCheckAmount =>
      'Check the exact amount + the merchant code';

  @override
  String get paymentFailedSolutionRetryFromSignup =>
      'Start again from the Registration page';

  @override
  String get paymentFailedSolutionContactIfError =>
      'Contact support if you think this is a mistake';

  @override
  String get paymentFailedSolutionCheckInternet =>
      'Check your Internet connection';

  @override
  String get paymentFailedSolutionContactSupport => 'Contact ARENA support';

  @override
  String get paymentFailedAccountNotRegistered =>
      'Your account was not registered.';

  @override
  String get paymentFailedRetryButton => '↻ TRY AGAIN';

  @override
  String get paymentFailedContactSupportLink => 'Contact ARENA support';

  @override
  String get paymentFailedTitleRejected => 'PAYMENT REJECTED';

  @override
  String get paymentFailedTitleFailed => 'PAYMENT FAILED';

  @override
  String get paymentFailedCauseTitle => '⚠ Cause';

  @override
  String get paymentFailedErrorCodeLabel => 'Error code: ';

  @override
  String get paymentFailedSolutionsTitle => '💡 Solutions';

  @override
  String get paymentHistoryAppBarTitle => 'HISTORY';

  @override
  String get paymentHistoryErrorPrefix => 'Error: ';

  @override
  String get paymentHistoryTabPayments => 'PAYMENTS';

  @override
  String get paymentHistoryTabGains => 'WINNINGS';

  @override
  String get paymentHistoryGainsEmpty =>
      'No winnings yet. Win a competition to receive a payout!';

  @override
  String get paymentHistoryBadgePaid => 'PAID OUT';

  @override
  String get paymentHistoryBadgePending => 'PENDING';

  @override
  String get paymentHistoryBadgeToClaim => 'TO CLAIM';

  @override
  String get paymentHistoryGainRanked => 'Winnings · rank ';

  @override
  String get paymentHistoryGainGeneric => 'Competition winnings';

  @override
  String get paymentHistoryClaimButton => 'CLAIM MY WINNINGS';

  @override
  String get paymentHistoryClaimSuccess =>
      'Winnings claimed — the staff will process the payout.';

  @override
  String get paymentHistoryClaimFailPrefix => 'Failed: ';

  @override
  String get paymentHistoryClaimSheetTitle => 'Claim my winnings';

  @override
  String get paymentHistoryClaimSheetSubtitle =>
      'Enter the Mobile Money number where you want to receive your payout.';

  @override
  String get paymentHistoryClaimMethodMtn => 'MTN MoMo';

  @override
  String get paymentHistoryClaimMethodOrange => 'Orange Money';

  @override
  String get paymentHistoryClaimPhoneHint =>
      'Mobile Money number (e.g. +237 6XX XX XX XX)';

  @override
  String get paymentHistoryClaimConfirm => 'CONFIRM';

  @override
  String get paymentHistoryClaimPhoneRequired => 'Number required.';

  @override
  String get paymentHistoryEmptyPayments => 'No payments yet.';

  @override
  String get paymentHistoryNetBalanceLabel => 'NET BALANCE';

  @override
  String get paymentHistoryTxTitle => 'Competition registration';

  @override
  String get paymentHistoryTxBadgePaid => 'PAID';

  @override
  String get paymentHistoryTxBadgePending => 'PENDING';

  @override
  String get paymentHistoryTxBadgeRefund => 'REFUND';

  @override
  String get paymentHistoryTxBadgeRefunded => 'REFUNDED';

  @override
  String get paymentHistoryTxBadgeFailed => 'FAILED';

  @override
  String get paymentHistoryResumeCompetition => 'Competition';

  @override
  String get paymentMethodMtnLabel => 'MTN Mobile Money';

  @override
  String get paymentMethodMtnCountries => 'Cameroon, Ivory Coast, Benin';

  @override
  String get paymentMethodOrangeLabel => 'Orange Money';

  @override
  String get paymentMethodOrangeCountries => 'Cameroon, Senegal, Mali';

  @override
  String get paymentPickerAppBarTitle => 'PAYMENT';

  @override
  String get paymentPickerMobileMoneySection => '📱 MOBILE MONEY';

  @override
  String get paymentPickerV2Notice =>
      '₿ Crypto + Wave + Moov available in V2 (automatic CinetPay / NowPayments gateways).';

  @override
  String get paymentPickerContinueButton => 'CONTINUE →';

  @override
  String get paymentPickerAmountLabel => 'AMOUNT TO PAY';

  @override
  String get paymentProcessingAppBarTitle => 'PAYMENT STATUS';

  @override
  String get paymentProcessingWaitingTitle => 'AWAITING VALIDATION';

  @override
  String get paymentProcessingWaitingSubtitle =>
      'The super-admin is verifying receipt of the payment on their ';

  @override
  String get paymentProcessingWaitingSubtitleSuffix => ' account.';

  @override
  String get paymentProcessingInfoNote =>
      '💡 You can close this page: the transaction stays pending on the admin side. You can come back to check the status from \"Payment history\" or the banner on the home screen.';

  @override
  String get paymentProcessingLeaveButton =>
      'LEAVE (THE TRANSACTION CONTINUES)';

  @override
  String get paymentProcessingCancelButton => 'Cancel the transaction';

  @override
  String get paymentProcessingCancelDialogTitle => 'Cancel the payment?';

  @override
  String get paymentProcessingCancelDialogBody =>
      'If you have already paid on Mobile Money, wait for validation instead of cancelling here (otherwise the admin will not register your account).';

  @override
  String get paymentProcessingCancelDialogStay => 'Stay';

  @override
  String get paymentProcessingCancelDialogConfirm => 'Cancel anyway';

  @override
  String get paymentProcessingRecapCompetition => 'Competition';

  @override
  String get paymentProcessingRecapAmount => 'Amount';

  @override
  String get paymentProcessingRecapMethod => 'Method';

  @override
  String get paymentProcessingRecapPhone => 'Your number';

  @override
  String get paymentProcessingRecapReference => 'Reference';

  @override
  String get paymentSuccessTitle => 'PAYMENT SUCCESSFUL!';

  @override
  String get paymentSuccessSubtitle => 'Your registration is confirmed.';

  @override
  String get paymentSuccessSeeCompetition => '🏆 VIEW COMPETITION';

  @override
  String get paymentSuccessBackHome => 'Back to home';

  @override
  String get paymentSuccessReceiptAmount => 'Amount';

  @override
  String get paymentSuccessReceiptMethod => 'Method';

  @override
  String get paymentSuccessReceiptTransaction => 'Transaction no.';

  @override
  String get paymentSuccessReceiptDate => 'Date';

  @override
  String get paymentSuccessRegisteredLabel => '🏆 You are registered for';

  @override
  String get payoutKycStepIdRecto => 'ID document (front)';

  @override
  String get payoutKycStepIdVerso => 'ID document (back)';

  @override
  String get payoutKycStepSelfie => 'Verification selfie';

  @override
  String get payoutKycAppBarTitle => 'VERIFY';

  @override
  String get payoutKycAcceptedDocsLabel => 'ACCEPTED DOCUMENTS';

  @override
  String get payoutKycSubmitForReview => 'SUBMIT FOR VERIFICATION';

  @override
  String get payoutKycNextRectoRequired => 'NEXT (front required)';

  @override
  String payoutKycPendingGain(Object amount) {
    return '💰 Earnings of $amount XAF';
  }

  @override
  String get payoutKycPendingExplain =>
      'For this amount, we need to verify your identity before the payout. It\'s quick (within 24h).';

  @override
  String get payoutKycDocNationalId => 'National ID card';

  @override
  String get payoutKycDocPassport => 'Passport';

  @override
  String get payoutKycDocDriverLicense => 'Driver\'s license';

  @override
  String get payoutKycPhotoCaptured => 'Photo captured';

  @override
  String get payoutKycRetake => 'RETAKE';

  @override
  String get payoutKycPhotographFront => 'Photograph the front';

  @override
  String get payoutKycCaptureHint => 'Good lighting, sharp photo, no glare';

  @override
  String get payoutKycTakePhoto => '📸 TAKE PHOTO';

  @override
  String get payoutKycSecurityLabel => 'Security: ';

  @override
  String get payoutKycSecurityNote =>
      'your documents are encrypted and used solely for regulatory verification.';

  @override
  String get aboutLinkCgu => 'Terms of Use';

  @override
  String get aboutLinkPrivacy => 'Privacy Policy';

  @override
  String get aboutLinkCookies => 'Cookies';

  @override
  String get aboutLinkSupport => 'Support';

  @override
  String get aboutLinkSite => 'arena.app site';

  @override
  String get aboutAppBarTitle => 'ABOUT';

  @override
  String get aboutMadeInCameroon => 'Made in Cameroon 🇨🇲';

  @override
  String get aboutLinksLabel => 'LINKS';

  @override
  String get aboutBuiltWith => 'Built with';

  @override
  String get aboutMissionTitle => '📜 Our mission';

  @override
  String get aboutMissionBody =>
      'ARENA democratizes mobile e-sports in Africa by offering fair tournaments, mobile money winnings, and a premium experience to virtual football enthusiasts.';

  @override
  String aboutLinkComingSoon(Object label) {
    return '$label coming in PHASE 12.5';
  }

  @override
  String get adminMessagesAppBarTitle => 'ARENA Messages';

  @override
  String adminMessagesError(Object error) {
    return 'Error: $error';
  }

  @override
  String get adminMessagesEmpty => 'No messages from ARENA.';

  @override
  String get deleteAccountStepWarning => 'WARNING';

  @override
  String get deleteAccountStepPendingEarnings => 'PENDING EARNINGS';

  @override
  String get deleteAccountStepConfirmation => 'CONFIRMATION';

  @override
  String get deleteAccountStepDone => 'DONE';

  @override
  String get deleteAccountAppBarTitle => 'DELETE';

  @override
  String get deleteAccountLossHistory =>
      'All your match and tournament history';

  @override
  String get deleteAccountLossBadges => 'Your badges and achievements';

  @override
  String get deleteAccountLossChats => 'Your conversations and match chats';

  @override
  String get deleteAccountLossPaymentMethods => 'Your saved payment methods';

  @override
  String get deleteAccountIrreversibleTitle => 'This action is irreversible';

  @override
  String get deleteAccountLossIntro =>
      'By deleting your account, you will lose:';

  @override
  String get deleteAccountRetentionNotice =>
      'Your account will be deactivated immediately, then anonymized (personal data erased) within 30 days. Legal accounting records (payments) are kept in anonymized form. During this period, you can contact support to cancel.';

  @override
  String get deleteAccountUnderstandContinue => 'I UNDERSTAND, CONTINUE';

  @override
  String get deleteAccountHasPendingTitle => 'You have pending earnings';

  @override
  String get deleteAccountHasPendingBody =>
      'Collect your pending payments before deleting your account. Once deleted, these funds can no longer be sent to you.';

  @override
  String get deleteAccountBack => 'BACK';

  @override
  String get deleteAccountNoPendingTitle => 'No pending earnings';

  @override
  String get deleteAccountNoPendingBody =>
      'You can proceed with the deletion without risk of losing any pending payments.';

  @override
  String get deleteAccountContinue => 'CONTINUE';

  @override
  String get deleteAccountConfirmWord => 'DELETE';

  @override
  String get deleteAccountConfirmTitle => 'Confirm deletion';

  @override
  String get deleteAccountPasswordLabel => 'Password';

  @override
  String get deleteAccountReasonLabel => 'Reason (optional)';

  @override
  String get deleteAccountDeletePermanently => 'DELETE PERMANENTLY';

  @override
  String get deleteAccountDoneTitle => 'Account deactivated';

  @override
  String get deleteAccountDoneBody =>
      'Your account will be anonymized (personal data erased) within 30 days. Contact support if you change your mind.';

  @override
  String get deleteAccountBackToHome => 'BACK TO HOME';

  @override
  String get editProfileWhatsappInvalidError => 'Invalid WhatsApp number.';

  @override
  String get editProfileUpdatedSnack => 'Profile updated.';

  @override
  String get editProfileAppBarTitle => 'EDIT';

  @override
  String get editProfileSaveTooltip => 'Save';

  @override
  String get editProfileColorEditableHint => 'Color editable below';

  @override
  String get editProfileAvatarChangeHint => 'Change photo';

  @override
  String get editProfileAvatarFromGallery => 'Choose from gallery';

  @override
  String get editProfileAvatarFromCamera => 'Take a photo';

  @override
  String get editProfileAvatarRemove => 'Remove photo';

  @override
  String get editProfileAvatarUpdatedSnack => 'Profile photo updated.';

  @override
  String get editProfileUsernameCaption => 'USERNAME';

  @override
  String get editProfileUsernameMinError => 'Minimum 3 characters';

  @override
  String get editProfileUsernameMaxError => 'Maximum 20 characters';

  @override
  String get editProfileCountryCaption => 'COUNTRY';

  @override
  String get editProfileAvatarColorCaption => 'AVATAR COLOR';

  @override
  String get editProfileWhatsappHint => 'E.g. 07 07 07 07 07';

  @override
  String get editProfileWhatsappInvalidErrorText => 'Invalid number.';

  @override
  String get editProfileSaveButton => 'SAVE';

  @override
  String get friendsAppBarTitle => 'My friends';

  @override
  String get friendsSearchTooltip => 'Search';

  @override
  String get friendsTabFriends => 'Friends';

  @override
  String get friendsTabRequests => 'Requests';

  @override
  String get friendsTabBlocked => 'Blocked';

  @override
  String get friendsEmptyLabel => 'No friends yet.';

  @override
  String get friendsEmptyHint =>
      'Tap the magnifier at the top to search for some.';

  @override
  String get friendsRemoveCancel => 'Cancel';

  @override
  String get friendsRemoveConfirm => 'Confirm';

  @override
  String get friendsSectionReceived => 'RECEIVED';

  @override
  String get friendsSectionSent => 'SENT';

  @override
  String get friendsNoRequests => 'No requests.';

  @override
  String get friendsNoPendingRequests => 'No pending requests.';

  @override
  String get friendsCancelRequest => 'Cancel';

  @override
  String get friendsBlockedEmptyLabel => 'No blocked players.';

  @override
  String get friendsUnblockAction => 'Unblock';

  @override
  String get friendsSearchAppBarTitle => 'Search';

  @override
  String get friendsSearchHint => 'Username';

  @override
  String get friendsSearchPrompt => 'Type at least 2 characters to search.';

  @override
  String get matchHistoryAppBarLoadingTitle => 'History';

  @override
  String get matchHistoryAppBarTitle => 'HISTORY';

  @override
  String get matchHistoryError =>
      'Unable to load your history. Check your connection.';

  @override
  String get matchHistoryFilterAll => 'All';

  @override
  String get matchHistoryFilterWins => 'W';

  @override
  String get matchHistoryFilterLosses => 'L';

  @override
  String get matchHistoryFilterOngoing => 'Ongoing';

  @override
  String get matchHistoryEmptyTitle => 'No matches';

  @override
  String get matchHistoryEmptyDescription =>
      'Your matches will appear here from your first competition.';

  @override
  String get matchHistoryOpponentFallback => 'Opponent';

  @override
  String get playerProfileUnavailable =>
      'Profile unavailable. Please sign in again.';

  @override
  String get playerProfileSuccessHeader => '🏆 ACHIEVEMENTS';

  @override
  String get playerProfileRecentMatchesHeader => 'RECENT MATCHES';

  @override
  String get playerProfileSettingsButton => 'SETTINGS';

  @override
  String get playerProfileSignOutButton => 'SIGN OUT';

  @override
  String get playerProfileJoinedPrefix => 'Joined';

  @override
  String get playerProfileTierBronze => '🥉 BRONZE';

  @override
  String get playerProfileTierSilver => '🥈 SILVER';

  @override
  String get playerProfileTierGold => '🥇 GOLD';

  @override
  String get playerProfileTierElite => '💎 ELITE';

  @override
  String get playerProfileEditTooltip => 'Edit';

  @override
  String get playerProfileEditAvatarTooltip => 'Edit avatar';

  @override
  String get playerProfileStatWins => 'Wins';

  @override
  String get playerProfileStatLosses => 'Losses';

  @override
  String get playerProfileStatWinRate => 'Win rate';

  @override
  String get playerProfileNoCompletedMatches => 'No completed matches yet.';

  @override
  String get playerProfileFriendsTitle => 'My friends';

  @override
  String get playerProfileNoFriends => 'No friends yet';

  @override
  String get playerProfileReferralTitle => 'My referrals';

  @override
  String get playerProfileReferralCodeCopied => 'Referral code copied';

  @override
  String get playerProfileReferralCodeGenerating => 'Generating code…';

  @override
  String get playerProfileReferralExplainer =>
      'Share your code to refer friends. Once you reach your quota, you\'ll automatically gain access to free competitions with conditional rewards.';

  @override
  String get playerProfileResultWin => 'W';

  @override
  String get playerProfileResultLoss => 'L';

  @override
  String get playerProfileResultDraw => 'D';

  @override
  String get publicProfileAppBarTitle => 'Profile';

  @override
  String get publicProfilePlayerNotFound => 'Player not found.';

  @override
  String get publicProfileRecentMatchesHeader => 'RECENT MATCHES';

  @override
  String get publicProfileCtaAddFriend => 'ADD FRIEND';

  @override
  String get publicProfileCtaRequestSent => 'REQUEST SENT';

  @override
  String get publicProfileCtaCancel => 'CANCEL';

  @override
  String get publicProfileRequestCancelled => 'Request cancelled';

  @override
  String get publicProfileCtaAccept => 'ACCEPT';

  @override
  String get publicProfileCtaDecline => 'DECLINE';

  @override
  String get publicProfileRequestDeclined => 'Request declined';

  @override
  String get publicProfileCtaFriend => 'FRIEND';

  @override
  String get publicProfileCtaRemove => 'REMOVE';

  @override
  String get publicProfileFriendRemoved => 'Friend removed';

  @override
  String get publicProfileCtaBlock => 'BLOCK';

  @override
  String get publicProfileBlockConfirmDetail =>
      'You will no longer be able to chat during matches.';

  @override
  String get publicProfilePlayerBlocked => 'Player blocked';

  @override
  String get publicProfileCtaUnblock => 'UNBLOCK';

  @override
  String get publicProfilePlayerUnblocked => 'Player unblocked';

  @override
  String get publicProfileCtaUnavailable => 'UNAVAILABLE';

  @override
  String get publicProfileDialogCancel => 'Cancel';

  @override
  String get publicProfileDialogConfirm => 'Confirm';

  @override
  String get publicProfileStatsHeader => 'STATS';

  @override
  String get publicProfileStatWin => 'W';

  @override
  String get publicProfileStatLoss => 'L';

  @override
  String get publicProfileStatDraw => 'D';

  @override
  String get publicProfileWinRateLabel => 'Win rate';

  @override
  String get publicProfileGoalsScored => 'Goals scored';

  @override
  String get publicProfileGoalsConceded => 'Goals conceded';

  @override
  String get publicProfileNoCompletedMatches => 'No completed matches yet.';

  @override
  String get publicProfileResultWin => 'W';

  @override
  String get publicProfileResultLoss => 'L';

  @override
  String get publicProfileResultDraw => 'D';

  @override
  String get settingsAppBarTitle => 'SETTINGS';

  @override
  String get settingsSectionPreferences => 'PREFERENCES';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get settingsSectionPrivacy => 'PRIVACY';

  @override
  String get settingsSectionHelp => 'HELP & INFO';

  @override
  String get settingsVersionFooter => 'v1.0.0 · build 12';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsCurrencyLabel => 'Currency';

  @override
  String get settingsMarketingTitle => 'Marketing notifications';

  @override
  String get settingsMarketingSubtitle => 'Tips, new tournaments, promotions';

  @override
  String get settingsChangeEmailTitle => 'Change email';

  @override
  String get settingsChangePasswordTitle => 'Change password';

  @override
  String get settingsLoginMethodsTitle => 'Sign-in methods';

  @override
  String get settingsLoginMethodsSubtitle => 'Google / Apple — coming soon';

  @override
  String get settingsNewEmailDialogTitle => 'New email';

  @override
  String get settingsNewEmailHint => 'name@example.com';

  @override
  String get settingsDialogCancel => 'Cancel';

  @override
  String get settingsDialogConfirm => 'Confirm';

  @override
  String get settingsEmailChangeConfirmSnack =>
      'Check your inbox to confirm the change.';

  @override
  String get settingsNewPasswordDialogTitle => 'New password';

  @override
  String get settingsNewPasswordHint => '8 characters minimum';

  @override
  String get settingsPasswordUpdatedSnack => 'Password updated.';

  @override
  String get settingsDownloadDataTitle => 'Download my data';

  @override
  String get settingsDownloadDataExporting => 'Exporting…';

  @override
  String get settingsDownloadDataSubtitle =>
      'Generates a JSON file of all your data';

  @override
  String get settingsDeleteAccountTitle => 'Delete my account';

  @override
  String get settingsExportSuccessTitle => 'Export successful';

  @override
  String get settingsExportPathCopied => 'Path copied to clipboard.';

  @override
  String get settingsExportContentLabel => 'Content:';

  @override
  String get settingsDialogOk => 'OK';

  @override
  String get settingsReplayIntroTitle => 'Replay introduction';

  @override
  String get settingsSupportTitle => 'Support';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutSubtitle =>
      'ARENA V1.0 — Mobile e-sport tournament platform';

  @override
  String get matchOverlayContinue => '▶ Resume';

  @override
  String get matchOverlayPauseRecording => '⏸ Pause recording';

  @override
  String get matchOverlayStopForfeit => '🛑 Stop (forfeit)';

  @override
  String get recordingErrorSolutionStep1 => 'Go to Settings → Apps → ARENA';

  @override
  String get recordingErrorSolutionStep2 =>
      'Enable \"Display over other apps\"';

  @override
  String get recordingErrorSolutionStep3 => 'Disable Battery Saver for ARENA';

  @override
  String get recordingErrorSolutionStep4 =>
      'Allow ARENA to run in the background';

  @override
  String get recordingErrorAppBarTitle => 'Recording error';

  @override
  String get recordingErrorHeadline => 'RECORDING IMPOSSIBLE';

  @override
  String get recordingErrorAntiCheatNotice =>
      'Without recording, the match cannot start (anti-cheat).';

  @override
  String get recordingErrorSolutionsLabel => 'SOLUTIONS';

  @override
  String get recordingErrorRetryButton => '↻ RETRY';

  @override
  String get recordingErrorForfeitButton => '🏳 FORFEIT (lose)';

  @override
  String get recordingErrorContactSupport => 'Contact support';

  @override
  String get recordingErrorCauseTitle => '⚠️ Detected cause';

  @override
  String get recordingErrorCausePermissionPrefix => 'Permission ';

  @override
  String get recordingErrorCausePermissionSuffix => ' missing.';

  @override
  String get liveStreamsAppBarTitle => 'LIVE NOW';

  @override
  String get liveStreamsErrorPrefixV2 => 'Error: ';

  @override
  String get liveStreamsEmptyTitle => 'No live matches';

  @override
  String get liveStreamsEmptyDescription =>
      'Live broadcasts appear here as soon as an admin selects a match for streaming.';

  @override
  String get liveStreamsBroadcastByPrefix => 'Broadcast by ';

  @override
  String get startStreamingAlreadyLive => 'You\'re streaming this match live';

  @override
  String get startStreamingSelected =>
      'This match is selected for live streaming';

  @override
  String get startStreamingOpponentLive => 'Match streaming live';

  @override
  String get startStreamingStartButton => 'Start';

  @override
  String get startStreamingStartedSnack => 'Streaming started.';

  @override
  String get watchStreamConnecting => 'Connecting…';

  @override
  String get watchStreamWaitingBroadcaster => 'Waiting for the broadcaster…';

  @override
  String get watchStreamSpectatorChat => 'SPECTATOR CHAT';

  @override
  String get watchStreamChatUnavailable => 'Chat unavailable';

  @override
  String get watchStreamChatEmpty => 'Be the first to comment!';

  @override
  String get watchStreamChatHint => 'Send a message…';

  @override
  String get watchStreamLiveBadge => 'LIVE';

  @override
  String bannedLoadStateError(Object error) {
    return 'Unable to load the request status: $error';
  }

  @override
  String cguWhatsappLabel(Object dialCode) {
    return 'WHATSAPP ($dialCode)';
  }

  @override
  String cguWhatsappHelper(Object dialCode) {
    return 'The country code $dialCode is added automatically.';
  }

  @override
  String cguConsentRequiredSuffix(Object title) {
    return '$title *';
  }

  @override
  String linkAccountEmailLineNoEmail(Object providerLabel) {
    return 'The email address of this $providerLabel account is already used by an ARENA account.';
  }

  @override
  String linkAccountEmailLineWithEmail(Object email) {
    return '$email is already used by an ARENA account (password).';
  }

  @override
  String registerStepperTitle(Object step) {
    return 'Step $step / 3';
  }

  @override
  String registerWhatsappLabel(Object dialCode) {
    return 'WHATSAPP ($dialCode)';
  }

  @override
  String registerWhatsappHelper(Object dialCode) {
    return 'The country code $dialCode is added automatically.';
  }

  @override
  String bracketCaption(Object playerCount) {
    return 'SINGLE ELIMINATION · $playerCount PLAYERS';
  }

  @override
  String referralCardDescription(Object referralQuota) {
    return 'You must refer $referralQuota friend(s) to register for this free competition. Share your code with them so they create their ARENA account.';
  }

  @override
  String referralProgressError(Object error) {
    return 'Unable to verify your progress: $error';
  }

  @override
  String referralFriendsRemaining(Object count) {
    return '$count more friend(s) to refer';
  }

  @override
  String referralCodeCopied(Object code) {
    return 'Code $code copied to clipboard';
  }

  @override
  String referralShareMessage(Object code) {
    return 'Join me on ARENA! Free mobile e-sport tournaments with rewards. Use my referral code when you sign up: $code';
  }

  @override
  String liveStreamsOthersCount(Object count) {
    return '+$count more';
  }

  @override
  String pendingPaymentMultipleTitle(Object count) {
    return '$count payments pending';
  }

  @override
  String upcomingMatchesError(Object error) {
    return 'Error: $error';
  }

  @override
  String upcomingMatchVsOpponent(Object opponentName) {
    return 'vs $opponentName';
  }

  @override
  String upcomingBadgeInHours(Object hours) {
    return 'IN ${hours}H';
  }

  @override
  String upcomingBadgeInDays(Object days) {
    return 'IN ${days}D';
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
    return 'Failed: $message';
  }

  @override
  String manualUploadError(Object error) {
    return 'Error: $error';
  }

  @override
  String outcomeWinner(Object winner) {
    return 'Winner: Player $winner…';
  }

  @override
  String outcomeResubmitError(Object error) {
    return 'Unable to resubmit: $error';
  }

  @override
  String outcomeScoreShootout(Object pen1, Object pen2) {
    return 'PSO $pen1 — $pen2';
  }

  @override
  String matchHeaderSelfSuffix(Object username) {
    return '$username · YOU';
  }

  @override
  String recordingLiveStreamError(Object error) {
    return 'Unable to start the broadcast: $error';
  }

  @override
  String recordingPermBundleNeedsSettings(Object list) {
    return 'Allow $list in Settings > Apps > ARENA';
  }

  @override
  String recordingPermBundleDenied(Object list) {
    return '$list permission denied — tap I\'M IN THE ROOM again';
  }

  @override
  String recordingBannerUnavailable(Object error) {
    return 'Recording unavailable — $error\nTap here to retry.';
  }

  @override
  String notificationsTimeMinutesAgo(Object minutes) {
    return '$minutes min ago';
  }

  @override
  String notificationsTimeHoursAgo(Object hours) {
    return '$hours h ago';
  }

  @override
  String mobileMoneyDialHelp(Object method) {
    return 'Dial this code on your $method, pay the exact amount, then come back here and tap \"I HAVE PAID\".';
  }

  @override
  String deleteAccountStepCaption(Object stepNum, Object stepLabel) {
    return 'STEP $stepNum/04 · $stepLabel';
  }

  @override
  String deleteAccountCheckErrorNote(Object checkError) {
    return 'Note: verification inconclusive (table unavailable). Detail: $checkError';
  }

  @override
  String deleteAccountTypeToConfirmLabel(Object confirmWord) {
    return 'Type \"$confirmWord\" to confirm';
  }

  @override
  String editProfileWhatsappCaption(Object dialCode) {
    return 'WHATSAPP ($dialCode)';
  }

  @override
  String editProfileWhatsappHelper(Object dialCode) {
    return 'The country code $dialCode is added automatically.';
  }

  @override
  String friendsErrorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String friendsRemoveDialogTitle(Object username) {
    return 'Remove $username?';
  }

  @override
  String friendsAcceptedSnack(Object username) {
    return '$username is now your friend';
  }

  @override
  String friendsUnblockedSnack(Object username) {
    return '$username unblocked';
  }

  @override
  String friendsSearchErrorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String playerProfileError(Object error) {
    return 'Error: $error';
  }

  @override
  String playerProfileStatsError(Object error) {
    return 'Stats unavailable ($error)';
  }

  @override
  String playerProfileMatchRowError(Object error) {
    return 'Error: $error';
  }

  @override
  String playerProfileFriendsCountSingular(Object friendsCount) {
    return '$friendsCount friend';
  }

  @override
  String playerProfileFriendsCountPlural(Object friendsCount) {
    return '$friendsCount friends';
  }

  @override
  String playerProfileReferralCountSingular(Object count) {
    return '$count invite';
  }

  @override
  String playerProfileReferralCountPlural(Object count) {
    return '$count invites';
  }

  @override
  String publicProfileError(Object error) {
    return 'Error: $error';
  }

  @override
  String publicProfileRequestSent(Object username) {
    return 'Request sent to $username';
  }

  @override
  String publicProfileNowFriend(Object username) {
    return '$username is now your friend';
  }

  @override
  String publicProfileRemoveConfirmTitle(Object username) {
    return 'Remove $username?';
  }

  @override
  String publicProfileBlockConfirmTitle(Object username) {
    return 'Block $username?';
  }

  @override
  String publicProfileWinRateValue(Object pct, Object total) {
    return '$pct% ($total matches)';
  }

  @override
  String publicProfileMatchRowError(Object error) {
    return 'Error: $error';
  }

  @override
  String settingsMarketingError(Object error) {
    return 'Error: $error';
  }

  @override
  String settingsEmailChangeError(Object error) {
    return 'Error: $error';
  }

  @override
  String settingsPasswordChangeError(Object error) {
    return 'Error: $error';
  }

  @override
  String settingsExportError(Object error) {
    return 'Export failed: $error';
  }

  @override
  String settingsExportFileLabel(Object sizeKb) {
    return 'File ($sizeKb KB):';
  }

  @override
  String startStreamingErrorSnack(Object error) {
    return 'Error: $error';
  }

  @override
  String watchStreamFailed(Object reason) {
    return 'Failed: $reason';
  }

  @override
  String watchStreamChatSendError(Object error) {
    return 'Send error: $error';
  }

  @override
  String watchStreamViewersWatching(Object viewers) {
    return '$viewers watching';
  }

  @override
  String get authErrInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrEmailAlreadyRegistered =>
      'An account already exists with this email.';

  @override
  String get authErrWeakPassword => 'Password too weak: 8 characters minimum.';

  @override
  String get authErrEmailNotConfirmed =>
      'Confirm your registration via the link sent by email.';

  @override
  String get authErrUserBanned => 'This account is suspended. Contact support.';

  @override
  String get authErrWrongApp =>
      'This is an administrator account. Use the ARENA Admin app.';

  @override
  String get authErrNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get authErrRateLimited =>
      'Too many attempts. Try again in a few minutes.';

  @override
  String get authErrInvalidInvitation =>
      'Invitation code invalid, expired or already used.';

  @override
  String get authErrInvalidTotp => 'Incorrect 6-digit code.';

  @override
  String get authErrTotpReplay =>
      'This code has already been used. Wait for the next one.';

  @override
  String get authErrAdminLocked =>
      'Account locked after 3 attempts. Try again in 30 minutes.';

  @override
  String get authErrBackendUnavailable =>
      'Service temporarily unavailable. Try again later.';

  @override
  String get authErrUsernameTaken =>
      'This username is already taken. Choose another one.';

  @override
  String get authErrSsoCancelled => 'Sign-in cancelled.';

  @override
  String get authErrSsoIdToken =>
      'Sign-in failed. Check your network and try again.';

  @override
  String get authErrSsoConfig =>
      'Sign-in unavailable right now. Contact support.';

  @override
  String get authErrInvalidResetCode => 'Incorrect code. Check your email.';

  @override
  String get authErrExpiredResetCode => 'Code expired. Request a new code.';

  @override
  String get authErrUnknown => 'Something went wrong. Try again.';

  @override
  String get matchStepCodeRoom => 'Room code';

  @override
  String get matchStepOpponentJoining => 'Opponent joining';

  @override
  String get matchStepInProgress => 'Match in progress';

  @override
  String get matchStepResult => 'Result';

  @override
  String get activeCompetitionsEmpty =>
      'No active competition for this filter.';

  @override
  String get myTournamentsEmpty =>
      'You\'re not registered for any tournament yet.';

  @override
  String get myTournamentsBrowseCta => 'Browse tournaments';

  @override
  String get filterAll => 'All';

  @override
  String get filterFree => 'Free';

  @override
  String get filterPaid => 'Paid';

  @override
  String get filterUpcoming => 'Upcoming';

  @override
  String get filterOngoing => 'Ongoing';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get compFormatSingleElim => 'Single elimination';

  @override
  String get compFormatGroupsKnockout => 'Groups + knockout';

  @override
  String get compFormatRoundRobin => 'Round robin';

  @override
  String get matchStepWord => 'STEP';
}
