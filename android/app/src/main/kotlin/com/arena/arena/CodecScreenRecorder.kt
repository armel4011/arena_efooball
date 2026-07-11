package com.arena.arena

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Build
import android.util.Log
import android.view.Surface

/**
 * Encodeur d'écran basé sur [MediaCodec] + [MediaMuxer], utilisé à la place de
 * `MediaRecorder` sur les encodeurs matériels qui IGNORENT
 * `setVideoEncodingBitRate` (observé sur Qualcomm/QC2Comp des Redmi : un ciblage
 * 130 kbps produit ~820 kbps en VBR par défaut).
 *
 * On configure explicitement le **mode débit constant** (`BITRATE_MODE_CBR`) :
 * l'encodeur cappe alors le débit total à la cible quelle que soit la motion →
 * le poids du fichier = `bitRate × durée`, PRÉDICTIBLE (130 kbps ⇒ ~24 Mo pour
 * 25 min, sous la cible 30 Mo).
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

    private var trackIndex = -1
    @Volatile private var muxerStarted = false
    @Volatile private var stopRequested = false
    private val bufferInfo = MediaCodec.BufferInfo()

    /**
     * Configure l'encodeur H.264 en CBR et renvoie la Surface d'entrée à
     * brancher sur le `VirtualDisplay`. Lève si la configuration échoue.
     */
    fun start(
        width: Int,
        height: Int,
        bitRate: Int,
        fps: Int,
        outputPath: String,
    ): Surface {
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
            // CBR : force le débit constant. C'est LE réglage que MediaRecorder
            // n'expose pas et dont l'absence laissait l'encodeur ignorer la cible.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                setInteger(
                    MediaFormat.KEY_BITRATE_MODE,
                    MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CBR,
                )
            }
        }

        val c = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        c.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        inputSurface = c.createInputSurface()
        c.start()
        codec = c

        muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

        drainThread = Thread({ drainLoop() }, "arena-codec-drain").apply { start() }
        Log.d("ArenaRecorder", "MediaCodec CBR ${bitRate / 1000}kbps ${width}x$height/${fps}fps")
        return inputSurface!!
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
