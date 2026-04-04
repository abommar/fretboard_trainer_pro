package com.dontfretaboutitai.frettrainerez.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Vibration
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
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
import com.dontfretaboutitai.frettrainerez.ui.theme.TextMuted
import com.dontfretaboutitai.frettrainerez.ui.theme.TextPrimary

@Composable
fun SettingsScreen(
    soundEnabled: Boolean,
    hapticsEnabled: Boolean,
    useFlats: Boolean,
    onSoundToggle: (Boolean) -> Unit,
    onHapticsToggle: (Boolean) -> Unit,
    onFlatsToggle: (Boolean) -> Unit,
    onBack: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgColor)
            .statusBarsPadding(),
    ) {
        // Top nav bar
        SettingsTopBar(onBack = onBack)

        Spacer(modifier = Modifier.height(8.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            SettingsToggleRow(
                icon       = Icons.Default.VolumeUp,
                iconTint   = Color(0xFF2ECC71),
                title      = "Sound Effects",
                subtitle   = "Play fret tones during gameplay",
                checked    = soundEnabled,
                onChecked  = onSoundToggle,
            )

            SettingsToggleRow(
                icon       = Icons.Default.Vibration,
                iconTint   = Color(0xFFFF9800),
                title      = "Haptic Feedback",
                subtitle   = "Vibrate on correct and wrong answers",
                checked    = hapticsEnabled,
                onChecked  = onHapticsToggle,
            )

            SettingsToggleRow(
                icon       = Icons.Default.MusicNote,
                iconTint   = Color(0xFF9C27B0),
                title      = "Use Flat Names",
                subtitle   = "Show Bb, Eb instead of A#, D#",
                checked    = useFlats,
                onChecked  = onFlatsToggle,
            )
        }
    }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

@Composable
private fun SettingsTopBar(onBack: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(CardBg)
            .padding(horizontal = 4.dp, vertical = 4.dp),
    ) {
        // Back button — left
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

        // Title — centered
        Text(
            text       = "Settings",
            color      = TextPrimary,
            fontSize   = 17.sp,
            fontWeight = FontWeight.Bold,
            modifier   = Modifier.align(Alignment.Center),
        )
    }
}

// ---------------------------------------------------------------------------
// Toggle row
// ---------------------------------------------------------------------------

@Composable
private fun SettingsToggleRow(
    icon: ImageVector,
    iconTint: Color,
    title: String,
    subtitle: String,
    checked: Boolean,
    onChecked: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(CardBg, RoundedCornerShape(12.dp))
            .padding(horizontal = 14.dp, vertical = 14.dp),
        verticalAlignment     = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        // Icon badge
        Box(
            modifier          = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(iconTint.copy(alpha = 0.18f)),
            contentAlignment  = Alignment.Center,
        ) {
            Icon(
                imageVector        = icon,
                contentDescription = null,
                tint               = iconTint,
                modifier           = Modifier.size(22.dp),
            )
        }

        // Text
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text       = title,
                color      = TextPrimary,
                fontSize   = 15.sp,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                text     = subtitle,
                color    = TextMuted,
                fontSize = 12.sp,
            )
        }

        // Switch
        Switch(
            checked         = checked,
            onCheckedChange = onChecked,
            colors          = SwitchDefaults.colors(
                checkedThumbColor       = AccentRed,
                checkedTrackColor       = AccentRed.copy(alpha = 0.38f),
                uncheckedThumbColor     = TextMuted,
                uncheckedTrackColor     = TextMuted.copy(alpha = 0.25f),
            ),
        )
    }
}
