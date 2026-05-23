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
 *   * 360p shorter dimension, aspect ratio preserved (so a 1080×2400
 *     portrait device produces ~ 360×800, a 1920×1080 landscape
 *     game render produces 640×360),
 *   * 500 kbps H.264 (≈90 MB for a 25-min match),
 *   * 24 fps — perfectly fine for proof-of-result footage.
 *
 * Lifecycle:
 *   START intent (with MediaProjection result) → setup + start.
 *   STOP intent → stop, release, publish path, exit foreground.
 *
 * Result handoff: the activity calls [requestStopAndDrain] which
 * stashes a one-shot callback. Once the service has finalised the
 * MP4 and released the recorder it invokes the callback with the
 * absolute file path. Callback may also fire with null if the
 * recording never started (or already stopped).
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

        // Target 360p on the SHORTER axis, preserve aspect ratio,
        // align dimensions to a multiple of 16 (H.264 encoder
        // requirement on most chips).
        val shorter = minOf(realW, realH)
        val scale = 360.0 / shorter
        val outW = ((realW * scale).toInt()) and -16
        val outH = ((realH * scale).toInt()) and -16
        Log.d(TAG, "recording at ${outW}x${outH} (screen ${realW}x${realH} @ ${density}dpi)")

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
        // 500 kbps gives ~90 MB for a 25-min match — well under the
        // proof bucket's 100 MB ceiling. Combine with 24 fps so the
        // encoder has enough budget per frame for game footage.
        recorder.setVideoEncodingBitRate(500_000)
        recorder.setVideoFrameRate(24)
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
        try {
            mediaRecorder?.stop()
        } catch (e: Exception) {
            Log.w(TAG, "mediaRecorder.stop() threw", e)
        }
        try { mediaRecorder?.release() } catch (_: Exception) {}
        mediaRecorder = null
        try { virtualDisplay?.release() } catch (_: Exception) {}
        virtualDisplay = null
        try { projection?.stop() } catch (_: Exception) {}
        projection = null
        outputPath = null
        isActive = false
        // Verify the file actually exists before publishing — if
        // mediaRecorder.stop() threw before finalising the moov atom
        // the file would be unreadable and the caller should treat
        // it as "no recording".
        val finalPath = path?.takeIf { File(it).exists() && File(it).length() > 0 }
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
