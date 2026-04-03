package com.dontfretaboutitai.frettrainerez.ui.components

import android.graphics.Paint
import android.graphics.Typeface
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
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
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dontfretaboutitai.frettrainerez.models.Fretboard
import com.dontfretaboutitai.frettrainerez.models.FretPosition
import com.dontfretaboutitai.frettrainerez.models.FretboardStyle
import com.dontfretaboutitai.frettrainerez.models.GuitarTuning
import com.dontfretaboutitai.frettrainerez.models.Note

private const val STRING_COUNT      = 6
private const val FRET_COUNT        = 12
private const val NUT_WIDTH_DP      = 14f
private const val FRET_WIDTH_DP     = 48f
private const val BOARD_HEIGHT_DP   = 168f
private const val FRET_NUM_HEIGHT_DP = 20f
private const val LABEL_WIDTH_DP    = 30f

private val INLAY_FRETS      = setOf(3, 5, 7, 9)
private const val INLAY_DOUBLE = 12

@Composable
fun FretboardView(
    style: FretboardStyle = FretboardStyle.ROSEWOOD,
    highlightString: Int? = null,
    highlightFret: Int? = null,
    highlightColor: Color = Color(0xFFE94560),
    foundPositions: Set<FretPosition> = emptySet(),
    wrongPositions: Set<FretPosition> = emptySet(),
    flashPositions: Set<FretPosition> = emptySet(),
    useFlats: Boolean = false,
    maxFret: Int = 22,
    tuning: GuitarTuning = GuitarTuning.standard,
    onFretTap: ((string: Int, fret: Int) -> Unit)? = null,
) {
    val density       = LocalDensity.current
    val fretboard     = remember(tuning) { Fretboard(tuning) }
    val scrollState   = rememberScrollState()
    val displayFrets  = minOf(maxFret, FRET_COUNT)
    val totalWidthDp  = NUT_WIDTH_DP.dp + FRET_WIDTH_DP.dp * displayFrets
    val boardHeightDp = BOARD_HEIGHT_DP.dp
    val fretNumHDp    = FRET_NUM_HEIGHT_DP.dp
    val labelWidthDp  = LABEL_WIDTH_DP.dp

    val nutWidthPx    = with(density) { NUT_WIDTH_DP.dp.toPx() }
    val fretWidthPx   = with(density) { FRET_WIDTH_DP.dp.toPx() }
    val boardHeightPx = with(density) { boardHeightDp.toPx() }
    val fretNumHPx    = with(density) { fretNumHDp.toPx() }
    val labelSizePx   = with(density) { 10.5.sp.toPx() }
    val fretNumSizePx = with(density) { 9.sp.toPx() }

    fun fretCenter(fret: Int): Float =
        if (fret == 0) nutWidthPx / 2f
        else nutWidthPx + (fret - 1) * fretWidthPx + fretWidthPx / 2f

    fun stringY(s: Int): Float = boardHeightPx / (STRING_COUNT + 1) * (s + 1)

    // Build string display names — lowercase the high string when same note as low
    val stringNames: List<String> = List(STRING_COUNT) { s ->
        val note = tuning.strings[s]
        val name = note.displayName(tuning.useFlats || useFlats)
        // Conventional: high string (index 5) uses lowercase if same pitch class as string 0
        if (s == STRING_COUNT - 1 && note == tuning.strings[0]) name.lowercase() else name
    }

    Row {
        // ── Fixed left: string name labels ──────────────────────────────────
        Box(
            modifier = Modifier
                .width(labelWidthDp)
                .height(fretNumHDp + boardHeightDp)
        ) {
            Canvas(modifier = Modifier.matchParentSize()) {
                val paint = Paint().apply {
                    isAntiAlias  = true
                    typeface     = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                    textSize     = labelSizePx
                    textAlign    = Paint.Align.CENTER
                }
                for (s in 0 until STRING_COUNT) {
                    val y     = fretNumHPx + stringY(s)
                    val label = stringNames[s]
                    // Low strings slightly brighter (thicker gauge feel)
                    val alpha = (200 - s * 18).coerceAtLeast(120)
                    paint.color = android.graphics.Color.WHITE
                    paint.alpha = alpha
                    drawIntoCanvas { c ->
                        c.nativeCanvas.drawText(label, size.width / 2f, y + labelSizePx * 0.38f, paint)
                    }
                }
            }
        }

        // ── Scrollable: fret numbers + fretboard ────────────────────────────
        Column(
            modifier = Modifier
                .weight(1f)
                .horizontalScroll(scrollState)
        ) {
            // Fret number row
            Canvas(
                modifier = Modifier
                    .width(totalWidthDp)
                    .height(fretNumHDp)
            ) {
                val paint = Paint().apply {
                    isAntiAlias = true
                    textSize    = fretNumSizePx
                    textAlign   = Paint.Align.CENTER
                    color       = android.graphics.Color.WHITE
                    alpha       = 110
                }
                // "open" label above nut
                drawIntoCanvas { c ->
                    c.nativeCanvas.drawText("0", fretCenter(0), fretNumHPx * 0.82f, paint)
                    for (f in 1..displayFrets) {
                        c.nativeCanvas.drawText(
                            f.toString(),
                            fretCenter(f),
                            fretNumHPx * 0.82f,
                            paint
                        )
                    }
                }
                // Thin separator line below numbers
                drawLine(
                    color       = Color.White.copy(alpha = 0.08f),
                    start       = Offset(0f, fretNumHPx - 1f),
                    end         = Offset(size.width, fretNumHPx - 1f),
                    strokeWidth = 1f
                )
            }

            // Fretboard canvas
            Canvas(
                modifier = Modifier
                    .width(totalWidthDp)
                    .height(boardHeightDp)
                    .background(Brush.horizontalGradient(style.boardColors))
                    .pointerInput(onFretTap, displayFrets) {
                        if (onFretTap == null) return@pointerInput
                        detectTapGestures { offset ->
                            val fret = if (offset.x < nutWidthPx) 0
                            else ((offset.x - nutWidthPx) / fretWidthPx).toInt() + 1
                            val fretClamped = fret.coerceIn(0, displayFrets)
                            val spacing = size.height / (STRING_COUNT + 1)
                            val string  = ((offset.y / spacing) - 1).toInt().coerceIn(0, STRING_COUNT - 1)
                            onFretTap(string, fretClamped)
                        }
                    }
            ) {
                val spacing   = boardHeightPx / (STRING_COUNT + 1)
                val fretBrush = Brush.verticalGradient(style.fretColors)
                val strBrush  = Brush.horizontalGradient(style.stringColors)

                // Nut
                drawRect(
                    color     = style.nutColor,
                    topLeft   = Offset(0f, 0f),
                    size      = Size(nutWidthPx, boardHeightPx)
                )
                // Subtle nut edge highlight
                drawLine(
                    color       = Color.White.copy(alpha = 0.18f),
                    start       = Offset(nutWidthPx - 1f, 2f),
                    end         = Offset(nutWidthPx - 1f, boardHeightPx - 2f),
                    strokeWidth = 1f
                )

                // Fret wires
                for (f in 1..displayFrets) {
                    val x = nutWidthPx + (f - 1) * fretWidthPx
                    drawLine(
                        brush       = fretBrush,
                        start       = Offset(x, 3f),
                        end         = Offset(x, boardHeightPx - 3f),
                        strokeWidth = if (f == 1) 3.5f else 2f,
                        cap         = StrokeCap.Round
                    )
                    // Fret highlight (light edge on left side of wire)
                    drawLine(
                        color       = Color.White.copy(alpha = 0.12f),
                        start       = Offset(x - 1f, 3f),
                        end         = Offset(x - 1f, boardHeightPx - 3f),
                        strokeWidth = 1f
                    )
                }

                // Strings — graduated thickness low→high
                for (s in 0 until STRING_COUNT) {
                    val y         = stringY(s)
                    val thickness = 3.2f - s * 0.38f  // low E ~3.2px, high e ~1.1px
                    drawLine(
                        brush       = strBrush,
                        start       = Offset(0f, y),
                        end         = Offset(size.width, y),
                        strokeWidth = thickness,
                        cap         = StrokeCap.Butt
                    )
                }

                // Inlay dots
                val pearl = style.pearlBase
                for (f in 1..displayFrets) {
                    val cx = fretCenter(f)
                    if (f in INLAY_FRETS) {
                        // Outer glow
                        drawCircle(color = pearl.copy(alpha = 0.18f), radius = 9f,  center = Offset(cx, boardHeightPx / 2f))
                        // Pearl dot
                        drawCircle(color = pearl.copy(alpha = 0.60f), radius = 5.5f, center = Offset(cx, boardHeightPx / 2f))
                        // Specular
                        drawCircle(color = Color.White.copy(alpha = 0.35f), radius = 2f, center = Offset(cx - 1.5f, boardHeightPx / 2f - 1.5f))
                    }
                    if (f == INLAY_DOUBLE) {
                        for (dotY in listOf(spacing * 2f, spacing * 5f)) {
                            drawCircle(color = pearl.copy(alpha = 0.18f), radius = 9f,   center = Offset(cx, dotY))
                            drawCircle(color = pearl.copy(alpha = 0.60f), radius = 5.5f, center = Offset(cx, dotY))
                            drawCircle(color = Color.White.copy(alpha = 0.35f), radius = 2f, center = Offset(cx - 1.5f, dotY - 1.5f))
                        }
                    }
                }

                // Flash positions (Memory mode)
                for (pos in flashPositions) {
                    if (pos.fret > displayFrets) continue
                    drawFretDot(fretCenter(pos.fret), stringY(pos.string), Color(0xFFE94560))
                }

                // Found positions (correct — green)
                for (pos in foundPositions) {
                    if (pos.fret > displayFrets) continue
                    drawFretDot(fretCenter(pos.fret), stringY(pos.string), Color(0xFF2ECC71))
                }

                // Wrong flash (red)
                for (pos in wrongPositions) {
                    if (pos.fret > displayFrets) continue
                    drawFretDot(fretCenter(pos.fret), stringY(pos.string), Color(0xFFE74C3C))
                }

                // Highlight dot (Name That Note)
                if (highlightString != null && highlightFret != null && highlightFret <= displayFrets) {
                    val cx = fretCenter(highlightFret)
                    val cy = stringY(highlightString)
                    // Outer glow
                    drawCircle(color = highlightColor.copy(alpha = 0.25f), radius = 20f, center = Offset(cx, cy))
                    // Dot
                    drawFretDot(cx, cy, highlightColor, radius = 14f)
                }
            }
        }
    }
}

// Draws a polished fret dot with inner highlight
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawFretDot(
    cx: Float, cy: Float, color: Color, radius: Float = 12f
) {
    // Shadow/glow
    drawCircle(color = color.copy(alpha = 0.22f), radius = radius + 5f, center = Offset(cx, cy))
    // Filled dot
    drawCircle(color = color, radius = radius, center = Offset(cx, cy))
    // Specular highlight (top-left)
    drawCircle(
        color  = Color.White.copy(alpha = 0.28f),
        radius = radius * 0.38f,
        center = Offset(cx - radius * 0.28f, cy - radius * 0.28f)
    )
    // Outer ring
    drawCircle(
        color       = Color.White.copy(alpha = 0.15f),
        radius      = radius,
        center      = Offset(cx, cy),
        style       = Stroke(width = 1.5f)
    )
}
