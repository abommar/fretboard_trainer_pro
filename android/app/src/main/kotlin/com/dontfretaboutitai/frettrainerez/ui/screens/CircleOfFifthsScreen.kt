package com.dontfretaboutitai.frettrainerez.ui.screens

import android.content.res.Configuration
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dontfretaboutitai.frettrainerez.models.ChordFunction
import com.dontfretaboutitai.frettrainerez.models.DiatonicChord
import com.dontfretaboutitai.frettrainerez.models.MusicTheory
import com.dontfretaboutitai.frettrainerez.ui.theme.CardBg
import com.dontfretaboutitai.frettrainerez.ui.theme.BgColor
import com.dontfretaboutitai.frettrainerez.ui.theme.TextMuted
import com.dontfretaboutitai.frettrainerez.ui.theme.TextPrimary
import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

// Function colors matching iOS
private val TonicColor       = Color(0xFF2ECC71)   // green
private val SubdominantColor = Color(0xFF4499FF)   // blue
private val DominantColor    = Color(0xFFFF8C00)   // orange

private fun functionColor(fn: ChordFunction): Color = when (fn) {
    ChordFunction.TONIC       -> TonicColor
    ChordFunction.SUBDOMINANT -> SubdominantColor
    ChordFunction.DOMINANT    -> DominantColor
}

private fun keyOuterColor(i: Int): Color =
    Color.hsv(i / 12f * 360f, 0.55f, 0.45f)

private fun keyInnerColor(i: Int): Color =
    Color.hsv(i / 12f * 360f, 0.35f, 0.30f)

// ── Circle canvas composable ──────────────────────────────────────────────────

@Composable
private fun CoFCanvas(
    selectedKey: Int?,
    highlightMap: Map<Int, ChordFunction>,
    useFlats: Boolean,
    modifier: Modifier = Modifier,
    onKeySelected: (Int?) -> Unit,
) {
    val density = LocalDensity.current
    Canvas(
        modifier = modifier
            .pointerInput(Unit) {
                detectTapGestures { offset ->
                    val w  = size.width.toFloat()
                    val cx = w / 2f
                    val cy = size.height.toFloat() / 2f
                    val dx = offset.x - cx
                    val dy = offset.y - cy
                    val r       = sqrt(dx * dx + dy * dy)
                    val outerR  = w / 2f * 0.92f
                    val innerR  = w / 2f * 0.36f

                    if (r < innerR || r > outerR) {
                        onKeySelected(null)
                        return@detectTapGestures
                    }
                    var angle = atan2(dy, dx) + PI.toFloat() / 2f
                    if (angle < 0) angle += 2f * PI.toFloat()
                    val sliceAngle = 2f * PI.toFloat() / 12f
                    val index = ((angle / sliceAngle).roundToInt() % 12 + 12) % 12
                    onKeySelected(if (selectedKey == index) null else index)
                }
            }
    ) {
        drawCoFCircle(
            selectedKey   = selectedKey,
            highlightMap  = highlightMap,
            useFlats      = useFlats,
            labelSizePx   = with(density) { 12.sp.toPx() },
            relLabelPx    = with(density) { 9.sp.toPx() },
            centerLabelPx = with(density) { 9.sp.toPx() },
        )
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun CircleOfFifthsScreen(
    useFlats: Boolean,
    onBack: () -> Unit,
) {
    var selectedKey by remember { mutableStateOf<Int?>(null) }

    val highlightMap = remember(selectedKey) {
        selectedKey?.let { MusicTheory.diatonicCirclePositions(it) } ?: emptyMap()
    }

    val isLandscape = LocalConfiguration.current.orientation == Configuration.ORIENTATION_LANDSCAPE

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgColor)
            .statusBarsPadding(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        CoFTopBar(onBack = onBack)

        if (isLandscape) {
            // ── Landscape: circle on left, detail card on right ──────────────
            Row(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
            ) {
                // Left: square circle canvas
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .aspectRatio(1f)
                        .padding(12.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    CoFCanvas(
                        selectedKey  = selectedKey,
                        highlightMap = highlightMap,
                        useFlats     = useFlats,
                        modifier     = Modifier.fillMaxSize(),
                        onKeySelected = { selectedKey = it },
                    )
                }

                // Vertical divider
                Box(
                    modifier = Modifier
                        .width(1.dp)
                        .fillMaxHeight()
                        .background(Color.White.copy(alpha = 0.08f)),
                )

                // Right: fixed (no scroll) detail area in landscape
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    if (selectedKey == null) {
                        Text(
                            text     = "Tap a key to explore",
                            color    = TextMuted.copy(alpha = 0.5f),
                            fontSize = 13.sp,
                            modifier = Modifier.padding(top = 4.dp),
                        )
                    } else {
                        KeyDetailCard(
                            selectedKey = selectedKey!!,
                            useFlats    = useFlats,
                            applyHorizontalPadding = false,
                            compact = true,
                        )
                    }
                }
            }
        } else {
            // ── Portrait: stacked layout ─────────────────────────────────────
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Spacer(Modifier.height(12.dp))

                // Circle canvas — square (aspectRatio 1:1) so it never overflows
                Box(
                    modifier = Modifier
                        .padding(horizontal = 24.dp)
                        .fillMaxWidth()
                        .aspectRatio(1f),
                    contentAlignment = Alignment.Center,
                ) {
                    CoFCanvas(
                        selectedKey   = selectedKey,
                        highlightMap  = highlightMap,
                        useFlats      = useFlats,
                        modifier      = Modifier.fillMaxSize(),
                        onKeySelected = { selectedKey = it },
                    )
                }

                Spacer(Modifier.height(12.dp))

                // Detail card or hint
                if (selectedKey == null) {
                    Text(
                        text     = "Tap a key to explore",
                        color    = TextMuted.copy(alpha = 0.5f),
                        fontSize = 13.sp,
                        modifier = Modifier.padding(top = 4.dp),
                    )
                } else {
                    KeyDetailCard(
                        selectedKey = selectedKey!!,
                        useFlats    = useFlats,
                        applyHorizontalPadding = true,
                    )
                }

                Spacer(Modifier.height(24.dp))
            }
        }
    }
}

// ── Key detail card ───────────────────────────────────────────────────────────

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun KeyDetailCard(
    selectedKey: Int,
    useFlats: Boolean,
    applyHorizontalPadding: Boolean = true,
    compact: Boolean = false,
) {
    val ki             = MusicTheory.circleOfFifths[selectedKey]
    val keyName        = MusicTheory.enharmonicLabel(ki.major, selectedKey)
    val diatonicChords = remember(selectedKey, useFlats) {
        MusicTheory.diatonicChords(selectedKey, useFlats)
    }

    val outerSpacing = if (compact) 6.dp else 12.dp
    val cardPadding  = if (compact) 10.dp else 16.dp

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (applyHorizontalPadding) Modifier.padding(horizontal = 16.dp) else Modifier)
            .background(CardBg, RoundedCornerShape(12.dp))
            .clip(RoundedCornerShape(12.dp))
            .padding(cardPadding),
        verticalArrangement = Arrangement.spacedBy(outerSpacing),
    ) {
        // 1. Key name
        Text(
            text       = keyName,
            color      = TextPrimary,
            fontSize   = if (compact) 16.sp else 18.sp,
            fontWeight = FontWeight.Bold,
        )

        // 2. Diatonic chords — FlowRow of pill chips
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalArrangement   = Arrangement.spacedBy(6.dp),
        ) {
            diatonicChords.forEach { chord ->
                val fc = functionColor(chord.chordFunction)
                Column(
                    modifier = Modifier
                        .background(fc.copy(alpha = 0.25f), RoundedCornerShape(20.dp))
                        .padding(
                            horizontal = if (compact) 10.dp else 12.dp,
                            vertical   = if (compact) 4.dp  else 6.dp,
                        ),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(
                        text       = chord.numeral,
                        color      = fc,
                        fontSize   = 11.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        text     = chord.name,
                        color    = fc,
                        fontSize = 9.sp,
                    )
                }
            }
        }

        // 3. Common progressions
        MusicTheory.commonProgressions.forEach { progression ->
            if (compact) {
                // Single-row layout: name label + chord boxes on same line
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Text(
                        text     = progression.name,
                        color    = TextMuted,
                        fontSize = 9.sp,
                        modifier = Modifier.width(60.dp),
                    )
                    progression.indices.forEach { idx ->
                        val chordName = diatonicChords.getOrNull(idx)?.name ?: ""
                        Text(
                            text       = chordName,
                            color      = TextPrimary,
                            fontSize   = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            modifier   = Modifier
                                .background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(6.dp))
                                .padding(horizontal = 6.dp, vertical = 3.dp),
                        )
                    }
                }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        text     = progression.name,
                        color    = TextMuted,
                        fontSize = 10.sp,
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        progression.indices.forEach { idx ->
                            val chordName = diatonicChords.getOrNull(idx)?.name ?: ""
                            Text(
                                text       = chordName,
                                color      = TextPrimary,
                                fontSize   = 12.sp,
                                fontWeight = FontWeight.SemiBold,
                                modifier   = Modifier
                                    .background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(6.dp))
                                    .padding(horizontal = 8.dp, vertical = 4.dp),
                            )
                        }
                    }
                }
            }
        }
    }
}

// ── Circle drawing ────────────────────────────────────────────────────────────

private fun DrawScope.drawCoFCircle(
    selectedKey:   Int?,
    highlightMap:  Map<Int, ChordFunction>,
    useFlats:      Boolean,
    labelSizePx:   Float,
    relLabelPx:    Float,
    centerLabelPx: Float,
) {
    val cx = size.width  / 2f
    val cy = size.height / 2f
    val outerR = size.width / 2f * 0.92f
    val midR   = size.width / 2f * 0.62f
    val innerR = size.width / 2f * 0.36f

    val sliceDeg = 360f / 12f
    val hasSelection = selectedKey != null

    for (i in 0 until 12) {
        val startDeg = i * sliceDeg - sliceDeg / 2f - 90f
        val isDiatonic  = highlightMap.containsKey(i)
        val isSelected  = selectedKey == i
        val baseAlpha = when {
            !hasSelection            -> 0.75f
            isSelected || isDiatonic -> 0.88f
            else                     -> 0.20f
        }

        // Outer wedge (major key)
        val outerFill = keyOuterColor(i).copy(alpha = baseAlpha)
        val outerPath = wedgePath(cx, cy, midR, outerR, startDeg, sliceDeg)
        drawPath(outerPath, outerFill)
        drawPath(outerPath, Color.Black.copy(alpha = 0.4f), style = Stroke(width = 1f))

        // Inner wedge (relative minor)
        val innerFill = keyInnerColor(i).copy(alpha = baseAlpha)
        val innerPath = wedgePath(cx, cy, innerR, midR, startDeg, sliceDeg)
        drawPath(innerPath, innerFill)
        drawPath(innerPath, Color.Black.copy(alpha = 0.4f), style = Stroke(width = 1f))

        // Chord function overlay
        highlightMap[i]?.let { fn ->
            val overlay = functionColor(fn).copy(alpha = 0.32f)
            drawPath(wedgePath(cx, cy, midR, outerR, startDeg, sliceDeg), overlay)
            drawPath(wedgePath(cx, cy, innerR, midR, startDeg, sliceDeg), overlay)
        }

        // White selection border
        if (isSelected) {
            drawPath(wedgePath(cx, cy, midR, outerR, startDeg, sliceDeg),
                Color.White.copy(alpha = 0.85f), style = Stroke(width = 2.5f))
            drawPath(wedgePath(cx, cy, innerR, midR, startDeg, sliceDeg),
                Color.White.copy(alpha = 0.85f), style = Stroke(width = 2.5f))
        }

        // Labels
        val midAngleRad = Math.toRadians((i * sliceDeg - 90.0))
        val majorLabelR = (midR + outerR) / 2f
        val minorLabelR = (innerR + midR) / 2f

        val ki = MusicTheory.circleOfFifths[i]
        val majorLabel = MusicTheory.enharmonicLabel(ki.major, i)
        val minorLabel = MusicTheory.relativeLabel(ki.relative, i)

        drawIntoCanvas { c ->
            val majorPaint = android.graphics.Paint().apply {
                isAntiAlias = true
                textSize    = labelSizePx
                textAlign   = android.graphics.Paint.Align.CENTER
                color       = android.graphics.Color.WHITE
                alpha       = if (hasSelection && !isSelected && !isDiatonic) 80 else 220
                typeface    = android.graphics.Typeface.create(
                    android.graphics.Typeface.DEFAULT,
                    if (isSelected) android.graphics.Typeface.BOLD else android.graphics.Typeface.NORMAL
                )
            }
            c.nativeCanvas.drawText(
                majorLabel,
                cx + majorLabelR * cos(midAngleRad).toFloat(),
                cy + majorLabelR * sin(midAngleRad).toFloat() + labelSizePx * 0.38f,
                majorPaint,
            )

            val minorPaint = android.graphics.Paint().apply {
                isAntiAlias = true
                textSize    = relLabelPx
                textAlign   = android.graphics.Paint.Align.CENTER
                color       = android.graphics.Color.WHITE
                alpha       = if (hasSelection && !isSelected && !isDiatonic) 50 else 150
            }
            c.nativeCanvas.drawText(
                minorLabel,
                cx + minorLabelR * cos(midAngleRad).toFloat(),
                cy + minorLabelR * sin(midAngleRad).toFloat() + relLabelPx * 0.38f,
                minorPaint,
            )
        }
    }

    // Center circle
    drawCircle(color = Color(0xFF0D0D1E), radius = innerR, center = Offset(cx, cy))
    drawCircle(color = Color.White.copy(alpha = 0.15f), radius = innerR, center = Offset(cx, cy), style = Stroke(width = 1f))

    // Center "Circle\nof 5ths" label
    drawIntoCanvas { c ->
        val p = android.graphics.Paint().apply {
            isAntiAlias = true
            textSize    = centerLabelPx
            textAlign   = android.graphics.Paint.Align.CENTER
            color       = android.graphics.Color.WHITE
            alpha       = 100
        }
        c.nativeCanvas.drawText("Circle", cx, cy - centerLabelPx * 0.5f, p)
        c.nativeCanvas.drawText("of 5ths", cx, cy + centerLabelPx * 0.9f, p)
    }
}

private fun wedgePath(
    cx: Float, cy: Float,
    innerR: Float, outerR: Float,
    startDeg: Float, sweepDeg: Float,
): Path {
    val path     = Path()
    val startRad = Math.toRadians(startDeg.toDouble())
    val endRad   = Math.toRadians((startDeg + sweepDeg).toDouble())

    path.moveTo(cx + outerR * cos(startRad).toFloat(), cy + outerR * sin(startRad).toFloat())
    path.arcTo(
        rect = androidx.compose.ui.geometry.Rect(cx - outerR, cy - outerR, cx + outerR, cy + outerR),
        startAngleDegrees = startDeg,
        sweepAngleDegrees = sweepDeg,
        forceMoveTo = false,
    )
    path.lineTo(cx + innerR * cos(endRad).toFloat(), cy + innerR * sin(endRad).toFloat())
    path.arcTo(
        rect = androidx.compose.ui.geometry.Rect(cx - innerR, cy - innerR, cx + innerR, cy + innerR),
        startAngleDegrees = startDeg + sweepDeg,
        sweepAngleDegrees = -sweepDeg,
        forceMoveTo = false,
    )
    path.close()
    return path
}

// ── Top bar ───────────────────────────────────────────────────────────────────

@Composable
private fun CoFTopBar(onBack: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(CardBg)
            .padding(horizontal = 4.dp, vertical = 4.dp),
    ) {
        IconButton(onClick = onBack, modifier = Modifier.align(Alignment.CenterStart)) {
            Icon(
                imageVector        = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Back",
                tint               = TextPrimary,
                modifier           = Modifier.size(22.dp),
            )
        }
        Text(
            text       = "Circle of Fifths",
            color      = TextPrimary,
            fontSize   = 17.sp,
            fontWeight = FontWeight.Bold,
            modifier   = Modifier.align(Alignment.Center),
        )
    }
}
