package com.dontfretaboutitai.frettrainerez.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dontfretaboutitai.frettrainerez.audio.NoteAudioEngine
import com.dontfretaboutitai.frettrainerez.models.ChordLibrary
import com.dontfretaboutitai.frettrainerez.models.ChordType
import com.dontfretaboutitai.frettrainerez.models.ChordVoicing
import com.dontfretaboutitai.frettrainerez.models.Note
import com.dontfretaboutitai.frettrainerez.ui.theme.AccentRed
import com.dontfretaboutitai.frettrainerez.ui.theme.BgColor
import com.dontfretaboutitai.frettrainerez.ui.theme.CardBg
import com.dontfretaboutitai.frettrainerez.ui.theme.TextMuted
import com.dontfretaboutitai.frettrainerez.ui.theme.TextPrimary
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private fun chordTypeColor(type: ChordType): Color = when (type) {
    ChordType.MAJOR     -> Color(0xFF4A9EFF)
    ChordType.MINOR     -> Color(0xFF9C6FD6)
    ChordType.DOMINANT7 -> Color(0xFFE94560)
    ChordType.MAJOR7    -> Color(0xFF2ECC71)
    ChordType.MINOR7    -> Color(0xFFFF9800)
    ChordType.SUS2      -> Color(0xFF00BCD4)
    ChordType.SUS4      -> Color(0xFFFF5722)
}

@Composable
fun ChordChartsScreen(
    useFlats: Boolean,
    audioEngine: NoteAudioEngine? = null,
    onBack: () -> Unit,
) {
    var selectedRoot by remember { mutableStateOf(Note.C) }
    var selectedType by remember { mutableStateOf(ChordType.MAJOR) }
    val scope = rememberCoroutineScope()

    val voicings = remember(selectedRoot, selectedType) {
        ChordLibrary.voicings(selectedRoot, selectedType)
    }

    val typeColor = chordTypeColor(selectedType)

    fun playChord(voicing: ChordVoicing) {
        scope.launch {
            voicing.frets.forEachIndexed { string, fret ->
                if (fret != null) {
                    audioEngine?.play(string, fret)
                    delay(45)
                }
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgColor)
            .statusBarsPadding()
            .navigationBarsPadding(),
    ) {
        // Shared nav bar — full width, never moves
        ChordChartsTopBar(onBack = onBack)

        // Two fixed panels side by side — nothing shifts
        Row(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
        ) {
            // ── LEFT PANEL: filters + voicing list ──────────────────────────
            Column(
                modifier = Modifier
                    .width(215.dp)
                    .fillMaxHeight()
                    .background(CardBg.copy(alpha = 0.55f)),
            ) {
                // Root note chips — 2 rows of 6
                val notes = Note.entries
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp, vertical = 6.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Row(
                        modifier              = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        notes.take(6).forEach { note ->
                            NoteChip(
                                note     = note,
                                selected = note == selectedRoot,
                                useFlats = useFlats,
                                onClick  = { selectedRoot = note },
                                modifier = Modifier.weight(1f),
                            )
                        }
                    }
                    Row(
                        modifier              = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        notes.drop(6).forEach { note ->
                            NoteChip(
                                note     = note,
                                selected = note == selectedRoot,
                                useFlats = useFlats,
                                onClick  = { selectedRoot = note },
                                modifier = Modifier.weight(1f),
                            )
                        }
                    }
                }

                // Type chips — horizontal scroll
                Row(
                    modifier              = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState())
                        .padding(horizontal = 8.dp, vertical = 3.dp),
                    horizontalArrangement = Arrangement.spacedBy(5.dp),
                ) {
                    ChordType.entries.forEach { type ->
                        TypeChip(
                            type     = type,
                            selected = type == selectedType,
                            onClick  = { selectedType = type },
                        )
                    }
                }

                // Thin separator
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(Color.White.copy(alpha = 0.08f))
                )

                // Voicing cards — fills remaining height
                if (voicings.isEmpty()) {
                    Box(
                        modifier         = Modifier.weight(1f).fillMaxWidth(),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("No voicings available", color = TextMuted, fontSize = 11.sp)
                    }
                } else {
                    LazyColumn(
                        modifier            = Modifier.weight(1f).fillMaxWidth(),
                        contentPadding      = androidx.compose.foundation.layout.PaddingValues(6.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        items(voicings) { voicing ->
                            VoicingCard(
                                voicing = voicing,
                                onPlay  = { playChord(voicing) },
                            )
                        }
                    }
                }
            }

            // Vertical divider
            Box(
                modifier = Modifier
                    .width(1.dp)
                    .fillMaxHeight()
                    .background(Color.White.copy(alpha = 0.10f))
            )

            // ── RIGHT PANEL: theory breakdown ────────────────────────────────
            TheoryPanel(
                selectedRoot = selectedRoot,
                selectedType = selectedType,
                typeColor    = typeColor,
                voicings     = voicings,
                useFlats     = useFlats,
                modifier     = Modifier.weight(1f).fillMaxHeight(),
            )
        }
    }
}

// ---------------------------------------------------------------------------
// Note chip — weight-based so rows fill the fixed panel width
// ---------------------------------------------------------------------------

@Composable
private fun NoteChip(
    note: Note,
    selected: Boolean,
    useFlats: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .background(
                color = if (selected) AccentRed else Color.White.copy(alpha = 0.07f),
                shape = RoundedCornerShape(6.dp),
            )
            .clip(RoundedCornerShape(6.dp))
            .clickable { onClick() }
            .padding(vertical = 5.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text       = note.displayName(useFlats),
            color      = if (selected) TextPrimary else TextMuted,
            fontSize   = 11.sp,
            fontWeight = FontWeight.Medium,
        )
    }
}

// ---------------------------------------------------------------------------
// Type chip
// ---------------------------------------------------------------------------

@Composable
private fun TypeChip(
    type: ChordType,
    selected: Boolean,
    onClick: () -> Unit,
) {
    Box(
        modifier = Modifier
            .background(
                color = if (selected) Color(0xFF2A2A6A) else Color.White.copy(alpha = 0.07f),
                shape = RoundedCornerShape(6.dp),
            )
            .clip(RoundedCornerShape(6.dp))
            .clickable { onClick() }
            .padding(horizontal = 9.dp, vertical = 5.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text       = type.displayName,
            color      = if (selected) TextPrimary else TextMuted,
            fontSize   = 11.sp,
            fontWeight = FontWeight.Medium,
        )
    }
}

// ---------------------------------------------------------------------------
// Voicing card
// ---------------------------------------------------------------------------

@Composable
private fun VoicingCard(
    voicing: ChordVoicing,
    onPlay: () -> Unit,
) {
    Column(
        modifier            = Modifier
            .fillMaxWidth()
            .background(CardBg, RoundedCornerShape(10.dp))
            .padding(horizontal = 8.dp, vertical = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(3.dp),
    ) {
        Text(
            text       = voicing.name,
            color      = TextPrimary,
            fontSize   = 11.sp,
            fontWeight = FontWeight.Bold,
        )

        ChordDiagram(
            voicing  = voicing,
            modifier = Modifier
                .fillMaxWidth()
                .height(88.dp),
        )

        Text(
            text       = if (voicing.baseFret > 1) "fr ${voicing.baseFret}" else "",
            color      = TextMuted,
            fontSize   = 9.sp,
            fontWeight = FontWeight.Medium,
        )

        Button(
            onClick        = onPlay,
            colors         = ButtonDefaults.buttonColors(containerColor = AccentRed),
            shape          = RoundedCornerShape(7.dp),
            modifier       = Modifier.fillMaxWidth().height(26.dp),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(0.dp),
        ) {
            Icon(
                imageVector        = Icons.Default.PlayArrow,
                contentDescription = "Play",
                tint               = Color.White,
                modifier           = Modifier.size(13.dp),
            )
            Spacer(Modifier.width(3.dp))
            Text(
                text       = "Play",
                color      = Color.White,
                fontSize   = 11.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}

// ---------------------------------------------------------------------------
// Theory panel (right)
// ---------------------------------------------------------------------------

@Composable
private fun TheoryPanel(
    selectedRoot: Note,
    selectedType: ChordType,
    typeColor: Color,
    voicings: List<ChordVoicing>,
    useFlats: Boolean,
    modifier: Modifier = Modifier,
) {
    val chordTones    = voicings.firstOrNull()?.chordTones ?: emptyList()
    val degreeSymbols = selectedType.degreeSymbols
    val degreeNames   = selectedType.degreeNames
    val rootName      = selectedRoot.displayName(useFlats)
    val chordName     = "$rootName${selectedType.suffix}"

    Column(
        modifier = modifier
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
    ) {
        Text(
            text       = chordName,
            color      = typeColor,
            fontSize   = 22.sp,
            fontWeight = FontWeight.Black,
        )
        Text(
            text     = selectedType.mood,
            color    = TextMuted,
            fontSize = 10.sp,
            modifier = Modifier.padding(top = 2.dp),
        )

        Spacer(Modifier.height(12.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(1.dp)
                .background(Color.White.copy(alpha = 0.10f))
        )
        Spacer(Modifier.height(12.dp))

        // NOTES + INTERVALS side by side
        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(24.dp),
            verticalAlignment     = Alignment.Top,
        ) {
            // Note pills
            if (chordTones.isNotEmpty()) {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    TheoryLabel("NOTES")
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        chordTones.zip(degreeSymbols).forEach { (note, degree) ->
                            val noteHue   = note.value / 12f * 360f
                            val pillColor = Color.hsv(noteHue, 0.80f, 0.95f)
                            val hueNorm   = note.value / 12f
                            val textColor = if (hueNorm > 0.14f && hueNorm < 0.56f)
                                Color.Black.copy(alpha = 0.85f) else Color.White

                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(3.dp),
                            ) {
                                Box(
                                    modifier = Modifier
                                        .background(pillColor, RoundedCornerShape(50))
                                        .padding(horizontal = 7.dp, vertical = 3.dp),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    Text(
                                        text       = note.displayName(useFlats),
                                        color      = textColor,
                                        fontSize   = 11.sp,
                                        fontWeight = FontWeight.Black,
                                    )
                                }
                                Text(
                                    text       = degree,
                                    color      = TextMuted,
                                    fontSize   = 9.sp,
                                    fontWeight = FontWeight.Bold,
                                    fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                                )
                            }
                        }
                    }
                }
            }

            // Intervals
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                TheoryLabel("INTERVALS")
                degreeSymbols.zip(degreeNames).forEach { (symbol, name) ->
                    Row(
                        verticalAlignment     = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Text(
                            text       = symbol,
                            color      = typeColor,
                            fontSize   = 10.sp,
                            fontWeight = FontWeight.Black,
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                            modifier   = Modifier.width(22.dp),
                        )
                        Text(
                            text     = name,
                            color    = TextMuted,
                            fontSize = 11.sp,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun TheoryLabel(text: String) {
    Text(
        text          = text,
        color         = TextMuted,
        fontSize      = 9.sp,
        fontWeight    = FontWeight.Bold,
        letterSpacing = 1.sp,
    )
}

// ---------------------------------------------------------------------------
// Chord diagram canvas
// ---------------------------------------------------------------------------

@Composable
private fun ChordDiagram(
    voicing: ChordVoicing,
    modifier: Modifier = Modifier,
) {
    val woodColor = Color(0xFF2E1F14)
    val nutColor  = Color(0xFFE8D5A3)
    val dotColor  = AccentRed

    Canvas(modifier = modifier) {
        val padH    = size.width  * 0.12f
        val padV    = size.height * 0.14f
        val gridW   = size.width  - padH * 2f
        val gridH   = size.height - padV * 2f
        val strGap  = gridW / 5f
        val fretGap = gridH / 4f
        val dotR    = (strGap * 0.30f).coerceAtMost(fretGap * 0.35f)

        val frets = voicing.frets
        val base  = voicing.baseFret

        // Wood background
        drawRect(
            color   = woodColor,
            topLeft = Offset(padH, padV),
            size    = Size(gridW, gridH),
        )

        // Nut or fret number
        if (base == 1) {
            drawRect(
                color   = nutColor,
                topLeft = Offset(padH, padV - 4f),
                size    = Size(gridW, 5f),
            )
        } else {
            drawIntoCanvas { c ->
                val p = android.graphics.Paint().apply {
                    isAntiAlias = true
                    textSize    = fretGap * 0.38f
                    textAlign   = android.graphics.Paint.Align.RIGHT
                    color       = android.graphics.Color.WHITE
                    alpha       = 150
                }
                c.nativeCanvas.drawText("${base}fr", padH - 5f, padV + fretGap * 0.28f, p)
            }
        }

        // Fret lines
        for (f in 0..4) {
            drawLine(
                color       = Color(0xFF888888).copy(alpha = 0.70f),
                start       = Offset(padH, padV + f * fretGap),
                end         = Offset(padH + gridW, padV + f * fretGap),
                strokeWidth = 1.5f,
            )
        }

        // String lines
        for (s in 0..5) {
            val x = padH + s * strGap
            drawLine(
                color       = Color(0xFFC0C0C0).copy(alpha = 0.80f),
                start       = Offset(x, padV),
                end         = Offset(x, padV + gridH),
                strokeWidth = 1.2f,
            )
        }

        // Dots, open circles, mute marks
        for (s in 0..5) {
            val fretVal = frets[s]
            val x       = padH + s * strGap
            val aboveY  = padV - fretGap * 0.42f

            when {
                fretVal == null -> {
                    drawIntoCanvas { c ->
                        val p = android.graphics.Paint().apply {
                            isAntiAlias = true
                            textSize    = fretGap * 0.50f
                            textAlign   = android.graphics.Paint.Align.CENTER
                            color       = android.graphics.Color.WHITE
                            alpha       = 140
                        }
                        c.nativeCanvas.drawText("×", x, aboveY + fretGap * 0.18f, p)
                    }
                }
                fretVal == 0 -> {
                    drawCircle(
                        color  = Color.White.copy(alpha = 0.70f),
                        radius = dotR * 0.72f,
                        center = Offset(x, aboveY),
                        style  = Stroke(width = 1.5f),
                    )
                }
                else -> {
                    val relFret = fretVal - base + 1
                    val cy      = padV + (relFret - 0.5f) * fretGap
                    drawCircle(color = dotColor, radius = dotR, center = Offset(x, cy))
                    drawCircle(
                        color  = Color.White.copy(alpha = 0.25f),
                        radius = dotR * 0.38f,
                        center = Offset(x - dotR * 0.22f, cy - dotR * 0.22f),
                    )
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Nav bar
// ---------------------------------------------------------------------------

@Composable
private fun ChordChartsTopBar(onBack: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(CardBg)
            .padding(horizontal = 4.dp, vertical = 2.dp),
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
            text       = "Chord Charts",
            color      = TextPrimary,
            fontSize   = 17.sp,
            fontWeight = FontWeight.Bold,
            modifier   = Modifier.align(Alignment.Center),
        )
    }
}
