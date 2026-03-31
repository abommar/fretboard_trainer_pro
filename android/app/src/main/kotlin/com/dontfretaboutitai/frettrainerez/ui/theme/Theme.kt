package com.dontfretaboutitai.frettrainerez.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val DarkColors = darkColorScheme(
    primary          = AccentRed,
    secondary        = AccentGold,
    background       = BgColor,
    surface          = CardBg,
    onPrimary        = TextPrimary,
    onSecondary      = TextPrimary,
    onBackground     = TextPrimary,
    onSurface        = TextPrimary,
    error            = WrongRed,
    onError          = TextPrimary,
)

@Composable
fun FretTrainerTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColors,
        content     = content
    )
}
