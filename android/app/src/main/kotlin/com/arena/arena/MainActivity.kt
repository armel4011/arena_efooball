package com.arena.arena

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Wires the `arena/native` method channel used by PHASE 8:
 *   * `bringToFront` — pull ARENA back from the recents stack after
 *     a tap on the floating button.
 *   * `saveVideoToGallery` — publish a finished MP4 from the app's
 *     private cache into the user-visible Download/ARENA folder via
 *     MediaStore.Downloads (Android 10+ scoped-storage friendly).
 *   * `startCustomRecording` / `stopCustomRecording` — drive
 *     [ArenaRecorderService] directly so we control resolution,
 *     bitrate and output filename (target: 360p / 500 kbps so a
 *     25-min match stays well under 100 MB).
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val TAG = "ArenaNative"
        const val NATIVE_CHANNEL = "arena/native"
        // EventChannel poussé Native → Dart pour signaler les évènements
        // hors-flow (ex. MediaProjection arrêtée via la notif système).
        const val NATIVE_EVENTS_CHANNEL = "arena/native/events"
        const val DOWNLOADS_SUBDIR = "ARENA"
        // request code for the MediaProjection permission dialog.
        const val RECORDING_PERMISSION_REQUEST = 0x4242
    }

    // Sink courant de l'EventChannel — null quand aucun listener Dart
    // n'est branché. Préservé entre les vies d'activité pour pouvoir
    // pousser un évènement même si l'app est en background.
    private var nativeEventSink: EventChannel.EventSink? = null

    // Pending state during the system MediaProjection dialog. The
    // Flutter call is async — we stash the result + the requested
    // start parameters here and forward them to the service once the
    // user accepts (or we resolve the result with false on cancel).
    private data class PendingStart(
        val filename: String,
        val title: String,
        val message: String,
        val result: MethodChannel.Result,
    )

    private var pendingStart: PendingStart? = null

    @Deprecated("Using startActivityForResult/onActivityResult — the modern" +
        " ActivityResult APIs aren't exposed by Flutter's FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != RECORDING_PERMISSION_REQUEST) return
        val pending = pendingStart ?: return
        pendingStart = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            Log.d(TAG, "recording permission denied (resultCode=$resultCode)")
            pending.result.success(false)
            return
        }
        val intent = Intent(applicationContext, ArenaRecorderService::class.java).apply {
            action = ArenaRecorderService.ACTION_START
            putExtra(ArenaRecorderService.EXTRA_RESULT_CODE, resultCode)
            putExtra(ArenaRecorderService.EXTRA_RESULT_DATA, data)
            putExtra(ArenaRecorderService.EXTRA_FILENAME, pending.filename)
            putExtra(ArenaRecorderService.EXTRA_TITLE, pending.title)
            putExtra(ArenaRecorderService.EXTRA_MESSAGE, pending.message)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            pending.result.success(true)
        } catch (e: Exception) {
            Log.w(TAG, "startForegroundService failed", e)
            pending.result.success(false)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "bringToFront" -> {
                        val intent = Intent(applicationContext, MainActivity::class.java).apply {
                            addFlags(
                                Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                            )
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "saveVideoToGallery" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("BAD_ARGS", "Missing 'path' argument", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = saveVideoToGallery(path)
                            result.success(uri?.toString())
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    "startCustomRecording" -> {
                        val filename = call.argument<String>("filename") ?: "match"
                        val title = call.argument<String>("title") ?: "ARENA"
                        val message =
                            call.argument<String>("message") ?: "Enregistrement en cours"
                        startCustomRecording(filename, title, message, result)
                    }
                    "stopCustomRecording" -> {
                        stopCustomRecording(result)
                    }
                    "startLivekitCaptureFgs" -> {
                        startLivekitCaptureFgs(result)
                    }
                    "stopLivekitCaptureFgs" -> {
                        stopLivekitCaptureFgs(result)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_EVENTS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    nativeEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    nativeEventSink = null
                }
            })

        // Branche le callback de mort de MediaProjection vers l'EventChannel.
        // Agora détient un AudioRecord sur la même projection ; sans signal
        // Dart, son thread interne retry en boucle (AudioFlinger -22).
        ArenaRecorderService.onProjectionDied = {
            runOnUiThread {
                try {
                    nativeEventSink?.success(mapOf("event" to "media_projection_died"))
                } catch (e: Exception) {
                    Log.w(TAG, "nativeEventSink.success failed", e)
                }
            }
        }

        // Tap "Arrêter" sur la notif de capture LiveKit → on prévient Dart pour
        // qu'il coupe la room (liveKitCaptureService.stop()).
        LivekitCaptureFgsService.onStopRequested = {
            runOnUiThread {
                try {
                    nativeEventSink?.success(mapOf("event" to "livekit_stop_requested"))
                } catch (e: Exception) {
                    Log.w(TAG, "nativeEventSink.success (livekit stop) failed", e)
                }
            }
        }
    }

    override fun onDestroy() {
        // Le service Kotlin peut survivre à l'activité — sans cleanup, son
        // callback retient une ref vers une activité morte et fuit.
        ArenaRecorderService.onProjectionDied = null
        LivekitCaptureFgsService.onStopRequested = null
        nativeEventSink = null
        super.onDestroy()
    }

    // ──────────────────────────────────────────────────────────────
    // Custom MediaProjection recording — drives ArenaRecorderService
    // ──────────────────────────────────────────────────────────────

    private fun startCustomRecording(
        filename: String,
        title: String,
        message: String,
        result: MethodChannel.Result,
    ) {
        if (pendingStart != null) {
            result.success(false)
            return
        }
        if (ArenaRecorderService.isActive) {
            // Already recording — treat the second call as a no-op
            // success rather than a crash; the foreground service is
            // alive and will deliver a path on stop.
            result.success(true)
            return
        }
        pendingStart = PendingStart(filename, title, message, result)
        try {
            val pm = applicationContext
                .getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            @Suppress("DEPRECATION")
            startActivityForResult(
                pm.createScreenCaptureIntent(),
                RECORDING_PERMISSION_REQUEST
            )
        } catch (e: Exception) {
            Log.w(TAG, "createScreenCaptureIntent failed", e)
            pendingStart = null
            result.success(false)
        }
    }

    private fun stopCustomRecording(result: MethodChannel.Result) {
        // Ask the service to stop and wait for it to publish its
        // output path. The service tears down MediaRecorder +
        // VirtualDisplay + MediaProjection and writes `lastOutputPath`
        // before stopping itself.
        ArenaRecorderService.requestStopAndDrain { path ->
            result.success(path ?: "")
        }
        val intent = Intent(applicationContext, ArenaRecorderService::class.java).apply {
            action = ArenaRecorderService.ACTION_STOP
        }
        try {
            startService(intent)
        } catch (e: Exception) {
            Log.w(TAG, "stopService(start) failed", e)
        }
    }

    // ──────────────────────────────────────────────────────────────
    // LiveKit anti-cheat capture — shell mediaProjection FGS
    // ──────────────────────────────────────────────────────────────
    // flutter_webrtc (capture LiveKit) ne fournit aucun foreground service ;
    // Android 14+ en exige un de type mediaProjection AVANT de démarrer la
    // projection, sinon l'app est tuée. On lance donc [LivekitCaptureFgsService]
    // (coquille, sans projection propre) juste avant `enableScreenShare()`
    // côté Dart, et on l'arrête à la fin de la capture.

    private fun startLivekitCaptureFgs(result: MethodChannel.Result) {
        val intent = Intent(applicationContext, LivekitCaptureFgsService::class.java).apply {
            action = LivekitCaptureFgsService.ACTION_START
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            result.success(true)
        } catch (e: Exception) {
            Log.w(TAG, "startLivekitCaptureFgs failed", e)
            result.success(false)
        }
    }

    private fun stopLivekitCaptureFgs(result: MethodChannel.Result) {
        val intent = Intent(applicationContext, LivekitCaptureFgsService::class.java).apply {
            action = LivekitCaptureFgsService.ACTION_STOP
        }
        try {
            startService(intent)
        } catch (e: Exception) {
            Log.w(TAG, "stopLivekitCaptureFgs failed", e)
        }
        result.success(true)
    }

    // ──────────────────────────────────────────────────────────────
    // saveVideoToGallery — Download/ARENA/<name>.mp4 via MediaStore
    // ──────────────────────────────────────────────────────────────

    private fun saveVideoToGallery(srcPath: String): Uri? {
        val src = File(srcPath)
        if (!src.exists() || src.length() == 0L) return null
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null

        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, src.name)
            put(MediaStore.Downloads.MIME_TYPE, "video/mp4")
            put(
                MediaStore.Downloads.RELATIVE_PATH,
                "${Environment.DIRECTORY_DOWNLOADS}/$DOWNLOADS_SUBDIR"
            )
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val collection = MediaStore.Downloads.getContentUri(
            MediaStore.VOLUME_EXTERNAL_PRIMARY
        )
        val uri = resolver.insert(collection, values) ?: return null
        try {
            resolver.openOutputStream(uri)?.use { out ->
                src.inputStream().use { input -> input.copyTo(out) }
            } ?: run {
                resolver.delete(uri, null, null)
                return null
            }
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
        val done = ContentValues().apply {
            put(MediaStore.Downloads.IS_PENDING, 0)
        }
        resolver.update(uri, done, null, null)
        return uri
    }
}
