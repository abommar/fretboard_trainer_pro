package com.dontfretaboutitai.frettrainerez.audio

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.roundToInt

/**
 * Karplus-Strong plucked-string synthesis, matching the iOS NoteAudioEngine.
 *
 * Open-string MIDI notes (low E → high E): 40, 45, 50, 55, 59, 64
 * play(string, fret) computes midi = openMidi + fret, synthesizes ~1.5s of samples,
 * and schedules them on a one-shot AudioTrack (static mode).
 */
class NoteAudioEngine {

    var audioUnavailable: Boolean = false
        private set

    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    private val sampleRate = 44100
    private val durationSec = 1.5f
    private val totalSamples = (sampleRate * durationSec).roundToInt()

    // MIDI note for each open string: low E=40, A=45, D=50, G=55, B=59, high e=64
    private val openStringMidi = intArrayOf(40, 45, 50, 55, 59, 64)

    fun play(string: Int, fret: Int) {
        if (string < 0 || string > 5) return
        val midi = openStringMidi[string] + fret
        scope.launch { renderAndPlay(midi) }
    }

    private fun renderAndPlay(midiNote: Int) {
        val freq = 440.0 * Math.pow(2.0, (midiNote - 69) / 12.0)
        val samples = karplusStrong(freq)

        val minBufSize = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        if (minBufSize == AudioTrack.ERROR_BAD_VALUE || minBufSize == AudioTrack.ERROR) {
            audioUnavailable = true
            return
        }

        val bufferSize = maxOf(minBufSize, samples.size * 2)

        try {
            val track = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_GAME)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .build()
                )
                .setBufferSizeInBytes(bufferSize)
                .setTransferMode(AudioTrack.MODE_STATIC)
                .build()

            track.write(samples, 0, samples.size)
            track.play()

            // Release after playback finishes (non-blocking; track plays asynchronously)
            scope.launch {
                kotlinx.coroutines.delay((durationSec * 1000 + 200).toLong())
                track.stop()
                track.release()
            }
        } catch (e: Exception) {
            audioUnavailable = true
        }
    }

    /**
     * Karplus-Strong algorithm:
     * 1. Fill a delay line of length ≈ sampleRate/freq with band-limited noise.
     * 2. Average each sample with the previous (low-pass filter) to produce decay.
     * 3. Apply Hann fade-out on the last 10% to prevent click.
     */
    private fun karplusStrong(freq: Double): ShortArray {
        val delayLen = maxOf(1, (sampleRate / freq).roundToInt())
        val buffer   = ShortArray(totalSamples)

        // Seed delay line with noise
        val delayLine = FloatArray(delayLen) { (Math.random().toFloat() * 2f - 1f) }

        val fadeStart = (totalSamples * 0.9f).roundToInt()

        for (i in 0 until totalSamples) {
            val idx  = i % delayLen
            val next = (idx + 1) % delayLen
            val avg  = 0.498f * (delayLine[idx] + delayLine[next])
            delayLine[idx] = avg

            val fadeGain = if (i >= fadeStart) {
                val pos = (i - fadeStart).toFloat() / (totalSamples - fadeStart)
                (0.5f * (1f + cos(PI.toFloat() * pos))).toFloat()
            } else 1f

            val sample = (avg * fadeGain * Short.MAX_VALUE).toInt()
                .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
            buffer[i] = sample.toShort()
        }

        return buffer
    }
}
