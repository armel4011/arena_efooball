package com.arena.arena

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Bundle
import android.util.Log
import android.view.Surface

/**
 * Encodeur d'écran basé sur [MediaCodec] + [MediaMuxer], utilisé comme encodeur
 * PRIMAIRE sur tous les appareils, à la place de `MediaRecorder` qui IGNORE
 * `setVideoEncodingBitRate` sur beaucoup d'encodeurs matériels (Qualcomm des
 * Redmi ET Snapdragon 888 des Samsung : un ciblage 160 kbps produit ~147 Mo).
 *
 * [start] NÉGOCIE les paramètres avec les capacités réelles de l'encodeur AVC
 * du device (résolution alignée/bornée, bitrate/fps bornés) pour couvrir tout
 * type de puce, puis configure le **mode débit constant** (`BITRATE_MODE_CBR`)
 * s'il est supporté — l'encodeur cappe alors le débit à la cible quelle que soit
 * la motion → poids = `bitRate × durée`, PRÉDICTIBLE (160 kbps ⇒ ~30 Mo / 25
 * min). Si l'encodeur ne supporte pas le CBR, on retombe sur le **VBR** (qui
 * respecte quand même `KEY_BIT_RATE` bien mieux que MediaRecorder).
 *
 * Cycle : [start] configure le codec en mode surface, crée la surface d'entrée
 * (à donner au `VirtualDisplay` de la MediaProjection) et démarre un thread de
 * drain qui pousse les buffers encodés dans le muxer MP4. [stop] signale la fin
 * de flux, laisse le drain finaliser le moov, puis relâche tout.
 */
class CodecScreenRecorder {

    private var codec: MediaCodec? = null
    private var muxer: MediaMuxer? = null
    private var inputSurface: Surface? = null
    private var drainThread: Thread? = null

    /**
     * Dimensions RÉELLEMENT configurées après négociation avec les capacités de
     * l'encodeur (peuvent différer de celles demandées : alignement/bornes). Le
     * `VirtualDisplay` DOIT être créé à ces dimensions. 0 tant que [start] n'a
     * pas réussi.
     */
    var configuredWidth = 0
        private set
    var configuredHeight = 0
        private set

    private var trackIndex = -1
    @Volatile private var muxerStarted = false
    @Volatile private var stopRequested = false
    private val bufferInfo = MediaCodec.BufferInfo()

    /**
     * NÉGOCIE les paramètres selon les capacités RÉELLES de l'encodeur AVC du
     * device (mode de débit, résolution, bitrate, fps) — pour couvrir tout type
     * de puce (Qualcomm, Exynos, MediaTek, Unisoc, Kirin, Tensor, bas de gamme…)
     * — puis configure l'encodeur et renvoie la Surface d'entrée à brancher sur
     * le `VirtualDisplay`. Les dimensions retenues sont exposées via
     * [configuredWidth] / [configuredHeight]. Lève si AUCUN mode ne configure —
     * l'appelant retombe alors sur MediaRecorder.
     */
    fun start(
        width: Int,
        height: Int,
        bitRate: Int,
        fps: Int,
        outputPath: String,
    ): Surface {
        // ── Sondage des capacités (best-effort : si le sondage échoue, on garde
        //    les valeurs demandées et on tente CBR puis VBR) ───────────────────
        var w = width
        var h = height
        var br = bitRate
        var f = fps
        var supportsCbr = true
        var supportsVbr = true
        var probe: MediaCodec? = null
        try {
            probe = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
            val caps = probe.codecInfo
                .getCapabilitiesForType(MediaFormat.MIMETYPE_VIDEO_AVC)
            val enc = caps.encoderCapabilities
            supportsCbr = enc.isBitrateModeSupported(
                MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CBR,
            )
            supportsVbr = enc.isBitrateModeSupported(
                MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR,
            )
            val vc = caps.videoCapabilities
            // Résolution : alignée sur les contraintes de l'encodeur (certaines
            // puces exigent un alignement 16, d'autres 2) et bornée à sa plage
            // supportée — sinon configure() lève.
            w = alignDown(width, vc.widthAlignment)
                .coerceIn(vc.supportedWidths.lower, vc.supportedWidths.upper)
            val hRange = try {
                vc.getSupportedHeightsFor(w)
            } catch (_: Exception) {
                vc.supportedHeights
            }
            h = alignDown(height, vc.heightAlignment)
                .coerceIn(hRange.lower, hRange.upper)
            br = bitRate.coerceIn(vc.bitrateRange.lower, vc.bitrateRange.upper)
            val frRange = try {
                vc.getSupportedFrameRatesFor(w, h)
            } catch (_: Exception) {
                null
            }
            if (frRange != null) {
                f = fps.toDouble()
                    .coerceIn(frRange.lower, frRange.upper)
                    .toInt()
                    .coerceAtLeast(1)
            }
        } catch (_: Exception) {
            // Sondage impossible : valeurs brutes + CBR/VBR à tenter.
        } finally {
            try { probe?.release() } catch (_: Exception) {}
        }
        configuredWidth = w
        configuredHeight = h

        // Préférence des modes de débit : CBR (poids le plus prédictible) → VBR
        // (respecte quand même KEY_BIT_RATE bien mieux que MediaRecorder). On
        // saute les modes non supportés pour éviter un configure() qui lève.
        val modes = ArrayList<Int>(2)
        if (supportsCbr) modes.add(MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CBR)
        if (supportsVbr) modes.add(MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR)
        if (modes.isEmpty()) modes.add(MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR)

        var lastError: Exception? = null
        for (mode in modes) {
            try {
                return startWithMode(w, h, br, f, mode, outputPath)
            } catch (e: Exception) {
                Log.w("ArenaRecorder", "encoder configure failed (mode=$mode) — next", e)
                lastError = e
                releasePartial()
            }
        }
        throw lastError ?: IllegalStateException("aucun mode d'encodeur AVC exploitable")
    }

    /** Configure + démarre le codec pour un [bitrateMode] donné. Lève si échec. */
    private fun startWithMode(
        width: Int,
        height: Int,
        bitRate: Int,
        fps: Int,
        bitrateMode: Int,
        outputPath: String,
    ): Surface {
        // Réinitialise l'état : une tentative de mode précédente a pu poser ces
        // flags (releasePartial met stopRequested=true).
        stopRequested = false
        muxerStarted = false
        trackIndex = -1

        val format = MediaFormat.createVideoFormat(
            MediaFormat.MIMETYPE_VIDEO_AVC, width, height,
        ).apply {
            setInteger(
                MediaFormat.KEY_COLOR_FORMAT,
                MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface,
            )
            setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)
            setInteger(MediaFormat.KEY_BITRATE_MODE, bitrateMode)
            // Plafond DUR du débit crête. De nombreux encodeurs matériels
            // Qualcomm (observé SD888 / `c2.qti.avc`) DÉPASSENT largement la
            // cible CBR sur une entrée-surface (screen capture) — le fichier
            // sort 4–9× trop lourd. KEY_MAX_BITRATE agit comme plafond que le
            // HW respecte même quand son contrôle de débit CBR dérive.
            // `KEY_MAX_BITRATE` est @hide → on pose la clé littérale ("max-bitrate").
            setInteger("max-bitrate", bitRate)
        }

        val c = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        codec = c
        c.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        inputSurface = c.createInputSurface()
        c.start()

        // Ré-assertion du débit APRÈS start(). Certains encodeurs Qualcomm ne
        // VERROUILLENT la cible qu'au premier `setParameters` : sans ça, ils
        // démarrent à leur débit par défaut (bien plus haut) et n'y reviennent
        // jamais. Idempotent et sans effet là où la cible est déjà respectée.
        try {
            c.setParameters(
                Bundle().apply {
                    putInt(MediaCodec.PARAMETER_KEY_VIDEO_BITRATE, bitRate)
                },
            )
        } catch (_: Exception) {}

        muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

        drainThread = Thread({ drainLoop() }, "arena-codec-drain").apply { start() }
        val modeName =
            if (bitrateMode == MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CBR) "CBR" else "VBR"
        // Log.i (PAS Log.d : proguard-android-optimize STRIPPE Log.d/v en
        // release) — sert à vérifier sur l'appareil quel encodeur/mode a servi.
        Log.i(
            "ArenaRecorder",
            "MediaCodec $modeName ${bitRate / 1000}kbps ${width}x$height/${fps}fps codec=${c.name}",
        )
        return inputSurface!!
    }

    private fun alignDown(value: Int, alignment: Int): Int {
        if (alignment <= 1) return value
        return value - (value % alignment)
    }

    /** Relâche best-effort l'état alloué par [start] en cas d'échec de config. */
    private fun releasePartial() {
        stopRequested = true
        try { drainThread?.join(300) } catch (_: Exception) {}
        try { muxer?.release() } catch (_: Exception) {}
        try { codec?.stop() } catch (_: Exception) {}
        try { codec?.release() } catch (_: Exception) {}
        try { inputSurface?.release() } catch (_: Exception) {}
        codec = null
        muxer = null
        inputSurface = null
        drainThread = null
    }

    private fun drainLoop() {
        val c = codec ?: return
        while (!stopRequested) {
            val idx = try {
                c.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)
            } catch (e: IllegalStateException) {
                // Codec relâché sous nos pieds — on sort.
                break
            }
            when {
                idx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    // Le vrai format (avec csd-0/1) n'est connu qu'ici : on ajoute
                    // la piste et on démarre le muxer maintenant.
                    if (!muxerStarted) {
                        trackIndex = muxer!!.addTrack(c.outputFormat)
                        muxer!!.start()
                        muxerStarted = true
                    }
                }
                idx >= 0 -> {
                    // Les buffers CODEC_CONFIG (SPS/PPS) sont déjà passés dans
                    // addTrack via le format — on ne les mux pas en échantillon.
                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
                        bufferInfo.size = 0
                    }
                    if (bufferInfo.size > 0 && muxerStarted) {
                        val buf = c.getOutputBuffer(idx)
                        if (buf != null) {
                            buf.position(bufferInfo.offset)
                            buf.limit(bufferInfo.offset + bufferInfo.size)
                            muxer!!.writeSampleData(trackIndex, buf, bufferInfo)
                        }
                    }
                    c.releaseOutputBuffer(idx, false)
                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        break // fin de flux : le moov sera écrit par muxer.stop()
                    }
                }
                // INFO_TRY_AGAIN_LATER : rien à draîner pour l'instant → on reboucle.
            }
        }
    }

    /**
     * Finalise l'enregistrement. Le `VirtualDisplay` doit avoir été relâché
     * AVANT (plus de frames entrantes). Renvoie `true` si le MP4 a été muxé et
     * finalisé proprement (moov écrit), `false` sinon (fichier tronqué).
     */
    fun stop(): Boolean {
        var ok = false
        try {
            // Signale la fin de flux : l'encodeur émet ses derniers buffers +
            // un buffer marqué END_OF_STREAM que le drain attend pour sortir.
            try { codec?.signalEndOfInputStream() } catch (_: Exception) {}
            drainThread?.join(2500)
            // Filet : si le drain n'a pas vu l'EOS (encodeur muet), on le force.
            stopRequested = true
            drainThread?.join(500)
            ok = muxerStarted
        } catch (_: Exception) {
        } finally {
            try { if (muxerStarted) muxer?.stop() } catch (_: Exception) { ok = false }
            try { muxer?.release() } catch (_: Exception) {}
            try { codec?.stop() } catch (_: Exception) {}
            try { codec?.release() } catch (_: Exception) {}
            try { inputSurface?.release() } catch (_: Exception) {}
            codec = null
            muxer = null
            inputSurface = null
            drainThread = null
        }
        return ok
    }

    private companion object {
        private const val TIMEOUT_US = 10_000L
    }
}
