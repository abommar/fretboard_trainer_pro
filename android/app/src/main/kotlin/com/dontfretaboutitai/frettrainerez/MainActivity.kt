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
import com.dontfretaboutitai.frettrainerez.ui.components.AppScreen
import com.dontfretaboutitai.frettrainerez.ui.screens.ChordChartsScreen
import com.dontfretaboutitai.frettrainerez.ui.screens.ChordJamScreen
import com.dontfretaboutitai.frettrainerez.ui.screens.ChromaticTunerScreen
import com.dontfretaboutitai.frettrainerez.ui.screens.CircleOfFifthsScreen
import com.dontfretaboutitai.frettrainerez.ui.screens.FretboardStyleScreen
import com.dontfretaboutitai.frettrainerez.ui.screens.MainScreen
import com.dontfretaboutitai.frettrainerez.ui.screens.ScalesScreen
import com.dontfretaboutitai.frettrainerez.ui.screens.SettingsScreen
import com.dontfretaboutitai.frettrainerez.ui.theme.FretTrainerTheme

class MainActivity : ComponentActivity() {

    private val gameState: GameState by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val prefs       = getSharedPreferences("fret_trainer_ui", Context.MODE_PRIVATE)
        val audioEngine = NoteAudioEngine()

        setContent {
            FretTrainerTheme {
                var soundEnabled    by remember { mutableStateOf(prefs.getBoolean("soundEnabled",    false)) }
                var useFlats        by remember { mutableStateOf(prefs.getBoolean("useFlats",        false)) }
                var hapticsEnabled  by remember { mutableStateOf(prefs.getBoolean("hapticsEnabled",  false)) }
                var fretboardStyle  by remember {
                    mutableStateOf(
                        prefs.getString("fretboardStyle", FretboardStyle.ROSEWOOD.name)
                            ?.let { runCatching { FretboardStyle.valueOf(it) }.getOrNull() }
                            ?: FretboardStyle.ROSEWOOD
                    )
                }
                var activeScreen by remember { mutableStateOf<AppScreen?>(null) }

                when (activeScreen) {
                    AppScreen.CIRCLE_OF_FIFTHS -> CircleOfFifthsScreen(
                        useFlats = useFlats,
                        onBack   = { activeScreen = null },
                    )

                    AppScreen.CHORD_CHARTS -> ChordChartsScreen(
                        useFlats    = useFlats,
                        audioEngine = audioEngine,
                        onBack      = { activeScreen = null },
                    )

                    AppScreen.CHORD_JAM -> ChordJamScreen(
                        useFlats    = useFlats,
                        audioEngine = audioEngine,
                        onBack      = { activeScreen = null },
                    )

                    AppScreen.TUNER -> ChromaticTunerScreen(
                        useFlats = useFlats,
                        onBack   = { activeScreen = null },
                    )

                    AppScreen.SCALES -> ScalesScreen(
                        useFlats = useFlats,
                        onBack   = { activeScreen = null },
                    )

                    AppScreen.STYLE -> FretboardStyleScreen(
                        selectedStyle   = fretboardStyle,
                        onStyleSelected = { style ->
                            fretboardStyle = style
                            prefs.edit().putString("fretboardStyle", style.name).apply()
                        },
                        onBack = { activeScreen = null },
                    )

                    AppScreen.SETTINGS -> SettingsScreen(
                        soundEnabled   = soundEnabled,
                        hapticsEnabled = hapticsEnabled,
                        useFlats       = useFlats,
                        onSoundToggle  = { v ->
                            soundEnabled = v
                            prefs.edit().putBoolean("soundEnabled", v).apply()
                        },
                        onHapticsToggle = { v ->
                            hapticsEnabled = v
                            prefs.edit().putBoolean("hapticsEnabled", v).apply()
                        },
                        onFlatsToggle = { v ->
                            useFlats = v
                            prefs.edit().putBoolean("useFlats", v).apply()
                        },
                        onBack = { activeScreen = null },
                    )

                    null -> MainScreen(
                        gameState      = gameState,
                        audioEngine    = audioEngine,
                        soundEnabled   = soundEnabled,
                        useFlats       = useFlats,
                        fretboardStyle = fretboardStyle,
                        onNavigate     = { screen -> activeScreen = screen },
                    )
                }
            }
        }
    }
}
