package com.arena.arena

import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.view.PixelCopy
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.random.Random

/**
 * Wires the `arena/native` method channel used by the floating-button
 * overlay (PHASE 8.5) to bring ARENA back to the foreground from a
 * short tap, and by PHASE 8.4 to publish a finished recording from
 * the app's private cache into the user-visible Download/ARENA folder.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val NATIVE_CHANNEL = "arena/native"
        const val DOWNLOADS_SUBDIR = "ARENA"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "bringToFront" -> {
                        // Re-launch our own activity with the right flags so
                        // the OS pulls it from the back stack instead of
                        // creating a new task. SINGLE_TOP avoids spawning a
                        // duplicate; REORDER_TO_FRONT pulls the existing one
                        // forward; NEW_TASK is required when the call comes
                        // from the overlay service context.
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
                    "takeScreenshot" -> {
                        // Captures ARENA's own window (decorView). When the
                        // game is in foreground ARENA's view is offscreen,
                        // so the capture is whatever ARENA last rendered.
                        // Real game capture needs a parallel MediaProjection
                        // session — deferred.
                        takeScreenshot { uri, error ->
                            if (error != null) {
                                result.error("SCREENSHOT_FAILED", error, null)
                            } else {
                                result.success(uri?.toString())
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Copies [srcPath] into the user-visible Download/ARENA/ folder via
     * MediaStore — the only Android 10+ scoped-storage-friendly way to
     * surface a file in any file manager without WRITE_EXTERNAL_STORAGE.
     * Returns the resulting content:// URI, or null if the source file
     * was missing or the OS is pre-Q (MediaStore.Downloads doesn't exist).
     */
    private fun saveVideoToGallery(srcPath: String): Uri? {
        val src = File(srcPath)
        if (!src.exists() || src.length() == 0L) return null
        // Downloads collection only exists on Q+. Pre-Q would need
        // WRITE_EXTERNAL_STORAGE, which we don't request — file stays
        // in the app cache.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null

        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, src.name)
            put(MediaStore.Downloads.MIME_TYPE, "video/mp4")
            put(
                MediaStore.Downloads.RELATIVE_PATH,
                "${Environment.DIRECTORY_DOWNLOADS}/$DOWNLOADS_SUBDIR"
            )
            // Mark as pending so other apps don't see a half-copied file.
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

    /**
     * Captures the activity window into a PNG inside Download/ARENA/.
     * On Android O+ uses PixelCopy (hardware accel, no permissions);
     * pre-O falls back to View.draw(Canvas) into a software bitmap.
     */
    private fun takeScreenshot(callback: (Uri?, String?) -> Unit) {
        val window = this.window
        val view = window.decorView
        val w = view.width
        val h = view.height
        if (w <= 0 || h <= 0) {
            callback(null, "Window not laid out yet (w=$w, h=$h)")
            return
        }
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PixelCopy.request(window, bitmap, { copyResult ->
                if (copyResult == PixelCopy.SUCCESS) {
                    try {
                        val uri = savePngToDownloads(bitmap)
                        callback(uri, null)
                    } catch (e: Exception) {
                        callback(null, e.message)
                    }
                } else {
                    callback(null, "PixelCopy code=$copyResult")
                }
            }, Handler(Looper.getMainLooper()))
        } else {
            try {
                view.draw(Canvas(bitmap))
                val uri = savePngToDownloads(bitmap)
                callback(uri, null)
            } catch (e: Exception) {
                callback(null, e.message)
            }
        }
    }

    private fun savePngToDownloads(bitmap: Bitmap): Uri? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val resolver = applicationContext.contentResolver
        val rand = Random.nextInt(999999).toString().padStart(6, '0')
        val name = "match_screenshot_$rand.png"
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, name)
            put(MediaStore.Downloads.MIME_TYPE, "image/png")
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
                bitmap.compress(Bitmap.CompressFormat.PNG, 90, out)
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
