package com.arena.arena

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Foreground service « coquille » pour la capture anti-triche LiveKit.
 *
 * Contrairement à [ArenaRecorderService] (recorder natif qui détient SA propre
 * MediaProjection + MediaRecorder), ce service ne crée AUCUNE projection : il
 * se contente de tourner en foreground avec le type `mediaProjection`. C'est la
 * SEULE chose dont flutter_webrtc a besoin côté app.
 *
 * Pourquoi : flutter_webrtc (transitif de livekit_client) lance lui-même la
 * MediaProjection dans `getDisplayMedia`, mais ne fournit aucun foreground
 * service. Or Android 14+ (API 34) / 15 EXIGE qu'un FGS de type
 * `mediaProjection` tourne AVANT que la projection ne démarre, sinon le système
 * tue l'app (SecurityException). L'exemple officiel de flutter_webrtc résout ça
 * via le plugin tiers `flutter_background` ; on fait l'équivalent en Kotlin
 * maison pour rester sans dépendance (cf. [ArenaRecorderService]).
 *
 * Une seule MediaProjection existe donc à la fois (celle de flutter_webrtc) :
 * pas de conflit « 2 projections simultanées » d'Android 14+, et le recorder
 * natif reste mutuellement exclusif côté provider anti-triche.
 *
 * Cycle de vie : [ACTION_START] → startForeground ; [ACTION_STOP] → stop.
 * Piloté depuis Dart via le canal `arena/native`
 * (`startLivekitCaptureFgs` / `stopLivekitCaptureFgs`).
 */
class LivekitCaptureFgsService : Service() {

    companion object {
        private const val TAG = "LivekitCaptureFgs"
        private const val CHANNEL_ID = "arena_livekit_capture"
        private const val NOTIF_ID = 1102

        const val ACTION_START = "com.arena.arena.livekitfgs.START"
        const val ACTION_STOP = "com.arena.arena.livekitfgs.STOP"
        // Tap "Arrêter" sur la notif : ne stoppe PAS le FGS directement —
        // remonte à Dart (onStopRequested) qui appelle liveKitCaptureService
        // .stop() (déconnexion room → egress_ended + ACTION_STOP propre).
        const val ACTION_STOP_REQUEST = "com.arena.arena.livekitfgs.STOP_REQUEST"

        @Volatile
        var isActive: Boolean = false
            private set

        // Branché par MainActivity : pousse l'évènement "livekit_stop_requested"
        // vers l'EventChannel Dart quand l'utilisateur tape "Arrêter".
        @Volatile
        var onStopRequested: (() -> Unit)? = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                Log.d(TAG, "ACTION_STOP")
                stopForegroundCompat()
                isActive = false
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_STOP_REQUEST -> {
                // L'utilisateur a tapé "Arrêter" sur la notif. On délègue à Dart
                // (qui coupe la room LiveKit puis envoie ACTION_STOP) — sans ça,
                // tuer le FGS ne déconnecterait pas proprement la capture.
                Log.d(TAG, "ACTION_STOP_REQUEST → délégation Dart")
                val cb = onStopRequested
                if (cb != null) {
                    Handler(Looper.getMainLooper()).post {
                        try {
                            cb()
                        } catch (e: Exception) {
                            Log.w(TAG, "onStopRequested failed", e)
                        }
                    }
                    return START_STICKY
                }
                // Filet : pas de listener Dart (app en arrière-plan profond) →
                // on coupe au moins le FGS.
                stopForegroundCompat()
                isActive = false
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START -> {
                Log.d(TAG, "ACTION_START")
                try {
                    startForegroundCompat()
                    isActive = true
                } catch (e: Exception) {
                    Log.w(TAG, "startForeground failed", e)
                    isActive = false
                    stopSelf()
                    return START_NOT_STICKY
                }
                return START_STICKY
            }
            else -> {
                Log.w(TAG, "unknown action: ${intent?.action}")
                stopSelf()
                return START_NOT_STICKY
            }
        }
    }

    override fun onDestroy() {
        isActive = false
        super.onDestroy()
    }

    private fun startForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (mgr.getNotificationChannel(CHANNEL_ID) == null) {
                mgr.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "ARENA capture",
                        NotificationManager.IMPORTANCE_LOW
                    ).apply {
                        description = "Capture anti-triche en cours"
                    }
                )
            }
        }
        // Action "Arrêter" : re-cible le service avec ACTION_STOP_REQUEST, qui
        // remonte à Dart pour couper proprement la capture LiveKit.
        val stopIntent = Intent(this, LivekitCaptureFgsService::class.java).apply {
            action = ACTION_STOP_REQUEST
        }
        val stopPending = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ARENA")
            .setContentText("Enregistrement anti-triche en cours")
            .setSmallIcon(android.R.drawable.presence_video_online)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Arrêter", stopPending)
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
