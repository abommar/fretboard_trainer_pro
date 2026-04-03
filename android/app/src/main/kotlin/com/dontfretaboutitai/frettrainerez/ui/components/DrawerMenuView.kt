package com.dontfretaboutitai.frettrainerez.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Grain
import androidx.compose.material.icons.filled.LibraryMusic
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Piano
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.outlined.RadioButtonChecked
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dontfretaboutitai.frettrainerez.ui.theme.AccentRed
import com.dontfretaboutitai.frettrainerez.ui.theme.BgColor
import com.dontfretaboutitai.frettrainerez.ui.theme.CardBg
import com.dontfretaboutitai.frettrainerez.ui.theme.DrawerBg
import com.dontfretaboutitai.frettrainerez.ui.theme.TextMuted
import com.dontfretaboutitai.frettrainerez.ui.theme.TextPrimary

enum class AppScreen(val label: String, val subtitle: String, val icon: ImageVector) {
    CIRCLE_OF_FIFTHS("Circle of Fifths",  "Keys & diatonic chords",  Icons.Outlined.RadioButtonChecked),
    CHORD_CHARTS    ("Chord Charts",       "Diagrams & theory",       Icons.Filled.LibraryMusic),
    CHORD_JAM       ("Chord Jam",          "Build progressions",      Icons.Filled.MusicNote),
    TUNER           ("Chromatic Tuner",    "Mic-based pitch detector",Icons.Filled.Tune),
    SCALES          ("Scale Explorer",     "10 scales on the board",  Icons.Filled.Piano),
    STYLE           ("Fretboard Style",    "Wood themes",             Icons.Filled.Grain),
    SETTINGS        ("Settings",           "Sound, display & more",   Icons.Filled.Settings),
}

@Composable
fun AppDrawer(
    onNavigate: (AppScreen) -> Unit,
    onClose: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxHeight()
            .width(290.dp)
            .background(DrawerBg)
            .statusBarsPadding()
    ) {
        // Header
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 24.dp)
        ) {
            Column {
                Text(
                    text       = "FretTrainer EZ",
                    color      = TextPrimary,
                    fontSize   = 20.sp,
                    fontWeight = FontWeight.Black,
                )
                Text(
                    text     = "Guitar Fretboard Trainer",
                    color    = TextMuted,
                    fontSize = 12.sp,
                )
            }
        }

        Divider(color = Color.White.copy(alpha = 0.08f))
        Spacer(Modifier.height(8.dp))

        // Menu items
        AppScreen.entries.forEach { screen ->
            DrawerItem(
                screen    = screen,
                onClick   = { onNavigate(screen) }
            )
        }

        Spacer(Modifier.weight(1f))
        Divider(color = Color.White.copy(alpha = 0.08f))

        // Footer
        Text(
            text     = "Version 1.0",
            color    = TextMuted.copy(alpha = 0.5f),
            fontSize = 11.sp,
            modifier = Modifier.padding(20.dp)
        )
    }
}

@Composable
private fun DrawerItem(
    screen: AppScreen,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 2.dp)
            .clip(RoundedCornerShape(10.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // Icon badge
        Box(
            modifier = Modifier
                .size(36.dp)
                .background(CardBg, RoundedCornerShape(8.dp)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector        = screen.icon,
                contentDescription = screen.label,
                tint               = AccentRed,
                modifier           = Modifier.size(18.dp),
            )
        }

        Spacer(Modifier.width(14.dp))

        Column {
            Text(
                text       = screen.label,
                color      = TextPrimary,
                fontSize   = 14.sp,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                text     = screen.subtitle,
                color    = TextMuted,
                fontSize = 11.sp,
            )
        }
    }
}
