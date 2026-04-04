package com.dontfretaboutitai.frettrainerez.ui.screens

import android.Manifest
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.isActive
import kotlinx.coroutines.withContext
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.dontfretaboutitai.frettrainerez.models.GuitarTuning
import com.dontfretaboutitai.frettrainerez.models.Note
import com.dontfretaboutitai.frettrainerez.ui.theme.AccentRed
import com.dontfretaboutitai.frettrainerez.ui.theme.BgColor
import com.dontfretaboutitai.frettrainerez.ui.theme.CardBg
import com.dontfretaboutitai.frettrainerez.ui.theme.CorrectGreen
import com.dontfretaboutitai.frettrainerez.ui.theme.TextMuted
import com.dontfretaboutitai.frettrainerez.ui.theme.TextPrimary
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.log2
import kotlin.math.roundToInt
import kotlin.math.sqrt

private const val SAMPLE_RATE    = 44100
private const val BUFFER_SAMPLES = 4096

// Standard tuning reference (A4=440 Hz)
private fun noteFrequency(midiNote: Int): Double = 440.0 * Math.pow(2.0, (midiNote - 69) / 12.0)

/**
 * Detect fundamental frequency via Hann-windowed normalized autocorrelation with
 * McLeod "first significant peak" threshold (0.85 × global max).
 * Detects 50–2000 Hz.
 */
private fun detectPitch(buffer: ShortArray, sampleRate: Int): Double? {
    val n = buffer.size

    // RMS silence gate — 80 is permissive enough for a guitar mic'd at arm's length
    val rms = sqrt(buffer.sumOf { it.toDouble() * it }.toFloat() / n)
    if (rms < 80f) return null

    // Apply Hann window to reduce spectral leakage
    val windowed = FloatArray(n) { i ->
        buffer[i] * (0.5f * (1f - cos(2f * PI.toFloat() * i / (n - 1))))
    }

    // Lag range: 50 Hz – 2000 Hz
    val minLag = sampleRate / 2000   // ~2000 Hz max
    val maxLag = minOf(sampleRate / 50, n - 1)  // ~50 Hz min
    if (minLag >= maxLag) return null

    // Compute normalized ACF for every candidate lag.
    // Normalizing by (n - lag) removes length bias that would make small lags dominate.
    val nacf = FloatArray(maxLag + 2)
    for (lag in maxOf(0, minLag - 1)..(maxLag + 1)) {
        var sum = 0f
        for (i in 0 until n - lag) {
            sum += windowed[i] * windowed[i + lag]
        }
        nacf[lag] = sum / (n - lag).toFloat()
    }

    // McLeod "first significant peak": the first local maximum whose value exceeds
    // 85% of the global maximum. This avoids locking onto a sub-harmonic.
    val globalMax = nacf.slice(minLag..maxLag).maxOrNull() ?: return null
    if (globalMax <= 0f) return null
    val threshold = globalMax * 0.85f

    var bestLag = -1
    var bestVal = Float.NEGATIVE_INFINITY

    for (lag in (minLag + 1) until maxLag) {
        if (nacf[lag] > nacf[lag - 1] && nacf[lag] >= nacf[lag + 1] && nacf[lag] >= threshold) {
            bestLag = lag
            bestVal = nacf[lag]
            break
        }
    }

    // Fall back to global maximum if no clear peak was found
    if (bestLag == -1) {
        bestLag = (minLag..maxLag).maxByOrNull { nacf[it] } ?: return null
        bestVal = nacf[bestLag]
    }

    if (bestVal <= 0f) return null

    // Parabolic interpolation for sub-sample accuracy
    val y1 = nacf[maxOf(0, bestLag - 1)]
    val y2 = bestVal
    val y3 = nacf[minOf(maxLag + 1, bestLag + 1)]
    val denom = 2f * (2f * y2 - y1 - y3)
    val refined = if (denom != 0f) bestLag.toFloat() + (y1 - y3) / denom else bestLag.toFloat()

    return if (refined > 0f) sampleRate.toDouble() / refined else null
}

// Find closest MIDI note to a frequency
private fun closestMidi(freq: Double): Int {
    return (69 + 12 * log2(freq / 440.0)).roundToInt().coerceIn(28, 96)
}

// Cents deviation from nearest semitone (-50..+50)
private fun centsOff(freq: Double, midiNote: Int): Double {
    val target = noteFrequency(midiNote)
    return 1200.0 * log2(freq / target)
}

private fun midiToNoteName(midi: Int, useFlats: Boolean): String {
    val noteIdx = ((midi % 12) + 12) % 12
    val octave  = midi / 12 - 1
    val note    = Note.entries[noteIdx]
    return "${note.displayName(useFlats)}$octave"
}

// Note name without octave (e.g. "C#", "Bb") for string matching
private fun midiToNoteNameNoOctave(midi: Int, useFlats: Boolean): String {
    val noteIdx = ((midi % 12) + 12) % 12
    return Note.entries[noteIdx].displayName(useFlats)
}

@Composable
fun ChromaticTunerScreen(
    useFlats: Boolean,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    var hasPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        )
    }

    var detectedFreq      by remember { mutableFloatStateOf(0f) }
    var detectedMidi      by remember { mutableStateOf<Int?>(null) }
    var detectedNoteName  by remember { mutableStateOf<String?>(null) }  // no-octave name for string matching
    var centsDeviation    by remember { mutableFloatStateOf(0f) }
    var isListening       by remember { mutableStateOf(hasPermission) }
    var audioError        by remember { mutableStateOf(false) }
    var selectedTuning    by remember { mutableStateOf(GuitarTuning.standard) }

    val permLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        hasPermission = granted
        if (granted) isListening = true
    }

    val isLandscape = LocalConfiguration.current.orientation == Configuration.ORIENTATION_LANDSCAPE

    // Audio capture loop — coroutine-based for reliable Compose state updates
    LaunchedEffect(isListening, hasPermission) {
        if (!isListening || !hasPermission) {
            detectedFreq     = 0f
            detectedMidi     = null
            detectedNoteName = null
            centsDeviation   = 0f
            return@LaunchedEffect
        }

        audioError = false

        withContext(Dispatchers.IO) {
            val minBuf  = AudioRecord.getMinBufferSize(
                SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
            )
            val bufSize  = maxOf(if (minBuf > 0) minBuf else 0, BUFFER_SAMPLES * 2)
            val recorder = try {
                AudioRecord(
                    MediaRecorder.AudioSource.VOICE_RECOGNITION,
                    SAMPLE_RATE,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufSize,
                ).takeIf { it.state == AudioRecord.STATE_INITIALIZED }
            } catch (_: Exception) { null }

            if (recorder == null) {
                withContext(Dispatchers.Main) { audioError = true; isListening = false }
                return@withContext
            }

            try {
                recorder.startRecording()
            } catch (_: Exception) {
                recorder.release()
                withContext(Dispatchers.Main) { audioError = true; isListening = false }
                return@withContext
            }

            var confirmationNote: String? = null
            var confirmationCount = 0
            var smoothedCents     = 0f
            var lastSignalMs      = 0L
            val holdTimeoutMs     = 800L
            val buf               = ShortArray(BUFFER_SAMPLES)

            try {
                while (isActive) {
                    val read = recorder.read(buf, 0, buf.size)
                    if (read <= 0) continue

                    val freq  = detectPitch(buf, SAMPLE_RATE)
                    val nowMs = System.currentTimeMillis()

                    if (freq != null && freq in 50.0..2000.0) {
                        lastSignalMs  = nowMs
                        val midi      = closestMidi(freq)
                        val cents     = centsOff(freq, midi).toFloat().coerceIn(-50f, 50f)
                        smoothedCents = smoothedCents * 0.75f + cents * 0.25f

                        val rawNoteName = midiToNoteNameNoOctave(midi, useFlats)
                        if (rawNoteName == confirmationNote) {
                            confirmationCount++
                        } else {
                            confirmationNote  = rawNoteName
                            confirmationCount = 1
                        }

                        val newFreq  = freq.toFloat()
                        val newMidi  = midi
                        val newName  = rawNoteName
                        val newCents = smoothedCents

                        if (confirmationCount >= 2) {
                            withContext(Dispatchers.Main) {
                                detectedFreq     = newFreq
                                detectedMidi     = newMidi
                                detectedNoteName = newName
                                centsDeviation   = newCents
                            }
                        } else {
                            withContext(Dispatchers.Main) { centsDeviation = newCents }
                        }
                    } else {
                        if (nowMs - lastSignalMs >= holdTimeoutMs) {
                            withContext(Dispatchers.Main) {
                                detectedFreq     = 0f
                                detectedMidi     = null
                                detectedNoteName = null
                                centsDeviation   = 0f
                                smoothedCents    = 0f
                            }
                            smoothedCents    = 0f
                        }
                        confirmationNote  = null
                        confirmationCount = 0
                    }
                }
            } finally {
                recorder.stop()
                recorder.release()
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgColor)
            .statusBarsPadding(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        TunerTopBar(onBack = onBack)

        if (!hasPermission) {
            // Permission request UI — unchanged, fine for both orientations
            Box(
                modifier         = Modifier.weight(1f).fillMaxWidth(),
                contentAlignment = Alignment.Center,
            ) {
                Column(
                    horizontalAlignment   = Alignment.CenterHorizontally,
                    verticalArrangement   = Arrangement.spacedBy(16.dp),
                    modifier              = Modifier.padding(32.dp),
                ) {
                    Text(
                        text       = "Microphone Access Needed",
                        color      = TextPrimary,
                        fontSize   = 18.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign  = TextAlign.Center,
                    )
                    Text(
                        text      = "The tuner listens to your guitar through the microphone to detect pitch.",
                        color     = TextMuted,
                        fontSize  = 13.sp,
                        textAlign = TextAlign.Center,
                    )
                    Button(
                        onClick = { permLauncher.launch(Manifest.permission.RECORD_AUDIO) },
                        colors  = ButtonDefaults.buttonColors(containerColor = AccentRed),
                        shape   = RoundedCornerShape(10.dp),
                    ) {
                        Text("Grant Microphone Permission", color = TextPrimary)
                    }
                }
            }
        } else {
            // Main tuner UI
            val midi = detectedMidi

            if (isLandscape) {
                // ── Landscape: two-column layout ────────────────────────────
                Row(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth(),
                ) {
                    // LEFT: note display + meter, centered vertically
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center,
                    ) {
                        Text(
                            text       = if (midi != null) midiToNoteName(midi, useFlats) else "--",
                            color      = if (midi != null) inTuneColor(centsDeviation) else TextMuted,
                            fontSize   = 56.sp,
                            fontWeight = FontWeight.Black,
                            textAlign  = TextAlign.Center,
                        )
                        if (detectedFreq > 0f && midi != null) {
                            Text(
                                text     = "${"%.1f".format(detectedFreq)} Hz",
                                color    = TextMuted,
                                fontSize = 13.sp,
                            )
                        }
                        Spacer(Modifier.height(16.dp))
                        TunerMeter(
                            cents    = centsDeviation,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(90.dp)
                                .padding(horizontal = 24.dp),
                        )
                        Spacer(Modifier.height(8.dp))
                        if (midi != null) {
                            val label = when {
                                abs(centsDeviation) < 3f  -> "In Tune"
                                centsDeviation < 0f       -> "${"%.0f".format(centsDeviation)}¢ flat"
                                else                      -> "+${"%.0f".format(centsDeviation)}¢ sharp"
                            }
                            Text(
                                text       = label,
                                color      = inTuneColor(centsDeviation),
                                fontSize   = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                            )
                        }
                    }

                    // Vertical divider
                    Box(
                        modifier = Modifier
                            .width(1.dp)
                            .fillMaxHeight()
                            .background(Color.White.copy(alpha = 0.08f)),
                    )

                    // RIGHT: controls, scrollable
                    Column(
                        modifier = Modifier
                            .width(260.dp)
                            .fillMaxHeight()
                            .verticalScroll(rememberScrollState()),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center,
                    ) {
                        Spacer(Modifier.height(16.dp))
                        Button(
                            onClick = { audioError = false; isListening = !isListening },
                            colors  = ButtonDefaults.buttonColors(
                                containerColor = if (audioError) Color(0xFF8B0000) else if (isListening) Color(0xFF333355) else AccentRed,
                            ),
                            shape    = RoundedCornerShape(12.dp),
                            modifier = Modifier.width(160.dp).height(44.dp),
                        ) {
                            Text(
                                text       = if (audioError) "Mic Error – Retry" else if (isListening) "Stop" else "Start Tuning",
                                color      = TextPrimary,
                                fontWeight = FontWeight.Bold,
                            )
                        }
                        Spacer(Modifier.height(16.dp))
                        TuningSelector(
                            selectedTuning   = selectedTuning,
                            onTuningSelected = { selectedTuning = it },
                        )
                        Spacer(Modifier.height(16.dp))
                        OpenStringReference(
                            tuning         = selectedTuning,
                            activeNoteName = detectedNoteName,
                            useFlats       = useFlats,
                        )
                        Spacer(Modifier.height(16.dp))
                    }
                }
            } else {
                // ── Portrait: stacked layout ─────────────────────────────────
                Spacer(Modifier.height(24.dp))

                // Note name display (with octave)
                Text(
                    text       = if (midi != null) midiToNoteName(midi, useFlats) else "--",
                    color      = if (midi != null) inTuneColor(centsDeviation) else TextMuted,
                    fontSize   = 64.sp,
                    fontWeight = FontWeight.Black,
                    textAlign  = TextAlign.Center,
                )

                if (detectedFreq > 0f && midi != null) {
                    Text(
                        text     = "${"%.1f".format(detectedFreq)} Hz",
                        color    = TextMuted,
                        fontSize = 14.sp,
                    )
                }

                Spacer(Modifier.height(32.dp))

                // Tuning meter — unchanged composable
                TunerMeter(
                    cents    = centsDeviation,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(100.dp)
                        .padding(horizontal = 32.dp),
                )

                Spacer(Modifier.height(16.dp))

                // Cents label
                if (midi != null) {
                    val label = when {
                        abs(centsDeviation) < 3f  -> "In Tune"
                        centsDeviation < 0f       -> "${"%.0f".format(centsDeviation)}¢ flat"
                        else                      -> "+${"%.0f".format(centsDeviation)}¢ sharp"
                    }
                    Text(
                        text       = label,
                        color      = inTuneColor(centsDeviation),
                        fontSize   = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }

                Spacer(Modifier.height(32.dp))

                // Start/Stop button
                Button(
                    onClick = { audioError = false; isListening = !isListening },
                    colors  = ButtonDefaults.buttonColors(
                        containerColor = if (audioError) Color(0xFF8B0000) else if (isListening) Color(0xFF333355) else AccentRed,
                    ),
                    shape    = RoundedCornerShape(12.dp),
                    modifier = Modifier.width(160.dp).height(48.dp),
                ) {
                    Text(
                        text       = if (audioError) "Mic Error – Retry" else if (isListening) "Stop" else "Start Tuning",
                        color      = TextPrimary,
                        fontWeight = FontWeight.Bold,
                    )
                }

                Spacer(Modifier.weight(1f))

                // Tuning selector dropdown
                TuningSelector(
                    selectedTuning = selectedTuning,
                    onTuningSelected = { selectedTuning = it },
                )

                Spacer(Modifier.height(12.dp))

                // Open string reference row — now tuning-aware with highlight
                OpenStringReference(
                    tuning           = selectedTuning,
                    activeNoteName   = detectedNoteName,
                    useFlats         = useFlats,
                )

                Spacer(Modifier.height(16.dp))
            }
        }
    }
}

private fun inTuneColor(cents: Float): Color = when {
    abs(cents) < 5f  -> CorrectGreen
    abs(cents) < 15f -> Color(0xFFFFD700)
    else             -> AccentRed
}

// ── Tuner meter (unchanged) ────────────────────────────────────────────────────

@Composable
private fun TunerMeter(cents: Float, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val cx      = size.width / 2f
        val cy      = size.height * 0.85f
        val radius  = size.height * 0.80f
        val startA  = 210f
        val sweepA  = 120f

        // Arc track
        drawArc(
            color       = Color.White.copy(alpha = 0.08f),
            startAngle  = startA,
            sweepAngle  = sweepA,
            useCenter   = false,
            topLeft     = Offset(cx - radius, cy - radius),
            size        = Size(radius * 2f, radius * 2f),
            style       = Stroke(width = 14f, cap = StrokeCap.Round),
        )

        // Center tick
        val centerAng = Math.toRadians((startA + sweepA / 2f).toDouble())
        drawLine(
            color       = CorrectGreen.copy(alpha = 0.5f),
            start       = Offset(
                cx + (radius - 20f) * Math.cos(centerAng).toFloat(),
                cy + (radius - 20f) * Math.sin(centerAng).toFloat(),
            ),
            end         = Offset(
                cx + (radius + 8f) * Math.cos(centerAng).toFloat(),
                cy + (radius + 8f) * Math.sin(centerAng).toFloat(),
            ),
            strokeWidth = 2f,
        )

        // Needle
        val needleAngle = startA + sweepA / 2f + cents / 50f * (sweepA / 2f)
        val needleRad   = Math.toRadians(needleAngle.toDouble())
        val needleColor = inTuneColor(cents)
        drawLine(
            color       = needleColor,
            start       = Offset(cx, cy),
            end         = Offset(
                cx + (radius - 10f) * Math.cos(needleRad).toFloat(),
                cy + (radius - 10f) * Math.sin(needleRad).toFloat(),
            ),
            strokeWidth = 3f,
            cap         = StrokeCap.Round,
        )

        // Needle pivot
        drawCircle(color = needleColor, radius = 6f, center = Offset(cx, cy))

        // Tick marks at -25, 0, +25 (relative positions)
        val tickOffsets = listOf(-25f, 0f, 25f)
        for (t in tickOffsets) {
            val ta = startA + sweepA / 2f + t / 50f * (sweepA / 2f)
            val tr = Math.toRadians(ta.toDouble())
            drawLine(
                color       = Color.White.copy(alpha = 0.25f),
                start       = Offset(
                    cx + (radius - 18f) * Math.cos(tr).toFloat(),
                    cy + (radius - 18f) * Math.sin(tr).toFloat(),
                ),
                end         = Offset(
                    cx + (radius + 2f) * Math.cos(tr).toFloat(),
                    cy + (radius + 2f) * Math.sin(tr).toFloat(),
                ),
                strokeWidth = 1.5f,
            )
        }
    }
}

// ── Tuning selector ───────────────────────────────────────────────────────────

@Composable
private fun TuningSelector(
    selectedTuning: GuitarTuning,
    onTuningSelected: (GuitarTuning) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }

    Column(
        modifier            = Modifier.padding(horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text          = "TUNING",
            color         = TextMuted,
            fontSize      = 9.sp,
            fontWeight    = FontWeight.Bold,
            letterSpacing = 1.sp,
            modifier      = Modifier.padding(bottom = 4.dp),
        )

        Box(modifier = Modifier.wrapContentSize(Alignment.TopCenter)) {
            Row(
                modifier = Modifier
                    .background(CardBg, RoundedCornerShape(8.dp))
                    .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(8.dp))
                    .clickable { expanded = true }
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text(
                    text       = selectedTuning.name,
                    color      = TextPrimary,
                    fontSize   = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Icon(
                    imageVector        = Icons.Filled.ArrowDropDown,
                    contentDescription = "Select tuning",
                    tint               = TextMuted,
                    modifier           = Modifier.size(18.dp),
                )
            }

            DropdownMenu(
                expanded         = expanded,
                onDismissRequest = { expanded = false },
                modifier         = Modifier.background(CardBg),
            ) {
                GuitarTuning.all.forEach { tuning ->
                    DropdownMenuItem(
                        text = {
                            Text(
                                text      = tuning.name,
                                color     = if (tuning.id == selectedTuning.id) inTuneColor(0f) else TextPrimary,
                                fontSize  = 14.sp,
                                fontWeight = if (tuning.id == selectedTuning.id) FontWeight.Bold else FontWeight.Normal,
                            )
                        },
                        onClick = {
                            onTuningSelected(tuning)
                            expanded = false
                        },
                    )
                }
            }
        }
    }
}

// ── Open string reference ─────────────────────────────────────────────────────

/**
 * Row of 6 string boxes for the selected tuning.
 * The box whose note matches [activeNoteName] (no-octave sharp/flat name) is highlighted.
 * Standard MIDI offsets per string for standard tuning: low E=40, A=45, D=50, G=55, B=59, high E=64.
 * For alternate tunings the Note enum value is used directly to derive the display name.
 */
@Composable
private fun OpenStringReference(
    tuning: GuitarTuning,
    activeNoteName: String?,
    useFlats: Boolean,
) {
    // Standard tuning MIDI roots for octave display: index 0 = lowest string
    // (E2=40, A2=45, D3=50, G3=55, B3=59, E4=64)
    val standardMidiRoots = listOf(40, 45, 50, 55, 59, 64)

    Column(
        modifier            = Modifier.padding(horizontal = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text          = "OPEN STRINGS",
            color         = TextMuted,
            fontSize      = 9.sp,
            fontWeight    = FontWeight.Bold,
            letterSpacing = 1.sp,
            modifier      = Modifier.padding(bottom = 6.dp),
        )
        Row(
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            modifier = Modifier.horizontalScroll(rememberScrollState()),
        ) {
            tuning.strings.forEachIndexed { idx, note ->
                val displayName = note.displayName(tuning.useFlats || useFlats)
                // Determine if this string is active: compare against detected no-octave name
                // using both sharp and flat representations so detection always matches.
                val isActive = activeNoteName != null &&
                    (note.sharpName == activeNoteName || note.flatName == activeNoteName)

                // Derive approximate frequency from standard MIDI root adjusted by semitone offset
                val semitoneOffset = note.value - Note.entries[((standardMidiRoots[idx] % 12) + 12) % 12].value
                val adjustedMidi = standardMidiRoots[idx] + semitoneOffset
                val freqHz = noteFrequency(adjustedMidi)

                // String number label: string 6 = index 0 (lowest), string 1 = index 5 (highest)
                val stringNum = 6 - idx

                Column(
                    modifier = Modifier
                        .background(
                            color = if (isActive) Color.White.copy(alpha = 0.10f) else CardBg,
                            shape = RoundedCornerShape(8.dp),
                        )
                        .border(
                            width = if (isActive) 1.5.dp else 0.dp,
                            color = if (isActive) inTuneColor(0f).copy(alpha = 0.7f) else Color.Transparent,
                            shape = RoundedCornerShape(8.dp),
                        )
                        .padding(horizontal = 5.dp, vertical = 5.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(
                        text     = "$stringNum",
                        color    = TextMuted.copy(alpha = 0.6f),
                        fontSize = 8.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        text       = displayName,
                        color      = if (isActive) inTuneColor(0f) else TextPrimary,
                        fontSize   = 14.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        text     = "${"%.0f".format(freqHz)}Hz",
                        color    = TextMuted,
                        fontSize = 8.sp,
                    )
                }
            }
        }
    }
}

// ── Top bar (unchanged) ────────────────────────────────────────────────────────

@Composable
private fun TunerTopBar(onBack: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(CardBg)
            .padding(horizontal = 4.dp, vertical = 4.dp),
    ) {
        IconButton(
            onClick  = onBack,
            modifier = Modifier.align(Alignment.CenterStart),
        ) {
            Icon(
                imageVector        = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Back",
                tint               = TextPrimary,
                modifier           = Modifier.size(22.dp),
            )
        }
        Text(
            text       = "Chromatic Tuner",
            color      = TextPrimary,
            fontSize   = 17.sp,
            fontWeight = FontWeight.Bold,
            modifier   = Modifier.align(Alignment.Center),
        )
    }
}
