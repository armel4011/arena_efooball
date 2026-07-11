package com.arena.arena

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
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
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import java.io.File

/**
 * Foreground service that hosts the MediaProjection + MediaRecorder
 * for the anti-cheat screen recording. Replaces the upstream
 * `flutter_screen_recording` plugin so we can pick our own
 * resolution / bitrate / framerate:
 *
 *   * 540p shorter dimension, aspect ratio preserved (so a 1080×2400
 *     portrait device produces ~ 544×1216, a 1920×1080 landscape
 *     game render produces 960×544),
 *   * 600 kbps H.264 (≈113 MB pour un match plein de 25 min, ~80 MB
 *     pour 18 min — confortablement sous le ceiling 500 MB du bucket
 *     `match-recordings` ET upload mobile money-friendly),
 *   * 24 fps — fluidité suffisante pour relire un jeu d'eFootball
 *     ou un Jeu de Dames et distinguer le score à l'écran.
 *
 * Profil MIUI/Xiaomi (Build.MANUFACTURER = Xiaomi / marques Redmi, POCO) :
 * 360p / 130 kbps / 15 fps → ≈24 MB pour 25 min (sous la cible 30 MB). L'OS
 * MIUI bride l'exécution background des apps force-stopped ; un fichier léger
 * maximise les chances de livrer la preuve dans cette fenêtre d'upload étroite.
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
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        const val EXTRA_FILENAME = "filename"
        const val EXTRA_TITLE = "title"
        const val EXTRA_MESSAGE = "message"

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
    private var outputPath: String? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                Log.d(TAG, "ACTION_STOP received")
                teardown()
                stopForegroundCompat()
                stopSelf()
                return START_NOT_STICKY
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

        // Profil d'encodage. Par défaut : 540p / 600 kbps / 24 fps (~113 MB max
        // pour 25 min) — net pour relire un HUD de jeu (score, chrono, joueurs).
        //
        // MIUI/Xiaomi : la fenêtre d'exécution BACKGROUND y est agressivement
        // bridée (l'OS tue l'isolate d'une app force-stopped avant la fin d'un
        // gros upload). On produit donc un fichier BEAUCOUP plus léger pour
        // maximiser les chances de livrer la preuve dans cette fenêtre :
        //   360p / 130 kbps / 15 fps → ≈24 MB pour 25 min (marge sous la cible
        //   30 MB malgré la variance VBR de l'encodeur). À 360p le HUD reste
        //   lisible car on descend AUSSI la résolution (un 540p à 130 kbps
        //   serait un brouillard de macroblocks, moins lisible).
        val xiaomi = Build.MANUFACTURER.equals("Xiaomi", ignoreCase = true) ||
            Build.BRAND.equals("Xiaomi", ignoreCase = true) ||
            Build.BRAND.equals("Redmi", ignoreCase = true) ||
            Build.BRAND.equals("POCO", ignoreCase = true)
        val targetShort = if (xiaomi) 360 else 540
        val videoBitRate = if (xiaomi) 130_000 else 600_000
        val videoFps = if (xiaomi) 15 else 24

        // Cible `targetShort` sur l'axe COURT, ratio préservé, dimensions
        // alignées sur un multiple de 16 (contrainte encodeur H.264).
        val shorter = minOf(realW, realH)
        val scale = targetShort.toDouble() / shorter
        val outW = ((realW * scale).toInt()) and -16
        val outH = ((realH * scale).toInt()) and -16
        Log.d(
            TAG,
            "recording at ${outW}x${outH} @ ${videoBitRate / 1000}kbps/${videoFps}fps " +
                "(screen ${realW}x${realH} @ ${density}dpi, xiaomi=$xiaomi)",
        )

        val outFile = File(externalCacheDir ?: cacheDir, "$filename.mp4")
        outputPath = outFile.absolutePath

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
        // Bitrate / fps selon le profil (cf. plus haut) : standard 600 kbps/24 fps
        // (~113 MB/25min) ; MIUI/Xiaomi allégé 130 kbps/15 fps (~24 MB/25min, sous
        // la cible 30 MB) pour un upload background fiable malgré le bridage OS.
        recorder.setVideoEncodingBitRate(videoBitRate)
        recorder.setVideoFrameRate(videoFps)
        recorder.setOutputFile(outFile.absolutePath)
        recorder.prepare()
        mediaRecorder = recorder

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
            outW, outH, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            recorder.surface,
            null, null
        )

        recorder.start()
        Log.d(TAG, "recording started: ${outFile.absolutePath}")
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
        try {
            mediaRecorder?.stop()
            stopSucceeded = true
        } catch (e: Exception) {
            Log.w(TAG, "mediaRecorder.stop() threw — moov atom NOT written, file is truncated", e)
        }

        try { mediaRecorder?.release() } catch (_: Exception) {}
        mediaRecorder = null
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
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.presence_video_online)
            .setOngoing(true)
            .build()
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
