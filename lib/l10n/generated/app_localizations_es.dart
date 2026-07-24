// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'ARENA';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonStart => 'Empezar';

  @override
  String get commonSkip => 'Omitir';

  @override
  String get commonLoading => 'Cargando…';

  @override
  String get commonError => 'Ocurrió un error';

  @override
  String get onboardingSlide1Title => 'TORNEOS E-SPORT PANAFRICANOS';

  @override
  String get onboardingSlide1Body =>
      'Bienvenido a ARENA, la plataforma #1 de torneos de eFootball, Jeu de Dames y Mobile FC en África.';

  @override
  String get onboardingSlide2Title => 'BRACKETS, DUELOS REALES';

  @override
  String get onboardingSlide2Body =>
      'Eliminación directa o fase de grupos: sube en el árbol del torneo y vence a todos tus rivales para llevarte la recompensa.';

  @override
  String get onboardingSlide3Title => 'CÓDIGO DE SALA COMPARTIDO';

  @override
  String get onboardingSlide3Body =>
      'Compartes tu código de sala en el juego, se enfrentan, y luego validan el marcador juntos en ARENA.';

  @override
  String get onboardingSlide4Title => 'RECOMPENSAS PAGADAS AL INSTANTE';

  @override
  String get onboardingSlide4Body =>
      'Obtén recompensas incluso en competiciones con inscripción gratuita y diviértete.';

  @override
  String get onboardingNext => 'SIGUIENTE';

  @override
  String get onboardingStart => 'EMPEZAR';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingExitTitle => '¿Salir de la introducción?';

  @override
  String get onboardingExitBody =>
      'Puedes volver a verla más tarde desde Perfil > Ver introducción de nuevo.';

  @override
  String get authEmailLabel => 'CORREO ELECTRÓNICO';

  @override
  String get authEmailHint => 'jugador@arena.app';

  @override
  String get authPasswordLabel => 'CONTRASEÑA';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authOr => 'O';

  @override
  String get authContinueGoogle => 'Continuar con Google';

  @override
  String get authSignUp => 'Registrarse';

  @override
  String get loginTitle => 'INICIO DE SESIÓN';

  @override
  String get loginSubtitle => 'Continúa tu recorrido en ARENA.';

  @override
  String get loginSubmit => 'INICIAR SESIÓN';

  @override
  String get loginNoAccount => '¿Aún no tienes cuenta? ';

  @override
  String get forgotPasswordTitle => 'CONTRASEÑA OLVIDADA';

  @override
  String get forgotPasswordSubtitle =>
      'Ingresa el correo vinculado a tu cuenta y te enviaremos un código de 6 dígitos para restablecer tu contraseña.';

  @override
  String get forgotPasswordSubmit => 'ENVIAR CÓDIGO';

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
      'Detalla tu solicitud (mínimo 10 caracteres).';

  @override
  String get bannedSendError =>
      'Error al enviar. Verifica tu conexión e inténtalo de nuevo.';

  @override
  String get bannedAppBarTitle => 'Cuenta suspendida';

  @override
  String get bannedSignOut => 'CERRAR SESIÓN';

  @override
  String get bannedArenaRequestTitle => '📨 ARENA SOLICITUD';

  @override
  String get bannedArenaRequestIntro =>
      'Explica por qué crees que tu suspensión debería reconsiderarse. El equipo de Arena Solicitud analiza cada petición en un plazo de 48 horas.';

  @override
  String get bannedMessageHint => 'Describe tu caso (mínimo 10 caracteres)…';

  @override
  String get bannedSendingLabel => 'ENVIANDO…';

  @override
  String get bannedSendRequestLabel => '✉️ ENVIAR MI SOLICITUD';

  @override
  String get bannedPermanentTitle => 'Cuenta baneada de forma permanente';

  @override
  String get bannedPermanentBody =>
      'Se te encontró responsable de una disputa en 3 ocasiones. Conforme a las reglas de ARENA, tu cuenta ha sido desactivada.';

  @override
  String get bannedOverdueTitle => 'Análisis retrasado (> 48h)';

  @override
  String get bannedPendingTitle => 'Solicitud en análisis';

  @override
  String get bannedOverdueBody =>
      'Tu solicitud lleva abierta más de 48 horas. El equipo de Arena Solicitud ya fue notificado; gracias por tu paciencia.';

  @override
  String get bannedPendingBody =>
      'El equipo de Arena Solicitud tiene 48 horas para analizar tu solicitud. Se te notificará en cuanto se tome una decisión.';

  @override
  String get bannedYourMessageLabel => 'Tu mensaje';

  @override
  String get bannedRejectedTitle => '❌ Solicitud anterior rechazada';

  @override
  String get bannedReasonLabel => 'Motivo';

  @override
  String get bannedRejectedBody =>
      'Puedes enviar una nueva solicitud con información adicional a continuación.';

  @override
  String get bannedApprovedTitle => '✅ Reintegración aprobada';

  @override
  String get bannedApprovedBody =>
      '¡Bienvenido de nuevo a ARENA! Vuelve a iniciar sesión para acceder a tu cuenta.';

  @override
  String get cguCompleteProfileTitle => 'COMPLETA TU\nPERFIL';

  @override
  String get cguCompleteProfileSubtitle =>
      'Falta un poco de información antes de que puedas jugar.';

  @override
  String get cguWhatsappHint => 'Ej. 07 07 07 07 07';

  @override
  String get cguWhatsappInvalid => 'Número de WhatsApp inválido.';

  @override
  String get cguReadTermsLink => 'Leer los Términos y Condiciones de Uso';

  @override
  String get cguReadPrivacyLink => 'Leer la política de privacidad';

  @override
  String get cguAcceptTermsConsent =>
      'Acepto los Términos y la política de privacidad';

  @override
  String get cguMarketingConsent =>
      'Acepto recibir información sobre nuevos torneos (opcional)';

  @override
  String get cguContinueButton => 'CONTINUAR';

  @override
  String get cguRefuseSignOut => 'Rechazar y cerrar sesión';

  @override
  String get cguDocPlaceholderBody =>
      'La versión completa se mostrará aquí (FASE 9 — AboutPage + WebView hacia los documentos alojados).';

  @override
  String get cguDialogOk => 'OK';

  @override
  String get cguCountryLabel => 'PAÍS';

  @override
  String get linkAccountDefaultProvider => 'Google';

  @override
  String get linkAccountAppBarTitle => 'Vincular cuentas';

  @override
  String get linkAccountExistsTitle => 'La cuenta ya existe';

  @override
  String get linkAccountExistingMethodsLabel => 'MÉTODOS EXISTENTES';

  @override
  String get linkAccountEmailPasswordMethod => 'Correo + contraseña';

  @override
  String get linkAccountChooseContinue =>
      'Elige cómo continuar a continuación.';

  @override
  String get linkAccountLinkBothButton => '🔗 VINCULAR AMBAS CUENTAS';

  @override
  String get linkAccountPhaseSnack =>
      'Disponible en la FASE 2.3 (inicio de sesión social con Google/Apple).';

  @override
  String get linkAccountLoginPasswordButton => 'INICIAR SESIÓN CON CONTRASEÑA';

  @override
  String get linkAccountCancelButton => 'Cancelar';

  @override
  String get registerEmailRequired => 'Correo requerido.';

  @override
  String get registerEmailInvalid => 'Formato de correo inválido.';

  @override
  String get registerPasswordTooShort => 'Mínimo 8 caracteres.';

  @override
  String get registerPasswordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get registerAccountStepTitle => 'CREA\nTU CUENTA';

  @override
  String get registerAccountStepSubtitle =>
      'Correo + contraseña (mínimo 8 caracteres).';

  @override
  String get registerGoogleSignUp => 'Registrarte con Google';

  @override
  String get registerEmailLabel => 'CORREO';

  @override
  String get registerPasswordLabel => 'CONTRASEÑA';

  @override
  String get registerPasswordConfirmLabel => 'CONFIRMAR CONTRASEÑA';

  @override
  String get registerAccountContinueButton => 'CONTINUAR';

  @override
  String get registerProfileStepTitle => 'TU\nPERFIL';

  @override
  String get registerProfileStepSubtitle =>
      'Apodo + país + aceptación de los términos.';

  @override
  String get registerUsernameLabel => 'APODO';

  @override
  String get registerUsernameHint => '3 a 20 caracteres';

  @override
  String get registerWhatsappHint => 'Ej. 07 07 07 07 07';

  @override
  String get registerWhatsappInvalid => 'Número de WhatsApp inválido.';

  @override
  String get registerAvatarColorLabel => 'COLOR DE AVATAR';

  @override
  String get registerReferralCodeLabel => 'CÓDIGO DE REFERIDO (OPCIONAL)';

  @override
  String get registerReferralCodeHint => 'Ej. ARN-3F9A';

  @override
  String get registerReferralCodeHelper =>
      'El código de un amigo de ARENA. Te permite aparecer en sus referidos — déjalo vacío si no tienes uno.';

  @override
  String get registerCguConsent => 'Acepto los Términos y Condiciones de Uso';

  @override
  String get registerPrivacyConsent => 'Acepto la Política de Privacidad';

  @override
  String get registerMarketingConsent =>
      'Acepto recibir comunicaciones de marketing (opcional)';

  @override
  String get registerCreateAccountButton => 'CREAR MI CUENTA';

  @override
  String get registerCountryLabel => 'PAÍS';

  @override
  String get registerCountryHint => 'Elige tu país';

  @override
  String get registerSuccessTitle => 'CUENTA\nCREADA';

  @override
  String get registerSuccessSubtitle =>
      'Bienvenido a ARENA. Ya estás listo para unirte a los torneos.';

  @override
  String get registerSuccessContinueButton => 'CONTINUAR';

  @override
  String get registerOrDivider => 'O';

  @override
  String get resetCodeNewCodeSent => 'Nuevo código enviado.';

  @override
  String get resetCodeTitle => 'VERIFICACIÓN';

  @override
  String get resetCodeSubtitle => 'Ingresa el código de 6 dígitos enviado a';

  @override
  String get resetCodeFieldLabel => 'CÓDIGO';

  @override
  String get resetCodeVerifyButton => 'VERIFICAR';

  @override
  String get resetCodeResending => 'Enviando…';

  @override
  String get resetCodeResendButton => 'Reenviar código';

  @override
  String get resetPwPasswordRequired => 'Contraseña requerida';

  @override
  String get resetPwMinChars => 'Mínimo 8 caracteres';

  @override
  String get resetPwPasswordsDontMatch => 'Las contraseñas no coinciden';

  @override
  String get resetPwTitle => 'NUEVA CONTRASEÑA';

  @override
  String get resetPwSubtitle =>
      'Elige una contraseña segura. Se usará para tu próximo inicio de sesión.';

  @override
  String get resetPwNewPasswordLabel => 'NUEVA CONTRASEÑA';

  @override
  String get resetPwNewPasswordHint => 'Al menos 8 caracteres';

  @override
  String get resetPwConfirmLabel => 'CONFIRMAR';

  @override
  String get resetPwConfirmHint => 'Vuelve a escribir tu contraseña';

  @override
  String get resetPwUpdateButton => 'ACTUALIZAR';

  @override
  String get resetPwSuccessTitle => 'CONTRASEÑA ACTUALIZADA';

  @override
  String get resetPwSuccessSubtitle =>
      'Ahora puedes iniciar sesión con tu nueva contraseña.';

  @override
  String get resetPwLoginButton => 'INICIAR SESIÓN';

  @override
  String get splashTagline => 'e-sport panafricano';

  @override
  String get splashLoginButton => 'INICIAR SESIÓN';

  @override
  String get splashCreateAccountButton => 'CREAR UNA CUENTA';

  @override
  String get splashVersionLabel => 'v1.0 — ARENA Camerún';

  @override
  String get splashStatPlayers => 'jugadores';

  @override
  String get splashStatTournaments => 'torneos';

  @override
  String get splashStatXaf => 'XAF';

  @override
  String get bracketEmptyTitle => 'Bracket aún no generado';

  @override
  String get bracketEmptyDescription =>
      'El bracket se mostrará aquí en cuanto el administrador cierre las inscripciones y lance el sorteo.';

  @override
  String get bracketZoomHint =>
      '↔ pellizca para hacer zoom · desliza para navegar';

  @override
  String get groupStandingsEmptyTitle => 'Aún no hay clasificación';

  @override
  String get groupStandingsEmptyDescription =>
      'La clasificación se mostrará en cuanto se jueguen los primeros encuentros.';

  @override
  String get groupStandingsColPlayer => 'JUGADOR';

  @override
  String get groupStandingsColPlayed => 'J';

  @override
  String get groupStandingsColWins => 'G';

  @override
  String get groupStandingsColDraws => 'E';

  @override
  String get groupStandingsColLosses => 'P';

  @override
  String get groupStandingsColGoalsFor => 'GF';

  @override
  String get groupStandingsColGoalsAgainst => 'GC';

  @override
  String get groupStandingsColDiff => 'Dif';

  @override
  String get groupStandingsColPoints => 'Pts';

  @override
  String get groupStandingsPlayerFallback => 'Jugador ';

  @override
  String get callPlaceCallFailed => 'No se pudo iniciar la llamada.';

  @override
  String get callNoAnswer => 'Sin respuesta.';

  @override
  String get callDeclined => 'Llamada rechazada.';

  @override
  String get callEnded => 'Llamada finalizada.';

  @override
  String get callStatusConnecting => 'Conectando…';

  @override
  String get callStatusRinging => 'Timbrando…';

  @override
  String get callStatusConnected => 'En llamada';

  @override
  String get callStatusEnded => 'Llamada finalizada';

  @override
  String get callStatusFailed => 'Error en la llamada';

  @override
  String get callControlUnmute => 'Reactivar';

  @override
  String get callControlMute => 'Silenciar';

  @override
  String get callControlSpeaker => 'Altavoz';

  @override
  String get callControlEarpiece => 'Auricular';

  @override
  String get callControlClose => 'Cerrar';

  @override
  String get chatOfflineQueued =>
      'Sin conexión — mensaje enviado al reconectar.';

  @override
  String get chatSendFailed => 'No se pudo enviar: ';

  @override
  String get chatPickerUnavailable => 'Selector no disponible: ';

  @override
  String get chatUploadFailed => 'Error al subir: ';

  @override
  String get chatAttachGallery => 'Elegir de la galería';

  @override
  String get chatAttachCamera => 'Tomar una foto';

  @override
  String get chatDeleteDialogTitle => '¿Eliminar este mensaje?';

  @override
  String get chatDeleteDialogContent =>
      'Este mensaje se marcará como eliminado. El otro jugador verá \"Mensaje eliminado\" en su lugar.';

  @override
  String get chatDeleteDialogCancel => 'Cancelar';

  @override
  String get chatDeleteDialogConfirm => 'ELIMINAR';

  @override
  String get chatGenericFailure => 'Error: ';

  @override
  String get chatEmptyTitle => 'Todavía no hay mensajes';

  @override
  String get chatEmptyDescription => 'Sé el primero en escribir aquí.';

  @override
  String get chatAppBarUsernameFallback => 'Jugador';

  @override
  String get chatAppBarTyping => 'escribiendo…';

  @override
  String get chatAppBarOnline => 'en línea';

  @override
  String get chatAppBarOffline => 'sin conexión';

  @override
  String get chatMessageDeleted => 'Mensaje eliminado';

  @override
  String get chatMediaUnsupported => 'Contenido: ';

  @override
  String get chatRoomCodeCopied => 'Código copiado';

  @override
  String get chatRoomCodeTapToCopy => 'toca para copiar';

  @override
  String get chatInputTooltipKeyboard => 'Teclado';

  @override
  String get chatInputTooltipEmoji => 'Emoji';

  @override
  String get chatInputTooltipAttach => 'Adjuntar una imagen';

  @override
  String get chatInputHint => 'Mensaje…';

  @override
  String get friendChatOfflineQueued =>
      'Sin conexión — mensaje enviado al reconectar.';

  @override
  String get friendChatSendFailed => 'No se pudo: ';

  @override
  String get friendChatPickerFailed => 'Selector: ';

  @override
  String get friendChatGenericFailure => 'Error: ';

  @override
  String get friendChatAttachGallery => 'Elegir de la galería';

  @override
  String get friendChatAttachCamera => 'Tomar una foto';

  @override
  String get friendChatDeleteDialogTitle => '¿Eliminar este mensaje?';

  @override
  String get friendChatDeleteDialogContent =>
      'Tu amigo verá «Mensaje eliminado» en su lugar.';

  @override
  String get friendChatDeleteDialogCancel => 'Cancelar';

  @override
  String get friendChatDeleteDialogConfirm => 'ELIMINAR';

  @override
  String get friendChatEmptyTitle => 'Inicia la conversación';

  @override
  String get friendChatEmptyDescription =>
      'Envía un primer mensaje a tu amigo.';

  @override
  String get friendChatUsernameFallback => 'Amigo';

  @override
  String get friendChatSubtitleFriend => 'Amigo';

  @override
  String get inboxAppBarTitle => 'MENSAJES';

  @override
  String get inboxComposeTooltip => 'Buscar un jugador';

  @override
  String get inboxTabDirect => 'DIRECTO';

  @override
  String get inboxTabTournaments => 'TORNEOS';

  @override
  String get inboxNoConversationsTitle => 'Ninguna conversación';

  @override
  String get inboxNoConversationsDesc =>
      'Vuelve a conectarte para ver tus conversaciones.';

  @override
  String get inboxSectionFriends => 'AMIGOS';

  @override
  String get inboxSectionMatches => 'PARTIDOS';

  @override
  String get inboxEmptyHint =>
      'Todavía no hay conversaciones.\nAbre una conversación desde la sala de partido\no desde la pestaña Amigos.';

  @override
  String get inboxDeleteDialogTitle => '¿Eliminar esta conversación?';

  @override
  String get inboxDeleteDialogContent =>
      'La conversación se quitará de tu bandeja de entrada. Puedes volver a encontrarla reabriendo el chat más tarde.';

  @override
  String get inboxDeleteCancel => 'Cancelar';

  @override
  String get inboxDeleteConfirm => 'ELIMINAR';

  @override
  String get inboxDeleteFailure => 'Error: ';

  @override
  String get inboxOpponentWaiting => 'En espera';

  @override
  String get inboxMatchPending => 'Esperando a un rival';

  @override
  String get inboxMatchScheduled => 'Partido programado';

  @override
  String get inboxMatchReady => 'Código de sala compartido';

  @override
  String get inboxMatchInProgress => 'En curso — toca para chatear';

  @override
  String get inboxMatchScorePending => 'Esperando el resultado';

  @override
  String get inboxMatchAwaitingValidation => 'Validación del resultado';

  @override
  String get inboxMatchDisputed => 'Resultado en disputa — admin en proceso';

  @override
  String get inboxMatchCompleted => 'Partido finalizado';

  @override
  String get inboxMatchCancelled => 'Partido cancelado';

  @override
  String get inboxMatchForfeited => 'Forfait';

  @override
  String get inboxTimeSoon => 'Pronto';

  @override
  String get inboxCompRegistrationOpen => 'Inscripciones abiertas';

  @override
  String get inboxCompRegistrationClosed => 'Inscripciones cerradas';

  @override
  String get inboxCompOngoing => 'En curso';

  @override
  String get inboxCompCompleted => 'Finalizada';

  @override
  String get inboxCompCancelled => 'Cancelada';

  @override
  String get inboxCompDraft => 'Borrador';

  @override
  String get inboxNoActiveCompTitle => 'Ninguna competencia activa';

  @override
  String get inboxNoActiveCompDesc =>
      'Los hilos de conversación de tus competencias aparecerán aquí en cuanto te unas a un torneo.';

  @override
  String get inboxWaitingTitle => 'En espera';

  @override
  String get inboxWaitingDesc =>
      'Estás inscrito, pero las competencias aún no se han cargado.';

  @override
  String get inboxChatWithFriend => 'Chatear con tu amigo';

  @override
  String get inboxFriendDefaultName => 'Amigo';

  @override
  String get inboxArenaTeam => 'Equipo ARENA';

  @override
  String get inboxArenaOfficialBadge => 'OFICIAL';

  @override
  String get inboxArenaPreviewDefault =>
      'Soporte, anuncios e información oficial';

  @override
  String get inboxArenaPreviewImage => '📷 Imagen';

  @override
  String get inboxTimeJustNow => 'justo ahora';

  @override
  String get inboxErrorPrefix => 'Error: ';

  @override
  String get compDetailAppBarTitle => 'COMPETENCIA';

  @override
  String get compDetailNotFoundTitle => 'Competencia no encontrada';

  @override
  String get compDetailNotFoundDesc =>
      'Puede que un administrador la haya eliminado.';

  @override
  String get compDetailStatusDraft => 'BORRADOR';

  @override
  String get compDetailStatusOpen => 'ABIERTO';

  @override
  String get compDetailStatusFull => 'INSCRIPCIONES CERRADAS';

  @override
  String get compDetailStatusOngoing => 'EN CURSO';

  @override
  String get compDetailStatusCompleted => 'FINALIZADO';

  @override
  String get compDetailStatusCancelled => 'CANCELADO';

  @override
  String get compDetailCtaRegisterFree => 'INSCRIBIRME GRATIS';

  @override
  String get compDetailCtaRegisterPaidPrefix => 'INSCRIBIRME · ';

  @override
  String get compDetailRegistrationsClosed => 'INSCRIPCIONES CERRADAS';

  @override
  String get compDetailGatedLockNotice =>
      '🔒 El bracket, los partidos en vivo y el chat 1 a 1 están reservados a los jugadores inscritos.';

  @override
  String get compDetailPrizeFree => 'GRATIS';

  @override
  String get compDetailPrizeFreeLabel => 'INSCRIPCIÓN LIBRE';

  @override
  String get compDetailPrizeToWinLabel => 'A GANAR';

  @override
  String get compDetailTabInfos => 'INFO';

  @override
  String get compDetailTabParticipants => 'PARTICIP.';

  @override
  String get compDetailTabNextMatch => 'PRÓXIMO PARTIDO';

  @override
  String get compDetailTabCalendar => 'CALENDARIO';

  @override
  String get compDetailTabRanking => 'CLASIFICACIÓN';

  @override
  String get compScheduleEmptyTitle => 'Ningún partido programado';

  @override
  String get compScheduleEmptyDescription =>
      'El calendario aparecerá en cuanto el organizador genere el cuadro.';

  @override
  String get compScheduleUnscheduled => 'Por programar';

  @override
  String get compDetailParticipantsTitle => 'Lista de participantes';

  @override
  String get compDetailParticipantsDesc =>
      'La lista de inscritos con avatares y estadísticas aparecerá aquí. Fuente: tabla `registrations`.';

  @override
  String get compDetailInfoPrizeLabel => 'Recompensa';

  @override
  String get compDetailInfoPrizeNone => 'Ninguna';

  @override
  String get compDetailInfoFeeLabel => 'Costo de inscripción';

  @override
  String get compDetailInfoFeeFree => 'Gratis';

  @override
  String get compDetailInfoFormatLabel => 'Formato';

  @override
  String get compDetailInfoStartLabel => 'Inicio';

  @override
  String get compDetailInfoCapacityLabel => 'Capacidad';

  @override
  String get compDetailInfoCapacitySuffix => ' jugadores';

  @override
  String get compDetailDescriptionHeader => '📝 DESCRIPCIÓN';

  @override
  String get compDetailRankingNoParticipantTitle => 'Ningún participante';

  @override
  String get compDetailRankingNoParticipantDesc =>
      'Todavía nadie se ha inscrito en esta competencia.';

  @override
  String get compDetailRankingNotPublishedTitle =>
      'Clasificación aún no publicada';

  @override
  String get compDetailRankingNotPublishedDesc =>
      'Los organizadores publicarán la clasificación final una vez que termine la competencia.';

  @override
  String get compDetailRankingUnranked => 'Sin clasificar';

  @override
  String get compDetailRankingPlaceSuffix => '.º lugar';

  @override
  String get compDetailFormatSingleElim => 'Eliminación directa';

  @override
  String get compDetailFormatGroupsKnockout => 'Grupos + eliminación';

  @override
  String get compDetailFormatRoundRobin => 'Round robin';

  @override
  String get compDetailTabBracket => 'BRACKET';

  @override
  String get compDetailTabGroups => 'GRUPOS';

  @override
  String get compListReset => 'Restablecer';

  @override
  String get compListEmptyTitleAll => 'Ninguna competencia';

  @override
  String get compListEmptyTitleGamePrefix => 'Ninguna competencia en ';

  @override
  String get compListEmptyDesc =>
      'Cada semana se publican nuevos torneos. ¡Vuelve pronto!';

  @override
  String get compListFilterStatus => 'Estado';

  @override
  String get compListFilterPricing => 'Tarifa';

  @override
  String get compListFormatSingleElim => 'Eliminación directa';

  @override
  String get compListFormatGroupsKnockout => 'Grupos + eliminación';

  @override
  String get compListFormatRoundRobin => 'Round robin';

  @override
  String get regConfirmAppBarTitle => 'PAGO';

  @override
  String get regConfirmPrizeDistribution => 'REPARTO DE PREMIOS';

  @override
  String get regConfirmDownloadGame => 'DESCARGAR EL JUEGO';

  @override
  String get regConfirmCtaReferralsInsufficient => '👥 REFERIDOS INSUFICIENTES';

  @override
  String get regConfirmCtaRegisterFree => 'INSCRIBIRME GRATIS';

  @override
  String get regConfirmCtaProceedPaymentPrefix => 'PROCEDER AL PAGO · ';

  @override
  String get regConfirmCtaXafSuffix => ' XAF';

  @override
  String get regConfirmCancel => 'Cancelar';

  @override
  String get regConfirmNoSession =>
      'No hay sesión activa — no se puede inscribir.';

  @override
  String get regConfirmOfflineQueued =>
      'Sin conexión — inscripción guardada, se confirmará al reconectarte.';

  @override
  String get regConfirmConfirmedPrefix => 'Inscripción confirmada a las ';

  @override
  String get regConfirmErrorPrefix => 'Error: ';

  @override
  String get regConfirmDisplayTitleStart => 'Confirma ';

  @override
  String get regConfirmDisplayTitleAccent => 'tu inscripción.';

  @override
  String get regConfirmPillFree => 'GRATIS';

  @override
  String get regConfirmPillPaid => 'DE PAGO';

  @override
  String get regConfirmBreakdownFee => 'Costo de inscripción';

  @override
  String get regConfirmBreakdownService => 'Costo de servicio';

  @override
  String get regConfirmBreakdownServiceIncluded => 'Incluido';

  @override
  String get regConfirmBreakdownTotal => 'Total a pagar';

  @override
  String get regConfirmRanksRewardedSingle => '1 puesto premiado';

  @override
  String get regConfirmRanksRewardedPluralSuffix => ' puestos premiados';

  @override
  String get regConfirmAckLabel =>
      'Acepto las reglas del torneo y el reglamento interno.';

  @override
  String get regConfirmStoreLinkError => 'No se pudo abrir el enlace.';

  @override
  String get regConfirmPlayStore => 'Play Store';

  @override
  String get regConfirmAppStore => 'App Store';

  @override
  String get referralCardTitle => 'Referido requerido';

  @override
  String get referralQuotaReached =>
      '✓ Cuota alcanzada — ¡ya puedes inscribirte!';

  @override
  String get referralShareSubject => 'Únete a mí en ARENA';

  @override
  String get referralYourCodeLabel => 'TU CÓDIGO';

  @override
  String get referralCopyButton => 'Copiar';

  @override
  String get referralShareButton => 'Compartir';

  @override
  String get homeSectionNextMatch => '⚡ PRÓXIMO PARTIDO';

  @override
  String get homeSectionLive => 'EN VIVO';

  @override
  String get homeSectionActiveTournaments => '★ MIS TORNEOS';

  @override
  String get homeSectionYourStats => '📊 TUS ESTADÍSTICAS';

  @override
  String get homeViewAllLink => 'Ver todo';

  @override
  String get mainLayoutExitConfirm => 'Toca de nuevo para salir de ARENA';

  @override
  String get mainLayoutTitleHome => 'INICIO';

  @override
  String get mainLayoutTitleCompetitions => 'COMPETICIONES';

  @override
  String get mainLayoutTitleMessages => 'MENSAJES';

  @override
  String get mainLayoutTitleProfile => 'PERFIL';

  @override
  String get mainLayoutNavHome => 'Inicio';

  @override
  String get mainLayoutNavCompetitions => 'Competiciones';

  @override
  String get mainLayoutNavChat => 'Chat';

  @override
  String get mainLayoutNavProfile => 'Perfil';

  @override
  String get homeHeaderDefaultUsername => 'Jugador';

  @override
  String get homeHeaderTierBronze => '🥉 BRONCE';

  @override
  String get homeHeaderSearchTooltip => 'Buscar un jugador';

  @override
  String get liveStreamsErrorPrefix => 'Error: ';

  @override
  String get liveStreamsBadgeLive => 'EN VIVO';

  @override
  String get liveStreamsTapToWatch => 'Toca para ver en vivo';

  @override
  String get liveStreamsEmptyState => 'No hay ningún live en curso';

  @override
  String get pendingPaymentCompetitionFallback => 'Competición';

  @override
  String get pendingPaymentSingleTitle => 'Pago pendiente de validación';

  @override
  String get pendingPaymentTapToCheck => 'Toca para verificar el estado';

  @override
  String get promoBannerLinkOpenError => 'No se pudo abrir el enlace.';

  @override
  String get tutorialWatchCta => 'Ver el tutorial';

  @override
  String get statGridMatchesLabel => 'Partidos';

  @override
  String get statGridWdlLabel => 'V/D/E';

  @override
  String get statGridWinRateLabel => 'Win rate';

  @override
  String get upcomingMatchesEmpty => 'Ningún partido programado';

  @override
  String get upcomingMatchOpponentWaiting => 'Esperando';

  @override
  String get upcomingMatchLive => 'EN VIVO';

  @override
  String get upcomingBadgeInProgress => 'EN CURSO';

  @override
  String get upcomingBadgeToSchedule => 'POR PROGRAMAR';

  @override
  String get upcomingBadgeReady => 'LISTO';

  @override
  String get upcomingBadgeTomorrow => 'MAÑANA';

  @override
  String get upcomingPhaseMatch => 'Partido';

  @override
  String get upcomingPhaseFinal => 'Final';

  @override
  String get upcomingPhaseSemiFinal => 'Semifinal';

  @override
  String get upcomingPhaseQuarterFinal => 'Cuartos de final';

  @override
  String get upcomingPhaseRoundOf16 => 'Octavos de final';

  @override
  String get upcomingPhaseRoundOf32 => 'Dieciseisavos de final';

  @override
  String get matchRoomTitleDefault => 'PARTIDO';

  @override
  String get matchRoomChatTooltip => 'Chatea con tu adversario';

  @override
  String get matchRoomNotFoundTitle => 'Partido no encontrado';

  @override
  String get matchRoomNotFoundDescription =>
      'Puede que un admin haya cancelado el partido.';

  @override
  String get matchLockedTitle => 'Sala bloqueada';

  @override
  String get matchLockedBody =>
      'El acceso a este partido se abre 5 minutos antes del inicio.';

  @override
  String matchLockedScheduled(String scheduled) {
    return 'Inicio: $scheduled';
  }

  @override
  String get matchLockedNoScheduleTitle => 'Horario por definir';

  @override
  String get matchLockedNoScheduleBody =>
      'Este partido aún no tiene un horario programado. Te notificaremos en cuanto se programe.';

  @override
  String get matchRulesSectionTitle => 'Reglas del juego';

  @override
  String get matchRulesVideoTitle => 'Para ver antes de jugar';

  @override
  String get roleIntroHomeTitle => 'ERES EL JUGADOR LOCAL';

  @override
  String get roleIntroAwayTitle => 'ERES EL JUGADOR VISITANTE';

  @override
  String roleIntroHomeBody(String game) {
    return 'Como jugador LOCAL, debes recibir al jugador VISITANTE: te toca a ti crear el código de la sala.\n\nPaso 1: inicia $game hasta el menú principal y selecciona tu equipo.\nPaso 2: vuelve a tu partido en Arena e ingresa el nombre de tu equipo.\nPaso 3: inicia la grabación del partido desde Arena seleccionando $game.\nNOTA: LA GRABACIÓN DEL PARTIDO ES OBLIGATORIA.\nPaso 4: una vez iniciada la grabación, crea el código de la sala y envíaselo al jugador VISITANTE mediante el botón flotante rojo o la notificación de Arena, luego espera a que se una a la sala sin salir de $game.\nPaso 5: jueguen el partido. Al finalizar el encuentro, ingresa el marcador con el botón rojo o la notificación de Arena, sin salir de $game.\n\n⚠️ EL INCUMPLIMIENTO DE ESTOS PASOS PUEDE PROVOCAR UNA DERROTA POR FORFAIT Y LA ATRIBUCIÓN DE LA VICTORIA POR ABANDONO AL JUGADOR VISITANTE.';
  }

  @override
  String roleIntroAwayBody(String game) {
    return 'Como jugador VISITANTE, serás recibido por el jugador LOCAL: él te enviará un código de sala.\n\nPaso 1: inicia $game hasta el menú principal y selecciona tu equipo.\nPaso 2: vuelve a tu partido en Arena, copia el código de la sala e ingresa el nombre de tu equipo.\nPaso 3: inicia la grabación del partido desde Arena seleccionando $game.\nNOTA: LA GRABACIÓN DEL PARTIDO ES OBLIGATORIA.\nPaso 4: una vez iniciada la grabación, únete al jugador LOCAL en la sala con el código que te envió (puedes encontrar este código en cualquier momento en el botón flotante rojo).\nPaso 5: jueguen el partido. Al finalizar el encuentro, ingresa el marcador con el botón rojo o la notificación de Arena, sin salir de $game.\n\n⚠️ EL INCUMPLIMIENTO DE ESTOS PASOS PUEDE PROVOCAR UNA DERROTA POR FORFAIT Y LA ATRIBUCIÓN DE LA VICTORIA POR ABANDONO AL JUGADOR LOCAL.';
  }

  @override
  String roleIntroConfirmLaunched(String game) {
    return 'Confirmo que ya inicié $game y llegué al menú principal.';
  }

  @override
  String get roleIntroGotIt => 'Entendido';

  @override
  String get manualUploadButtonLabel => 'Enviar un video de prueba';

  @override
  String get manualUploadSuccess => 'Video enviado. ¡Gracias!';

  @override
  String get outcomeFinalScore => 'MARCADOR FINAL';

  @override
  String get outcomeDraw => 'Empate.';

  @override
  String get outcomeEditMyScore => 'MODIFICAR MI MARCADOR';

  @override
  String get outcomeDisputeInProgress => 'LITIGIO EN CURSO';

  @override
  String get outcomeDisputeExplanation =>
      'Sus marcadores no coinciden. Si te equivocaste, corrígelo; si no, espera a que tu adversario corrija el suyo. Sin acuerdo, un admin decidirá a partir de las pruebas.';

  @override
  String get outcomeScoreCardYou => 'TÚ';

  @override
  String get outcomeScoreCardPlayer1 => 'JUGADOR 1';

  @override
  String get outcomeScoreCardPlayer2 => 'JUGADOR 2';

  @override
  String get matchHeaderPlayer1 => 'Jugador 1';

  @override
  String get matchHeaderPlayer2 => 'Jugador 2';

  @override
  String get matchHeaderBadgeHome => 'LOCAL';

  @override
  String get matchHeaderBadgeAway => 'VISITANTE';

  @override
  String get recordingActionResume => 'Continuar';

  @override
  String get recordingActionPause => 'Pausa (máx. 2 min)';

  @override
  String get recordingActionSaveStop => 'Guardar y detener';

  @override
  String get recordingActionForfeit => 'Detener (forfait)';

  @override
  String get recordingNoRecordingInProgress => 'Ninguna grabación en curso.';

  @override
  String get recordingStateRecording => 'Grabación en curso';

  @override
  String get recordingStatePaused => 'En pausa — reanuda antes de 2 min';

  @override
  String get recordingStateForfeited => 'Forfait declarado';

  @override
  String get recordingStateStopped => 'Grabación detenida';

  @override
  String get recordingStateIdle => 'Ninguna grabación';

  @override
  String get recordingLiveStreamStarted => 'Transmisión en vivo iniciada.';

  @override
  String get recordingReplaySavedDownloads =>
      'Repetición guardada en Descargas › ARENA';

  @override
  String get recordingReplayInCache =>
      'Repetición disponible en la caché de la app';

  @override
  String get recordingPermMissingMic => 'micrófono';

  @override
  String get recordingPermMissingNotifications => 'notificaciones';

  @override
  String get recordingPermOverlayNeedsSettings =>
      'Activa \"Mostrar sobre otras apps\" para ARENA en Ajustes > Apps > Acceso especial';

  @override
  String get recordingPermOverlayDenied =>
      'Overlay rechazado — vuelve a tocar ESTOY EN LA SALA después de activarlo';

  @override
  String get recordingBannerRecording =>
      'Grabación anticheat en curso\nToca para ver las acciones';

  @override
  String get recordingBannerPaused =>
      'Partido en pausa — toca para reanudar o detener';

  @override
  String get recordingBannerForfeitPauseExpired => 'Abandono: pausa expirada';

  @override
  String get recordingBannerForfeitDeclared => 'Abandono declarado';

  @override
  String get stepBodyMatchInProgressTitle => 'Partido en curso';

  @override
  String get stepBodyMatchInProgressDesc =>
      'Los jugadores están jugando o validando el marcador.';

  @override
  String get stepBodyMatchCancelledTitle => 'PARTIDO CANCELADO';

  @override
  String get stepBodyMatchCancelledDesc => 'El admin canceló este partido.';

  @override
  String get stepBodyForfeitTitle => 'ABANDONO';

  @override
  String get stepBodyForfeitDesc => 'Uno de los jugadores no inició a tiempo.';

  @override
  String get stepBodyAwaitRoomCodeTitle => 'Esperando el código de la sala';

  @override
  String get stepBodyAwaitRoomCodeDesc =>
      'Los jugadores van a crear una sala en el juego y compartir el código aquí.';

  @override
  String get stepBodyAwaitHomeCodeTitle =>
      'Esperando el código del jugador local';

  @override
  String get stepBodyAwaitHomeCodeDesc =>
      'Juegas de visitante en este partido. El jugador local creará la sala en el juego y te enviará el código aquí en cuanto lo comparta.';

  @override
  String get openChatButton => 'ABRIR EL CHAT';

  @override
  String get roomReadyMarkStartedError => 'No se pudo marcar como iniciado: ';

  @override
  String get roomReadyCodeCopied => 'Código copiado al portapapeles';

  @override
  String get roomReadyHintObserver =>
      'Los jugadores van a unirse a la sala e iniciar el partido.';

  @override
  String get roomReadyHintHome =>
      'Ya compartiste el código. Esperando a que tu rival se una, luego confirmen el inicio.';

  @override
  String get roomReadyHintAway =>
      'Únete a la sala en el juego con este código, luego confirma cuando ambos jugadores estén dentro.';

  @override
  String get roomReadyCodeLabel => 'CÓDIGO DE LA SALA';

  @override
  String get roomReadyCopyTooltip => 'Copiar el código';

  @override
  String get roomReadyTeamNameLabel => 'NOMBRE DE TU EQUIPO';

  @override
  String get roomReadyTeamNameHint => 'Ej. Real Madrid, FC Barcelona…';

  @override
  String get roomReadyTeamNameHelper =>
      'Obligatorio — el equipo que usas en este partido. Visible para el admin en caso de litigio anticheat.';

  @override
  String get roomReadyInRoomButton => 'ESTOY EN LA SALA';

  @override
  String get roomReadyJoinedButton => 'ME UNÍ A LA SALA';

  @override
  String get startRecordingTitle => 'Prepara tu partido';

  @override
  String get startRecordingDesc =>
      'Ingresa el nombre de tu equipo y luego inicia la grabación. Después crearás tu sala en eFootball y enviarás el código a tu rival desde el botón flotante, sin salir del juego.';

  @override
  String get startRecordingButton => 'INICIAR GRABACIÓN';

  @override
  String get startRecordingTeamStepTitle => 'El nombre de tu equipo';

  @override
  String get startRecordingTeamStepDesc =>
      'Ingresa el nombre del equipo que usas en este partido y luego continúa.';

  @override
  String get startRecordingActivateTitle => 'Activa tu grabación';

  @override
  String get startRecordingActivateDesc =>
      'La grabación anticheat va a iniciar. Autoriza la captura de pantalla, luego crea tu sala en eFootball y envía el código desde el botón flotante.';

  @override
  String get stepBodyHostPreparingTitle =>
      'El anfitrión está preparando la sala';

  @override
  String get stepBodyHostPreparingDesc =>
      'El jugador local inicia su grabación y crea la sala. El código llegará aquí en breve.';

  @override
  String get stepBodyHomeAwaitCreateRoomTitle => 'Grabación en curso';

  @override
  String get stepBodyHomeAwaitCreateRoomDesc =>
      'Crea tu sala en eFootball y luego envía el código a tu rival desde el botón flotante rojo (mini «llave»).';

  @override
  String get stepBodyAwayAwaitCodeTitle => 'Esperando el código';

  @override
  String get stepBodyAwayAwaitCodeDesc =>
      'El anfitrión está creando su sala. El código de la sala llegará aquí — entonces podrás unirte.';

  @override
  String get roomReadyCodeSharedBadge => 'CÓDIGO COMPARTIDO';

  @override
  String get roomReadySyncingHint => 'Sincronizando con tu rival…';

  @override
  String get scoreEditErrorRange => 'Los marcadores deben estar entre 0 y 99.';

  @override
  String get scoreEditErrorTieBeforePens =>
      'El marcador reglamentario debe estar empatado antes de los penales.';

  @override
  String get scoreEditErrorPensRange => 'Los penales deben estar entre 0 y 30.';

  @override
  String get scoreEditErrorPensTie =>
      'Los penales no pueden terminar empatados.';

  @override
  String get scoreEditDialogTitle => 'Corregir tu marcador';

  @override
  String get scoreEditMyScoreLabel => 'Mi marcador';

  @override
  String get scoreEditOpponentLabel => 'Rival';

  @override
  String get scoreEditViaPenaltiesLabel => 'Decidido por penales';

  @override
  String get scoreEditMyPenLabel => 'Mis penales';

  @override
  String get scoreEditOppPenLabel => 'Penales rival';

  @override
  String get scoreEditCancelButton => 'Cancelar';

  @override
  String get scoreEditResendButton => 'REENVIAR';

  @override
  String get scoreFlowErrorRange => 'Los marcadores deben estar entre 0 y 99.';

  @override
  String get scoreFlowErrorTieBeforePens =>
      'El marcador reglamentario debe estar empatado antes de los penales.';

  @override
  String get scoreFlowErrorPensRange => 'Los penales deben estar entre 0 y 30.';

  @override
  String get scoreFlowErrorPensTie =>
      'Los penales no pueden terminar empatados.';

  @override
  String get scoreFlowSubmitError => 'No se pudo enviar: ';

  @override
  String get scoreFlowProofUploadError => 'No se pudo subir: ';

  @override
  String get scoreFlowResolutionError => 'Error de resolución: ';

  @override
  String get scoreFlowSessionExpiredTitle => 'Sesión expirada';

  @override
  String get scoreFlowSessionExpiredDescription =>
      'Vuelve a conectarte para ingresar un marcador.';

  @override
  String get scoreFlowEnterFinalScoreLabel => 'INGRESA EL MARCADOR FINAL';

  @override
  String get scoreFlowEnterFinalScoreHint =>
      'Ingresa los goles de cada lado. Si ambas entradas coinciden, el partido se valida automáticamente.';

  @override
  String get scoreFlowMyScoreLabel => 'Mi marcador';

  @override
  String get scoreFlowOppScoreLabel => 'Marcador del rival';

  @override
  String get scoreFlowViaPenaltiesTitle => 'Partido decidido por penales';

  @override
  String get scoreFlowViaPenaltiesSubtitle =>
      'Marca esto solo si el marcador reglamentario está empatado.';

  @override
  String get scoreFlowMyPenLabel => 'Mis penales';

  @override
  String get scoreFlowOppPenLabel => 'Penales del rival';

  @override
  String get scoreFlowSubmitButton => 'ENVIAR MARCADOR';

  @override
  String get scoreFlowValidationInProgress => 'VALIDACIÓN EN CURSO';

  @override
  String get scoreFlowWaitingOpponent => 'ESPERANDO A TU RIVAL';

  @override
  String get scoreFlowYouSubmitted => 'Enviaste: ';

  @override
  String get scoreFlowOnPenalties => 'En penales: ';

  @override
  String get scoreFlowComparingScores =>
      'Comparando los marcadores de ambos jugadores…';

  @override
  String get scoreFlowOpponentNotSubmitted =>
      'Tu rival aún no ha ingresado su marcador.';

  @override
  String get scoreFlowProofAttached => 'Prueba adjunta';

  @override
  String get scoreFlowProofPrompt => 'Adjunta una foto o video (recomendado)';

  @override
  String get scoreFlowProofHelper =>
      'Captura de pantalla de la pantalla final del partido o clip de la última jugada — útil en caso de litigio.';

  @override
  String get scoreFlowUploading => 'Subiendo…';

  @override
  String get scoreFlowReplaceButton => 'Reemplazar';

  @override
  String get scoreFlowRemoveProofTooltip => 'Quitar la prueba';

  @override
  String get scoreFlowChooseFileButton => 'Elegir un archivo';

  @override
  String get shareCodeErrorLength =>
      'El código debe tener entre 4 y 12 caracteres.';

  @override
  String get shareCodeErrorSendFailed => 'No se pudo compartir el código: ';

  @override
  String get shareCodeRoomLabel => 'CÓDIGO DE SALA (CREADA POR EL LOCAL)';

  @override
  String get shareCodeEnterPrompt => 'Ingresa tu código de eFootball:';

  @override
  String get shareCodeOpponentWillReceive =>
      'Tu rival recibirá este código en el chat en cuanto lo envíes.';

  @override
  String get shareCodeOpponentReceives =>
      'Tu rival recibe este código en el chat en cuanto lo envías.';

  @override
  String get shareCodeSubmitButton => 'ENVIAR CÓDIGO';

  @override
  String get shareCodeOverlayButton => 'ENVIAR SIN SALIR DE EFOOTBALL';

  @override
  String get shareCodeOverlayHint =>
      'Crea tu sala en eFootball y luego envía el código desde un botón flotante — sin salir del juego, la sala sigue activa.';

  @override
  String get shareCodeInputHint => 'Ej: 8K3-TZ9';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsMarkAllReadTooltip => 'Marcar todo como leído';

  @override
  String get notificationsMarkAllReadError =>
      'No se pudo marcar todo como leído.';

  @override
  String get notificationsLoadError => 'Error al cargar.\n';

  @override
  String get notificationsSignedOut =>
      'Inicia sesión para ver tus notificaciones.';

  @override
  String get notificationsEmpty => 'Todavía no hay notificaciones.';

  @override
  String get notificationsFilterAll => 'Todas';

  @override
  String get notificationsFilterMatch => 'Partidos';

  @override
  String get notificationsFilterEarning => 'Ganancias';

  @override
  String get notificationsFilterSystem => 'Sistema';

  @override
  String get notificationsTimeJustNow => 'Ahora mismo';

  @override
  String get notificationsTimeYesterday => 'Ayer';

  @override
  String get mobileMoneyDefaultCountry => '🇨🇲 Camerún';

  @override
  String get mobileMoneyCountryLabel => 'PAÍS';

  @override
  String get mobileMoneyNumberLabel => 'NÚMERO ';

  @override
  String get mobileMoneyNumberHelp =>
      'El número desde el cual vas a pagar (útil para que el súper admin encuentre tu transacción).';

  @override
  String get mobileMoneyPhoneValid => '✓ Número válido ';

  @override
  String get mobileMoneySubmitSending => 'ENVIANDO…';

  @override
  String get mobileMoneySubmitPaid => 'YA PAGUÉ ';

  @override
  String get mobileMoneyCodeCopied => 'Código de comercio copiado.';

  @override
  String get mobileMoneyDialerError =>
      'No se pudo abrir el marcador. Copia el código y márcalo manualmente.';

  @override
  String get mobileMoneySubmitError => 'Error al enviar: ';

  @override
  String get mobileMoneyNoConnection => 'Sin conexión: ';

  @override
  String get mobileMoneyHeroPayment => 'Pago ';

  @override
  String get mobileMoneyHeroForAmount => 'Por ';

  @override
  String get mobileMoneyMerchantCodeTitle => 'Código de comercio';

  @override
  String get mobileMoneyCopyButton => '📋 COPIAR';

  @override
  String get mobileMoneyExecuteButton => '📞 EJECUTAR';

  @override
  String get mobileMoneyMissingCodeTitle => '⚠ Falta el código de comercio';

  @override
  String get mobileMoneyMissingCodeBody =>
      'El admin aún no configuró un código de comercio para este método en esta competencia. Elige otro método o contacta con soporte.';

  @override
  String get mobileMoneyDisclaimerExactAmount =>
      'Paga el monto EXACTO — si no, el súper admin lo rechazará';

  @override
  String get mobileMoneyDisclaimerKeepSms =>
      'Guarda el SMS de confirmación de Mobile Money como comprobante';

  @override
  String get mobileMoneyDisclaimerManualValidation =>
      'El admin valida tu pago manualmente tras recibirlo';

  @override
  String get mobileMoneyDisclaimerTitle => '⚠ Antes de continuar';

  @override
  String get paymentFailedRejectedWithReason =>
      'El súper admin rechazó tu pago: ';

  @override
  String get paymentFailedRejectedGeneric =>
      'El súper admin rechazó tu pago (monto incorrecto o transacción no encontrada en la cuenta comercial).';

  @override
  String get paymentFailedNetwork =>
      'Hubo un problema de red durante el envío. No se realizó ningún cobro del lado de ARENA.';

  @override
  String get paymentFailedUnknown =>
      'No se pudo confirmar el pago. Vuelve a intentarlo o contacta con soporte.';

  @override
  String get paymentFailedSolutionCheckAmount =>
      'Verifica el monto exacto y el código de comercio';

  @override
  String get paymentFailedSolutionRetryFromSignup =>
      'Vuelve a empezar desde la página de Inscripción';

  @override
  String get paymentFailedSolutionContactIfError =>
      'Contacta con soporte si crees que es un error';

  @override
  String get paymentFailedSolutionCheckInternet =>
      'Verifica tu conexión a Internet';

  @override
  String get paymentFailedSolutionContactSupport =>
      'Contacta con el soporte de ARENA';

  @override
  String get paymentFailedAccountNotRegistered => 'Tu cuenta no fue inscrita.';

  @override
  String get paymentFailedRetryButton => '↻ VOLVER A INTENTAR';

  @override
  String get paymentFailedContactSupportLink =>
      'Contactar con el soporte de ARENA';

  @override
  String get paymentFailedTitleRejected => 'PAGO RECHAZADO';

  @override
  String get paymentFailedTitleFailed => 'PAGO FALLIDO';

  @override
  String get paymentFailedCauseTitle => '⚠ Causa';

  @override
  String get paymentFailedErrorCodeLabel => 'Código de error: ';

  @override
  String get paymentFailedSolutionsTitle => '💡 Soluciones';

  @override
  String get paymentHistoryAppBarTitle => 'HISTORIAL';

  @override
  String get paymentHistoryErrorPrefix => 'Error: ';

  @override
  String get paymentHistoryTabPayments => 'PAGOS';

  @override
  String get paymentHistoryTabGains => 'GANANCIAS';

  @override
  String get paymentHistoryGainsEmpty =>
      'Todavía no hay ganancias. ¡Gana una competencia para recibir un pago!';

  @override
  String get paymentHistoryBadgePaid => 'PAGADO';

  @override
  String get paymentHistoryBadgePending => 'PENDIENTE';

  @override
  String get paymentHistoryBadgeToClaim => 'POR RECLAMAR';

  @override
  String get paymentHistoryGainRanked => 'Ganancia · puesto ';

  @override
  String get paymentHistoryGainGeneric => 'Ganancia de competencia';

  @override
  String get paymentHistoryClaimButton => 'RECLAMAR MI GANANCIA';

  @override
  String get paymentHistoryClaimSuccess =>
      'Ganancia reclamada — el equipo procederá al pago.';

  @override
  String get paymentHistoryClaimFailPrefix => 'Error: ';

  @override
  String get paymentHistoryClaimSheetTitle => 'Reclamar mi ganancia';

  @override
  String get paymentHistoryClaimSheetSubtitle =>
      'Indica el número de Mobile Money en el que quieres recibir tu pago.';

  @override
  String get paymentHistoryClaimMethodMtn => 'MTN MoMo';

  @override
  String get paymentHistoryClaimMethodOrange => 'Orange Money';

  @override
  String get paymentHistoryClaimPhoneHint =>
      'Número de Mobile Money (ej. +237 6XX XX XX XX)';

  @override
  String get paymentHistoryClaimConfirm => 'CONFIRMAR';

  @override
  String get paymentHistoryClaimPhoneRequired => 'Número requerido.';

  @override
  String get paymentHistoryClaimOperatorHint =>
      'Operador (ej. Wave, MTN MoMo, Orange Money)';

  @override
  String get paymentHistoryClaimOperatorRequired => 'Operador requerido.';

  @override
  String get paymentHistoryEmptyPayments => 'Todavía no hay pagos.';

  @override
  String get paymentHistoryNetBalanceLabel => 'SALDO NETO';

  @override
  String get paymentHistoryTxTitle => 'Inscripción a competencia';

  @override
  String get paymentHistoryTxBadgePaid => 'PAGADO';

  @override
  String get paymentHistoryTxBadgePending => 'PENDIENTE';

  @override
  String get paymentHistoryTxBadgeRefund => 'REEMBOLSO';

  @override
  String get paymentHistoryTxBadgeRefunded => 'REEMBOLSADO';

  @override
  String get paymentHistoryTxBadgeFailed => 'FALLIDO';

  @override
  String get paymentHistoryResumeCompetition => 'Competición';

  @override
  String get paymentMethodMtnLabel => 'MTN Mobile Money';

  @override
  String get paymentMethodMtnCountries => 'Camerún, Costa de Marfil, Benín';

  @override
  String get paymentMethodOrangeLabel => 'Orange Money';

  @override
  String get paymentMethodOrangeCountries => 'Camerún, Senegal, Malí';

  @override
  String get paymentPickerAppBarTitle => 'PAGO';

  @override
  String get paymentPickerMobileMoneySection => '📱 MOBILE MONEY';

  @override
  String get paymentPickerV2Notice =>
      '₿ Crypto + Wave + Moov disponibles en V2 (pasarelas automáticas CinetPay / NowPayments).';

  @override
  String get paymentPickerContinueButton => 'CONTINUAR →';

  @override
  String get paymentPickerAmountLabel => 'MONTO A PAGAR';

  @override
  String get paymentProcessingAppBarTitle => 'ESTADO DEL PAGO';

  @override
  String get paymentProcessingWaitingTitle => 'ESPERANDO VALIDACIÓN';

  @override
  String get paymentProcessingWaitingSubtitle =>
      'El súper admin está verificando la recepción del pago en su cuenta ';

  @override
  String get paymentProcessingWaitingSubtitleSuffix => ' account.';

  @override
  String get paymentProcessingInfoNote =>
      '💡 Puedes cerrar esta página: la transacción sigue pendiente del lado del admin. Podrás volver a verificar el estado desde \"Historial de pagos\" o el banner en el inicio.';

  @override
  String get paymentProcessingLeaveButton => 'SALIR (LA TRANSACCIÓN CONTINÚA)';

  @override
  String get paymentProcessingCancelButton => 'Cancelar la transacción';

  @override
  String get paymentProcessingCancelDialogTitle => '¿Cancelar el pago?';

  @override
  String get paymentProcessingCancelDialogBody =>
      'Si ya pagaste por Mobile Money, espera la validación en lugar de cancelar aquí (de lo contrario, el admin no inscribirá tu cuenta).';

  @override
  String get paymentProcessingCancelDialogStay => 'Quedarme';

  @override
  String get paymentProcessingCancelDialogConfirm => 'Cancelar de todos modos';

  @override
  String get paymentProcessingRecapCompetition => 'Competición';

  @override
  String get paymentProcessingRecapAmount => 'Monto';

  @override
  String get paymentProcessingRecapMethod => 'Método';

  @override
  String get paymentProcessingRecapPhone => 'Tu número';

  @override
  String get paymentProcessingRecapReference => 'Referencia';

  @override
  String get paymentSuccessTitle => '¡PAGO EXITOSO!';

  @override
  String get paymentSuccessSubtitle => 'Tu inscripción está confirmada.';

  @override
  String get paymentSuccessSeeCompetition => '🏆 VER LA COMPETICIÓN';

  @override
  String get paymentSuccessBackHome => 'Volver al inicio';

  @override
  String get paymentSuccessReceiptAmount => 'Monto';

  @override
  String get paymentSuccessReceiptMethod => 'Método';

  @override
  String get paymentSuccessReceiptTransaction => 'N.° de transacción';

  @override
  String get paymentSuccessReceiptDate => 'Fecha';

  @override
  String get paymentSuccessRegisteredLabel => '🏆 Estás inscrito en';

  @override
  String get payoutKycStepIdRecto => 'Documento de identidad (frente)';

  @override
  String get payoutKycStepIdVerso => 'Documento de identidad (reverso)';

  @override
  String get payoutKycStepSelfie => 'Selfie de verificación';

  @override
  String get payoutKycAppBarTitle => 'VERIFICAR';

  @override
  String get payoutKycAcceptedDocsLabel => 'DOCUMENTOS ACEPTADOS';

  @override
  String get payoutKycSubmitForReview => 'ENVIAR PARA VERIFICACIÓN';

  @override
  String get payoutKycNextRectoRequired => 'SIGUIENTE (frente requerido)';

  @override
  String payoutKycPendingGain(Object amount) {
    return '💰 Ganancia de $amount XAF';
  }

  @override
  String get payoutKycPendingExplain =>
      'Para este monto, debemos verificar tu identidad antes del pago. Es rápido (en menos de 24 h).';

  @override
  String get payoutKycDocNationalId => 'Cédula de identidad nacional';

  @override
  String get payoutKycDocPassport => 'Pasaporte';

  @override
  String get payoutKycDocDriverLicense => 'Licencia de conducir';

  @override
  String get payoutKycPhotoCaptured => 'Foto capturada';

  @override
  String get payoutKycRetake => 'VOLVER A TOMAR';

  @override
  String get payoutKycPhotographFront => 'Fotografiar el frente';

  @override
  String get payoutKycCaptureHint =>
      'Buena iluminación, foto nítida, sin reflejos';

  @override
  String get payoutKycTakePhoto => '📸 TOMAR FOTO';

  @override
  String get payoutKycSecurityLabel => 'Seguridad: ';

  @override
  String get payoutKycSecurityNote =>
      'tus documentos están cifrados y se usan únicamente para la verificación regulatoria.';

  @override
  String get aboutLinkCgu => 'Términos y condiciones';

  @override
  String get aboutLinkPrivacy => 'Privacy Policy';

  @override
  String get aboutLinkCookies => 'Cookies';

  @override
  String get aboutLinkSupport => 'Soporte';

  @override
  String get aboutLinkSite => 'Sitio arena.app';

  @override
  String get aboutAppBarTitle => 'ACERCA DE';

  @override
  String get aboutMadeInCameroon => 'Made in Cameroon 🇨🇲';

  @override
  String get aboutLinksLabel => 'ENLACES';

  @override
  String get aboutBuiltWith => 'Built with';

  @override
  String get aboutMissionTitle => '📜 Nuestra misión';

  @override
  String get aboutMissionBody =>
      'ARENA democratiza el e-sport móvil en África ofreciendo torneos justos, ganancias en mobile money, y una experiencia premium a los apasionados del fútbol virtual.';

  @override
  String aboutLinkComingSoon(Object label) {
    return '$label llega en la FASE 12.5';
  }

  @override
  String get adminMessagesAppBarTitle => 'Mensajes ARENA';

  @override
  String adminMessagesError(Object error) {
    return 'Error: $error';
  }

  @override
  String get adminMessagesEmpty => 'No hay ningún mensaje de parte de ARENA.';

  @override
  String get deleteAccountStepWarning => 'ADVERTENCIA';

  @override
  String get deleteAccountStepPendingEarnings => 'GANANCIAS PENDIENTES';

  @override
  String get deleteAccountStepConfirmation => 'CONFIRMACIÓN';

  @override
  String get deleteAccountStepDone => 'LISTO';

  @override
  String get deleteAccountAppBarTitle => 'ELIMINAR';

  @override
  String get deleteAccountLossHistory =>
      'Todo tu historial de partidas y torneos';

  @override
  String get deleteAccountLossBadges => 'Tus insignias y logros';

  @override
  String get deleteAccountLossChats => 'Tus conversaciones y chats de partida';

  @override
  String get deleteAccountLossPaymentMethods => 'Tus métodos de pago guardados';

  @override
  String get deleteAccountIrreversibleTitle => 'Esta acción es irreversible';

  @override
  String get deleteAccountLossIntro => 'Al eliminar tu cuenta, vas a perder:';

  @override
  String get deleteAccountRetentionNotice =>
      'Tu cuenta será desactivada de inmediato y luego anonimizada (datos personales borrados) en un plazo de 30 días. Los comprobantes contables legales (pagos) se conservan de forma anonimizada. Durante este período, puedes contactar al soporte para cancelar.';

  @override
  String get deleteAccountUnderstandContinue => 'ENTIENDO, CONTINUAR';

  @override
  String get deleteAccountHasPendingTitle => 'Tienes ganancias pendientes';

  @override
  String get deleteAccountHasPendingBody =>
      'Retira tus pagos pendientes antes de eliminar tu cuenta. Una vez eliminada, ya no podrás recibir esos fondos.';

  @override
  String get deleteAccountBack => 'VOLVER';

  @override
  String get deleteAccountNoPendingTitle => 'Ninguna ganancia pendiente';

  @override
  String get deleteAccountNoPendingBody =>
      'Puedes continuar con la eliminación sin riesgo de perder pagos en curso.';

  @override
  String get deleteAccountContinue => 'CONTINUAR';

  @override
  String get deleteAccountConfirmWord => 'ELIMINAR';

  @override
  String get deleteAccountConfirmTitle => 'Confirma la eliminación';

  @override
  String get deleteAccountPasswordLabel => 'Contraseña';

  @override
  String get deleteAccountReasonLabel => 'Motivo (opcional)';

  @override
  String get deleteAccountDeletePermanently => 'ELIMINAR DEFINITIVAMENTE';

  @override
  String get deleteAccountDoneTitle => 'Cuenta desactivada';

  @override
  String get deleteAccountDoneBody =>
      'Tu cuenta será anonimizada (datos personales eliminados) en un plazo de 30 días. Contacta al soporte si cambias de opinión.';

  @override
  String get deleteAccountBackToHome => 'VOLVER AL INICIO';

  @override
  String get editProfileWhatsappInvalidError => 'Número de WhatsApp inválido.';

  @override
  String get editProfileUpdatedSnack => 'Perfil actualizado.';

  @override
  String get editProfileAppBarTitle => 'MODIFICAR';

  @override
  String get editProfileSaveTooltip => 'Guardar';

  @override
  String get editProfileColorEditableHint => 'Color modificable abajo';

  @override
  String get editProfileAvatarChangeHint => 'Modificar la foto';

  @override
  String get editProfileAvatarFromGallery => 'Elegir de la galería';

  @override
  String get editProfileAvatarFromCamera => 'Tomar una foto';

  @override
  String get editProfileAvatarRemove => 'Quitar la foto';

  @override
  String get editProfileAvatarUpdatedSnack => 'Foto de perfil actualizada.';

  @override
  String get editProfileUsernameCaption => 'NOMBRE DE USUARIO';

  @override
  String get editProfileUsernameMinError => 'Mínimo 3 caracteres';

  @override
  String get editProfileUsernameMaxError => 'Máximo 20 caracteres';

  @override
  String get editProfileCountryCaption => 'PAÍS';

  @override
  String get editProfileAvatarColorCaption => 'COLOR DEL AVATAR';

  @override
  String get editProfileWhatsappHint => 'Ej. 07 07 07 07 07';

  @override
  String get editProfileWhatsappInvalidErrorText => 'Número inválido.';

  @override
  String get editProfileSaveButton => 'GUARDAR';

  @override
  String get friendsAppBarTitle => 'Mis amigos';

  @override
  String get friendsSearchTooltip => 'Buscar';

  @override
  String get friendsTabFriends => 'Amigos';

  @override
  String get friendsTabRequests => 'Solicitudes';

  @override
  String get friendsTabBlocked => 'Bloqueados';

  @override
  String get friendsEmptyLabel => 'Aún no tienes amigos.';

  @override
  String get friendsEmptyHint => 'Toca la lupa arriba para buscar.';

  @override
  String get friendsRemoveCancel => 'Cancelar';

  @override
  String get friendsRemoveConfirm => 'Confirmar';

  @override
  String get friendsSectionReceived => 'RECIBIDAS';

  @override
  String get friendsSectionSent => 'ENVIADAS';

  @override
  String get friendsNoRequests => 'Ninguna solicitud.';

  @override
  String get friendsNoPendingRequests => 'Ninguna solicitud pendiente.';

  @override
  String get friendsCancelRequest => 'Cancelar';

  @override
  String get friendsBlockedEmptyLabel => 'Ningún jugador bloqueado.';

  @override
  String get friendsUnblockAction => 'Desbloquear';

  @override
  String get friendsSearchAppBarTitle => 'Buscar';

  @override
  String get friendsSearchHint => 'Nombre de usuario';

  @override
  String get friendsSearchPrompt =>
      'Escribe al menos 2 caracteres para buscar.';

  @override
  String get matchHistoryAppBarLoadingTitle => 'Historial';

  @override
  String get matchHistoryAppBarTitle => 'HISTORIAL';

  @override
  String get matchHistoryError =>
      'No se pudo cargar tu historial. Verifica tu conexión.';

  @override
  String get matchHistoryFilterAll => 'Todos';

  @override
  String get matchHistoryFilterWins => 'V';

  @override
  String get matchHistoryFilterLosses => 'D';

  @override
  String get matchHistoryFilterOngoing => 'En curso';

  @override
  String get matchHistoryEmptyTitle => 'Ningún partido';

  @override
  String get matchHistoryEmptyDescription =>
      'Tus partidos aparecerán aquí desde tu primera competición.';

  @override
  String get matchHistoryOpponentFallback => 'Adversario';

  @override
  String get playerProfileUnavailable =>
      'Perfil no disponible. Vuelve a iniciar sesión.';

  @override
  String get playerProfileSuccessHeader => '🏆 LOGROS';

  @override
  String get playerProfileRecentMatchesHeader => 'PARTIDOS RECIENTES';

  @override
  String get playerProfilePaymentsButton => 'RECLAMO DE GANANCIAS';

  @override
  String get playerProfileSettingsButton => 'AJUSTES';

  @override
  String get playerProfileSignOutButton => 'CERRAR SESIÓN';

  @override
  String get playerProfileJoinedPrefix => 'Inscrito en';

  @override
  String get playerProfileTierBronze => '🥉 BRONCE';

  @override
  String get playerProfileTierSilver => '🥈 PLATA';

  @override
  String get playerProfileTierGold => '🥇 ORO';

  @override
  String get playerProfileTierElite => '💎 ÉLITE';

  @override
  String get playerProfileEditTooltip => 'Modificar';

  @override
  String get playerProfileEditAvatarTooltip => 'Modificar el avatar';

  @override
  String get playerProfileStatWins => 'Victorias';

  @override
  String get playerProfileStatLosses => 'Derrotas';

  @override
  String get playerProfileStatWinRate => 'Win rate';

  @override
  String get playerProfileNoCompletedMatches =>
      'Aún no hay partidos completados.';

  @override
  String get playerProfileFriendsTitle => 'Mis amigos';

  @override
  String get playerProfileNoFriends => 'Aún no tienes amigos';

  @override
  String get playerProfileReferralTitle => 'Mi referido';

  @override
  String get playerProfileReferralCodeCopied => 'Código de referido copiado';

  @override
  String get playerProfileReferralCodeGenerating => 'Generando el código…';

  @override
  String get playerProfileReferralExplainer =>
      'Comparte tu código para invitar a amigos. Al alcanzar tu cuota, accedes automáticamente a competiciones gratuitas con recompensa condicionada.';

  @override
  String get playerProfileResultWin => 'V';

  @override
  String get playerProfileResultLoss => 'D';

  @override
  String get playerProfileResultDraw => 'E';

  @override
  String get publicProfileAppBarTitle => 'Perfil';

  @override
  String get publicProfilePlayerNotFound => 'Jugador no encontrado.';

  @override
  String get publicProfileRecentMatchesHeader => 'PARTIDOS RECIENTES';

  @override
  String get publicProfileCtaAddFriend => 'AGREGAR AMIGO';

  @override
  String get publicProfileCtaRequestSent => 'SOLICITUD ENVIADA';

  @override
  String get publicProfileCtaCancel => 'CANCELAR';

  @override
  String get publicProfileRequestCancelled => 'Solicitud cancelada';

  @override
  String get publicProfileCtaAccept => 'ACEPTAR';

  @override
  String get publicProfileCtaDecline => 'RECHAZAR';

  @override
  String get publicProfileRequestDeclined => 'Solicitud rechazada';

  @override
  String get publicProfileCtaFriend => 'AMIGO';

  @override
  String get publicProfileCtaRemove => 'QUITAR';

  @override
  String get publicProfileFriendRemoved => 'Amigo eliminado';

  @override
  String get publicProfileCtaBlock => 'BLOQUEAR';

  @override
  String get publicProfileBlockConfirmDetail =>
      'Ya no podrás chatear en el chat de partido.';

  @override
  String get publicProfilePlayerBlocked => 'Jugador bloqueado';

  @override
  String get publicProfileCtaUnblock => 'DESBLOQUEAR';

  @override
  String get publicProfilePlayerUnblocked => 'Jugador desbloqueado';

  @override
  String get publicProfileCtaUnavailable => 'NO DISPONIBLE';

  @override
  String get publicProfileDialogCancel => 'Cancelar';

  @override
  String get publicProfileDialogConfirm => 'Confirmar';

  @override
  String get publicProfileStatsHeader => 'ESTADÍSTICAS';

  @override
  String get publicProfileStatWin => 'G';

  @override
  String get publicProfileStatLoss => 'P';

  @override
  String get publicProfileStatDraw => 'E';

  @override
  String get publicProfileWinRateLabel => 'Porcentaje de victorias';

  @override
  String get publicProfileGoalsScored => 'Goles anotados';

  @override
  String get publicProfileGoalsConceded => 'Goles recibidos';

  @override
  String get publicProfileNoCompletedMatches =>
      'Aún no hay partidos completados.';

  @override
  String get publicProfileResultWin => 'G';

  @override
  String get publicProfileResultLoss => 'P';

  @override
  String get publicProfileResultDraw => 'E';

  @override
  String get settingsAppBarTitle => 'AJUSTES';

  @override
  String get settingsSectionPreferences => 'PREFERENCIAS';

  @override
  String get settingsSectionAccount => 'CUENTA';

  @override
  String get settingsSectionPrivacy => 'PRIVACIDAD';

  @override
  String get settingsSectionHelp => 'AYUDA E INFO';

  @override
  String get settingsVersionFooter => 'v1.0.0 · build 12';

  @override
  String get settingsLanguageLabel => 'Idioma';

  @override
  String get settingsCurrencyLabel => 'Moneda';

  @override
  String get settingsMarketingTitle => 'Notificaciones de marketing';

  @override
  String get settingsMarketingSubtitle =>
      'Consejos, nuevos torneos, promociones';

  @override
  String get settingsChangeEmailTitle => 'Cambiar el correo';

  @override
  String get settingsChangePasswordTitle => 'Cambiar la contraseña';

  @override
  String get settingsLoginMethodsTitle => 'Métodos de inicio de sesión';

  @override
  String get settingsLoginMethodsSubtitle => 'Google / Apple — próximamente';

  @override
  String get settingsNewEmailDialogTitle => 'Nuevo correo';

  @override
  String get settingsNewEmailHint => 'nombre@ejemplo.com';

  @override
  String get settingsDialogCancel => 'Cancelar';

  @override
  String get settingsDialogConfirm => 'Confirmar';

  @override
  String get settingsEmailChangeConfirmSnack =>
      'Revisa tu correo para confirmar el cambio.';

  @override
  String get settingsNewPasswordDialogTitle => 'Nueva contraseña';

  @override
  String get settingsNewPasswordHint => '8 caracteres mínimo';

  @override
  String get settingsPasswordUpdatedSnack => 'Contraseña actualizada.';

  @override
  String get settingsDownloadDataTitle => 'Descargar mis datos';

  @override
  String get settingsDownloadDataExporting => 'Exportando…';

  @override
  String get settingsDownloadDataSubtitle =>
      'Genera un archivo JSON con todos tus datos';

  @override
  String get settingsDeleteAccountTitle => 'Eliminar mi cuenta';

  @override
  String get settingsExportSuccessTitle => 'Exportación exitosa';

  @override
  String get settingsExportPathCopied => 'Ruta copiada al portapapeles.';

  @override
  String get settingsExportContentLabel => 'Contenido:';

  @override
  String get settingsDialogOk => 'OK';

  @override
  String get settingsReplayIntroTitle => 'Volver a ver la introducción';

  @override
  String get settingsSupportTitle => 'Soporte';

  @override
  String get settingsContactSupportSubtitle => 'Chatea con el equipo de ARENA';

  @override
  String get supportChatTitle => 'Contacto / Ayuda';

  @override
  String get supportChatHeaderSubtitle => 'Equipo ARENA';

  @override
  String get supportChatEmptyTitle => '¿Tienes una pregunta? Escríbenos';

  @override
  String get supportChatEmptyDescription =>
      'El equipo de ARENA te responde aquí. Cuéntanos tu problema y te contactaremos lo antes posible.';

  @override
  String get supportOptionsTitle => 'Contactar al soporte';

  @override
  String get supportOptionChat => 'Chatear con el equipo';

  @override
  String get supportOptionChatSubtitle =>
      'Respuesta en la app, te contactamos pronto';

  @override
  String get supportOptionEmail => 'Escribir un correo';

  @override
  String get updateTitle => 'Actualización disponible';

  @override
  String updateMessage(Object version) {
    return 'La versión $version está disponible.';
  }

  @override
  String get updateChangelogLabel => 'Novedades';

  @override
  String get updateDownloading => 'Descargando…';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get updateNow => 'Actualizar ahora';

  @override
  String get updateFailed =>
      'Error al actualizar. Inténtalo de nuevo más tarde.';

  @override
  String get settingsAboutTitle => 'Acerca de';

  @override
  String get settingsAboutSubtitle =>
      'ARENA V1.0 — Plataforma de torneos e-sport móvil';

  @override
  String get matchOverlayContinue => '▶ Continuar';

  @override
  String get matchOverlayPauseRecording => '⏸ Pausar grabación';

  @override
  String get matchOverlayStopForfeit => '🛑 Detener (abandono)';

  @override
  String get recordingErrorSolutionStep1 => 'Ve a Ajustes → Apps → ARENA';

  @override
  String get recordingErrorSolutionStep2 =>
      'Activa \"Mostrar sobre otras apps\"';

  @override
  String get recordingErrorSolutionStep3 =>
      'Desactiva el ahorro de batería para ARENA';

  @override
  String get recordingErrorSolutionStep4 =>
      'Permite que ARENA se ejecute en segundo plano';

  @override
  String get recordingErrorAppBarTitle => 'Error de grabación';

  @override
  String get recordingErrorHeadline => 'GRABACIÓN IMPOSIBLE';

  @override
  String get recordingErrorAntiCheatNotice =>
      'Sin grabación, el partido no puede comenzar (anti-trampas).';

  @override
  String get recordingErrorSolutionsLabel => 'SOLUCIONES';

  @override
  String get recordingErrorRetryButton => '↻ REINTENTAR';

  @override
  String get recordingErrorForfeitButton => '🏳 ABANDONAR (perder)';

  @override
  String get recordingErrorContactSupport => 'Contactar al soporte';

  @override
  String get recordingErrorCauseTitle => '⚠️ Causa detectada';

  @override
  String get recordingErrorCausePermissionPrefix => 'Permiso ';

  @override
  String get recordingErrorCausePermissionSuffix => ' faltante.';

  @override
  String get liveStreamsAppBarTitle => 'EN VIVO AHORA';

  @override
  String get liveStreamsErrorPrefixV2 => 'Error: ';

  @override
  String get liveStreamsEmptyTitle => 'Ningún partido en directo';

  @override
  String get liveStreamsEmptyDescription =>
      'Las transmisiones en vivo aparecen aquí en cuanto un admin selecciona un partido para la transmisión.';

  @override
  String get liveStreamsBroadcastByPrefix => 'Transmitido por ';

  @override
  String get startStreamingAlreadyLive =>
      'Estás transmitiendo este partido en vivo';

  @override
  String get startStreamingSelected =>
      'Este partido está seleccionado para la transmisión en vivo';

  @override
  String get startStreamingOpponentLive => 'Partido transmitido en vivo';

  @override
  String get startStreamingStartButton => 'Iniciar';

  @override
  String get startStreamingStartedSnack => 'Transmisión iniciada.';

  @override
  String get watchStreamConnecting => 'Conectando…';

  @override
  String get watchStreamWaitingBroadcaster => 'Esperando al transmisor…';

  @override
  String get watchStreamSpectatorChat => 'CHAT DE ESPECTADORES';

  @override
  String get watchStreamChatUnavailable => 'Chat no disponible';

  @override
  String get watchStreamChatEmpty => '¡Sé el primero en comentar!';

  @override
  String get watchStreamChatHint => 'Escribe un mensaje…';

  @override
  String get watchStreamLiveBadge => 'EN VIVO';

  @override
  String bannedLoadStateError(Object error) {
    return 'No se pudo cargar el estado de la solicitud: $error';
  }

  @override
  String cguWhatsappLabel(Object dialCode) {
    return 'WHATSAPP ($dialCode)';
  }

  @override
  String cguWhatsappHelper(Object dialCode) {
    return 'El código de país $dialCode se agrega automáticamente.';
  }

  @override
  String cguConsentRequiredSuffix(Object title) {
    return '$title *';
  }

  @override
  String linkAccountEmailLineNoEmail(Object providerLabel) {
    return 'El correo de esta cuenta $providerLabel ya está en uso por una cuenta ARENA.';
  }

  @override
  String linkAccountEmailLineWithEmail(Object email) {
    return '$email ya está en uso por una cuenta ARENA (contraseña).';
  }

  @override
  String registerStepperTitle(Object step) {
    return 'Paso $step / 3';
  }

  @override
  String registerWhatsappLabel(Object dialCode) {
    return 'WHATSAPP ($dialCode)';
  }

  @override
  String registerWhatsappHelper(Object dialCode) {
    return 'El código de país $dialCode se agrega automáticamente.';
  }

  @override
  String bracketCaption(Object playerCount) {
    return 'ELIMINACIÓN DIRECTA · $playerCount JUGADORES';
  }

  @override
  String referralCardDescription(Object referralQuota) {
    return 'Debes recomendar a $referralQuota amigo(s) para inscribirte en esta competencia gratuita. Comparte tu código con ellos para que creen su cuenta ARENA.';
  }

  @override
  String referralProgressError(Object error) {
    return 'No se pudo verificar tu progreso: $error';
  }

  @override
  String referralFriendsRemaining(Object count) {
    return 'Faltan $count amigo(s) por recomendar';
  }

  @override
  String referralCodeCopied(Object code) {
    return 'Código $code copiado al portapapeles';
  }

  @override
  String referralShareMessage(Object code) {
    return '¡Únete a mí en ARENA! Torneos de e-sports móviles gratuitos con premios. Usa mi código de referido al registrarte: $code';
  }

  @override
  String liveStreamsOthersCount(Object count) {
    return '+$count más';
  }

  @override
  String pendingPaymentMultipleTitle(Object count) {
    return '$count pagos pendientes';
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
    return 'EN ${hours}H';
  }

  @override
  String upcomingBadgeInDays(Object days) {
    return 'EN ${days}D';
  }

  @override
  String upcomingPhaseRound(Object round) {
    return 'Ronda $round';
  }

  @override
  String matchRoomTitleNumbered(Object number) {
    return 'PARTIDO #$number';
  }

  @override
  String manualUploadFailure(Object message) {
    return 'Error: $message';
  }

  @override
  String manualUploadError(Object error) {
    return 'Error: $error';
  }

  @override
  String outcomeWinner(Object winner) {
    return 'Ganador: Jugador $winner…';
  }

  @override
  String outcomeResubmitError(Object error) {
    return 'No se pudo reenviar: $error';
  }

  @override
  String outcomeScoreShootout(Object pen1, Object pen2) {
    return 'PEN $pen1 — $pen2';
  }

  @override
  String matchHeaderSelfSuffix(Object username) {
    return '$username · TÚ';
  }

  @override
  String recordingLiveStreamError(Object error) {
    return 'No se pudo iniciar la transmisión: $error';
  }

  @override
  String recordingPermBundleNeedsSettings(Object list) {
    return 'Permite $list en Ajustes > Aplicaciones > ARENA';
  }

  @override
  String recordingPermBundleDenied(Object list) {
    return 'Permiso $list denegado — vuelve a tocar ESTOY EN LA SALA';
  }

  @override
  String recordingBannerUnavailable(Object error) {
    return 'Grabación no disponible — $error\nToca aquí para reintentar.';
  }

  @override
  String notificationsTimeMinutesAgo(Object minutes) {
    return 'Hace $minutes min';
  }

  @override
  String notificationsTimeHoursAgo(Object hours) {
    return 'Hace $hours h';
  }

  @override
  String mobileMoneyDialHelp(Object method) {
    return 'Marca este código en tu $method, paga el monto exacto y luego vuelve aquí para tocar \"YA PAGUÉ\".';
  }

  @override
  String deleteAccountStepCaption(Object stepNum, Object stepLabel) {
    return 'PASO $stepNum/04 · $stepLabel';
  }

  @override
  String deleteAccountCheckErrorNote(Object checkError) {
    return 'Nota: verificación no concluyente (tabla no disponible). Detalle: $checkError';
  }

  @override
  String deleteAccountTypeToConfirmLabel(Object confirmWord) {
    return 'Escribe \"$confirmWord\" para confirmar';
  }

  @override
  String editProfileWhatsappCaption(Object dialCode) {
    return 'WHATSAPP ($dialCode)';
  }

  @override
  String editProfileWhatsappHelper(Object dialCode) {
    return 'El código de país $dialCode se agrega automáticamente.';
  }

  @override
  String friendsErrorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String friendsRemoveDialogTitle(Object username) {
    return '¿Eliminar a $username?';
  }

  @override
  String friendsAcceptedSnack(Object username) {
    return '$username ahora es tu amigo';
  }

  @override
  String friendsUnblockedSnack(Object username) {
    return '$username desbloqueado';
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
    return 'Estadísticas no disponibles ($error)';
  }

  @override
  String playerProfileMatchRowError(Object error) {
    return 'Error: $error';
  }

  @override
  String playerProfileFriendsCountSingular(Object friendsCount) {
    return '$friendsCount amigo';
  }

  @override
  String playerProfileFriendsCountPlural(Object friendsCount) {
    return '$friendsCount amigos';
  }

  @override
  String playerProfileReferralCountSingular(Object count) {
    return '$count invitado';
  }

  @override
  String playerProfileReferralCountPlural(Object count) {
    return '$count invitados';
  }

  @override
  String publicProfileError(Object error) {
    return 'Error: $error';
  }

  @override
  String publicProfileRequestSent(Object username) {
    return 'Solicitud enviada a $username';
  }

  @override
  String publicProfileNowFriend(Object username) {
    return '$username ahora es tu amigo';
  }

  @override
  String publicProfileRemoveConfirmTitle(Object username) {
    return '¿Eliminar a $username?';
  }

  @override
  String publicProfileBlockConfirmTitle(Object username) {
    return '¿Bloquear a $username?';
  }

  @override
  String publicProfileWinRateValue(Object pct, Object total) {
    return '$pct% ($total partidos)';
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
    return 'No se pudo exportar: $error';
  }

  @override
  String settingsExportFileLabel(Object sizeKb) {
    return 'Archivo ($sizeKb KB):';
  }

  @override
  String startStreamingErrorSnack(Object error) {
    return 'Error: $error';
  }

  @override
  String watchStreamFailed(Object reason) {
    return 'Error: $reason';
  }

  @override
  String watchStreamChatSendError(Object error) {
    return 'Error al enviar: $error';
  }

  @override
  String watchStreamViewersWatching(Object viewers) {
    return '$viewers viendo';
  }

  @override
  String get authErrInvalidCredentials => 'Email o contraseña incorrectos.';

  @override
  String get authErrEmailAlreadyRegistered =>
      'Ya existe una cuenta con este email.';

  @override
  String get authErrWeakPassword =>
      'Contraseña demasiado débil: mínimo 8 caracteres.';

  @override
  String get authErrEmailNotConfirmed =>
      'Confirma tu registro con el enlace que recibiste por email.';

  @override
  String get authErrUserBanned =>
      'Esta cuenta está suspendida. Contacta con soporte.';

  @override
  String get authErrWrongApp =>
      'Esta cuenta es de administrador. Usa la aplicación ARENA Admin.';

  @override
  String get authErrNetwork =>
      'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.';

  @override
  String get authErrRateLimited =>
      'Demasiados intentos. Inténtalo de nuevo en unos minutos.';

  @override
  String get authErrInvalidInvitation =>
      'Código de invitación inválido, expirado o ya utilizado.';

  @override
  String get authErrInvalidTotp => 'Código de 6 dígitos incorrecto.';

  @override
  String get authErrTotpReplay =>
      'Este código ya fue utilizado. Espera el siguiente.';

  @override
  String get authErrAdminLocked =>
      'Cuenta bloqueada tras 3 intentos. Inténtalo de nuevo en 30 minutos.';

  @override
  String get authErrBackendUnavailable =>
      'Servicio momentáneamente no disponible. Inténtalo más tarde.';

  @override
  String get authErrUsernameTaken =>
      'Este nombre de usuario ya está en uso. Elige otro.';

  @override
  String get authErrSsoCancelled => 'Conexión cancelada.';

  @override
  String get authErrSsoIdToken =>
      'No se pudo conectar. Verifica tu red e inténtalo de nuevo.';

  @override
  String get authErrSsoConfig =>
      'Conexión no disponible por el momento. Contacta con soporte.';

  @override
  String get authErrInvalidResetCode => 'Código incorrecto. Verifica tu email.';

  @override
  String get authErrExpiredResetCode =>
      'Código expirado. Solicita un nuevo código.';

  @override
  String get authErrUnknown => 'Ocurrió un error. Inténtalo de nuevo.';

  @override
  String get matchStepCodeRoom => 'Código de sala';

  @override
  String get matchStepOpponentJoining => 'El rival se une';

  @override
  String get matchStepInProgress => 'Partido en curso';

  @override
  String get matchStepResult => 'Resultado';

  @override
  String get activeCompetitionsEmpty =>
      'No hay competiciones activas para este filtro.';

  @override
  String get myTournamentsEmpty => 'Aún no te has inscrito a ningún torneo.';

  @override
  String get myTournamentsBrowseCta => 'Explorar torneos';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterFree => 'Gratuitas';

  @override
  String get filterPaid => 'De pago';

  @override
  String get filterUpcoming => 'Próximas';

  @override
  String get filterOngoing => 'En curso';

  @override
  String get filterCompleted => 'Finalizadas';

  @override
  String get statusToReprogram => 'Por reprogramar';

  @override
  String get compFormatSingleElim => 'Eliminación directa';

  @override
  String get compFormatGroupsKnockout => 'Grupos + eliminación';

  @override
  String get compFormatRoundRobin => 'Todos contra todos';

  @override
  String get matchStepWord => 'ETAPA';

  @override
  String get paymentOptionsMissing =>
      'El pago aún no está configurado para esta competición. Contacta con el organizador.';

  @override
  String get countryPickTitle => 'Elige tu país';

  @override
  String get countryPickSubtitle =>
      'Selecciona el país desde el que vas a pagar.';

  @override
  String get countryPickConfirm => 'CONTINUAR';

  @override
  String get countryPickCancel => 'Cancelar';

  @override
  String get countryStepTitle => 'País';

  @override
  String get countryOrganizerLabel => 'País organizador';

  @override
  String get countryOrganizerHint =>
      'Se usa para el alcance de administración por país. No afecta a los países habilitados para el pago.';

  @override
  String get countryPaymentSectionTitle => 'Opciones de pago por país';

  @override
  String get countryPaymentSectionHint =>
      'Para cada país habilitado, agrega uno o más operadores (Orange Money, MTN MoMo, Wave…) con su código de transferencia. El jugador elige su país y luego un operador al momento de pagar.';

  @override
  String get countryFreeNote =>
      'Competición gratuita: no se necesita ninguna configuración de pago. Solo se requiere el país organizador.';

  @override
  String get countryOperatorNameLabel => 'Nombre del operador';

  @override
  String get countryOperatorNameHint => 'ej. Orange Money';

  @override
  String get countryTransferCodeLabel => 'Código de transferencia';

  @override
  String get countryTransferCodeHint => 'ej. *126*1*001234#';

  @override
  String get countryAddOperator => 'Agregar un operador';

  @override
  String get countryRemoveOperator => 'Eliminar el operador';

  @override
  String get countryAddCountry => 'Agregar un país';

  @override
  String get countryRemoveCountry => 'Eliminar este país';

  @override
  String get countryChooseCountry => 'Elegir un país';

  @override
  String get countrySaveOperator => 'Guardar este operador';

  @override
  String countryOperatorTemplatesButton(int count) {
    return 'Mis operadores ($count)';
  }

  @override
  String get countryOperatorSavedToast => 'Operador guardado como modelo.';

  @override
  String get countryOperatorEmptyToast =>
      'Completa el nombre y el código del operador antes de guardar.';

  @override
  String get countryValidationNeedOne =>
      'Activa al menos un país y completa cada operador (nombre + código).';

  @override
  String get adminScopeRestrictionsTitle => 'RESTRICCIONES (opcional)';

  @override
  String get adminScopeRestrictionsHint =>
      'Limita a este futuro administrador a ciertos países y/o secciones. Deja en blanco para acceso completo.';

  @override
  String get adminScopeCountriesLabel => 'Países autorizados';

  @override
  String get adminScopeSectionsLabel => 'Secciones autorizadas';

  @override
  String get adminScopeAllCountries => 'Todos los países';

  @override
  String get adminScopeAllSections => 'Todas las secciones';

  @override
  String adminScopePerimeterBanner(String countries) {
    return 'Alcance: $countries';
  }

  @override
  String get adminScopeOutOfPerimeter => 'Acción fuera de tu alcance.';
}
