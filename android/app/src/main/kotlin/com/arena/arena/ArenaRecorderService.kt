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
import android.view.Surface
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import java.io.File

/**
 * Foreground service that hosts the MediaProjection + encoder for the
 * anti-cheat screen recording. Replaces the upstream
 * `flutter_screen_recording` plugin so we can pick our own
 * resolution / bitrate / framerate.
 *
 * PROFIL ALLÉGÉ (toute la flotte, cible ≈30 MB / 25 min — upload mobile
 * money-friendly ET livrable dans une fenêtre background étroite) :
 *   * Défaut : 480p (axe court), ratio préservé, 160 kbps H.264, 20 fps.
 *     480p garde le HUD (score, chrono) lisible pour l'arbitrage, 160 kbps
 *     tient la cible poids, 20 fps suffit à relire un eFootball / Jeu de Dames.
 *   * MIUI/Xiaomi (Build.MANUFACTURER = Xiaomi / marques Redmi, POCO) :
 *     360p / 130 kbps / 15 fps → ≈24 MB pour 25 min. MIUI bride l'exécution
 *     background des apps force-stopped ; un fichier encore plus léger maximise
 *     les chances de livrer la preuve dans cette fenêtre d'upload.
 *
 * ENCODEUR + FILET DE SÉCURITÉ :
 *   * Xiaomi/MIUI : [CodecScreenRecorder] (MediaCodec en CBR) — l'encodeur
 *     matériel Qualcomm des Redmi ignore le `setVideoEncodingBitRate` de
 *     MediaRecorder (VBR → ~820 kbps observé pour une cible de 130). CBR force
 *     le débit constant → poids prédictible. Si l'init MediaCodec échoue (CBR
 *     non supporté, dimensions refusées…), on RETOMBE sur MediaRecorder : une
 *     preuve plus lourde vaut infiniment mieux qu'aucune preuve.
 *   * Autres appareils : MediaRecorder standard, éprouvé — il respecte le
 *     bitrate demandé hors puces QCom, donc pas besoin du chemin MediaCodec.
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
    // Chemin MediaCodec CBR (Xiaomi/MIUI) — alternatif à mediaRecorder.
    private var codecRecorder: CodecScreenRecorder? = null
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

        // Profil d'encodage ALLÉGÉ (cf. KDoc de classe). Cible ≈30 MB / 25 min
        // sur toute la flotte pour un upload mobile-friendly.
        //   Défaut     : 480p / 160 kbps / 20 fps — HUD lisible, poids tenu
        //                (MediaRecorder respecte ce bitrate hors puces QCom).
        //   MIUI/Xiaomi: 360p / 130 kbps / 15 fps — fenêtre background plus
        //                étroite ⇒ fichier encore plus léger (≈24 MB / 25 min).
        val xiaomi = Build.MANUFACTURER.equals("Xiaomi", ignoreCase = true) ||
            Build.BRAND.equals("Xiaomi", ignoreCase = true) ||
            Build.BRAND.equals("Redmi", ignoreCase = true) ||
            Build.BRAND.equals("POCO", ignoreCase = true)
        val targetShort = if (xiaomi) 360 else 480
        val videoBitRate = if (xiaomi) 130_000 else 160_000
        val videoFps = if (xiaomi) 15 else 20

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

        // Encodeur → Surface d'entrée pour le VirtualDisplay.
        //  - Xiaomi/MIUI : MediaCodec CBR (l'encodeur matériel QCom ignore le
        //    bitrate de MediaRecorder → fichier ~6× trop lourd). FILET : si
        //    l'init échoue, on retombe sur MediaRecorder (preuve plus lourde
        //    mais preuve quand même).
        //  - Autres : MediaRecorder standard (éprouvé, respecte le bitrate).
        var codecSurface: Surface? = null
        if (xiaomi) {
            try {
                val cr = CodecScreenRecorder()
                codecSurface = cr.start(outW, outH, videoBitRate, videoFps, outFile.absolutePath)
                codecRecorder = cr
            } catch (e: Exception) {
                Log.w(TAG, "MediaCodec CBR init failed on Xiaomi — fallback MediaRecorder", e)
                codecRecorder = null
            }
        }
        val encoderSurface: Surface = codecSurface
            ?: buildMediaRecorder(outW, outH, videoBitRate, videoFps, outFile.absolutePath)

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
            encoderSurface,
            null, null
        )

        // MediaRecorder démarre son encodage ici ; MediaCodec (Xiaomi) tourne
        // déjà (son thread de drain a été lancé dans CodecScreenRecorder.start()).
        mediaRecorder?.start()
        Log.d(TAG, "recording started: ${outFile.absolutePath}")
    }

    /**
     * Construit et prépare un [MediaRecorder] H.264 SURFACE selon le profil,
     * le stocke dans [mediaRecorder] et renvoie sa Surface d'entrée. Utilisé sur
     * les appareils non-Xiaomi ET comme filet de secours si l'init MediaCodec
     * CBR échoue (cf. [startRecording]).
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
            // Chemin MediaCodec CBR (Xiaomi) : stop() signale l'EOS, laisse le
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
