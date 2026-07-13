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
import android.util.DisplayMetrics
import android.util.Log
import android.view.Surface
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
import java.io.File

/**
 * Foreground service that hosts the MediaProjection + encoder for the
 * anti-cheat screen recording. Replaces the upstream
 * `flutter_screen_recording` plugin so we can pick our own
 * resolution / bitrate / framerate.
 *
 * PROFIL ALLÉGÉ UNIFORME (toute la flotte, cible ≈30 MB / 25 min — upload
 * mobile money-friendly ET livrable dans une fenêtre background étroite) :
 *   360p (axe court, ratio préservé), 160 kbps H.264, 20 fps. 360p garde le
 *   HUD (score, chrono) lisible pour l'arbitrage ; 20 fps suffit à relire un
 *   eFootball / Jeu de Dames.
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
        // overlay) : HOME (domicile) ENVOIE via une réponse directe RemoteInput,
        // AWAY (extérieur) REÇOIT le code + un bouton « Copier ».
        const val ACTION_SUBMIT_CODE = "com.arena.arena.recorder.SUBMIT_CODE"
        const val ACTION_COPY_CODE = "com.arena.arena.recorder.COPY_CODE"
        const val ACTION_UPDATE_CODE = "com.arena.arena.recorder.UPDATE_CODE"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        const val EXTRA_FILENAME = "filename"
        const val EXTRA_TITLE = "title"
        const val EXTRA_MESSAGE = "message"
        const val EXTRA_ROOM_CODE = "room_code"
        const val EXTRA_AWAITING_CODE = "awaiting_code"
        const val REMOTE_INPUT_KEY = "arena_room_code"

        // Callback : le HOME a tapé le code dans la réponse directe de la notif.
        // Set par MainActivity ; forwardé à Dart (→ écrit matches.room_code).
        @Volatile
        var onRoomCodeSubmitted: ((String) -> Unit)? = null

        // Callback : l'utilisateur a tapé « Arrêter » sur la notif. Set par
        // MainActivity ; forwardé à Dart → coordinator.stopCleanly() (arrêt
        // COORDONNÉ des deux surfaces). Si Dart ne répond pas, ACTION_STOP
        // reste dispo comme filet (stop système MediaProjection).
        @Volatile
        var onStopRequested: (() -> Unit)? = null

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
    // Code room reçu à afficher (côté AWAY) ; null si aucun.
    private var roomCode: String? = null
    // Vrai côté HOME tant qu'il doit ENVOYER le code (affiche la réponse directe).
    private var awaitingCode: Boolean = false

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
                Log.d(TAG, "ACTION_STOP_REQUESTED — deferring to Dart coordinator")
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
                // HOME a validé la réponse directe → récupère le texte tapé.
                val typed = RemoteInput.getResultsFromIntent(intent)
                    ?.getCharSequence(REMOTE_INPUT_KEY)?.toString()?.trim()
                if (!typed.isNullOrEmpty()) {
                    awaitingCode = false
                    try { onRoomCodeSubmitted?.invoke(typed) } catch (_: Exception) {}
                    refreshNotification()
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
                // Dart pousse l'état du code : AWAY reçoit un code, ou HOME doit
                // l'envoyer (awaitingCode). On reconstruit juste la notif.
                // Si aucun enregistrement n'est en cours, ne PAS laisser un
                // service non-foreground zombie → stopSelf.
                if (!isActive) {
                    stopSelf()
                    return START_NOT_STICKY
                }
                roomCode = intent.getStringExtra(EXTRA_ROOM_CODE)
                awaitingCode = intent.getBooleanExtra(EXTRA_AWAITING_CODE, false)
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
        //   360p / 160 kbps / 20 fps → ≈30 MB pour 25 min (upload mobile-
        //   friendly). 360p garde le HUD (score, chrono) lisible pour l'arbitrage.
        val targetShort = 360
        val videoBitRate = 160_000
        val videoFps = 20

        // Cible `targetShort` sur l'axe COURT, ratio préservé, dimensions
        // alignées sur un multiple de 16 (contrainte encodeur H.264).
        val shorter = minOf(realW, realH)
        val scale = targetShort.toDouble() / shorter
        val outW = ((realW * scale).toInt()) and -16
        val outH = ((realH * scale).toInt()) and -16
        Log.d(
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
        var codecSurface: Surface? = null
        try {
            val cr = CodecScreenRecorder()
            codecSurface = cr.start(outW, outH, videoBitRate, videoFps, outFile.absolutePath)
            codecRecorder = cr
        } catch (e: Exception) {
            Log.w(TAG, "MediaCodec CBR init failed — fallback MediaRecorder", e)
            codecRecorder = null
        }
        val encoderSurface: Surface = codecSurface
            ?: buildMediaRecorder(outW, outH, videoBitRate, videoFps, outFile.absolutePath)
        Log.d(TAG, "encoder = ${if (codecSurface != null) "MediaCodec" else "MediaRecorder (fallback)"}")

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
        publishOutput(finalPath)
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
     * Notif de contrôle unifiée : compteur (chrono) + « Arrêter » + tap « Ouvrir
     * Arena », et l'échange du code room selon le rôle :
     *   * HOME (awaitingCode) → RÉPONSE DIRECTE (RemoteInput) pour ENVOYER le
     *     code sans quitter eFootball ;
     *   * AWAY (roomCode != null) → le code affiché + bouton « Copier ».
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
        // « Arrêter » passe par le coordinator Dart (arrêt coordonné des deux
        // surfaces), pas par ACTION_STOP direct.
        val stopIntent = Intent(this, ArenaRecorderService::class.java).apply {
            action = ACTION_STOP_REQUESTED
        }
        val stopPending = PendingIntent.getService(this, 1, stopIntent, pendingFlags())

        val code = roomCode
        val text = when {
            awaitingCode -> "Crée la room dans eFootball, puis envoie le code ici."
            !code.isNullOrEmpty() -> "Code room reçu : $code"
            else -> notifMessage
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(notifTitle)
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setSmallIcon(android.R.drawable.presence_video_online)
            .setOngoing(true)
            // Compteur d'enregistrement : chrono qui s'incrémente tout seul.
            .setUsesChronometer(true)
            .setWhen(recordStartMillis)
            .setShowWhen(true)
            .setContentIntent(openPending)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Arrêter",
                stopPending,
            )

        if (awaitingCode) {
            // HOME — réponse directe. Le PendingIntent DOIT être MUTABLE
            // (le système y injecte le texte saisi via RemoteInput).
            val remoteInput = RemoteInput.Builder(REMOTE_INPUT_KEY)
                .setLabel("Code de la room eFootball")
                .build()
            val submitIntent = Intent(this, ArenaRecorderService::class.java).apply {
                action = ACTION_SUBMIT_CODE
            }
            val mutableFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val submitPending = PendingIntent.getService(this, 2, submitIntent, mutableFlags)
            builder.addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_menu_send, "Envoyer le code", submitPending,
                ).addRemoteInput(remoteInput).build()
            )
        } else if (!code.isNullOrEmpty()) {
            // AWAY — copie du code reçu dans le presse-papier.
            val copyIntent = Intent(this, ArenaRecorderService::class.java).apply {
                action = ACTION_COPY_CODE
            }
            val copyPending = PendingIntent.getService(this, 3, copyIntent, pendingFlags())
            builder.addAction(android.R.drawable.ic_menu_save, "Copier", copyPending)
        }

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
