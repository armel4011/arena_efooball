// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ARENA';

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
  String get onboardingSlide1Title =>
      'بطولات الرياضات الإلكترونية لعموم أفريقيا';

  @override
  String get onboardingSlide1Body =>
      'مرحبًا بك في ARENA، المنصة رقم 1 لبطولات eFootball والداما وFC Mobile في أفريقيا.';

  @override
  String get onboardingSlide2Title => 'جداول الإقصاء، مواجهات حقيقية';

  @override
  String get onboardingSlide2Body =>
      'إقصاء مباشر أو دور المجموعات: تسلّق شجرة البطولة واهزم كل خصومك للفوز بالجائزة.';

  @override
  String get onboardingSlide3Title => 'رمز غرفة مشترك';

  @override
  String get onboardingSlide3Body =>
      'شارك رمز غرفتك داخل اللعبة، تواجها، ثم أكّدا النتيجة معًا في ARENA.';

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
  String get loginSubtitle => 'تابع رحلتك على ARENA.';

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

  @override
  String get bannedMinLengthError => 'يرجى توضيح طلبك (10 أحرف كحد أدنى).';

  @override
  String get bannedSendError => 'فشل الإرسال. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get bannedAppBarTitle => 'حساب موقوف';

  @override
  String get bannedSignOut => 'تسجيل الخروج';

  @override
  String get bannedArenaRequestTitle => '📨 طلب ARENA';

  @override
  String get bannedArenaRequestIntro =>
      'اشرح لماذا تعتقد أنه يجب إعادة النظر في حظرك. يراجع فريق طلب ARENA كل طلب خلال 48 ساعة.';

  @override
  String get bannedMessageHint => 'صِف حالتك (10 أحرف كحد أدنى)…';

  @override
  String get bannedSendingLabel => 'جارٍ الإرسال…';

  @override
  String get bannedSendRequestLabel => '✉️ إرسال طلبي';

  @override
  String get bannedPermanentTitle => 'حساب محظور نهائيًا';

  @override
  String get bannedPermanentBody =>
      'لقد وُجدت مذنبًا في نزاع 3 مرات. وفقًا لقاعدة ARENA، تم تعطيل حسابك.';

  @override
  String get bannedOverdueTitle => 'المراجعة متأخرة (> 48 ساعة)';

  @override
  String get bannedPendingTitle => 'الطلب قيد المراجعة';

  @override
  String get bannedOverdueBody =>
      'طلبك مفتوح منذ أكثر من 48 ساعة. تم إخطار فريق طلب ARENA — شكرًا على صبرك.';

  @override
  String get bannedPendingBody =>
      'لدى فريق طلب ARENA 48 ساعة لمراجعة طلبك. سيتم إخطارك بمجرد اتخاذ القرار.';

  @override
  String get bannedYourMessageLabel => 'رسالتك';

  @override
  String get bannedRejectedTitle => '❌ تم رفض الطلب السابق';

  @override
  String get bannedReasonLabel => 'السبب';

  @override
  String get bannedRejectedBody =>
      'يمكنك تقديم طلب جديد مع تفاصيل إضافية أدناه.';

  @override
  String get bannedApprovedTitle => '✅ تمت الموافقة على إعادة الإدماج';

  @override
  String get bannedApprovedBody =>
      'مرحبًا بعودتك إلى ARENA! سجّل الدخول مرة أخرى للوصول إلى حسابك.';

  @override
  String get cguCompleteProfileTitle => 'أكمل\nملفك الشخصي';

  @override
  String get cguCompleteProfileSubtitle =>
      'بعض المعلومات ناقصة قبل أن تتمكن من اللعب.';

  @override
  String get cguWhatsappHint => 'مثال 07 07 07 07 07';

  @override
  String get cguWhatsappInvalid => 'رقم واتساب غير صالح.';

  @override
  String get cguReadTermsLink => 'اقرأ الشروط والأحكام';

  @override
  String get cguReadPrivacyLink => 'اقرأ سياسة الخصوصية';

  @override
  String get cguAcceptTermsConsent =>
      'أوافق على الشروط والأحكام وسياسة الخصوصية';

  @override
  String get cguMarketingConsent =>
      'أوافق على تلقي معلومات حول البطولات الجديدة (اختياري)';

  @override
  String get cguContinueButton => 'متابعة';

  @override
  String get cguRefuseSignOut => 'رفض وتسجيل الخروج';

  @override
  String get cguDocPlaceholderBody =>
      'سيتم عرض النسخة الكاملة هنا (المرحلة 9 — صفحة حول + WebView للمستندات المستضافة).';

  @override
  String get cguDialogOk => 'حسنًا';

  @override
  String get cguCountryLabel => 'الدولة';

  @override
  String get linkAccountDefaultProvider => 'Google';

  @override
  String get linkAccountAppBarTitle => 'ربط الحسابات';

  @override
  String get linkAccountExistsTitle => 'الحساب موجود بالفعل';

  @override
  String get linkAccountExistingMethodsLabel => 'الطرق الحالية';

  @override
  String get linkAccountEmailPasswordMethod =>
      'البريد الإلكتروني + كلمة المرور';

  @override
  String get linkAccountChooseContinue => 'اختر كيفية المتابعة أدناه.';

  @override
  String get linkAccountLinkBothButton => '🔗 ربط الحسابين';

  @override
  String get linkAccountPhaseSnack =>
      'متاح في المرحلة 2.3 (تسجيل الدخول الاجتماعي عبر Google/Apple).';

  @override
  String get linkAccountLoginPasswordButton => 'تسجيل الدخول بكلمة المرور';

  @override
  String get linkAccountCancelButton => 'إلغاء';

  @override
  String get registerEmailRequired => 'البريد الإلكتروني مطلوب.';

  @override
  String get registerEmailInvalid => 'تنسيق البريد الإلكتروني غير صالح.';

  @override
  String get registerPasswordTooShort => '8 أحرف كحد أدنى.';

  @override
  String get registerPasswordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get registerAccountStepTitle => 'أنشئ\nحسابك';

  @override
  String get registerAccountStepSubtitle =>
      'البريد الإلكتروني + كلمة المرور (8 أحرف كحد أدنى).';

  @override
  String get registerGoogleSignUp => 'التسجيل عبر Google';

  @override
  String get registerEmailLabel => 'البريد الإلكتروني';

  @override
  String get registerPasswordLabel => 'كلمة المرور';

  @override
  String get registerPasswordConfirmLabel => 'تأكيد كلمة المرور';

  @override
  String get registerAccountContinueButton => 'متابعة';

  @override
  String get registerProfileStepTitle => 'ملفك\nالشخصي';

  @override
  String get registerProfileStepSubtitle =>
      'اسم المستخدم + الدولة + الموافقة على الشروط.';

  @override
  String get registerUsernameLabel => 'اسم المستخدم';

  @override
  String get registerUsernameHint => 'من 3 إلى 20 حرفًا';

  @override
  String get registerWhatsappHint => 'مثال 07 07 07 07 07';

  @override
  String get registerWhatsappInvalid => 'رقم واتساب غير صالح.';

  @override
  String get registerAvatarColorLabel => 'لون الصورة الرمزية';

  @override
  String get registerReferralCodeLabel => 'رمز الإحالة (اختياري)';

  @override
  String get registerReferralCodeHint => 'مثال ARN-3F9A';

  @override
  String get registerReferralCodeHelper =>
      'رمز صديق في ARENA. يتيح لك الظهور ضمن قائمة إحالاته — اتركه فارغًا إذا لم يكن لديك واحد.';

  @override
  String get registerCguConsent => 'أوافق على الشروط والأحكام';

  @override
  String get registerPrivacyConsent => 'أوافق على سياسة الخصوصية';

  @override
  String get registerMarketingConsent =>
      'أوافق على تلقي الرسائل التسويقية (اختياري)';

  @override
  String get registerCreateAccountButton => 'إنشاء حسابي';

  @override
  String get registerCountryLabel => 'الدولة';

  @override
  String get registerSuccessTitle => 'تم إنشاء\nالحساب';

  @override
  String get registerSuccessSubtitle =>
      'مرحبًا بك في ARENA. أنت جاهز للانضمام إلى البطولات.';

  @override
  String get registerSuccessContinueButton => 'متابعة';

  @override
  String get registerOrDivider => 'أو';

  @override
  String get resetCodeNewCodeSent => 'تم إرسال رمز جديد.';

  @override
  String get resetCodeTitle => 'التحقق';

  @override
  String get resetCodeSubtitle => 'أدخل الرمز المكوّن من 6 أرقام المُرسَل إلى';

  @override
  String get resetCodeFieldLabel => 'الرمز';

  @override
  String get resetCodeVerifyButton => 'تحقّق';

  @override
  String get resetCodeResending => 'جارٍ الإرسال…';

  @override
  String get resetCodeResendButton => 'إعادة إرسال الرمز';

  @override
  String get resetPwPasswordRequired => 'كلمة المرور مطلوبة';

  @override
  String get resetPwMinChars => '8 أحرف على الأقل';

  @override
  String get resetPwPasswordsDontMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get resetPwTitle => 'كلمة مرور جديدة';

  @override
  String get resetPwSubtitle =>
      'اختر كلمة مرور قوية. ستُستخدَم عند تسجيل دخولك القادم.';

  @override
  String get resetPwNewPasswordLabel => 'كلمة مرور جديدة';

  @override
  String get resetPwNewPasswordHint => '8 أحرف على الأقل';

  @override
  String get resetPwConfirmLabel => 'تأكيد';

  @override
  String get resetPwConfirmHint => 'أعد إدخال كلمة المرور';

  @override
  String get resetPwUpdateButton => 'تحديث';

  @override
  String get resetPwSuccessTitle => 'تم تحديث كلمة المرور';

  @override
  String get resetPwSuccessSubtitle =>
      'يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.';

  @override
  String get resetPwLoginButton => 'تسجيل الدخول';

  @override
  String get splashTagline => 'الرياضات الإلكترونية لعموم أفريقيا';

  @override
  String get splashLoginButton => 'تسجيل الدخول';

  @override
  String get splashCreateAccountButton => 'إنشاء حساب';

  @override
  String get splashVersionLabel => 'الإصدار 1.0 — ARENA الكاميرون';

  @override
  String get splashStatPlayers => 'لاعبون';

  @override
  String get splashStatTournaments => 'بطولات';

  @override
  String get splashStatXaf => 'XAF';

  @override
  String get bracketEmptyTitle => 'لم يتم إنشاء الشجرة بعد';

  @override
  String get bracketEmptyDescription =>
      'ستظهر الشجرة هنا بمجرد أن يُغلق المسؤول التسجيلات ويُجري القرعة.';

  @override
  String get bracketZoomHint => '↔ اقرص للتكبير · اسحب للتنقّل';

  @override
  String get groupStandingsEmptyTitle => 'لا يوجد ترتيب بعد';

  @override
  String get groupStandingsEmptyDescription =>
      'سيظهر الترتيب بمجرد لعب المباريات الأولى.';

  @override
  String get groupStandingsColPlayer => 'اللاعب';

  @override
  String get groupStandingsColPlayed => 'ل';

  @override
  String get groupStandingsColWins => 'ف';

  @override
  String get groupStandingsColDraws => 'ت';

  @override
  String get groupStandingsColLosses => 'خ';

  @override
  String get groupStandingsColGoalsFor => 'له';

  @override
  String get groupStandingsColGoalsAgainst => 'عليه';

  @override
  String get groupStandingsColDiff => 'الفارق';

  @override
  String get groupStandingsColPoints => 'نقاط';

  @override
  String get groupStandingsPlayerFallback => 'لاعب ';

  @override
  String get callPlaceCallFailed => 'تعذر بدء المكالمة.';

  @override
  String get callNoAnswer => 'لا يوجد رد.';

  @override
  String get callDeclined => 'تم رفض المكالمة.';

  @override
  String get callEnded => 'انتهت المكالمة.';

  @override
  String get callStatusConnecting => 'جارٍ الاتصال…';

  @override
  String get callStatusRinging => 'جارٍ الرنين…';

  @override
  String get callStatusConnected => 'في مكالمة';

  @override
  String get callStatusEnded => 'انتهت المكالمة';

  @override
  String get callStatusFailed => 'فشلت المكالمة';

  @override
  String get callControlUnmute => 'إلغاء الكتم';

  @override
  String get callControlMute => 'كتم';

  @override
  String get callControlSpeaker => 'مكبر الصوت';

  @override
  String get callControlEarpiece => 'سماعة الأذن';

  @override
  String get callControlClose => 'إغلاق';

  @override
  String get chatOfflineQueued =>
      'غير متصل — سيتم إرسال الرسالة عند إعادة الاتصال.';

  @override
  String get chatSendFailed => 'تعذر الإرسال: ';

  @override
  String get chatPickerUnavailable => 'أداة الاختيار غير متاحة: ';

  @override
  String get chatUploadFailed => 'فشل الرفع: ';

  @override
  String get chatAttachGallery => 'اختر من المعرض';

  @override
  String get chatAttachCamera => 'التقط صورة';

  @override
  String get chatDeleteDialogTitle => 'حذف هذه الرسالة؟';

  @override
  String get chatDeleteDialogContent =>
      'سيتم وضع علامة على هذه الرسالة كمحذوفة. سيرى اللاعب الآخر \"تم حذف الرسالة\" بدلاً منها.';

  @override
  String get chatDeleteDialogCancel => 'إلغاء';

  @override
  String get chatDeleteDialogConfirm => 'حذف';

  @override
  String get chatGenericFailure => 'فشل: ';

  @override
  String get chatEmptyTitle => 'لا توجد رسائل بعد';

  @override
  String get chatEmptyDescription => 'كن أول من يكتب هنا.';

  @override
  String get chatAppBarUsernameFallback => 'لاعب';

  @override
  String get chatAppBarTyping => 'يكتب…';

  @override
  String get chatAppBarOnline => 'متصل';

  @override
  String get chatAppBarOffline => 'غير متصل';

  @override
  String get chatMessageDeleted => 'تم حذف الرسالة';

  @override
  String get chatMediaUnsupported => 'وسائط: ';

  @override
  String get chatRoomCodeCopied => 'تم نسخ الرمز';

  @override
  String get chatRoomCodeTapToCopy => 'اضغط للنسخ';

  @override
  String get chatInputTooltipKeyboard => 'لوحة المفاتيح';

  @override
  String get chatInputTooltipEmoji => 'إيموجي';

  @override
  String get chatInputTooltipAttach => 'إرفاق صورة';

  @override
  String get chatInputHint => 'رسالة…';

  @override
  String get friendChatOfflineQueued =>
      'غير متصل — سيتم إرسال الرسالة عند إعادة الاتصال.';

  @override
  String get friendChatSendFailed => 'تعذر: ';

  @override
  String get friendChatPickerFailed => 'أداة الاختيار: ';

  @override
  String get friendChatGenericFailure => 'فشل: ';

  @override
  String get friendChatAttachGallery => 'اختر من المعرض';

  @override
  String get friendChatAttachCamera => 'التقط صورة';

  @override
  String get friendChatDeleteDialogTitle => 'حذف هذه الرسالة؟';

  @override
  String get friendChatDeleteDialogContent =>
      'سيرى صديقك «تم حذف الرسالة» بدلاً منها.';

  @override
  String get friendChatDeleteDialogCancel => 'إلغاء';

  @override
  String get friendChatDeleteDialogConfirm => 'حذف';

  @override
  String get friendChatEmptyTitle => 'ابدأ المحادثة';

  @override
  String get friendChatEmptyDescription => 'أرسل أول رسالة إلى صديقك.';

  @override
  String get friendChatUsernameFallback => 'صديق';

  @override
  String get friendChatSubtitleFriend => 'صديق';

  @override
  String get inboxAppBarTitle => 'الرسائل';

  @override
  String get inboxComposeTooltip => 'البحث عن لاعب';

  @override
  String get inboxTabDirect => 'مباشر';

  @override
  String get inboxTabTournaments => 'البطولات';

  @override
  String get inboxNoConversationsTitle => 'لا توجد محادثات';

  @override
  String get inboxNoConversationsDesc => 'أعد تسجيل الدخول لرؤية محادثاتك.';

  @override
  String get inboxSectionFriends => 'الأصدقاء';

  @override
  String get inboxSectionMatches => 'المباريات';

  @override
  String get inboxEmptyHint =>
      'لا توجد محادثات حتى الآن.\nابدأ محادثة من غرفة المباراة\nأو من علامة تبويب الأصدقاء.';

  @override
  String get inboxDeleteDialogTitle => 'حذف هذه المحادثة؟';

  @override
  String get inboxDeleteDialogContent =>
      'ستتم إزالة المحادثة من صندوق الوارد. يمكنك العثور عليها مجددًا بإعادة فتح المحادثة لاحقًا.';

  @override
  String get inboxDeleteCancel => 'إلغاء';

  @override
  String get inboxDeleteConfirm => 'حذف';

  @override
  String get inboxDeleteFailure => 'فشل: ';

  @override
  String get inboxOpponentWaiting => 'في الانتظار';

  @override
  String get inboxMatchPending => 'في انتظار خصم';

  @override
  String get inboxMatchScheduled => 'المباراة مجدولة';

  @override
  String get inboxMatchReady => 'تمت مشاركة رمز الغرفة';

  @override
  String get inboxMatchInProgress => 'جارية — اضغط للدردشة';

  @override
  String get inboxMatchScorePending => 'في انتظار النتيجة';

  @override
  String get inboxMatchAwaitingValidation => 'التحقق من النتيجة';

  @override
  String get inboxMatchDisputed =>
      'النتيجة متنازع عليها — قيد المراجعة الإدارية';

  @override
  String get inboxMatchCompleted => 'انتهت المباراة';

  @override
  String get inboxMatchCancelled => 'أُلغيت المباراة';

  @override
  String get inboxMatchForfeited => 'انسحاب';

  @override
  String get inboxTimeSoon => 'قريبًا';

  @override
  String get inboxCompRegistrationOpen => 'التسجيل مفتوح';

  @override
  String get inboxCompRegistrationClosed => 'التسجيل مغلق';

  @override
  String get inboxCompOngoing => 'جارية';

  @override
  String get inboxCompCompleted => 'منتهية';

  @override
  String get inboxCompCancelled => 'ملغاة';

  @override
  String get inboxCompDraft => 'مسودة';

  @override
  String get inboxNoActiveCompTitle => 'لا توجد منافسة نشطة';

  @override
  String get inboxNoActiveCompDesc =>
      'ستظهر مواضيع النقاش المرتبطة بمنافساتك هنا بمجرد انضمامك إلى بطولة.';

  @override
  String get inboxWaitingTitle => 'في الانتظار';

  @override
  String get inboxWaitingDesc => 'أنت مسجّل ولكن لم يتم تحميل المنافسات بعد.';

  @override
  String get inboxChatWithFriend => 'الدردشة مع صديقك';

  @override
  String get inboxFriendDefaultName => 'صديق';

  @override
  String get inboxArenaTeam => 'فريق ARENA';

  @override
  String get inboxArenaOfficialBadge => 'رسمي';

  @override
  String get inboxArenaPreviewDefault => 'الدعم والإعلانات والمعلومات الرسمية';

  @override
  String get inboxArenaPreviewImage => '📷 صورة';

  @override
  String get inboxTimeJustNow => 'الآن';

  @override
  String get inboxErrorPrefix => 'خطأ: ';

  @override
  String get compDetailAppBarTitle => 'المنافسة';

  @override
  String get compDetailNotFoundTitle => 'المنافسة غير موجودة';

  @override
  String get compDetailNotFoundDesc => 'ربما تم حذفها من قبل أحد المشرفين.';

  @override
  String get compDetailStatusDraft => 'مسودة';

  @override
  String get compDetailStatusOpen => 'مفتوح';

  @override
  String get compDetailStatusFull => 'مكتمل';

  @override
  String get compDetailStatusOngoing => 'جارية';

  @override
  String get compDetailStatusCompleted => 'منتهية';

  @override
  String get compDetailStatusCancelled => 'ملغاة';

  @override
  String get compDetailCtaRegisterFree => 'التسجيل مجانًا';

  @override
  String get compDetailCtaRegisterPaidPrefix => 'التسجيل · ';

  @override
  String get compDetailRegistrationsClosed => 'التسجيل مغلق';

  @override
  String get compDetailGatedLockNotice =>
      '🔒 الجدول والمباريات المباشرة والدردشة الفردية مخصصة للاعبين المسجّلين فقط.';

  @override
  String get compDetailPrizeFree => 'مجاني';

  @override
  String get compDetailPrizeFreeLabel => 'تسجيل مجاني';

  @override
  String get compDetailPrizeToWinLabel => 'للفوز';

  @override
  String get compDetailTabInfos => 'معلومات';

  @override
  String get compDetailTabParticipants => 'المشاركون';

  @override
  String get compDetailTabRanking => 'الترتيب';

  @override
  String get compDetailParticipantsTitle => 'قائمة المشاركين';

  @override
  String get compDetailParticipantsDesc =>
      'ستظهر هنا قائمة المسجّلين مع الصور والإحصائيات. المصدر: جدول `registrations`.';

  @override
  String get compDetailInfoPrizeLabel => 'الجائزة';

  @override
  String get compDetailInfoPrizeNone => 'لا شيء';

  @override
  String get compDetailInfoFeeLabel => 'رسوم التسجيل';

  @override
  String get compDetailInfoFeeFree => 'مجاني';

  @override
  String get compDetailInfoFormatLabel => 'النظام';

  @override
  String get compDetailInfoStartLabel => 'البداية';

  @override
  String get compDetailInfoCapacityLabel => 'السعة';

  @override
  String get compDetailInfoCapacitySuffix => ' لاعبًا';

  @override
  String get compDetailDescriptionHeader => '📝 الوصف';

  @override
  String get compDetailRankingNoParticipantTitle => 'لا يوجد مشاركون';

  @override
  String get compDetailRankingNoParticipantDesc =>
      'لم يسجّل أحد في هذه المنافسة بعد.';

  @override
  String get compDetailRankingNotPublishedTitle => 'لم يُنشر الترتيب بعد';

  @override
  String get compDetailRankingNotPublishedDesc =>
      'سينشر المنظمون الترتيب النهائي بمجرد انتهاء المنافسة.';

  @override
  String get compDetailRankingUnranked => 'غير مصنّف';

  @override
  String get compDetailRankingPlaceSuffix => ' المركز';

  @override
  String get compDetailFormatSingleElim => 'إقصاء مباشر';

  @override
  String get compDetailFormatGroupsKnockout => 'مجموعات + إقصاء';

  @override
  String get compDetailFormatRoundRobin => 'الدوري الكامل';

  @override
  String get compDetailTabBracket => 'الجدول';

  @override
  String get compDetailTabGroups => 'المجموعات';

  @override
  String get compListReset => 'إعادة تعيين';

  @override
  String get compListEmptyTitleAll => 'لا توجد منافسات';

  @override
  String get compListEmptyTitleGamePrefix => 'لا توجد منافسات على ';

  @override
  String get compListEmptyDesc => 'تُنشر بطولات جديدة كل أسبوع. عُد قريبًا!';

  @override
  String get compListFilterStatus => 'الحالة';

  @override
  String get compListFilterPricing => 'السعر';

  @override
  String get compListFormatSingleElim => 'إقصاء مباشر';

  @override
  String get compListFormatGroupsKnockout => 'مجموعات + إقصاء';

  @override
  String get compListFormatRoundRobin => 'الدوري الكامل';

  @override
  String get regConfirmAppBarTitle => 'الدفع';

  @override
  String get regConfirmPrizeDistribution => 'توزيع الجوائز';

  @override
  String get regConfirmDownloadGame => 'تنزيل اللعبة';

  @override
  String get regConfirmCtaReferralsInsufficient => '👥 إحالات غير كافية';

  @override
  String get regConfirmCtaRegisterFree => 'التسجيل مجانًا';

  @override
  String get regConfirmCtaProceedPaymentPrefix => 'المتابعة إلى الدفع · ';

  @override
  String get regConfirmCtaXafSuffix => ' فرنك';

  @override
  String get regConfirmCancel => 'إلغاء';

  @override
  String get regConfirmNoSession => 'لا توجد جلسة — التسجيل غير ممكن.';

  @override
  String get regConfirmOfflineQueued =>
      'غير متصل — تم حفظ التسجيل، وسيتأكد عند إعادة الاتصال.';

  @override
  String get regConfirmConfirmedPrefix => 'تم تأكيد التسجيل في ';

  @override
  String get regConfirmErrorPrefix => 'خطأ: ';

  @override
  String get regConfirmDisplayTitleStart => 'أكّد ';

  @override
  String get regConfirmDisplayTitleAccent => 'تسجيلك.';

  @override
  String get regConfirmPillFree => 'مجاني';

  @override
  String get regConfirmPillPaid => 'مدفوعة';

  @override
  String get regConfirmBreakdownFee => 'رسوم التسجيل';

  @override
  String get regConfirmBreakdownService => 'رسوم الخدمة';

  @override
  String get regConfirmBreakdownServiceIncluded => 'مشمولة';

  @override
  String get regConfirmBreakdownTotal => 'الإجمالي المستحق';

  @override
  String get regConfirmRanksRewardedSingle => 'مركز واحد يحصل على مكافأة';

  @override
  String get regConfirmRanksRewardedPluralSuffix => ' مراكز تحصل على مكافأة';

  @override
  String get regConfirmAckLabel => 'أوافق على قواعد البطولة واللائحة الداخلية.';

  @override
  String get regConfirmStoreLinkError => 'تعذّر فتح الرابط.';

  @override
  String get regConfirmPlayStore => 'Play Store';

  @override
  String get regConfirmAppStore => 'App Store';

  @override
  String get referralCardTitle => 'الإحالة مطلوبة';

  @override
  String get referralQuotaReached => '✓ تم بلوغ الحصة — يمكنك التسجيل!';

  @override
  String get referralShareSubject => 'انضم إليّ على ARENA';

  @override
  String get referralYourCodeLabel => 'رمزك';

  @override
  String get referralCopyButton => 'نسخ';

  @override
  String get referralShareButton => 'مشاركة';

  @override
  String get homeSectionNextMatch => '⚡ المباراة التالية';

  @override
  String get homeSectionLive => 'مباشر الآن';

  @override
  String get homeSectionActiveTournaments => '★ بطولاتي';

  @override
  String get homeSectionYourStats => '📊 إحصائياتك';

  @override
  String get homeViewAllLink => 'عرض الكل';

  @override
  String get mainLayoutExitConfirm => 'اضغط مرة أخرى للخروج من ARENA';

  @override
  String get mainLayoutTitleHome => 'الرئيسية';

  @override
  String get mainLayoutTitleCompetitions => 'المسابقات';

  @override
  String get mainLayoutTitleMessages => 'الرسائل';

  @override
  String get mainLayoutTitleProfile => 'الملف الشخصي';

  @override
  String get mainLayoutNavHome => 'الرئيسية';

  @override
  String get mainLayoutNavCompetitions => 'المسابقات';

  @override
  String get mainLayoutNavChat => 'الدردشة';

  @override
  String get mainLayoutNavProfile => 'الملف الشخصي';

  @override
  String get homeHeaderDefaultUsername => 'لاعب';

  @override
  String get homeHeaderTierBronze => '🥉 برونزي';

  @override
  String get homeHeaderSearchTooltip => 'البحث عن لاعب';

  @override
  String get liveStreamsErrorPrefix => 'خطأ: ';

  @override
  String get liveStreamsBadgeLive => 'مباشر';

  @override
  String get liveStreamsTapToWatch => 'اضغط للمشاهدة مباشرة';

  @override
  String get liveStreamsEmptyState => 'لا يوجد بث مباشر حاليًا';

  @override
  String get pendingPaymentCompetitionFallback => 'المسابقة';

  @override
  String get pendingPaymentSingleTitle => 'دفعة في انتظار التحقق';

  @override
  String get pendingPaymentTapToCheck => 'اضغط للتحقق من الحالة';

  @override
  String get promoBannerLinkOpenError => 'تعذر فتح الرابط.';

  @override
  String get tutorialWatchCta => 'شاهد البرنامج التعليمي';

  @override
  String get statGridMatchesLabel => 'المباريات';

  @override
  String get statGridWdlLabel => 'ف/خ/ت';

  @override
  String get statGridWinRateLabel => 'نسبة الفوز';

  @override
  String get upcomingMatchesEmpty => 'لا توجد مباراة مجدولة';

  @override
  String get upcomingMatchOpponentWaiting => 'في الانتظار';

  @override
  String get upcomingMatchLive => 'مباشر';

  @override
  String get upcomingBadgeInProgress => 'جارية';

  @override
  String get upcomingBadgeToSchedule => 'للجدولة';

  @override
  String get upcomingBadgeReady => 'جاهز';

  @override
  String get upcomingBadgeTomorrow => 'غدًا';

  @override
  String get upcomingPhaseMatch => 'مباراة';

  @override
  String get upcomingPhaseFinal => 'النهائي';

  @override
  String get upcomingPhaseSemiFinal => 'نصف النهائي';

  @override
  String get upcomingPhaseQuarterFinal => 'ربع النهائي';

  @override
  String get upcomingPhaseRoundOf16 => 'دور الـ16';

  @override
  String get upcomingPhaseRoundOf32 => 'دور الـ32';

  @override
  String get matchRoomTitleDefault => 'مباراة';

  @override
  String get matchRoomChatTooltip => 'الدردشة مع خصمك';

  @override
  String get matchRoomNotFoundTitle => 'المباراة غير موجودة';

  @override
  String get matchRoomNotFoundDescription =>
      'ربما تم إلغاء المباراة من قبل المشرف.';

  @override
  String get manualUploadButtonLabel => 'إرسال فيديو إثبات';

  @override
  String get manualUploadSuccess => 'تم إرسال الفيديو. شكرًا!';

  @override
  String get outcomeFinalScore => 'النتيجة النهائية';

  @override
  String get outcomeDraw => 'تعادل.';

  @override
  String get outcomeEditMyScore => 'تعديل نتيجتي';

  @override
  String get outcomeDisputeInProgress => 'نزاع جارٍ';

  @override
  String get outcomeDisputeExplanation =>
      'نتائجكما غير متطابقة. إذا أخطأت، فصححها؛ وإلا فانتظر حتى يصحح خصمك نتيجته. بدون اتفاق، سيبت المشرف بناءً على الأدلة.';

  @override
  String get outcomeScoreCardYou => 'أنت';

  @override
  String get outcomeScoreCardPlayer1 => 'اللاعب 1';

  @override
  String get outcomeScoreCardPlayer2 => 'اللاعب 2';

  @override
  String get matchHeaderPlayer1 => 'اللاعب 1';

  @override
  String get matchHeaderPlayer2 => 'اللاعب 2';

  @override
  String get matchHeaderBadgeHome => 'مضيف';

  @override
  String get matchHeaderBadgeAway => 'زائر';

  @override
  String get recordingActionResume => 'متابعة';

  @override
  String get recordingActionPause => 'إيقاف مؤقت (بحد أقصى دقيقتان)';

  @override
  String get recordingActionSaveStop => 'حفظ وإيقاف';

  @override
  String get recordingActionForfeit => 'إيقاف (انسحاب)';

  @override
  String get recordingNoRecordingInProgress => 'لا يوجد تسجيل جارٍ.';

  @override
  String get recordingStateRecording => 'التسجيل جارٍ';

  @override
  String get recordingStatePaused => 'متوقف مؤقتًا — استأنف خلال دقيقتين';

  @override
  String get recordingStateForfeited => 'تم إعلان الانسحاب';

  @override
  String get recordingStateStopped => 'تم إيقاف التسجيل';

  @override
  String get recordingStateIdle => 'لا يوجد تسجيل';

  @override
  String get recordingLiveStreamStarted => 'بدأ البث المباشر.';

  @override
  String get recordingReplaySavedDownloads =>
      'تم حفظ الإعادة في التنزيلات ‹ ARENA';

  @override
  String get recordingReplayInCache =>
      'الإعادة متاحة في ذاكرة التخزين المؤقت للتطبيق';

  @override
  String get recordingPermMissingMic => 'الميكروفون';

  @override
  String get recordingPermMissingNotifications => 'الإشعارات';

  @override
  String get recordingPermOverlayNeedsSettings =>
      'فعّل \"العرض فوق التطبيقات الأخرى\" لـ ARENA في الإعدادات > التطبيقات > الوصول الخاص';

  @override
  String get recordingPermOverlayDenied =>
      'تم رفض النافذة العائمة — اضغط مجددًا على \"أنا في الغرفة\" بعد التفعيل';

  @override
  String get recordingBannerRecording =>
      'تسجيل مكافحة الغش جارٍ\nاضغط للإجراءات';

  @override
  String get recordingBannerPaused =>
      'المباراة متوقفة مؤقتًا — اضغط للاستئناف أو الإيقاف';

  @override
  String get recordingBannerForfeitPauseExpired =>
      'انسحاب: تجاوز وقت الإيقاف المؤقت';

  @override
  String get recordingBannerForfeitDeclared => 'تم إعلان الانسحاب';

  @override
  String get stepBodyMatchInProgressTitle => 'المباراة جارية';

  @override
  String get stepBodyMatchInProgressDesc =>
      'اللاعبون يلعبون حاليًا أو يتحققون من النتيجة.';

  @override
  String get stepBodyMatchCancelledTitle => 'تم إلغاء المباراة';

  @override
  String get stepBodyMatchCancelledDesc => 'قام المسؤول بإلغاء هذه المباراة.';

  @override
  String get stepBodyForfeitTitle => 'انسحاب';

  @override
  String get stepBodyForfeitDesc => 'لم يبدأ أحد اللاعبين في الوقت المحدد.';

  @override
  String get stepBodyAwaitRoomCodeTitle => 'بانتظار رمز الغرفة';

  @override
  String get stepBodyAwaitRoomCodeDesc =>
      'سينشئ اللاعبون غرفة في اللعبة ويشاركون الرمز هنا.';

  @override
  String get stepBodyAwaitHomeCodeTitle => 'بانتظار رمز المضيف';

  @override
  String get stepBodyAwaitHomeCodeDesc =>
      'أنت الزائر في هذه المباراة. ينشئ اللاعب المضيف الغرفة في اللعبة وسيرسل لك الرمز هنا بمجرد مشاركته.';

  @override
  String get openChatButton => 'فتح الدردشة';

  @override
  String get roomReadyMarkStartedError => 'تعذّر تحديد البدء: ';

  @override
  String get roomReadyCodeCopied => 'تم نسخ الرمز إلى الحافظة';

  @override
  String get roomReadyHintObserver =>
      'سينضم اللاعبون إلى الغرفة ويبدؤون المباراة.';

  @override
  String get roomReadyHintHome =>
      'لقد شاركت الرمز. في انتظار انضمام خصمك، ثم أكّدا البدء معًا.';

  @override
  String get roomReadyHintAway =>
      'انضم إلى الغرفة داخل اللعبة باستخدام هذا الرمز، ثم أكّد بمجرد دخول كلا اللاعبين.';

  @override
  String get roomReadyCodeLabel => 'رمز الغرفة';

  @override
  String get roomReadyCopyTooltip => 'نسخ الرمز';

  @override
  String get roomReadyTeamNameLabel => 'اسم فريقك';

  @override
  String get roomReadyTeamNameHint => 'مثال: ريال مدريد، برشلونة…';

  @override
  String get roomReadyTeamNameHelper =>
      'إلزامي — الفريق الذي تستخدمه في هذه المباراة. مرئي للمشرف في حال نشوب نزاع لمكافحة الغش.';

  @override
  String get roomReadyInRoomButton => 'أنا في الغرفة';

  @override
  String get roomReadyCodeSharedBadge => 'تمت مشاركة الرمز';

  @override
  String get roomReadySyncingHint => 'جارٍ المزامنة مع خصمك…';

  @override
  String get scoreEditErrorRange => 'يجب أن تكون النتائج بين 0 و99.';

  @override
  String get scoreEditErrorTieBeforePens =>
      'يجب أن تكون نتيجة الوقت الأصلي متعادلة قبل ركلات الترجيح.';

  @override
  String get scoreEditErrorPensRange => 'يجب أن تكون ركلات الترجيح بين 0 و30.';

  @override
  String get scoreEditErrorPensTie =>
      'لا يمكن أن تنتهي ركلات الترجيح بالتعادل.';

  @override
  String get scoreEditDialogTitle => 'تصحيح نتيجتك';

  @override
  String get scoreEditMyScoreLabel => 'نتيجتي';

  @override
  String get scoreEditOpponentLabel => 'الخصم';

  @override
  String get scoreEditViaPenaltiesLabel => 'حُسمت بركلات الترجيح';

  @override
  String get scoreEditMyPenLabel => 'ركلات ترجيحي';

  @override
  String get scoreEditOppPenLabel => 'ركلات الخصم';

  @override
  String get scoreEditCancelButton => 'إلغاء';

  @override
  String get scoreEditResendButton => 'إعادة الإرسال';

  @override
  String get scoreFlowErrorRange => 'يجب أن تكون النتائج بين 0 و99.';

  @override
  String get scoreFlowErrorTieBeforePens =>
      'يجب أن تكون نتيجة الوقت الأصلي متعادلة قبل ركلات الترجيح.';

  @override
  String get scoreFlowErrorPensRange => 'يجب أن تكون ركلات الترجيح بين 0 و30.';

  @override
  String get scoreFlowErrorPensTie =>
      'لا يمكن أن تنتهي ركلات الترجيح بالتعادل.';

  @override
  String get scoreFlowSubmitError => 'تعذّر الإرسال: ';

  @override
  String get scoreFlowProofUploadError => 'تعذّر الرفع: ';

  @override
  String get scoreFlowResolutionError => 'خطأ في الحسم: ';

  @override
  String get scoreFlowSessionExpiredTitle => 'انتهت الجلسة';

  @override
  String get scoreFlowSessionExpiredDescription =>
      'سجّل الدخول مجددًا لإدخال نتيجة.';

  @override
  String get scoreFlowEnterFinalScoreLabel => 'أدخل النتيجة النهائية';

  @override
  String get scoreFlowEnterFinalScoreHint =>
      'أدخل أهداف كل طرف. إذا تطابق إدخالاكما، يتم اعتماد المباراة تلقائيًا.';

  @override
  String get scoreFlowMyScoreLabel => 'نتيجتي';

  @override
  String get scoreFlowOppScoreLabel => 'نتيجة الخصم';

  @override
  String get scoreFlowViaPenaltiesTitle => 'مباراة حُسمت بركلات الترجيح';

  @override
  String get scoreFlowViaPenaltiesSubtitle =>
      'حدّد هذا فقط إذا كانت نتيجة الوقت الأصلي متعادلة.';

  @override
  String get scoreFlowMyPenLabel => 'ركلات الترجيح الخاصة بي';

  @override
  String get scoreFlowOppPenLabel => 'ركلات ترجيح الخصم';

  @override
  String get scoreFlowSubmitButton => 'إرسال النتيجة';

  @override
  String get scoreFlowValidationInProgress => 'جارٍ التحقق';

  @override
  String get scoreFlowWaitingOpponent => 'في انتظار خصمك';

  @override
  String get scoreFlowYouSubmitted => 'لقد أرسلت: ';

  @override
  String get scoreFlowOnPenalties => 'بركلات الترجيح: ';

  @override
  String get scoreFlowComparingScores => 'جارٍ مقارنة نتيجتَي اللاعبين…';

  @override
  String get scoreFlowOpponentNotSubmitted => 'لم يُدخل خصمك نتيجته بعد.';

  @override
  String get scoreFlowProofAttached => 'تم إرفاق الدليل';

  @override
  String get scoreFlowProofPrompt => 'أرفق صورة أو فيديو (مُستحسن)';

  @override
  String get scoreFlowProofHelper =>
      'لقطة شاشة لشاشة نهاية المباراة أو مقطع للحركة الأخيرة — مفيد في حال نشوب نزاع.';

  @override
  String get scoreFlowUploading => 'جارٍ الرفع…';

  @override
  String get scoreFlowReplaceButton => 'استبدال';

  @override
  String get scoreFlowRemoveProofTooltip => 'إزالة الدليل';

  @override
  String get scoreFlowChooseFileButton => 'اختيار ملف';

  @override
  String get shareCodeErrorLength => 'يجب أن يتكوّن الرمز من 4 إلى 12 حرفًا.';

  @override
  String get shareCodeErrorSendFailed => 'تعذّر مشاركة الرمز: ';

  @override
  String get shareCodeRoomLabel => 'رمز الغرفة (يُنشئه المضيف)';

  @override
  String get shareCodeEnterPrompt => 'أدخل رمز eFootball الخاص بك:';

  @override
  String get shareCodeOpponentWillReceive =>
      'سيتلقّى خصمك هذا الرمز في الدردشة بمجرد إرساله.';

  @override
  String get shareCodeOpponentReceives =>
      'يتلقّى خصمك هذا الرمز في الدردشة بمجرد إرساله.';

  @override
  String get shareCodeSubmitButton => 'إرسال الرمز';

  @override
  String get shareCodeInputHint => 'مثال: 8K3-TZ9';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsMarkAllReadTooltip => 'تعليم الكل كمقروء';

  @override
  String get notificationsMarkAllReadError => 'تعذّر تعليم الكل كمقروء.';

  @override
  String get notificationsLoadError => 'حدث خطأ أثناء التحميل.\n';

  @override
  String get notificationsSignedOut => 'سجّل الدخول لرؤية إشعاراتك.';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات بعد.';

  @override
  String get notificationsFilterAll => 'الكل';

  @override
  String get notificationsFilterMatch => 'المباريات';

  @override
  String get notificationsFilterEarning => 'الأرباح';

  @override
  String get notificationsFilterSystem => 'النظام';

  @override
  String get notificationsTimeJustNow => 'الآن';

  @override
  String get notificationsTimeYesterday => 'أمس';

  @override
  String get mobileMoneyDefaultCountry => '🇨🇲 الكاميرون';

  @override
  String get mobileMoneyCountryLabel => 'الدولة';

  @override
  String get mobileMoneyNumberLabel => 'رقم ';

  @override
  String get mobileMoneyNumberHelp =>
      'الرقم الذي ستدفع منه (يساعد المشرف العام على إيجاد معاملتك).';

  @override
  String get mobileMoneyPhoneValid => '✓ رقم صالح ';

  @override
  String get mobileMoneySubmitSending => 'جارٍ الإرسال…';

  @override
  String get mobileMoneySubmitPaid => 'لقد دفعت ';

  @override
  String get mobileMoneyCodeCopied => 'تم نسخ رمز التاجر.';

  @override
  String get mobileMoneyDialerError =>
      'تعذّر فتح برنامج الاتصال. انسخ الرمز واطلبه يدويًا.';

  @override
  String get mobileMoneySubmitError => 'حدث خطأ أثناء الإرسال: ';

  @override
  String get mobileMoneyNoConnection => 'لا يوجد اتصال: ';

  @override
  String get mobileMoneyHeroPayment => 'الدفع ';

  @override
  String get mobileMoneyHeroForAmount => 'مقابل ';

  @override
  String get mobileMoneyMerchantCodeTitle => 'رمز التاجر';

  @override
  String get mobileMoneyCopyButton => '📋 نسخ';

  @override
  String get mobileMoneyExecuteButton => '📞 تنفيذ';

  @override
  String get mobileMoneyMissingCodeTitle => '⚠ رمز التاجر مفقود';

  @override
  String get mobileMoneyMissingCodeBody =>
      'لم يقم المشرف بعد بإعداد رمز تاجر لهذه الطريقة في هذه المسابقة. اختر طريقة أخرى أو تواصل مع الدعم.';

  @override
  String get mobileMoneyDisclaimerExactAmount =>
      'ادفع المبلغ بالضبط — وإلا سيرفضه المشرف العام';

  @override
  String get mobileMoneyDisclaimerKeepSms =>
      'احتفظ برسالة تأكيد Mobile Money كدليل';

  @override
  String get mobileMoneyDisclaimerManualValidation =>
      'يتحقّق المشرف يدويًا من دفعتك بعد استلامها';

  @override
  String get mobileMoneyDisclaimerTitle => '⚠ قبل المتابعة';

  @override
  String get paymentFailedRejectedWithReason => 'رفض المشرف العام دفعتك: ';

  @override
  String get paymentFailedRejectedGeneric =>
      'رفض المشرف العام دفعتك (مبلغ غير صحيح أو لم يتم العثور على المعاملة في حساب التاجر).';

  @override
  String get paymentFailedNetwork =>
      'حدثت مشكلة في الشبكة أثناء الإرسال. لم يتم خصم أي مبلغ من جانب ARENA.';

  @override
  String get paymentFailedUnknown =>
      'تعذّر تأكيد الدفع. حاول مجددًا أو تواصل مع الدعم.';

  @override
  String get paymentFailedSolutionCheckAmount =>
      'تحقّق من المبلغ بالضبط + رمز التاجر';

  @override
  String get paymentFailedSolutionRetryFromSignup =>
      'ابدأ من جديد من صفحة التسجيل';

  @override
  String get paymentFailedSolutionContactIfError =>
      'تواصل مع الدعم إذا كنت تعتقد أن هذا خطأ';

  @override
  String get paymentFailedSolutionCheckInternet => 'تحقّق من اتصالك بالإنترنت';

  @override
  String get paymentFailedSolutionContactSupport => 'تواصل مع دعم ARENA';

  @override
  String get paymentFailedAccountNotRegistered => 'لم يتم تسجيل حسابك.';

  @override
  String get paymentFailedRetryButton => '↻ إعادة المحاولة';

  @override
  String get paymentFailedContactSupportLink => 'تواصل مع دعم ARENA';

  @override
  String get paymentFailedTitleRejected => 'تم رفض الدفع';

  @override
  String get paymentFailedTitleFailed => 'فشل الدفع';

  @override
  String get paymentFailedCauseTitle => '⚠ السبب';

  @override
  String get paymentFailedErrorCodeLabel => 'رمز الخطأ: ';

  @override
  String get paymentFailedSolutionsTitle => '💡 الحلول';

  @override
  String get paymentHistoryAppBarTitle => 'السجل';

  @override
  String get paymentHistoryErrorPrefix => 'خطأ: ';

  @override
  String get paymentHistoryTabPayments => 'المدفوعات';

  @override
  String get paymentHistoryTabGains => 'الأرباح';

  @override
  String get paymentHistoryGainsEmpty =>
      'لا أرباح حتى الآن. افز ببطولة لتحصل على دفعة!';

  @override
  String get paymentHistoryBadgePaid => 'تم الدفع';

  @override
  String get paymentHistoryBadgePending => 'قيد الانتظار';

  @override
  String get paymentHistoryBadgeToClaim => 'للمطالبة';

  @override
  String get paymentHistoryGainRanked => 'أرباح · المرتبة ';

  @override
  String get paymentHistoryGainGeneric => 'أرباح البطولة';

  @override
  String get paymentHistoryClaimButton => 'المطالبة بأرباحي';

  @override
  String get paymentHistoryClaimSuccess =>
      'تمت المطالبة بالأرباح — سيقوم الفريق بإجراء الدفع.';

  @override
  String get paymentHistoryClaimFailPrefix => 'فشل: ';

  @override
  String get paymentHistoryClaimSheetTitle => 'المطالبة بأرباحي';

  @override
  String get paymentHistoryClaimSheetSubtitle =>
      'أدخل رقم Mobile Money الذي تريد استلام دفعتك عليه.';

  @override
  String get paymentHistoryClaimMethodMtn => 'MTN MoMo';

  @override
  String get paymentHistoryClaimMethodOrange => 'Orange Money';

  @override
  String get paymentHistoryClaimPhoneHint =>
      'رقم Mobile Money (مثال: +237 6XX XX XX XX)';

  @override
  String get paymentHistoryClaimConfirm => 'تأكيد';

  @override
  String get paymentHistoryClaimPhoneRequired => 'الرقم مطلوب.';

  @override
  String get paymentHistoryEmptyPayments => 'لا مدفوعات حتى الآن.';

  @override
  String get paymentHistoryNetBalanceLabel => 'الرصيد الصافي';

  @override
  String get paymentHistoryTxTitle => 'التسجيل في البطولة';

  @override
  String get paymentHistoryTxBadgePaid => 'مدفوع';

  @override
  String get paymentHistoryTxBadgePending => 'قيد الانتظار';

  @override
  String get paymentHistoryTxBadgeRefund => 'استرداد';

  @override
  String get paymentHistoryTxBadgeRefunded => 'تم الاسترداد';

  @override
  String get paymentHistoryTxBadgeFailed => 'فشل';

  @override
  String get paymentHistoryResumeCompetition => 'بطولة';

  @override
  String get paymentMethodMtnLabel => 'MTN Mobile Money';

  @override
  String get paymentMethodMtnCountries => 'الكاميرون، ساحل العاج، بنين';

  @override
  String get paymentMethodOrangeLabel => 'Orange Money';

  @override
  String get paymentMethodOrangeCountries => 'الكاميرون، السنغال، مالي';

  @override
  String get paymentPickerAppBarTitle => 'الدفع';

  @override
  String get paymentPickerMobileMoneySection => '📱 محفظة الهاتف المحمول';

  @override
  String get paymentPickerV2Notice =>
      '₿ العملات المشفرة + Wave + Moov متوفرة في الإصدار 2 (بوابات CinetPay / NowPayments التلقائية).';

  @override
  String get paymentPickerContinueButton => 'متابعة →';

  @override
  String get paymentPickerAmountLabel => 'المبلغ المطلوب دفعه';

  @override
  String get paymentProcessingAppBarTitle => 'حالة الدفع';

  @override
  String get paymentProcessingWaitingTitle => 'بانتظار التحقق';

  @override
  String get paymentProcessingWaitingSubtitle =>
      'يتحقق المشرف العام من استلام الدفعة على حساب ';

  @override
  String get paymentProcessingWaitingSubtitleSuffix => '.';

  @override
  String get paymentProcessingInfoNote =>
      '💡 يمكنك إغلاق هذه الصفحة: تبقى المعاملة قيد الانتظار لدى المشرف. يمكنك العودة للتحقق من الحالة من \"سجل المدفوعات\" أو الشريط في الصفحة الرئيسية.';

  @override
  String get paymentProcessingLeaveButton => 'مغادرة (تستمر المعاملة)';

  @override
  String get paymentProcessingCancelButton => 'إلغاء المعاملة';

  @override
  String get paymentProcessingCancelDialogTitle => 'إلغاء الدفع؟';

  @override
  String get paymentProcessingCancelDialogBody =>
      'إذا كنت قد دفعت بالفعل عبر Mobile Money، فانتظر التحقق بدلاً من الإلغاء هنا (وإلا فلن يسجّل المشرف حسابك).';

  @override
  String get paymentProcessingCancelDialogStay => 'البقاء';

  @override
  String get paymentProcessingCancelDialogConfirm => 'الإلغاء على أي حال';

  @override
  String get paymentProcessingRecapCompetition => 'البطولة';

  @override
  String get paymentProcessingRecapAmount => 'المبلغ';

  @override
  String get paymentProcessingRecapMethod => 'الطريقة';

  @override
  String get paymentProcessingRecapPhone => 'رقمك';

  @override
  String get paymentProcessingRecapReference => 'المرجع';

  @override
  String get paymentSuccessTitle => 'تم الدفع بنجاح!';

  @override
  String get paymentSuccessSubtitle => 'تم تأكيد تسجيلك.';

  @override
  String get paymentSuccessSeeCompetition => '🏆 عرض المنافسة';

  @override
  String get paymentSuccessBackHome => 'العودة إلى الرئيسية';

  @override
  String get paymentSuccessReceiptAmount => 'المبلغ';

  @override
  String get paymentSuccessReceiptMethod => 'الطريقة';

  @override
  String get paymentSuccessReceiptTransaction => 'رقم المعاملة';

  @override
  String get paymentSuccessReceiptDate => 'التاريخ';

  @override
  String get paymentSuccessRegisteredLabel => '🏆 أنت مسجل في';

  @override
  String get payoutKycStepIdRecto => 'وثيقة الهوية (الوجه الأمامي)';

  @override
  String get payoutKycStepIdVerso => 'وثيقة الهوية (الوجه الخلفي)';

  @override
  String get payoutKycStepSelfie => 'صورة شخصية للتحقق';

  @override
  String get payoutKycAppBarTitle => 'تحقق';

  @override
  String get payoutKycAcceptedDocsLabel => 'الوثائق المقبولة';

  @override
  String get payoutKycSubmitForReview => 'إرسال للتحقق';

  @override
  String get payoutKycNextRectoRequired => 'التالي (الوجه الأمامي مطلوب)';

  @override
  String payoutKycPendingGain(Object amount) {
    return '💰 أرباح بقيمة $amount XAF';
  }

  @override
  String get payoutKycPendingExplain =>
      'بالنسبة لهذا المبلغ، يجب علينا التحقق من هويتك قبل صرف الأرباح. الأمر سريع (خلال 24 ساعة).';

  @override
  String get payoutKycDocNationalId => 'بطاقة الهوية الوطنية';

  @override
  String get payoutKycDocPassport => 'جواز السفر';

  @override
  String get payoutKycDocDriverLicense => 'رخصة القيادة';

  @override
  String get payoutKycPhotoCaptured => 'تم التقاط الصورة';

  @override
  String get payoutKycRetake => 'إعادة الالتقاط';

  @override
  String get payoutKycPhotographFront => 'التقط صورة للوجه الأمامي';

  @override
  String get payoutKycCaptureHint => 'إضاءة جيدة، صورة واضحة، بدون انعكاسات';

  @override
  String get payoutKycTakePhoto => '📸 التقاط صورة';

  @override
  String get payoutKycSecurityLabel => 'الأمان: ';

  @override
  String get payoutKycSecurityNote =>
      'يتم تشفير وثائقك واستخدامها فقط للتحقق التنظيمي.';

  @override
  String get aboutLinkCgu => 'شروط الاستخدام';

  @override
  String get aboutLinkPrivacy => 'سياسة الخصوصية';

  @override
  String get aboutLinkCookies => 'ملفات تعريف الارتباط';

  @override
  String get aboutLinkSupport => 'الدعم';

  @override
  String get aboutLinkSite => 'موقع arena.app';

  @override
  String get aboutAppBarTitle => 'حول';

  @override
  String get aboutMadeInCameroon => 'صُنع في الكاميرون 🇨🇲';

  @override
  String get aboutLinksLabel => 'الروابط';

  @override
  String get aboutBuiltWith => 'بُني باستخدام';

  @override
  String get aboutMissionTitle => '📜 مهمتنا';

  @override
  String get aboutMissionBody =>
      'تعمل ARENA على إتاحة الرياضات الإلكترونية عبر الهاتف المحمول في إفريقيا من خلال تقديم بطولات عادلة وأرباح عبر المحفظة الإلكترونية وتجربة متميزة لعشاق كرة القدم الافتراضية.';

  @override
  String aboutLinkComingSoon(Object label) {
    return '$label قادم في المرحلة 12.5';
  }

  @override
  String get adminMessagesAppBarTitle => 'رسائل ARENA';

  @override
  String adminMessagesError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get adminMessagesEmpty => 'لا توجد رسائل من ARENA.';

  @override
  String get deleteAccountStepWarning => 'تحذير';

  @override
  String get deleteAccountStepPendingEarnings => 'أرباح معلّقة';

  @override
  String get deleteAccountStepConfirmation => 'تأكيد';

  @override
  String get deleteAccountStepDone => 'تم';

  @override
  String get deleteAccountAppBarTitle => 'حذف';

  @override
  String get deleteAccountLossHistory => 'كل سجل مبارياتك وبطولاتك';

  @override
  String get deleteAccountLossBadges => 'أوسمتك وإنجازاتك';

  @override
  String get deleteAccountLossChats => 'محادثاتك ودردشات المباريات';

  @override
  String get deleteAccountLossPaymentMethods => 'وسائل الدفع المحفوظة';

  @override
  String get deleteAccountIrreversibleTitle =>
      'هذا الإجراء لا يمكن التراجع عنه';

  @override
  String get deleteAccountLossIntro => 'بحذف حسابك، ستفقد:';

  @override
  String get deleteAccountRetentionNotice =>
      'سيتم تعطيل حسابك فوراً، ثم إخفاء هويته (محو البيانات الشخصية) خلال 30 يوماً. تُحفظ المستندات المحاسبية القانونية (المدفوعات) بصيغة مجهولة الهوية. خلال هذه المدة، يمكنك التواصل مع الدعم للإلغاء.';

  @override
  String get deleteAccountUnderstandContinue => 'أفهم، متابعة';

  @override
  String get deleteAccountHasPendingTitle => 'لديك أرباح معلّقة';

  @override
  String get deleteAccountHasPendingBody =>
      'استرجع مدفوعاتك المعلّقة قبل حذف حسابك. بعد الحذف، لن يكون بالإمكان إرسال هذه الأموال إليك.';

  @override
  String get deleteAccountBack => 'رجوع';

  @override
  String get deleteAccountNoPendingTitle => 'لا توجد أرباح معلّقة';

  @override
  String get deleteAccountNoPendingBody =>
      'يمكنك المتابعة في الحذف دون خطر فقدان أي مدفوعات جارية.';

  @override
  String get deleteAccountContinue => 'متابعة';

  @override
  String get deleteAccountConfirmWord => 'حذف';

  @override
  String get deleteAccountConfirmTitle => 'أكّد الحذف';

  @override
  String get deleteAccountPasswordLabel => 'كلمة المرور';

  @override
  String get deleteAccountReasonLabel => 'السبب (اختياري)';

  @override
  String get deleteAccountDeletePermanently => 'حذف نهائي';

  @override
  String get deleteAccountDoneTitle => 'تم تعطيل الحساب';

  @override
  String get deleteAccountDoneBody =>
      'سيتم إخفاء هوية حسابك (محو البيانات الشخصية) خلال 30 يوماً. تواصل مع الدعم إذا غيّرت رأيك.';

  @override
  String get deleteAccountBackToHome => 'العودة إلى الرئيسية';

  @override
  String get editProfileWhatsappInvalidError => 'رقم واتساب غير صالح.';

  @override
  String get editProfileUpdatedSnack => 'تم تحديث الملف الشخصي.';

  @override
  String get editProfileAppBarTitle => 'تعديل';

  @override
  String get editProfileSaveTooltip => 'حفظ';

  @override
  String get editProfileColorEditableHint => 'يمكن تعديل اللون أدناه';

  @override
  String get editProfileUsernameCaption => 'اسم المستخدم';

  @override
  String get editProfileUsernameMinError => '3 أحرف كحد أدنى';

  @override
  String get editProfileUsernameMaxError => '20 حرفاً كحد أقصى';

  @override
  String get editProfileCountryCaption => 'الدولة';

  @override
  String get editProfileAvatarColorCaption => 'لون الصورة الرمزية';

  @override
  String get editProfileWhatsappHint => 'مثال: 07 07 07 07 07';

  @override
  String get editProfileWhatsappInvalidErrorText => 'رقم غير صالح.';

  @override
  String get editProfileSaveButton => 'حفظ';

  @override
  String get friendsAppBarTitle => 'أصدقائي';

  @override
  String get friendsSearchTooltip => 'بحث';

  @override
  String get friendsTabFriends => 'الأصدقاء';

  @override
  String get friendsTabRequests => 'الطلبات';

  @override
  String get friendsTabBlocked => 'المحظورون';

  @override
  String get friendsEmptyLabel => 'لا أصدقاء بعد.';

  @override
  String get friendsEmptyHint => 'اضغط على العدسة في الأعلى للبحث عنهم.';

  @override
  String get friendsRemoveCancel => 'إلغاء';

  @override
  String get friendsRemoveConfirm => 'تأكيد';

  @override
  String get friendsSectionReceived => 'الواردة';

  @override
  String get friendsSectionSent => 'المرسلة';

  @override
  String get friendsNoRequests => 'لا توجد طلبات.';

  @override
  String get friendsNoPendingRequests => 'لا توجد طلبات معلّقة.';

  @override
  String get friendsCancelRequest => 'إلغاء';

  @override
  String get friendsBlockedEmptyLabel => 'لا يوجد لاعبون محظورون.';

  @override
  String get friendsUnblockAction => 'إلغاء الحظر';

  @override
  String get friendsSearchAppBarTitle => 'بحث';

  @override
  String get friendsSearchHint => 'اسم المستخدم';

  @override
  String get friendsSearchPrompt => 'اكتب حرفين على الأقل للبحث.';

  @override
  String get matchHistoryAppBarLoadingTitle => 'السجل';

  @override
  String get matchHistoryAppBarTitle => 'السجل';

  @override
  String get matchHistoryError => 'تعذّر تحميل سجلّك. تحقّق من اتصالك.';

  @override
  String get matchHistoryFilterAll => 'الكل';

  @override
  String get matchHistoryFilterWins => 'ف';

  @override
  String get matchHistoryFilterLosses => 'خ';

  @override
  String get matchHistoryFilterOngoing => 'جارية';

  @override
  String get matchHistoryEmptyTitle => 'لا توجد مباريات';

  @override
  String get matchHistoryEmptyDescription =>
      'ستظهر مبارياتك هنا بدءًا من أول منافسة.';

  @override
  String get matchHistoryOpponentFallback => 'الخصم';

  @override
  String get playerProfileUnavailable =>
      'الملف الشخصي غير متاح. يُرجى تسجيل الدخول مجددًا.';

  @override
  String get playerProfileSuccessHeader => '🏆 الإنجازات';

  @override
  String get playerProfileRecentMatchesHeader => 'المباريات الأخيرة';

  @override
  String get playerProfileSettingsButton => 'الإعدادات';

  @override
  String get playerProfileSignOutButton => 'تسجيل الخروج';

  @override
  String get playerProfileJoinedPrefix => 'انضمّ في';

  @override
  String get playerProfileTierBronze => '🥉 برونزي';

  @override
  String get playerProfileTierSilver => '🥈 فضي';

  @override
  String get playerProfileTierGold => '🥇 ذهبي';

  @override
  String get playerProfileTierElite => '💎 نخبة';

  @override
  String get playerProfileEditTooltip => 'تعديل';

  @override
  String get playerProfileStatWins => 'الانتصارات';

  @override
  String get playerProfileStatLosses => 'الهزائم';

  @override
  String get playerProfileStatWinRate => 'نسبة الفوز';

  @override
  String get playerProfileNoCompletedMatches => 'لا توجد مباريات مكتملة بعد.';

  @override
  String get playerProfileFriendsTitle => 'أصدقائي';

  @override
  String get playerProfileNoFriends => 'لا يوجد أصدقاء بعد';

  @override
  String get playerProfileReferralTitle => 'إحالاتي';

  @override
  String get playerProfileReferralCodeCopied => 'تم نسخ رمز الإحالة';

  @override
  String get playerProfileReferralCodeGenerating => 'جارٍ إنشاء الرمز…';

  @override
  String get playerProfileReferralExplainer =>
      'شارك رمزك لإحالة أصدقائك. بمجرد بلوغك الحصة المطلوبة، ستحصل تلقائيًا على الوصول إلى المنافسات المجانية ذات المكافآت المشروطة.';

  @override
  String get playerProfileResultWin => 'ف';

  @override
  String get playerProfileResultLoss => 'خ';

  @override
  String get playerProfileResultDraw => 'ت';

  @override
  String get publicProfileAppBarTitle => 'الملف الشخصي';

  @override
  String get publicProfilePlayerNotFound => 'اللاعب غير موجود.';

  @override
  String get publicProfileRecentMatchesHeader => 'المباريات الأخيرة';

  @override
  String get publicProfileCtaAddFriend => 'إضافة صديق';

  @override
  String get publicProfileCtaRequestSent => 'تم إرسال الطلب';

  @override
  String get publicProfileCtaCancel => 'إلغاء';

  @override
  String get publicProfileRequestCancelled => 'تم إلغاء الطلب';

  @override
  String get publicProfileCtaAccept => 'قبول';

  @override
  String get publicProfileCtaDecline => 'رفض';

  @override
  String get publicProfileRequestDeclined => 'تم رفض الطلب';

  @override
  String get publicProfileCtaFriend => 'صديق';

  @override
  String get publicProfileCtaRemove => 'إزالة';

  @override
  String get publicProfileFriendRemoved => 'تمت إزالة الصديق';

  @override
  String get publicProfileCtaBlock => 'حظر';

  @override
  String get publicProfileBlockConfirmDetail =>
      'لن تتمكّنا من التراسل في محادثة المباراة بعد الآن.';

  @override
  String get publicProfilePlayerBlocked => 'تم حظر اللاعب';

  @override
  String get publicProfileCtaUnblock => 'إلغاء الحظر';

  @override
  String get publicProfilePlayerUnblocked => 'تم إلغاء حظر اللاعب';

  @override
  String get publicProfileCtaUnavailable => 'غير متاح';

  @override
  String get publicProfileDialogCancel => 'إلغاء';

  @override
  String get publicProfileDialogConfirm => 'تأكيد';

  @override
  String get publicProfileStatsHeader => 'الإحصائيات';

  @override
  String get publicProfileStatWin => 'ف';

  @override
  String get publicProfileStatLoss => 'خ';

  @override
  String get publicProfileStatDraw => 'ت';

  @override
  String get publicProfileWinRateLabel => 'نسبة الفوز';

  @override
  String get publicProfileGoalsScored => 'الأهداف المسجّلة';

  @override
  String get publicProfileGoalsConceded => 'الأهداف المستقبَلة';

  @override
  String get publicProfileNoCompletedMatches => 'لا توجد مباريات مكتملة بعد.';

  @override
  String get publicProfileResultWin => 'ف';

  @override
  String get publicProfileResultLoss => 'خ';

  @override
  String get publicProfileResultDraw => 'ت';

  @override
  String get settingsAppBarTitle => 'الإعدادات';

  @override
  String get settingsSectionPreferences => 'التفضيلات';

  @override
  String get settingsSectionAccount => 'الحساب';

  @override
  String get settingsSectionPrivacy => 'الخصوصية';

  @override
  String get settingsSectionHelp => 'المساعدة والمعلومات';

  @override
  String get settingsVersionFooter => 'الإصدار 1.0.0 · بناء 12';

  @override
  String get settingsLanguageLabel => 'اللغة';

  @override
  String get settingsCurrencyLabel => 'العملة';

  @override
  String get settingsMarketingTitle => 'إشعارات تسويقية';

  @override
  String get settingsMarketingSubtitle => 'نصائح، بطولات جديدة، عروض ترويجية';

  @override
  String get settingsChangeEmailTitle => 'تغيير البريد الإلكتروني';

  @override
  String get settingsChangePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get settingsLoginMethodsTitle => 'طرق تسجيل الدخول';

  @override
  String get settingsLoginMethodsSubtitle => 'Google / Apple — قريبًا';

  @override
  String get settingsNewEmailDialogTitle => 'بريد إلكتروني جديد';

  @override
  String get settingsNewEmailHint => 'name@example.com';

  @override
  String get settingsDialogCancel => 'إلغاء';

  @override
  String get settingsDialogConfirm => 'تأكيد';

  @override
  String get settingsEmailChangeConfirmSnack =>
      'تحقّق من بريدك الإلكتروني لتأكيد التغيير.';

  @override
  String get settingsNewPasswordDialogTitle => 'كلمة مرور جديدة';

  @override
  String get settingsNewPasswordHint => '8 أحرف على الأقل';

  @override
  String get settingsPasswordUpdatedSnack => 'تم تحديث كلمة المرور.';

  @override
  String get settingsDownloadDataTitle => 'تنزيل بياناتي';

  @override
  String get settingsDownloadDataExporting => 'جارٍ التصدير…';

  @override
  String get settingsDownloadDataSubtitle =>
      'يُنشئ ملف JSON يحتوي على جميع بياناتك';

  @override
  String get settingsDeleteAccountTitle => 'حذف حسابي';

  @override
  String get settingsExportSuccessTitle => 'تم التصدير بنجاح';

  @override
  String get settingsExportPathCopied => 'تم نسخ المسار إلى الحافظة.';

  @override
  String get settingsExportContentLabel => 'المحتوى:';

  @override
  String get settingsDialogOk => 'موافق';

  @override
  String get settingsReplayIntroTitle => 'إعادة مشاهدة المقدمة';

  @override
  String get settingsSupportTitle => 'الدعم';

  @override
  String get settingsAboutTitle => 'حول';

  @override
  String get settingsAboutSubtitle =>
      'ARENA V1.0 — منصة بطولات الرياضات الإلكترونية للهواتف';

  @override
  String get matchOverlayContinue => '▶ متابعة';

  @override
  String get matchOverlayPauseRecording => '⏸ إيقاف التسجيل مؤقتاً';

  @override
  String get matchOverlayStopForfeit => '🛑 إيقاف (انسحاب)';

  @override
  String get recordingErrorSolutionStep1 =>
      'اذهب إلى الإعدادات ← التطبيقات ← ARENA';

  @override
  String get recordingErrorSolutionStep2 =>
      'فعّل \"العرض فوق التطبيقات الأخرى\"';

  @override
  String get recordingErrorSolutionStep3 => 'عطّل موفّر البطارية لتطبيق ARENA';

  @override
  String get recordingErrorSolutionStep4 =>
      'اسمح لتطبيق ARENA بالعمل في الخلفية';

  @override
  String get recordingErrorAppBarTitle => 'خطأ في التسجيل';

  @override
  String get recordingErrorHeadline => 'تعذّر التسجيل';

  @override
  String get recordingErrorAntiCheatNotice =>
      'بدون التسجيل، لا يمكن بدء المباراة (مكافحة الغش).';

  @override
  String get recordingErrorSolutionsLabel => 'الحلول';

  @override
  String get recordingErrorRetryButton => '↻ إعادة المحاولة';

  @override
  String get recordingErrorForfeitButton => '🏳 انسحاب (خسارة)';

  @override
  String get recordingErrorContactSupport => 'التواصل مع الدعم';

  @override
  String get recordingErrorCauseTitle => '⚠️ السبب المكتشف';

  @override
  String get recordingErrorCausePermissionPrefix => 'إذن ';

  @override
  String get recordingErrorCausePermissionSuffix => ' مفقود.';

  @override
  String get liveStreamsAppBarTitle => 'البث المباشر الآن';

  @override
  String get liveStreamsErrorPrefixV2 => 'خطأ: ';

  @override
  String get liveStreamsEmptyTitle => 'لا توجد مباريات مباشرة';

  @override
  String get liveStreamsEmptyDescription =>
      'تظهر عمليات البث المباشر هنا بمجرد أن يختار المشرف مباراة للبث.';

  @override
  String get liveStreamsBroadcastByPrefix => 'بث بواسطة ';

  @override
  String get startStreamingAlreadyLive => 'أنت تبث هذه المباراة مباشرة';

  @override
  String get startStreamingSelected => 'تم اختيار هذه المباراة للبث المباشر';

  @override
  String get startStreamingOpponentLive => 'المباراة تُبث مباشرة';

  @override
  String get startStreamingStartButton => 'ابدأ';

  @override
  String get startStreamingStartedSnack => 'بدأ البث.';

  @override
  String get watchStreamConnecting => 'جارٍ الاتصال…';

  @override
  String get watchStreamWaitingBroadcaster => 'في انتظار الباث…';

  @override
  String get watchStreamSpectatorChat => 'دردشة المشاهدين';

  @override
  String get watchStreamChatUnavailable => 'الدردشة غير متاحة';

  @override
  String get watchStreamChatEmpty => 'كن أول من يعلّق!';

  @override
  String get watchStreamChatHint => 'أرسل رسالة…';

  @override
  String get watchStreamLiveBadge => 'مباشر';

  @override
  String bannedLoadStateError(Object error) {
    return 'تعذر تحميل حالة الطلب: $error';
  }

  @override
  String cguWhatsappLabel(Object dialCode) {
    return 'واتساب ($dialCode)';
  }

  @override
  String cguWhatsappHelper(Object dialCode) {
    return 'تتم إضافة رمز الدولة $dialCode تلقائيًا.';
  }

  @override
  String cguConsentRequiredSuffix(Object title) {
    return '$title *';
  }

  @override
  String linkAccountEmailLineNoEmail(Object providerLabel) {
    return 'عنوان البريد الإلكتروني لحساب $providerLabel هذا مستخدم بالفعل من قبل حساب ARENA.';
  }

  @override
  String linkAccountEmailLineWithEmail(Object email) {
    return '$email مستخدم بالفعل من قبل حساب ARENA (كلمة المرور).';
  }

  @override
  String registerStepperTitle(Object step) {
    return 'الخطوة $step / 3';
  }

  @override
  String registerWhatsappLabel(Object dialCode) {
    return 'واتساب ($dialCode)';
  }

  @override
  String registerWhatsappHelper(Object dialCode) {
    return 'تتم إضافة رمز الدولة $dialCode تلقائيًا.';
  }

  @override
  String bracketCaption(Object playerCount) {
    return 'إقصاء مباشر · $playerCount لاعبًا';
  }

  @override
  String referralCardDescription(Object referralQuota) {
    return 'يجب عليك إحالة $referralQuota من الأصدقاء للتسجيل في هذه المسابقة المجانية. شارك رمزك معهم لينشئوا حساب ARENA الخاص بهم.';
  }

  @override
  String referralProgressError(Object error) {
    return 'تعذر التحقق من تقدمك: $error';
  }

  @override
  String referralFriendsRemaining(Object count) {
    return '$count من الأصدقاء المتبقين للإحالة';
  }

  @override
  String referralCodeCopied(Object code) {
    return 'تم نسخ الرمز $code إلى الحافظة';
  }

  @override
  String referralShareMessage(Object code) {
    return 'انضم إليّ على ARENA! بطولات الرياضات الإلكترونية المجانية على الهاتف مع جوائز. استخدم رمز الإحالة الخاص بي عند التسجيل: $code';
  }

  @override
  String liveStreamsOthersCount(Object count) {
    return '+$count أخرى';
  }

  @override
  String pendingPaymentMultipleTitle(Object count) {
    return '$count دفعات قيد الانتظار';
  }

  @override
  String upcomingMatchesError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String upcomingMatchVsOpponent(Object opponentName) {
    return 'ضد $opponentName';
  }

  @override
  String upcomingBadgeInHours(Object hours) {
    return 'خلال $hours س';
  }

  @override
  String upcomingBadgeInDays(Object days) {
    return 'خلال $days ي';
  }

  @override
  String upcomingPhaseRound(Object round) {
    return 'الجولة $round';
  }

  @override
  String matchRoomTitleNumbered(Object number) {
    return 'مباراة #$number';
  }

  @override
  String manualUploadFailure(Object message) {
    return 'فشل: $message';
  }

  @override
  String manualUploadError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String outcomeWinner(Object winner) {
    return 'الفائز: اللاعب $winner…';
  }

  @override
  String outcomeResubmitError(Object error) {
    return 'تعذّرت إعادة الإرسال: $error';
  }

  @override
  String outcomeScoreShootout(Object pen1, Object pen2) {
    return 'ركلات الترجيح $pen1 — $pen2';
  }

  @override
  String matchHeaderSelfSuffix(Object username) {
    return '$username · أنت';
  }

  @override
  String recordingLiveStreamError(Object error) {
    return 'تعذّر بدء البث: $error';
  }

  @override
  String recordingPermBundleNeedsSettings(Object list) {
    return 'اسمح بـ $list في الإعدادات > التطبيقات > ARENA';
  }

  @override
  String recordingPermBundleDenied(Object list) {
    return 'تم رفض إذن $list — اضغط مجددًا على \"أنا في الغرفة\"';
  }

  @override
  String recordingBannerUnavailable(Object error) {
    return 'التسجيل غير متاح — $error\nاضغط هنا لإعادة المحاولة.';
  }

  @override
  String notificationsTimeMinutesAgo(Object minutes) {
    return 'منذ $minutes دقيقة';
  }

  @override
  String notificationsTimeHoursAgo(Object hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String mobileMoneyDialHelp(Object method) {
    return 'اطلب هذا الرمز على $method الخاص بك، وادفع المبلغ بالضبط، ثم عُد هنا واضغط \"لقد دفعت\".';
  }

  @override
  String deleteAccountStepCaption(Object stepNum, Object stepLabel) {
    return 'الخطوة $stepNum/04 · $stepLabel';
  }

  @override
  String deleteAccountCheckErrorNote(Object checkError) {
    return 'ملاحظة: التحقق غير حاسم (الجدول غير متوفر). التفاصيل: $checkError';
  }

  @override
  String deleteAccountTypeToConfirmLabel(Object confirmWord) {
    return 'اكتب \"$confirmWord\" للتأكيد';
  }

  @override
  String editProfileWhatsappCaption(Object dialCode) {
    return 'واتساب ($dialCode)';
  }

  @override
  String editProfileWhatsappHelper(Object dialCode) {
    return 'تتم إضافة رمز الدولة $dialCode تلقائيًا.';
  }

  @override
  String friendsErrorMessage(Object error) {
    return 'خطأ: $error';
  }

  @override
  String friendsRemoveDialogTitle(Object username) {
    return 'إزالة $username؟';
  }

  @override
  String friendsAcceptedSnack(Object username) {
    return '$username الآن صديقك';
  }

  @override
  String friendsUnblockedSnack(Object username) {
    return 'تم إلغاء حظر $username';
  }

  @override
  String friendsSearchErrorMessage(Object error) {
    return 'خطأ: $error';
  }

  @override
  String playerProfileError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String playerProfileStatsError(Object error) {
    return 'الإحصائيات غير متاحة ($error)';
  }

  @override
  String playerProfileMatchRowError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String playerProfileFriendsCountSingular(Object friendsCount) {
    return '$friendsCount صديق';
  }

  @override
  String playerProfileFriendsCountPlural(Object friendsCount) {
    return '$friendsCount أصدقاء';
  }

  @override
  String playerProfileReferralCountSingular(Object count) {
    return '$count مدعوّ';
  }

  @override
  String playerProfileReferralCountPlural(Object count) {
    return '$count مدعوّين';
  }

  @override
  String publicProfileError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String publicProfileRequestSent(Object username) {
    return 'تم إرسال الطلب إلى $username';
  }

  @override
  String publicProfileNowFriend(Object username) {
    return '$username الآن صديقك';
  }

  @override
  String publicProfileRemoveConfirmTitle(Object username) {
    return 'إزالة $username؟';
  }

  @override
  String publicProfileBlockConfirmTitle(Object username) {
    return 'حظر $username؟';
  }

  @override
  String publicProfileWinRateValue(Object pct, Object total) {
    return '$pct% ($total مباريات)';
  }

  @override
  String publicProfileMatchRowError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String settingsMarketingError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String settingsEmailChangeError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String settingsPasswordChangeError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String settingsExportError(Object error) {
    return 'تعذّر التصدير: $error';
  }

  @override
  String settingsExportFileLabel(Object sizeKb) {
    return 'الملف ($sizeKb ك.ب):';
  }

  @override
  String startStreamingErrorSnack(Object error) {
    return 'خطأ: $error';
  }

  @override
  String watchStreamFailed(Object reason) {
    return 'فشل: $reason';
  }

  @override
  String watchStreamChatSendError(Object error) {
    return 'خطأ في الإرسال: $error';
  }

  @override
  String watchStreamViewersWatching(Object viewers) {
    return '$viewers يشاهدون';
  }

  @override
  String get authErrInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get authErrEmailAlreadyRegistered =>
      'يوجد حساب بالفعل بهذا البريد الإلكتروني.';

  @override
  String get authErrWeakPassword => 'كلمة المرور ضعيفة جدًا: 8 أحرف كحد أدنى.';

  @override
  String get authErrEmailNotConfirmed =>
      'أكّد تسجيلك عبر الرابط المُرسل بالبريد الإلكتروني.';

  @override
  String get authErrUserBanned => 'هذا الحساب موقوف. تواصل مع الدعم.';

  @override
  String get authErrWrongApp => 'هذا حساب مسؤول. استخدم تطبيق ARENA Admin.';

  @override
  String get authErrNetwork =>
      'لا يوجد اتصال بالإنترنت. تحقق من شبكتك وحاول مرة أخرى.';

  @override
  String get authErrRateLimited =>
      'محاولات كثيرة جدًا. حاول مرة أخرى بعد بضع دقائق.';

  @override
  String get authErrInvalidInvitation =>
      'رمز الدعوة غير صالح أو منتهٍ أو مستخدم بالفعل.';

  @override
  String get authErrInvalidTotp => 'الرمز المكوّن من 6 أرقام غير صحيح.';

  @override
  String get authErrTotpReplay =>
      'تم استخدام هذا الرمز بالفعل. انتظر الرمز التالي.';

  @override
  String get authErrAdminLocked =>
      'تم قفل الحساب بعد 3 محاولات. حاول مرة أخرى بعد 30 دقيقة.';

  @override
  String get authErrBackendUnavailable =>
      'الخدمة غير متوفرة مؤقتًا. حاول مرة أخرى لاحقًا.';

  @override
  String get authErrUsernameTaken =>
      'اسم المستخدم هذا مستخدم بالفعل. اختر اسمًا آخر.';

  @override
  String get authErrSsoCancelled => 'تم إلغاء تسجيل الدخول.';

  @override
  String get authErrSsoIdToken =>
      'تعذّر تسجيل الدخول. تحقق من شبكتك وحاول مرة أخرى.';

  @override
  String get authErrSsoConfig =>
      'تسجيل الدخول غير متاح حاليًا. تواصل مع الدعم.';

  @override
  String get authErrInvalidResetCode =>
      'رمز غير صحيح. تحقق من بريدك الإلكتروني.';

  @override
  String get authErrExpiredResetCode =>
      'انتهت صلاحية الرمز. اطلب رمزًا جديدًا.';

  @override
  String get authErrUnknown => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get matchStepCodeRoom => 'رمز الغرفة';

  @override
  String get matchStepOpponentJoining => 'الخصم ينضم';

  @override
  String get matchStepInProgress => 'المباراة جارية';

  @override
  String get matchStepResult => 'النتيجة';

  @override
  String get activeCompetitionsEmpty => 'لا توجد منافسة نشطة لهذا الفلتر.';

  @override
  String get myTournamentsEmpty => 'لست مسجّلاً في أي بطولة حتى الآن.';

  @override
  String get myTournamentsBrowseCta => 'تصفّح البطولات';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterFree => 'مجانية';

  @override
  String get filterPaid => 'مدفوعة';

  @override
  String get filterUpcoming => 'قادمة';

  @override
  String get filterOngoing => 'جارية';

  @override
  String get filterCompleted => 'منتهية';

  @override
  String get compFormatSingleElim => 'إقصاء مباشر';

  @override
  String get compFormatGroupsKnockout => 'مجموعات + إقصاء';

  @override
  String get compFormatRoundRobin => 'دوري';

  @override
  String get matchStepWord => 'الخطوة';
}
