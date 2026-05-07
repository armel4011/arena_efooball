package com.arena.arena

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Wires the `arena/native` method channel used by the floating-button
 * overlay (PHASE 8.5) to bring ARENA back to the foreground from a
 * short tap.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val NATIVE_CHANNEL = "arena/native"
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
                    else -> result.notImplemented()
                }
            }
    }
}
