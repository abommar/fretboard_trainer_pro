package com.dontfretaboutitai.frettrainerez.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.dontfretaboutitai.frettrainerez.models.Fretboard
import com.dontfretaboutitai.frettrainerez.models.FretPosition
import com.dontfretaboutitai.frettrainerez.models.FretboardStyle
import com.dontfretaboutitai.frettrainerez.models.GuitarTuning
import com.dontfretaboutitai.frettrainerez.models.Note

private val STRING_COUNT = 6
private val FRET_COUNT   = 12   // display frets 0–12
private val NUT_WIDTH_DP = 14f
private val FRET_WIDTH_DP = 52f
private val BOARD_HEIGHT_DP = 164f
private val STRING_SPACING_DP = BOARD_HEIGHT_DP / (STRING_COUNT + 1)

// Standard inlay positions (single dot frets)
private val INLAY_FRETS = setOf(3, 5, 7, 9)
private const val INLAY_FRET_DOUBLE = 12

@Composable
fun FretboardView(
    style: FretboardStyle = FretboardStyle.ROSEWOOD,
    highlightString: Int? = null,
    highlightFret: Int? = null,
    highlightColor: Color = Color(0xFFE94560),
    foundPositions: Set<FretPosition> = emptySet(),
    wrongPositions: Set<FretPosition> = emptySet(),
    flashPositions: Set<FretPosition> = emptySet(),   // Memory mode: shown during FLASHING
    showNoteLabels: Boolean = false,
    studyFilterNote: Note? = null,
    useFlats: Boolean = false,
    maxFret: Int = 22,
    tuning: GuitarTuning = GuitarTuning.standard,
    onFretTap: ((string: Int, fret: Int) -> Unit)? = null,
    heightDp: Dp = BOARD_HEIGHT_DP.dp,
) {
    val fretboard = remember(tuning) { Fretboard(tuning) }
    val density   = LocalDensity.current

    val nutWidthPx   = with(density) { NUT_WIDTH_DP.dp.toPx() }
    val fretWidthPx  = with(density) { FRET_WIDTH_DP.dp.toPx() }
    val boardHeightPx = with(density) { heightDp.toPx() }
    val displayFrets = minOf(maxFret, FRET_COUNT)
    val totalWidth   = NUT_WIDTH_DP.dp + FRET_WIDTH_DP.dp * displayFrets

    fun fretCenter(fret: Int): Float =
        if (fret == 0) nutWidthPx / 2f
        else nutWidthPx + (fret - 1) * fretWidthPx + fretWidthPx / 2f

    fun stringY(s: Int): Float {
        val spacing = boardHeightPx / (STRING_COUNT + 1)
        return spacing * (s + 1)
    }

    fun fretTapZoneX(fret: Int): Float =
        if (fret == 0) 0f
        else nutWidthPx + (fret - 1) * fretWidthPx

    Box(
        modifier = Modifier
            .height(heightDp)
            .horizontalScroll(rememberScrollState())
            .width(totalWidth)
    ) {
        Canvas(
            modifier = Modifier
                .height(heightDp)
                .width(totalWidth)
                .background(
                    Brush.horizontalGradient(style.boardColors)
                )
                .pointerInput(onFretTap, displayFrets) {
                    if (onFretTap == null) return@pointerInput
                    detectTapGestures { offset ->
                        val x = offset.x
                        val y = offset.y
                        // Determine fret from x
                        val fret = if (x < nutWidthPx) {
                            0
                        } else {
                            ((x - nutWidthPx) / fretWidthPx).toInt() + 1
                        }.coerceIn(0, displayFrets)
                        // Determine string from y
                        val spacing = size.height / (STRING_COUNT + 1)
                        val string = ((y / spacing) - 1).toInt().coerceIn(0, STRING_COUNT - 1)
                        onFretTap(string, fret)
                    }
                }
        ) {
            val spacing = boardHeightPx / (STRING_COUNT + 1)

            // --- Board gradient (drawn as background via Modifier.background above) ---

            // --- Nut ---
            drawRect(
                color = style.nutColor,
                topLeft = Offset(0f, 0f),
                size = Size(nutWidthPx, boardHeightPx)
            )

            // --- Fret wires ---
            val fretBrush = Brush.verticalGradient(style.fretColors)
            for (f in 1..displayFrets) {
                val x = nutWidthPx + (f - 1) * fretWidthPx
                drawLine(
                    brush = fretBrush,
                    start = Offset(x, 4f),
                    end   = Offset(x, boardHeightPx - 4f),
                    strokeWidth = if (f == 1) 3f else 2f,
                    cap = StrokeCap.Round
                )
            }

            // --- Strings ---
            for (s in 0 until STRING_COUNT) {
                val y = stringY(s)
                val thickness = 1f + (STRING_COUNT - 1 - s) * 0.6f   // low E thickest
                drawLine(
                    brush = Brush.horizontalGradient(style.stringColors),
                    start = Offset(0f, y),
                    end   = Offset(size.width, y),
                    strokeWidth = thickness,
                    cap = StrokeCap.Butt
                )
            }

            // --- Inlay dots ---
            val pearlColor = style.pearlBase
            for (f in 1..displayFrets) {
                val cx = fretCenter(f)
                val cy = boardHeightPx / 2f
                if (f in INLAY_FRETS) {
                    drawCircle(color = pearlColor.copy(alpha = 0.55f), radius = 5f, center = Offset(cx, cy))
                }
                if (f == INLAY_FRET_DOUBLE) {
                    drawCircle(color = pearlColor.copy(alpha = 0.55f), radius = 5f, center = Offset(cx, spacing * 2))
                    drawCircle(color = pearlColor.copy(alpha = 0.55f), radius = 5f, center = Offset(cx, spacing * 5))
                }
            }

            // --- Flash positions (Memory mode) ---
            for (pos in flashPositions) {
                if (pos.fret > displayFrets) continue
                val cx = fretCenter(pos.fret)
                val cy = stringY(pos.string)
                drawCircle(color = Color(0xFFE94560), radius = 12f, center = Offset(cx, cy))
            }

            // --- Found positions (green) ---
            for (pos in foundPositions) {
                if (pos.fret > displayFrets) continue
                val cx = fretCenter(pos.fret)
                val cy = stringY(pos.string)
                drawCircle(color = Color(0xFF2ECC71), radius = 12f, center = Offset(cx, cy))
            }

            // --- Wrong flash (red) ---
            for (pos in wrongPositions) {
                if (pos.fret > displayFrets) continue
                val cx = fretCenter(pos.fret)
                val cy = stringY(pos.string)
                drawCircle(color = Color(0xFFE74C3C), radius = 12f, center = Offset(cx, cy))
            }

            // --- Highlight dot (Name That Note / current question) ---
            if (highlightString != null && highlightFret != null && highlightFret <= displayFrets) {
                val cx = fretCenter(highlightFret)
                val cy = stringY(highlightString)
                drawCircle(color = highlightColor, radius = 14f, center = Offset(cx, cy))
                drawCircle(
                    color = Color.White.copy(alpha = 0.25f),
                    radius = 14f,
                    center = Offset(cx, cy),
                    style = Stroke(width = 2f)
                )
            }
        }
    }
}
