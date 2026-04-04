package com.dontfretaboutitai.frettrainerez.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dontfretaboutitai.frettrainerez.models.FretboardStyle
import com.dontfretaboutitai.frettrainerez.ui.theme.AccentRed
import com.dontfretaboutitai.frettrainerez.ui.theme.BgColor
import com.dontfretaboutitai.frettrainerez.ui.theme.CardBg
import com.dontfretaboutitai.frettrainerez.ui.theme.TextMuted
import com.dontfretaboutitai.frettrainerez.ui.theme.TextPrimary

@Composable
fun FretboardStyleScreen(
    selectedStyle: FretboardStyle,
    onStyleSelected: (FretboardStyle) -> Unit,
    onBack: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgColor)
            .statusBarsPadding(),
    ) {
        // Top nav bar
        StyleTopBar(onBack = onBack)

        Spacer(modifier = Modifier.height(8.dp))

        LazyColumn(
            modifier            = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            items(FretboardStyle.entries) { style ->
                StyleRow(
                    style      = style,
                    isSelected = style == selectedStyle,
                    onSelect   = { onStyleSelected(style) },
                )
            }
            item { Spacer(modifier = Modifier.height(8.dp)) }
        }
    }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

@Composable
private fun StyleTopBar(onBack: () -> Unit) {
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
            text       = "Fretboard Style",
            color      = TextPrimary,
            fontSize   = 17.sp,
            fontWeight = FontWeight.Bold,
            modifier   = Modifier.align(Alignment.Center),
        )
    }
}

// ---------------------------------------------------------------------------
// Style row
// ---------------------------------------------------------------------------

@Composable
private fun StyleRow(
    style: FretboardStyle,
    isSelected: Boolean,
    onSelect: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(CardBg, RoundedCornerShape(12.dp))
            .clip(RoundedCornerShape(12.dp))
            .clickable(onClick = onSelect)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment     = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        // Mini fretboard preview (160×52 dp)
        FretboardMiniPreview(
            style    = style,
            modifier = Modifier
                .width(160.dp)
                .height(52.dp)
                .clip(RoundedCornerShape(6.dp)),
        )

        // Name + descriptor
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text       = style.displayName,
                color      = TextPrimary,
                fontSize   = 15.sp,
                fontWeight = FontWeight.Bold,
            )
            Text(
                text     = style.descriptor,
                color    = TextMuted,
                fontSize = 12.sp,
            )
        }

        // Selected checkmark
        if (isSelected) {
            Icon(
                imageVector        = Icons.Default.Check,
                contentDescription = "Selected",
                tint               = AccentRed,
                modifier           = Modifier.size(22.dp),
            )
        } else {
            Spacer(modifier = Modifier.size(22.dp))
        }
    }
}

// ---------------------------------------------------------------------------
// Canvas mini-preview
// ---------------------------------------------------------------------------

@Composable
private fun FretboardMiniPreview(
    style: FretboardStyle,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier = modifier) {
        val w = size.width
        val h = size.height

        // Board gradient (horizontal)
        drawRect(
            brush = Brush.horizontalGradient(style.boardColors),
            size  = Size(w, h),
        )

        // Nut (left edge)
        val nutW = w * 0.055f
        drawRect(
            color   = style.nutColor,
            topLeft = Offset(0f, 0f),
            size    = Size(nutW, h),
        )

        // 6 fret wires
        val fretColor  = style.fretColors[1]
        val fretSpaceW = (w - nutW) / 6f
        for (i in 1..6) {
            val x = nutW + i * fretSpaceW
            drawLine(
                color       = fretColor,
                start       = Offset(x, 2f),
                end         = Offset(x, h - 2f),
                strokeWidth = if (i == 1) 2.5f else 1.5f,
                cap         = StrokeCap.Round,
            )
        }

        // 6 strings (horizontal)
        val stringColor  = style.stringColors[1]
        val stringSpaceH = h / 7f
        for (s in 1..6) {
            val y         = s * stringSpaceH
            val thickness = 2.2f - (s - 1) * 0.22f   // thicker at top (low E, string index 0)
            drawLine(
                color       = stringColor,
                start       = Offset(0f, y),
                end         = Offset(w, y),
                strokeWidth = thickness,
                cap         = StrokeCap.Butt,
            )
        }

        // Pearl inlay dots at fret slots 2 and 4
        val pearl = style.pearlBase
        for (fretSlot in listOf(2, 4)) {
            val cx = nutW + (fretSlot - 0.5f) * fretSpaceW
            val cy = h / 2f
            drawCircle(color = pearl.copy(alpha = 0.18f), radius = 6f,  center = Offset(cx, cy))
            drawCircle(color = pearl.copy(alpha = 0.65f), radius = 3.5f, center = Offset(cx, cy))
            drawCircle(color = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.35f), radius = 1.4f, center = Offset(cx - 1f, cy - 1f))
        }
    }
}
