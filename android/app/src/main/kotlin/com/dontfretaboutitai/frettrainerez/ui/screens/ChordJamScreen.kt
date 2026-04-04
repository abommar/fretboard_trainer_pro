package com.dontfretaboutitai.frettrainerez.ui.screens

import android.content.res.Configuration
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
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dontfretaboutitai.frettrainerez.audio.NoteAudioEngine
import com.dontfretaboutitai.frettrainerez.models.ChordLibrary
import com.dontfretaboutitai.frettrainerez.models.ChordType
import com.dontfretaboutitai.frettrainerez.models.ChordVoicing
import com.dontfretaboutitai.frettrainerez.models.Note
import com.dontfretaboutitai.frettrainerez.ui.theme.BgColor
import com.dontfretaboutitai.frettrainerez.ui.theme.CardBg
import com.dontfretaboutitai.frettrainerez.ui.theme.TextPrimary
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.UUID

// ── Fixed 20-chord palette (matching iOS) ─────────────────────────────────────

private data class ChordPreset(val id: String, val voicing: ChordVoicing)

private fun buildPresets(): List<ChordPreset> {
    fun p(root: Note, type: ChordType) =
        ChordPreset("${root.name}-${type.name}", ChordLibrary.voicings(root, type).first())
    return listOf(
        p(Note.C,  ChordType.MAJOR),
        p(Note.G,  ChordType.MAJOR),
        p(Note.D,  ChordType.MAJOR),
        p(Note.A,  ChordType.MAJOR),
        p(Note.E,  ChordType.MAJOR),
        p(Note.F,  ChordType.MAJOR),
        p(Note.A,  ChordType.MINOR),
        p(Note.E,  ChordType.MINOR),
        p(Note.D,  ChordType.MINOR),
        p(Note.B,  ChordType.MINOR),
        p(Note.C,  ChordType.DOMINANT7),
        p(Note.G,  ChordType.DOMINANT7),
        p(Note.D,  ChordType.DOMINANT7),
        p(Note.A,  ChordType.DOMINANT7),
        p(Note.E,  ChordType.DOMINANT7),
        p(Note.F,  ChordType.MAJOR7),
        p(Note.G,  ChordType.MAJOR7),
        p(Note.C,  ChordType.MAJOR7),
        p(Note.A,  ChordType.MINOR7),
        p(Note.D,  ChordType.MINOR7),
    )
}

private data class ArrangedChord(val id: String = UUID.randomUUID().toString(), val presetId: String)

private fun jamTypeColor(type: ChordType): Color = when (type) {
    ChordType.MAJOR     -> Color(0xFF4A8FE3)
    ChordType.MINOR     -> Color(0xFFA857F7)
    ChordType.DOMINANT7 -> Color(0xFFF29E14)
    ChordType.MAJOR7    -> Color(0xFF12BA85)
    ChordType.MINOR7    -> Color(0xFF8C5EF7)
    ChordType.SUS2      -> Color(0xFF0AB8D9)
    ChordType.SUS4      -> Color(0xFF17A6EB)
}

// ── Screen ────────────────────────────────────────────────────────────────────

@Composable
fun ChordJamScreen(
    useFlats: Boolean,
    audioEngine: NoteAudioEngine? = null,
    onBack: () -> Unit,
) {
    val scope       = rememberCoroutineScope()
    val presets     = remember { buildPresets() }
    val presetById  = remember(presets) { presets.associateBy { it.id } }
    val arrangement = remember { mutableStateListOf<ArrangedChord>() }
    val isLandscape = LocalConfiguration.current.orientation == Configuration.ORIENTATION_LANDSCAPE

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
        JamNavBar(
            hasChords = arrangement.isNotEmpty(),
            onClear   = { arrangement.clear() },
            onBack    = onBack,
        )
        HorizontalDivider(color = Color.White.copy(alpha = 0.08f))

        if (isLandscape) {
            // ── Landscape: side-by-side (mirrors iOS landscapeBody) ──────────
            Row(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
            ) {
                ArrangementPanel(
                    arrangement = arrangement,
                    presetById  = presetById,
                    useFlats    = useFlats,
                    onPlay      = { playChord(it) },
                    onRemove    = { arrangement.remove(it) },
                    modifier    = Modifier.weight(1f).fillMaxHeight(),
                )

                VerticalDivider(color = Color.White.copy(alpha = 0.08f))

                PalettePanel(
                    presets  = presets,
                    useFlats = useFlats,
                    onTap    = { preset ->
                        arrangement.add(ArrangedChord(presetId = preset.id))
                        playChord(preset.voicing)
                    },
                    modifier = Modifier.width(300.dp).fillMaxHeight(),
                )
            }
        } else {
            // ── Portrait: stacked (arrangement 44%, palette 56%) ─────────────
            ArrangementPanel(
                arrangement = arrangement,
                presetById  = presetById,
                useFlats    = useFlats,
                onPlay      = { playChord(it) },
                onRemove    = { arrangement.remove(it) },
                modifier    = Modifier.weight(0.44f).fillMaxWidth(),
            )
            HorizontalDivider(color = Color.White.copy(alpha = 0.08f))
            PalettePanel(
                presets  = presets,
                useFlats = useFlats,
                onTap    = { preset ->
                    arrangement.add(ArrangedChord(presetId = preset.id))
                    playChord(preset.voicing)
                },
                modifier = Modifier.weight(0.56f).fillMaxWidth(),
            )
        }
    }
}

// ── Arrangement panel ─────────────────────────────────────────────────────────

@Composable
private fun ArrangementPanel(
    arrangement: List<ArrangedChord>,
    presetById: Map<String, ChordPreset>,
    useFlats: Boolean,
    onPlay: (ChordVoicing) -> Unit,
    onRemove: (ArrangedChord) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.background(CardBg.copy(alpha = 0.50f)),
    ) {
        SectionHeader("YOUR PROGRESSION")

        if (arrangement.isEmpty()) {
            Box(
                modifier         = Modifier.fillMaxSize().padding(bottom = 16.dp),
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        imageVector        = Icons.Default.MusicNote,
                        contentDescription = null,
                        tint               = Color.White.copy(alpha = 0.20f),
                        modifier           = Modifier.size(32.dp),
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text     = "Tap a chord below to build your progression",
                        color    = Color.White.copy(alpha = 0.40f),
                        fontSize = 13.sp,
                    )
                }
            }
        } else {
            LazyVerticalGrid(
                columns               = GridCells.Adaptive(minSize = 86.dp),
                modifier              = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement   = Arrangement.spacedBy(8.dp),
            ) {
                items(arrangement, key = { it.id }) { item ->
                    val preset = presetById[item.presetId] ?: return@items
                    ArrangedChipView(
                        voicing  = preset.voicing,
                        useFlats = useFlats,
                        onTap    = { onPlay(preset.voicing) },
                        onRemove = { onRemove(item) },
                    )
                }
            }
        }
    }
}

// ── Palette panel ─────────────────────────────────────────────────────────────

@Composable
private fun PalettePanel(
    presets: List<ChordPreset>,
    useFlats: Boolean,
    onTap: (ChordPreset) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.background(CardBg.copy(alpha = 0.35f)),
    ) {
        SectionHeader("20 COMMON CHORDS")

        LazyVerticalGrid(
            columns               = GridCells.Fixed(4),
            modifier              = Modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement   = Arrangement.spacedBy(8.dp),
        ) {
            items(presets, key = { it.id }) { preset ->
                PaletteChipView(
                    voicing  = preset.voicing,
                    useFlats = useFlats,
                    onTap    = { onTap(preset) },
                )
            }
        }
    }
}

// ── Arranged chip ─────────────────────────────────────────────────────────────

@Composable
private fun ArrangedChipView(
    voicing: ChordVoicing,
    useFlats: Boolean,
    onTap: () -> Unit,
    onRemove: () -> Unit,
) {
    val typeColor  = jamTypeColor(voicing.type)
    val rootText   = voicing.root.displayName(useFlats)
    val suffixText = voicing.type.suffix

    Box(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    brush = Brush.verticalGradient(
                        listOf(typeColor.copy(alpha = 0.28f), typeColor.copy(alpha = 0.10f))
                    ),
                    shape = RoundedCornerShape(10.dp),
                )
                .border(1.5.dp, typeColor.copy(alpha = 0.55f), RoundedCornerShape(10.dp))
                .clip(RoundedCornerShape(10.dp))
                .clickable(onClick = onTap)
                .padding(vertical = 10.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(verticalAlignment = Alignment.Bottom) {
                Text(
                    text       = rootText,
                    color      = TextPrimary,
                    fontSize   = 17.sp,
                    fontWeight = FontWeight.Black,
                )
                if (suffixText.isNotEmpty()) {
                    Spacer(Modifier.width(2.dp))
                    Text(
                        text       = suffixText,
                        color      = typeColor,
                        fontSize   = 11.sp,
                        fontWeight = FontWeight.Bold,
                    )
                }
            }
            Text(
                text       = voicing.type.displayName,
                color      = typeColor.copy(alpha = 0.85f),
                fontSize   = 8.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }

        Box(
            modifier = Modifier
                .size(18.dp)
                .align(Alignment.TopEnd)
                .background(Color.Black.copy(alpha = 0.35f), CircleShape)
                .clip(CircleShape)
                .clickable(onClick = onRemove),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector        = Icons.Default.Close,
                contentDescription = "Remove",
                tint               = Color.White.copy(alpha = 0.80f),
                modifier           = Modifier.size(10.dp),
            )
        }
    }
}

// ── Palette chip ──────────────────────────────────────────────────────────────

@Composable
private fun PaletteChipView(
    voicing: ChordVoicing,
    useFlats: Boolean,
    onTap: () -> Unit,
) {
    val typeColor  = jamTypeColor(voicing.type)
    val rootText   = voicing.root.displayName(useFlats)
    val suffixText = voicing.type.suffix

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                brush = Brush.verticalGradient(
                    listOf(typeColor.copy(alpha = 0.18f), typeColor.copy(alpha = 0.06f))
                ),
                shape = RoundedCornerShape(10.dp),
            )
            .border(1.dp, typeColor.copy(alpha = 0.38f), RoundedCornerShape(10.dp))
            .clip(RoundedCornerShape(10.dp))
            .clickable(onClick = onTap)
            .padding(vertical = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(verticalAlignment = Alignment.Bottom) {
            Text(
                text       = rootText,
                color      = TextPrimary,
                fontSize   = 17.sp,
                fontWeight = FontWeight.Black,
            )
            if (suffixText.isNotEmpty()) {
                Spacer(Modifier.width(2.dp))
                Text(
                    text       = suffixText,
                    color      = typeColor,
                    fontSize   = 11.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
        }
        Text(
            text       = voicing.type.displayName,
            color      = typeColor.copy(alpha = 0.85f),
            fontSize   = 8.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

@Composable
private fun SectionHeader(text: String) {
    Text(
        text          = text,
        color         = Color.White.copy(alpha = 0.45f),
        fontSize      = 10.sp,
        fontWeight    = FontWeight.Bold,
        letterSpacing = 1.2.sp,
        modifier      = Modifier.padding(start = 16.dp, top = 12.dp, bottom = 4.dp),
    )
}

@Composable
private fun JamNavBar(
    hasChords: Boolean,
    onClear: () -> Unit,
    onBack: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(CardBg)
            .padding(horizontal = 4.dp, vertical = 2.dp),
        verticalAlignment     = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        IconButton(onClick = onBack) {
            Icon(
                imageVector        = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Back",
                tint               = TextPrimary,
                modifier           = Modifier.size(22.dp),
            )
        }

        Text(
            text       = "Chord Jam",
            color      = TextPrimary,
            fontSize   = 17.sp,
            fontWeight = FontWeight.Bold,
        )

        Text(
            text       = "Clear",
            color      = if (hasChords) Color(0xFFE94560) else Color.White.copy(alpha = 0.30f),
            fontSize   = 13.sp,
            fontWeight = FontWeight.SemiBold,
            modifier   = Modifier
                .clip(RoundedCornerShape(6.dp))
                .then(if (hasChords) Modifier.clickable(onClick = onClear) else Modifier)
                .padding(horizontal = 12.dp, vertical = 8.dp),
        )
    }
}
