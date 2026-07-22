package com.arena.arena

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.util.DisplayMetrics
import android.util.Log
import android.view.Surface
import android.view.WindowManager
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import java.io.File

/**
 * Foreground service that hosts the MediaProjection + encoder for the
 * anti-cheat screen recording. Replaces the upstream
 * `flutter_screen_recording` plugin so we can pick our own
 * resolution / bitrate / framerate.
 *
 * PROFIL ALLÉGÉ UNIFORME (toute la flotte, cible ≈45 MB / 25 min — upload
 * mobile money-friendly ET livrable dans une fenêtre background étroite) :
 *   360p (axe court, ratio préservé), 240 kbps H.264, 24 fps. 360p + 240 kbps
 *   gardent le HUD (score, chrono) BIEN lisible pour l'arbitrage ; 24 fps
 *   fluidifie la relecture d'un eFootball / Jeu de Dames.
 *
 * ENCODEUR + FILET DE SÉCURITÉ (uniforme sur toute la flotte) :
 *   * PRIMAIRE : [CodecScreenRecorder] (MediaCodec en CBR) sur TOUS les
 *     appareils. Beaucoup d'encodeurs matériels IGNORENT le
 *     `setVideoEncodingBitRate` de MediaRecorder (VBR → fichier plusieurs ×
 *     trop lourd) — pas seulement les Redmi : observé aussi sur un Samsung
 *     SM8350 (Snapdragon 888), ~147 MB pour une cible 160 kbps. CBR force le
 *     débit constant → poids prédictible (~30 MB / 25 min).
 *   * FILET : si l'init MediaCodec échoue (CBR non supporté sur une puce
 *     ancienne/bas de gamme, dimensions refusées…), on RETOMBE sur
 *     MediaRecorder — une preuve plus lourde vaut mieux qu'aucune preuve.
 *
 * Lifecycle:
 *   START intent (with MediaProjection result) → setup + start.
 *   STOP intent → stop, release, publish path, exit foreground.
 *
 * Result handoff: the activity calls [requestStopAndDrain] which
 * stashes a one-shot callback. Once the service has finalised the
 * MP4 and released the recorder it invokes the callback with the
 * absolute file path. Si `MediaRecorder.stop()` throw (état interne
 * cassé, projection morte avant le drain final), le moov atom du
 * MP4 n'est PAS écrit en fin de fichier — un player normal ne lit
 * alors que les ~10 premières secondes bufferisées. Dans ce cas on
 * publie `null` au lieu du path pour ne pas exposer un fichier
 * inutilisable comme "replay sauvegardé".
 */
class ArenaRecorderService : Service() {

    companion object {
        private const val TAG = "ArenaRecorder"
        private const val CHANNEL_ID = "arena_recorder"
        private const val NOTIF_ID = 1101

        const val ACTION_START = "com.arena.arena.recorder.START"
        const val ACTION_STOP = "com.arena.arena.recorder.STOP"
        // Tap « Arrêter » sur la notif : ne tear-down PAS directement — signale
        // Dart pour que le COORDINATOR orchestre l'arrêt (recording + notif +
        // bouton flottant fermés ensemble). Symétrique au bouton flottant, qui
        // passe déjà par coordinator.stopCleanly(). Cf. LiveKit onStopRequested.
        const val ACTION_STOP_REQUESTED = "com.arena.arena.recorder.STOP_REQUESTED"
        // Échange du code room via la notification (repli Pixel 9 du panneau
        // overlay). Une SEULE pastille cyan, selon le rôle :
        //   * HOME (domicile) ENVOIE → ouvre RoomCodeInputActivity (mini-dialogue).
        //     Reste disponible APRÈS l'envoi (« Renvoyer ») : recréer une room
        //     dans eFootball change le code, le HOME doit pouvoir le repousser.
        //   * AWAY (extérieur) REÇOIT le code → « Copier ».
        const val ACTION_SUBMIT_CODE = "com.arena.arena.recorder.SUBMIT_CODE"
        const val ACTION_COPY_CODE = "com.arena.arena.recorder.COPY_CODE"
        const val ACTION_UPDATE_CODE = "com.arena.arena.recorder.UPDATE_CODE"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        const val EXTRA_FILENAME = "filename"
        const val EXTRA_TITLE = "title"
        const val EXTRA_MESSAGE = "message"
        const val EXTRA_ROOM_CODE = "room_code"
        // Rôle du joueur : le HOME envoie le code, l'AWAY le reçoit. C'est bien
        // le RÔLE, pas « il manque un code » — le HOME garde l'envoi une fois le
        // code partagé, pour pouvoir le renvoyer.
        const val EXTRA_IS_HOME = "is_home"
        // Code saisi par le HOME dans RoomCodeInputActivity.
        const val EXTRA_TYPED_CODE = "typed_code"

        // Étape B — score saisi dans ScoreInputActivity (bouton « Score » de la
        // notif). Renvoyé au service (ACTION_SUBMIT_SCORE) qui forwarde à Dart.
        const val ACTION_SUBMIT_SCORE = "com.arena.arena.recorder.SUBMIT_SCORE"
        const val EXTRA_SCORE_MY = "score_my"
        const val EXTRA_SCORE_OPP = "score_opp"
        const val EXTRA_SCORE_VIA_PEN = "score_via_pen"
        const val EXTRA_SCORE_PEN_MY = "score_pen_my"
        const val EXTRA_SCORE_PEN_OPP = "score_pen_opp"

        // Callback : le HOME a tapé le code depuis la notif (mini-dialogue).
        // Set par MainActivity ; forwardé à Dart (→ écrit matches.room_code).
        @Volatile
        var onRoomCodeSubmitted: ((String) -> Unit)? = null

        // Callback : score saisi dans ScoreInputActivity (Étape B). Set par
        // MainActivity ; forwardé à Dart → même chemin que le score de l'overlay
        // (mappe selon le rôle, soumet + scelle la vidéo). Args : my, opp,
        // viaPenalties, myPen?, oppPen?.
        @Volatile
        var onScoreSubmitted: ((Int, Int, Boolean, Int?, Int?) -> Unit)? = null

        // Callback : l'utilisateur a tapé « Arrêter » sur la notif. Set par
        // MainActivity ; forwardé à Dart → coordinator.stopCleanly() (arrêt
        // COORDONNÉ des deux surfaces). Si Dart ne répond pas, ACTION_STOP
        // reste dispo comme filet (stop système MediaProjection).
        @Volatile
        var onStopRequested: (() -> Unit)? = null

        // Prefs du repli encodeur : mémorise qu'un modèle a déjà DÉPASSÉ sa
        // cible de débit avec l'encodeur matériel → on force l'encodeur logiciel
        // aux captures suivantes (auto-réparation, persiste entre sessions).
        private const val PREFS = "arena_recorder"
        private const val KEY_FORCE_SW = "force_sw_encoder"

        // Télémétrie : invoqué à l'arrêt quand le débit RÉEL du fichier dépasse
        // largement la cible (encodeur qui dérive). Set par MainActivity →
        // poussé à Dart (EventChannel) → Sentry. Rend visibles en PROD les
        // modèles fautifs sans avoir à les posséder. Payload : model, encoder,
        // targetKbps, actualKbps, sizeBytes, durationMs, switchedToSoftware.
        @Volatile
        var onRecorderDrift: ((Map<String, Any?>) -> Unit)? = null

        // True while the foreground service is hosting a recording.
        @Volatile
        var isActive: Boolean = false
            private set

        // Last finalised output path. Cleared by [requestStopAndDrain]
        // once consumed.
        @Volatile
        private var lastOutputPath: String? = null

        // Pending callback fired by the service when the recording is
        // fully torn down and the MP4 is closed on disk.
        @Volatile
        private var pendingDrain: ((String?) -> Unit)? = null

        // Fired when the MediaProjection dies (system "Stop" notif tap or
        // permission revoked). Set by MainActivity once the Flutter engine
        // is configured. Lets Dart libère Agora (qui détient un AudioRecord
        // sur la même projection) — sinon boucle infinie AudioFlinger -22.
        @Volatile
        var onProjectionDied: (() -> Unit)? = null

        /**
         * Registers a callback that fires when the service finishes
         * stopping and the MP4 file is finalised. If the service
         * isn't running, fires immediately with the last known path.
         */
        fun requestStopAndDrain(callback: (String?) -> Unit) {
            if (!isActive) {
                // Nothing to wait for — either we never started or
                // the recording already stopped. Hand back whatever
                // path we last published.
                val path = lastOutputPath
                lastOutputPath = null
                Handler(Looper.getMainLooper()).post { callback(path) }
                return
            }
            pendingDrain = callback
        }

        internal fun publishOutput(path: String?) {
            lastOutputPath = path
            val cb = pendingDrain
            pendingDrain = null
            if (cb != null) {
                Handler(Looper.getMainLooper()).post {
                    cb(path)
                    lastOutputPath = null
                }
            }
        }
    }

    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var mediaRecorder: MediaRecorder? = null
    // Chemin MediaCodec CBR (encodeur primaire) — alternatif à mediaRecorder.
    private var codecRecorder: CodecScreenRecorder? = null
    private var outputPath: String? = null
    // Horodatage de départ pour le chrono de la notif (compteur d'enregistrement
    // qui s'incrémente tout seul via setUsesChronometer — pas de re-post/s).
    private var recordStartMillis: Long = 0L
    // Titre/texte courants de la notif (mémorisés pour la reconstruire quand
    // l'état du code room change, sans re-passer par ACTION_START).
    private var notifTitle: String = "ARENA"
    private var notifMessage: String = "Enregistrement en cours"
    // Code room courant : celui que le HOME a envoyé, ou celui que l'AWAY a reçu.
    private var roomCode: String? = null
    // Vrai côté HOME (celui qui crée la room et ENVOIE le code).
    private var isHome: Boolean = false
    // Cible de débit demandée (kbps×1000) + encodeur réellement utilisé +
    // si on forçait déjà le logiciel — mémorisés au démarrage pour la
    // détection de dérive à l'arrêt (teardown).
    private var targetBitRate: Int = 240_000
    private var usedEncoderName: String = ""
    private var forcedSoftware: Boolean = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                Log.d(TAG, "ACTION_STOP received")
                teardown()
                stopForegroundCompat()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_STOP_REQUESTED -> {
                // Tap « Arrêter » sur la notif → on laisse le COORDINATOR Dart
                // orchestrer (il appellera ACTION_STOP + fermera le bouton
                // flottant). On ne tear-down PAS ici pour garder un seul chemin.
                // On RAMÈNE aussi ARENA au premier plan : le joueur qui arrête
                // depuis eFootball veut revenir dans l'app (envoyer son score…).
                Log.d(TAG, "ACTION_STOP_REQUESTED — bring to front + deferring to Dart")
                try {
                    startActivity(
                        Intent(applicationContext, MainActivity::class.java).apply {
                            addFlags(
                                Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
                            )
                        },
                    )
                } catch (e: Exception) {
                    Log.w(TAG, "bring to front on stop failed", e)
                }
                try { onStopRequested?.invoke() } catch (_: Exception) {}
                return START_STICKY
            }
            ACTION_START -> {
                val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
                @Suppress("DEPRECATION")
                val resultData: Intent? = intent.getParcelableExtra(EXTRA_RESULT_DATA)
                val filename = intent.getStringExtra(EXTRA_FILENAME) ?: "match"
                val title = intent.getStringExtra(EXTRA_TITLE) ?: "ARENA"
                val message = intent.getStringExtra(EXTRA_MESSAGE)
                    ?: "Enregistrement en cours"
                if (resultData == null) {
                    Log.w(TAG, "ACTION_START missing result data")
                    stopSelf()
                    return START_NOT_STICKY
                }
                recordStartMillis = System.currentTimeMillis()
                notifTitle = title
                notifMessage = message
                startForegroundCompat(title, message)
                try {
                    startRecording(resultCode, resultData, filename)
                    isActive = true
                } catch (e: Exception) {
                    Log.w(TAG, "startRecording failed", e)
                    teardown()
                    stopForegroundCompat()
                    stopSelf()
                    return START_NOT_STICKY
                }
                return START_STICKY
            }
            ACTION_SUBMIT_CODE -> {
                // HOME a validé le mini-dialogue → récupère le texte tapé.
                // On garde `isHome` : le code d'une room recréée change, le HOME
                // doit pouvoir le RENVOYER autant de fois que nécessaire.
                val typed = intent.getStringExtra(EXTRA_TYPED_CODE)?.trim()
                if (!typed.isNullOrEmpty()) {
                    roomCode = typed
                    try { onRoomCodeSubmitted?.invoke(typed) } catch (_: Exception) {}
                    refreshNotification()
                }
                return START_STICKY
            }
            ACTION_SUBMIT_SCORE -> {
                // Étape B — score validé dans ScoreInputActivity. On forwarde à
                // Dart, qui mappe selon le rôle, SOUMET le score et SCELLE la
                // vidéo (même chemin que le score de l'overlay). Le natif ne
                // stoppe PAS lui-même : Dart orchestre (submit → stopCleanly).
                val my = intent.getIntExtra(EXTRA_SCORE_MY, -1)
                val opp = intent.getIntExtra(EXTRA_SCORE_OPP, -1)
                if (my in 0..99 && opp in 0..99) {
                    val viaPen = intent.getBooleanExtra(EXTRA_SCORE_VIA_PEN, false)
                    val penMy = if (viaPen) intent.getIntExtra(EXTRA_SCORE_PEN_MY, -1) else -1
                    val penOpp = if (viaPen) intent.getIntExtra(EXTRA_SCORE_PEN_OPP, -1) else -1
                    try {
                        onScoreSubmitted?.invoke(
                            my, opp, viaPen,
                            penMy.takeIf { it >= 0 },
                            penOpp.takeIf { it >= 0 },
                        )
                    } catch (_: Exception) {}
                }
                return START_STICKY
            }
            ACTION_COPY_CODE -> {
                // AWAY a tapé « Copier » → code dans le presse-papier.
                val code = roomCode
                if (!code.isNullOrEmpty()) {
                    try {
                        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        cm.setPrimaryClip(ClipData.newPlainText("Code room", code))
                    } catch (e: Exception) {
                        Log.w(TAG, "copy room code failed", e)
                    }
                }
                return START_STICKY
            }
            ACTION_UPDATE_CODE -> {
                // Dart pousse l'état du code : le rôle (isHome) + le code courant
                // lu en base. On reconstruit juste la notif.
                // Si aucun enregistrement n'est en cours, ne PAS laisser un
                // service non-foreground zombie → stopSelf.
                if (!isActive) {
                    stopSelf()
                    return START_NOT_STICKY
                }
                roomCode = intent.getStringExtra(EXTRA_ROOM_CODE)
                isHome = intent.getBooleanExtra(EXTRA_IS_HOME, false)
                refreshNotification()
                return START_STICKY
            }
            else -> {
                Log.w(TAG, "unknown intent action: ${intent?.action}")
                stopSelf()
                return START_NOT_STICKY
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        teardown()
        super.onDestroy()
    }

    private fun startRecording(resultCode: Int, resultData: Intent, filename: String) {
        val pm = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val proj = pm.getMediaProjection(resultCode, resultData)
            ?: throw IllegalStateException("getMediaProjection returned null")
        projection = proj

        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        (getSystemService(Context.WINDOW_SERVICE) as WindowManager)
            .defaultDisplay.getRealMetrics(metrics)
        val realW = metrics.widthPixels
        val realH = metrics.heightPixels
        val density = metrics.densityDpi
        if (realW <= 0 || realH <= 0) {
            throw IllegalStateException("display dimensions invalid")
        }

        // Profil d'encodage ALLÉGÉ, UNIFORME sur toute la flotte :
        //   360p / 240 kbps / 24 fps → ≈45 MB pour 25 min (upload mobile-
        //   friendly). 360p + 240 kbps gardent le HUD (score, chrono) BIEN lisible
        //   pour l'arbitrage ; 24 fps fluidifie la relecture d'un eFootball.
        val targetShort = 360
        val videoBitRate = 240_000
        val videoFps = 24

        // Cible `targetShort` sur l'axe COURT, ratio préservé, dimensions
        // alignées sur un multiple de 16 (contrainte encodeur H.264).
        val shorter = minOf(realW, realH)
        val scale = targetShort.toDouble() / shorter
        val outW = ((realW * scale).toInt()) and -16
        val outH = ((realH * scale).toInt()) and -16
        // Log.i (PAS Log.d : strippé en release par proguard-android-optimize).
        Log.i(
            TAG,
            "recording at ${outW}x${outH} @ ${videoBitRate / 1000}kbps/${videoFps}fps " +
                "(screen ${realW}x${realH} @ ${density}dpi, " +
                "${Build.MANUFACTURER}/${Build.MODEL})",
        )

        val outFile = File(externalCacheDir ?: cacheDir, "$filename.mp4")
        outputPath = outFile.absolutePath

        // Encodeur → Surface d'entrée pour le VirtualDisplay.
        // PRIMAIRE : MediaCodec CBR sur TOUS les appareils. De nombreux encodeurs
        // matériels IGNORENT le `setVideoEncodingBitRate` de MediaRecorder (VBR →
        // fichier plusieurs × trop lourd) — pas seulement les Redmi : observé sur
        // un Samsung SM8350 (Snapdragon 888), où MediaRecorder à 160 kbps produit
        // ~147 MB pour 25 min. CBR force le débit constant → poids prédictible
        // (~30 MB) partout.
        // FILET : si l'init MediaCodec échoue (CBR non supporté sur une puce
        // ancienne/bas de gamme, dimensions refusées…), on retombe sur
        // MediaRecorder — une preuve plus lourde vaut mieux qu'aucune preuve.
        // Mémorise la cible pour la détection de dérive à l'arrêt (teardown).
        targetBitRate = videoBitRate
        // Repli auto : ce modèle a-t-il DÉJÀ dépassé sa cible avec l'encodeur
        // matériel lors d'une capture précédente ? Si oui, on force le logiciel.
        forcedSoftware = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(KEY_FORCE_SW, false)

        var codecSurface: Surface? = null
        try {
            val cr = CodecScreenRecorder()
            codecSurface = cr.start(
                outW, outH, videoBitRate, videoFps, outFile.absolutePath,
                forceSoftware = forcedSoftware,
            )
            codecRecorder = cr
            usedEncoderName = cr.encoderName
        } catch (e: Exception) {
            Log.w(TAG, "MediaCodec CBR init failed — fallback MediaRecorder", e)
            codecRecorder = null
            usedEncoderName = "MediaRecorder"
        }
        val encoderSurface: Surface = codecSurface
            ?: buildMediaRecorder(outW, outH, videoBitRate, videoFps, outFile.absolutePath)
        Log.i(TAG, "encoder = ${if (codecSurface != null) "MediaCodec" else "MediaRecorder (fallback)"}")

        // Le VirtualDisplay doit rendre AUX dimensions réellement configurées par
        // l'encodeur : CodecScreenRecorder a pu ajuster outW/outH aux contraintes
        // de la puce (alignement/bornes). En fallback MediaRecorder, on garde les
        // dimensions demandées (setVideoSize les a acceptées).
        val cr = codecRecorder
        val dispW = if (cr != null && cr.configuredWidth > 0) cr.configuredWidth else outW
        val dispH = if (cr != null && cr.configuredHeight > 0) cr.configuredHeight else outH

        proj.registerCallback(
            object : MediaProjection.Callback() {
                override fun onStop() {
                    Log.d(TAG, "MediaProjection.onStop — tearing down")
                    Handler(Looper.getMainLooper()).post {
                        // Notify Dart first — Agora detains an AudioRecord
                        // sur cette projection, sans leave() côté Dart son
                        // thread interne retry en boucle (AudioFlinger -22).
                        try { onProjectionDied?.invoke() } catch (_: Exception) {}
                        teardown()
                        stopForegroundCompat()
                        stopSelf()
                    }
                }
            },
            Handler(Looper.getMainLooper())
        )

        virtualDisplay = proj.createVirtualDisplay(
            "ArenaRecorder",
            dispW, dispH, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            encoderSurface,
            null, null
        )

        // MediaRecorder (fallback) démarre son encodage ici ; le MediaCodec
        // primaire tourne déjà (drain lancé dans CodecScreenRecorder.start()).
        mediaRecorder?.start()
        Log.d(TAG, "recording started: ${outFile.absolutePath}")
    }

    /**
     * Construit et prépare un [MediaRecorder] H.264 SURFACE selon le profil,
     * le stocke dans [mediaRecorder] et renvoie sa Surface d'entrée. Utilisé sur
     * comme filet de secours si l'init MediaCodec CBR échoue (cf.
     * [startRecording]).
     */
    private fun buildMediaRecorder(
        outW: Int,
        outH: Int,
        videoBitRate: Int,
        videoFps: Int,
        path: String,
    ): Surface {
        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(applicationContext)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        recorder.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        recorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
        recorder.setVideoSize(outW, outH)
        recorder.setVideoEncodingBitRate(videoBitRate)
        recorder.setVideoFrameRate(videoFps)
        recorder.setOutputFile(path)
        recorder.prepare()
        mediaRecorder = recorder
        return recorder.surface
    }

    private fun teardown() {
        val path = outputPath
        // Ordre critique pour que `MediaRecorder.stop()` finalise
        // proprement le moov atom MP4 :
        //   1. release du VirtualDisplay → l'encoder n'a plus de
        //      frames entrantes et peut draîner son buffer
        //   2. stop du MediaRecorder → écrit le moov atom en fin
        //      de fichier (sinon le MP4 reste illisible au-delà
        //      de la dernière keyframe, ~10 s typique)
        //   3. release du MediaRecorder
        //   4. stop de la MediaProjection (dernière)
        // L'ancien ordre (recorder.stop d'abord, virtualDisplay
        // après) provoquait IllegalStateException quand l'encoder
        // était encore alimenté → moov non écrit → file inutilisable.
        try { virtualDisplay?.release() } catch (_: Exception) {}
        virtualDisplay = null

        var stopSucceeded = false
        val cr = codecRecorder
        if (cr != null) {
            // Chemin MediaCodec CBR (primaire) : stop() signale l'EOS, laisse le
            // drain écrire le moov, puis relâche codec + muxer.
            stopSucceeded = try {
                cr.stop()
            } catch (e: Exception) {
                Log.w(TAG, "CodecScreenRecorder.stop() threw", e)
                false
            }
            codecRecorder = null
        } else {
            try {
                mediaRecorder?.stop()
                stopSucceeded = true
            } catch (e: Exception) {
                Log.w(TAG, "mediaRecorder.stop() threw — moov atom NOT written, file is truncated", e)
            }
            try { mediaRecorder?.release() } catch (_: Exception) {}
            mediaRecorder = null
        }

        try { projection?.stop() } catch (_: Exception) {}
        projection = null
        outputPath = null
        isActive = false

        // Si stop() a échoué, le file existe sur disque mais le
        // moov atom MP4 manque — un player ne lira que les ~10 s
        // bufferisées. Ne pas le publier comme "replay sauvegardé"
        // pour ne pas duper l'utilisateur ; lui afficher le snackbar
        // de fallback "Replay disponible dans le cache" via path null.
        val finalPath = if (stopSucceeded) {
            path?.takeIf { File(it).exists() && File(it).length() > 0 }
        } else {
            // Supprime le file corrompu pour libérer le cache.
            try { path?.let { File(it).delete() } } catch (_: Exception) {}
            null
        }
        maybeReportBitrateDrift(finalPath)
        publishOutput(finalPath)
    }

    /**
     * DÉTECTION DE DÉRIVE DE DÉBIT (robustesse prod). Certains encodeurs
     * matériels ne respectent pas la cible CBR (observé Samsung SD888 : ×4–9).
     * On mesure le débit RÉEL du fichier fini et, s'il dépasse largement la
     * cible, on (1) REMONTE une télémétrie (→ Sentry via Dart) pour repérer le
     * modèle fautif en prod, et (2) ACTIVE le repli encodeur LOGICIEL pour les
     * captures suivantes (auto-réparation persistante). Ne lève jamais.
     */
    private fun maybeReportBitrateDrift(path: String?) {
        if (path == null) return
        try {
            val sizeBytes = File(path).length()
            val durMs = System.currentTimeMillis() - recordStartMillis
            // Trop court / vide → non significatif (overhead conteneur domine).
            if (durMs < 3000 || sizeBytes <= 0) return
            // bits / ms = kbits/s = kbps.
            val actualKbps = (sizeBytes * 8 / durMs).toInt()
            val targetKbps = targetBitRate / 1000
            // Seuil > 2× la cible = dérive nette (le cas Samsung sortait à 4–9×).
            // En dessous : variance normale (audio, overhead) → on ne fait rien.
            if (actualKbps <= targetKbps * 2) return

            // Auto-réparation : si on n'était pas déjà en logiciel, on l'active
            // pour les prochaines captures de ce modèle (persistant entre runs).
            val switched = !forcedSoftware
            if (switched) {
                getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                    .putBoolean(KEY_FORCE_SW, true).apply()
            }
            Log.w(
                TAG,
                "bitrate drift: ${actualKbps}kbps vs target ${targetKbps}kbps " +
                    "(${Build.MANUFACTURER}/${Build.MODEL}, enc=$usedEncoderName, " +
                    "switchedToSoftware=$switched)",
            )
            onRecorderDrift?.invoke(
                mapOf(
                    "model" to "${Build.MANUFACTURER}/${Build.MODEL}",
                    "encoder" to usedEncoderName,
                    "targetKbps" to targetKbps,
                    "actualKbps" to actualKbps,
                    "sizeBytes" to sizeBytes,
                    "durationMs" to durMs,
                    "switchedToSoftware" to switched,
                ),
            )
        } catch (_: Exception) {
            // Télémétrie best-effort : ne jamais casser le teardown.
        }
    }

    // Flags PendingIntent : FLAG_IMMUTABLE est OBLIGATOIRE sur Android 12+ (S)
    // pour tout PendingIntent non explicitement mutable.
    private fun pendingFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }

    private fun startForegroundCompat(title: String, message: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (mgr.getNotificationChannel(CHANNEL_ID) == null) {
                mgr.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "ARENA recorder",
                        NotificationManager.IMPORTANCE_LOW
                    ).apply {
                        description = "Enregistrement anti-triche en cours"
                    }
                )
            }
        }
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    /** Re-poste la notif quand l'état du code room change, SANS refaire un
     *  startForeground (le service tourne déjà). */
    private fun refreshNotification() {
        try {
            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            mgr.notify(NOTIF_ID, buildNotification())
        } catch (e: Exception) {
            Log.w(TAG, "refreshNotification failed", e)
        }
    }

    /**
     * Notif de contrôle unifiée, RemoteViews (`DecoratedCustomViewStyle`) :
     * pastilles d'action COLORÉES avec vraies icônes (les actions standard
     * n'affichent ni icône Android 7+ ni couleur individuelle).
     *   * Compteur (Chronometer natif) + statut.
     *   * Pastilles : ⏹ Arrêter (rouge) · ⧉ Ouvrir (bleu) · 3e pastille cyan.
     *
     * La 3e pastille porte les deux faces — exclusives — de l'échange du code :
     * HOME « Envoyer » / « Renvoyer » → [RoomCodeInputActivity] ; AWAY (code reçu)
     * « Copier » → [ACTION_COPY_CODE]. Même emplacement, même cyan.
     *
     * Côté HOME la pastille ne disparaît JAMAIS pendant l'enregistrement :
     * recréer une room dans eFootball change le code, il faut pouvoir le
     * renvoyer autant de fois que nécessaire.
     *
     * Pas de réponse directe (RemoteInput) : le champ de saisie inline ne se
     * déclenche que depuis une action STANDARD, dont Android n'autorise ni
     * l'icône (≥ N) ni la couleur — d'où le mini-dialogue.
     */
    private fun buildNotification(): android.app.Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
        }
        val openPending = PendingIntent.getActivity(this, 0, openIntent, pendingFlags())
        // Étape B — le bouton « Score » ouvre la saisie du score par-dessus le
        // jeu (ScoreInputActivity). À la validation, Dart soumet le score ET
        // scelle la vidéo (= fin du match), comme le bouton « Score » de
        // l'overlay. Repli universel : marche là où la superposition est bloquée.
        val stopIntent = Intent(this, ScoreInputActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val stopPending = PendingIntent.getActivity(this, 1, stopIntent, pendingFlags())
        val copyIntent = Intent(this, ArenaRecorderService::class.java).apply {
            action = ACTION_COPY_CODE
        }
        val copyPending = PendingIntent.getService(this, 3, copyIntent, pendingFlags())
        val code = roomCode
        // HOME — mini-dialogue de saisie posé par-dessus eFootball. Pré-rempli
        // avec le code déjà envoyé (renvoi = souvent une retouche). `pendingFlags`
        // porte FLAG_UPDATE_CURRENT, donc l'extra suit les changements de code.
        val typeIntent = Intent(this, RoomCodeInputActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(EXTRA_ROOM_CODE, code)
        }
        val typePending = PendingIntent.getActivity(this, 4, typeIntent, pendingFlags())

        val hasCode = !code.isNullOrEmpty()
        val text = when {
            isHome && !hasCode -> "Crée la room dans eFootball, puis envoie le code ici."
            isHome -> "Code envoyé : $code — renvoie-le s'il change."
            hasCode -> "Code room reçu : $code"
            else -> notifMessage
        }
        // Base du Chronometer : timebase elapsedRealtime (≠ currentTimeMillis).
        val chronoBase =
            SystemClock.elapsedRealtime() - (System.currentTimeMillis() - recordStartMillis)
        // 3e pastille : « Envoyer »/« Renvoyer » (HOME) et « Copier » (AWAY) sont
        // exclusifs. Côté HOME elle reste là même une fois le code envoyé.
        val showSend = isHome
        val showCopy = !isHome && hasCode

        fun buildView(withButtons: Boolean): RemoteViews {
            val layout = if (withButtons) R.layout.notif_recorder_big
            else R.layout.notif_recorder_small
            return RemoteViews(packageName, layout).apply {
                setTextViewText(R.id.notif_status, text)
                setChronometer(R.id.notif_chrono, chronoBase, null, true)
                if (withButtons) {
                    setOnClickPendingIntent(R.id.notif_btn_stop, stopPending)
                    setOnClickPendingIntent(R.id.notif_btn_open, openPending)
                    setViewVisibility(
                        R.id.notif_btn_code,
                        if (showSend || showCopy) android.view.View.VISIBLE
                        else android.view.View.GONE,
                    )
                    if (showSend) {
                        setImageViewResource(R.id.notif_btn_code_icon, R.drawable.ic_notif_send)
                        setTextViewText(
                            R.id.notif_btn_code_label,
                            if (hasCode) "Renvoyer code" else "Envoyer code",
                        )
                        setOnClickPendingIntent(R.id.notif_btn_code, typePending)
                    } else if (showCopy) {
                        setImageViewResource(R.id.notif_btn_code_icon, R.drawable.ic_notif_copy)
                        setTextViewText(R.id.notif_btn_code_label, "Copier")
                        setOnClickPendingIntent(R.id.notif_btn_code, copyPending)
                    }
                }
            }
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(notifTitle)
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(getColor(R.color.notification_tint))
            .setOngoing(true)
            .setShowWhen(false)
            .setContentIntent(openPending)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(buildView(withButtons = false))
            .setCustomBigContentView(buildView(withButtons = true))

        return builder.build()
    }

    private fun stopForegroundCompat() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (_: Exception) {}
    }
}
