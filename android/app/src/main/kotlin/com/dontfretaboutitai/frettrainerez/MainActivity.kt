package com.dontfretaboutitai.frettrainerez

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.dontfretaboutitai.frettrainerez.audio.NoteAudioEngine
import com.dontfretaboutitai.frettrainerez.game.GameState
import com.dontfretaboutitai.frettrainerez.models.FretboardStyle
import com.dontfretaboutitai.frettrainerez.ui.screens.MainScreen
import com.dontfretaboutitai.frettrainerez.ui.theme.FretTrainerTheme

class MainActivity : ComponentActivity() {

    private val gameState: GameState by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val prefs        = getSharedPreferences("fret_trainer_ui", Context.MODE_PRIVATE)
        val audioEngine  = NoteAudioEngine()

        setContent {
            FretTrainerTheme {
                var soundEnabled   by remember { mutableStateOf(prefs.getBoolean("soundEnabled",   false)) }
                var useFlats       by remember { mutableStateOf(prefs.getBoolean("useFlats",       false)) }
                var fretboardStyle by remember {
                    mutableStateOf(
                        prefs.getString("fretboardStyle", FretboardStyle.ROSEWOOD.name)
                            ?.let { runCatching { FretboardStyle.valueOf(it) }.getOrNull() }
                            ?: FretboardStyle.ROSEWOOD
                    )
                }

                MainScreen(
                    gameState      = gameState,
                    audioEngine    = audioEngine,
                    soundEnabled   = soundEnabled,
                    useFlats       = useFlats,
                    fretboardStyle = fretboardStyle,
                )
            }
        }
    }
}
