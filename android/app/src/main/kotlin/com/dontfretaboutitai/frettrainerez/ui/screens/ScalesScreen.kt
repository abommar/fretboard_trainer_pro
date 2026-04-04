package com.dontfretaboutitai.frettrainerez.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dontfretaboutitai.frettrainerez.models.Fretboard
import com.dontfretaboutitai.frettrainerez.models.FretPosition
import com.dontfretaboutitai.frettrainerez.models.GuitarTuning
import com.dontfretaboutitai.frettrainerez.models.Note
import com.dontfretaboutitai.frettrainerez.models.ScaleType
import com.dontfretaboutitai.frettrainerez.ui.components.FretboardView
import com.dontfretaboutitai.frettrainerez.ui.theme.AccentRed
import com.dontfretaboutitai.frettrainerez.ui.theme.BgColor
import com.dontfretaboutitai.frettrainerez.ui.theme.CardBg
import com.dontfretaboutitai.frettrainerez.ui.theme.TextMuted
import com.dontfretaboutitai.frettrainerez.ui.theme.TextPrimary

private val ScaleBlue = Color(0xFF4A9EFF)

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ScalesScreen(
    useFlats: Boolean,
    onBack: () -> Unit,
) {
    var selectedRoot  by remember { mutableStateOf(Note.A) }
    var selectedScale by remember { mutableStateOf(ScaleType.PENTATONIC_MINOR) }

    val fretboard  = remember { Fretboard(GuitarTuning.standard) }
    val scaleNotes = remember(selectedRoot, selectedScale) {
        selectedScale.notes(selectedRoot).toSet()
    }

    // Compute fretboard positions — root → flashPositions (red), other scale tones → foundPositions (green)
    val flashPositions: Set<FretPosition> = remember(selectedRoot, scaleNotes) {
        buildSet {
            for (s in 0..5) {
                for (f in 0..12) {
                    if (fretboard.note(s, f) == selectedRoot) add(FretPosition(s, f))
                }
            }
        }
    }
    val foundPositions: Set<FretPosition> = remember(selectedRoot, scaleNotes) {
        buildSet {
            for (s in 0..5) {
                for (f in 0..12) {
                    val n = fretboard.note(s, f)
                    if (n != selectedRoot && n in scaleNotes) add(FretPosition(s, f))
                }
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgColor)
            .statusBarsPadding(),
    ) {
        // 1. Header bar
        ScalesTopBar(
            flavor = selectedScale.flavor,
            onBack = onBack,
        )

        Spacer(modifier = Modifier.height(8.dp))

        // 2. Scale note pills
        ScaleNotePills(
            root       = selectedRoot,
            scaleNotes = scaleNotes.toList(),
            useFlats   = useFlats,
        )

        Spacer(modifier = Modifier.height(8.dp))

        // 3. Main row: left panel + fretboard
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .padding(horizontal = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            // Left panel (140dp)
            LeftPanel(
                selectedRoot  = selectedRoot,
                selectedScale = selectedScale,
                useFlats      = useFlats,
                onRootSelect  = { selectedRoot = it },
                onScaleSelect = { selectedScale = it },
                modifier      = Modifier
                    .width(140.dp)
                    .fillMaxHeight(),
            )

            // Right: FretboardView
            Box(
                modifier        = Modifier
                    .weight(1f)
                    .fillMaxHeight(),
                contentAlignment = Alignment.TopStart,
            ) {
                FretboardView(
                    flashPositions = flashPositions,
                    foundPositions = foundPositions,
                    useFlats       = useFlats,
                    maxFret        = 22,
                    tuning         = GuitarTuning.standard,
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))
    }
}

// ---------------------------------------------------------------------------
// Header bar
// ---------------------------------------------------------------------------

@Composable
private fun ScalesTopBar(flavor: String, onBack: () -> Unit) {
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

        // Title + flavor centered together
        Column(
            modifier             = Modifier.align(Alignment.Center),
            horizontalAlignment  = Alignment.CenterHorizontally,
        ) {
            Text(
                text       = "Scale Explorer",
                color      = TextPrimary,
                fontSize   = 17.sp,
                fontWeight = FontWeight.Bold,
                textAlign  = TextAlign.Center,
            )
            Text(
                text      = flavor,
                color     = TextMuted,
                fontSize  = 11.sp,
                textAlign = TextAlign.Center,
            )
        }
    }
}

// ---------------------------------------------------------------------------
// Scale note pills
// ---------------------------------------------------------------------------

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ScaleNotePills(
    root: Note,
    scaleNotes: List<Note>,
    useFlats: Boolean,
) {
    FlowRow(
        modifier              = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalArrangement   = Arrangement.spacedBy(6.dp),
    ) {
        scaleNotes.forEach { note ->
            val isRoot  = note == root
            val bgColor = if (isRoot) AccentRed else ScaleBlue.copy(alpha = 0.20f)
            val txColor = if (isRoot) TextPrimary else ScaleBlue

            Box(
                modifier         = Modifier
                    .background(bgColor, RoundedCornerShape(20.dp))
                    .padding(horizontal = 10.dp, vertical = 4.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text       = note.displayName(useFlats),
                    color      = txColor,
                    fontSize   = 13.sp,
                    fontWeight = if (isRoot) FontWeight.Bold else FontWeight.SemiBold,
                )
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Left panel — root grid + scale list
// ---------------------------------------------------------------------------

@Composable
private fun LeftPanel(
    selectedRoot: Note,
    selectedScale: ScaleType,
    useFlats: Boolean,
    onRootSelect: (Note) -> Unit,
    onScaleSelect: (ScaleType) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier,
    ) {
        // "ROOT" label
        Text(
            text       = "ROOT",
            color      = TextMuted,
            fontSize   = 10.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 1.sp,
            modifier   = Modifier.padding(start = 2.dp, bottom = 4.dp),
        )

        // 4-column root grid (12 notes)
        LazyVerticalGrid(
            columns             = GridCells.Fixed(4),
            verticalArrangement = Arrangement.spacedBy(4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            modifier            = Modifier.fillMaxWidth(),
            // Fixed height: 2 rows × (chip height ~28dp + 4dp gap) ≈ 64dp
            // Use a fixed height so it doesn't fight the outer Column weight
            userScrollEnabled   = false,
        ) {
            items(Note.allCases) { note ->
                val isSelected = note == selectedRoot
                Box(
                    modifier = Modifier
                        .height(28.dp)
                        .background(
                            color = if (isSelected) AccentRed else CardBg,
                            shape = RoundedCornerShape(6.dp),
                        )
                        .clip(RoundedCornerShape(6.dp))
                        .clickable { onRootSelect(note) },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text       = note.displayName(useFlats),
                        color      = if (isSelected) TextPrimary else TextMuted,
                        fontSize   = 10.sp,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                        textAlign  = TextAlign.Center,
                        maxLines   = 1,
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // "SCALE" label
        Text(
            text          = "SCALE",
            color         = TextMuted,
            fontSize      = 10.sp,
            fontWeight    = FontWeight.Bold,
            letterSpacing = 1.sp,
            modifier      = Modifier.padding(start = 2.dp, bottom = 4.dp),
        )

        // Scale type list
        LazyColumn(
            modifier            = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            items(ScaleType.entries) { scale ->
                val isSelected = scale == selectedScale
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(CardBg, RoundedCornerShape(8.dp))
                        .then(
                            if (isSelected) Modifier.border(1.dp, AccentRed, RoundedCornerShape(8.dp))
                            else Modifier
                        )
                        .clip(RoundedCornerShape(8.dp))
                        .clickable { onScaleSelect(scale) }
                        .padding(horizontal = 8.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column {
                        Text(
                            text       = scale.displayName,
                            color      = if (isSelected) AccentRed else TextPrimary,
                            fontSize   = 11.sp,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.SemiBold,
                            maxLines   = 1,
                            overflow   = TextOverflow.Ellipsis,
                        )
                        Text(
                            text     = scale.flavor,
                            color    = TextMuted,
                            fontSize = 9.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }
            }
        }
    }
}
