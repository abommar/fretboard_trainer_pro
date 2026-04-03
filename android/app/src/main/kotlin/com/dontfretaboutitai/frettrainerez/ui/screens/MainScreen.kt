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
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dontfretaboutitai.frettrainerez.audio.NoteAudioEngine
import com.dontfretaboutitai.frettrainerez.game.AnswerState
import com.dontfretaboutitai.frettrainerez.game.Difficulty
import com.dontfretaboutitai.frettrainerez.game.FretAnswerState
import com.dontfretaboutitai.frettrainerez.game.GameMode
import com.dontfretaboutitai.frettrainerez.game.GameState
import com.dontfretaboutitai.frettrainerez.game.MemoryPhase
import com.dontfretaboutitai.frettrainerez.models.FretPosition
import com.dontfretaboutitai.frettrainerez.models.FretboardStyle
import com.dontfretaboutitai.frettrainerez.ui.components.AppDrawer
import com.dontfretaboutitai.frettrainerez.ui.components.AppScreen
import com.dontfretaboutitai.frettrainerez.ui.components.FretboardView
import com.dontfretaboutitai.frettrainerez.ui.components.NoteAnswerButtons
import com.dontfretaboutitai.frettrainerez.ui.theme.AccentGold
import com.dontfretaboutitai.frettrainerez.ui.theme.AccentRed
import com.dontfretaboutitai.frettrainerez.ui.theme.BgColor
import com.dontfretaboutitai.frettrainerez.ui.theme.CardBg
import com.dontfretaboutitai.frettrainerez.ui.theme.CorrectGreen
import com.dontfretaboutitai.frettrainerez.ui.theme.DrawerBg
import com.dontfretaboutitai.frettrainerez.ui.theme.TextMuted
import com.dontfretaboutitai.frettrainerez.ui.theme.TextPrimary
import kotlinx.coroutines.launch

@Composable
fun MainScreen(
    gameState: GameState,
    audioEngine: NoteAudioEngine,
    soundEnabled: Boolean,
    useFlats: Boolean,
    fretboardStyle: FretboardStyle,
    modifier: Modifier = Modifier,
) {
    val drawerState      = rememberDrawerState(DrawerValue.Closed)
    val scope            = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    // Play tone on new Name-It question
    LaunchedEffect(gameState.questionIndex) {
        if (gameState.gameMode == GameMode.NAME_THE_NOTE && soundEnabled) {
            audioEngine.play(gameState.currentString, gameState.currentFret)
        }
    }

    ModalNavigationDrawer(
        drawerState   = drawerState,
        scrimColor    = Color.Black.copy(alpha = 0.55f),
        drawerContent = {
            ModalDrawerSheet(drawerContainerColor = DrawerBg) {
                AppDrawer(
                    onNavigate = { screen ->
                        scope.launch {
                            drawerState.close()
                            snackbarHostState.showSnackbar("${screen.label} — coming soon")
                        }
                    },
                    onClose = { scope.launch { drawerState.close() } }
                )
            }
        },
    ) {
        Box(modifier = modifier.fillMaxSize()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .background(BgColor)
                    .statusBarsPadding(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                TopBar(
                    gameState  = gameState,
                    onMenuOpen = { scope.launch { drawerState.open() } }
                )

                ModeSelector(gameState = gameState)

                ScoreRow(gameState = gameState)

                // Fretboard
                val wrongPos = buildSet {
                    val fas = gameState.fretAnswerState
                    if (fas is FretAnswerState.Wrong) add(FretPosition(fas.string, fas.fret))
                }

                FretboardView(
                    style          = fretboardStyle,
                    highlightString = if (gameState.gameMode == GameMode.NAME_THE_NOTE) gameState.currentString else null,
                    highlightFret   = if (gameState.gameMode == GameMode.NAME_THE_NOTE) gameState.currentFret else null,
                    foundPositions  = gameState.foundFrets,
                    wrongPositions  = wrongPos,
                    flashPositions  = if (gameState.gameMode == GameMode.MEMORY_CHALLENGE &&
                        gameState.memoryPhase == MemoryPhase.FLASHING) gameState.required else emptySet(),
                    useFlats        = useFlats,
                    maxFret         = gameState.difficulty.maxFret,
                    tuning          = gameState.fretboard.tuning,
                    onFretTap       = { s, f ->
                        when (gameState.gameMode) {
                            GameMode.FIND_THE_FRET    -> {
                                if (soundEnabled) audioEngine.play(s, f)
                                gameState.submitFret(s, f)
                            }
                            GameMode.MEMORY_CHALLENGE -> {
                                if (soundEnabled) audioEngine.play(s, f)
                                gameState.submitMemoryTap(s, f)
                            }
                            else -> {}
                        }
                    },
                )

                Spacer(Modifier.height(8.dp))
                PromptText(gameState = gameState, useFlats = useFlats)
                Spacer(Modifier.height(8.dp))

                when (gameState.gameMode) {
                    GameMode.NAME_THE_NOTE    -> NoteAnswerButtons(
                        answerState = gameState.answerState,
                        correctNote = gameState.correctNote,
                        useFlats    = useFlats,
                        onAnswer    = { gameState.submit(it) },
                    )
                    GameMode.FIND_THE_FRET    -> FindItControls(gameState)
                    GameMode.MEMORY_CHALLENGE -> MemoryControls(gameState)
                }

                Spacer(Modifier.height(8.dp))
                DifficultySelector(gameState = gameState)
                Spacer(Modifier.weight(1f))
            }

            SnackbarHost(
                hostState = snackbarHostState,
                modifier  = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 16.dp)
            )
        }
    }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

@Composable
private fun TopBar(gameState: GameState, onMenuOpen: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment     = Alignment.CenterVertically,
    ) {
        IconButton(onClick = onMenuOpen) {
            Icon(
                imageVector        = Icons.Default.Menu,
                contentDescription = "Menu",
                tint               = TextPrimary,
                modifier           = Modifier.size(22.dp),
            )
        }

        Text(
            text       = "FretTrainer EZ",
            color      = TextPrimary,
            fontSize   = 17.sp,
            fontWeight = FontWeight.Black,
        )

        // Right side: streak badge or spacer to keep title centered
        Box(modifier = Modifier.padding(end = 8.dp)) {
            if (gameState.currentStreak >= 2) {
                Text(
                    text       = "🔥 ${gameState.currentStreak}",
                    color      = AccentGold,
                    fontSize   = 13.sp,
                    fontWeight = FontWeight.Bold,
                )
            } else {
                // Invisible spacer same width as hamburger icon
                Spacer(Modifier.size(40.dp))
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Mode selector
// ---------------------------------------------------------------------------

@Composable
private fun ModeSelector(gameState: GameState) {
    Row(
        modifier              = Modifier.fillMaxWidth().padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        GameMode.entries.forEach { mode ->
            val selected = mode == gameState.gameMode
            Button(
                onClick  = { gameState.changeMode(mode) },
                modifier = Modifier.weight(1f).height(36.dp),
                colors   = ButtonDefaults.buttonColors(
                    containerColor = if (selected) AccentRed else CardBg,
                ),
                shape = RoundedCornerShape(8.dp),
            ) {
                Text(
                    text       = mode.shortName,
                    fontSize   = 12.sp,
                    fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                    color      = if (selected) TextPrimary else TextMuted,
                )
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Score row
// ---------------------------------------------------------------------------

@Composable
private fun ScoreRow(gameState: GameState) {
    Row(
        modifier              = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(
            text = if (gameState.totalCount == 0) "Ready" else "${gameState.correctCount}/${gameState.totalCount}",
            color    = TextMuted,
            fontSize = 12.sp,
        )
        Text(
            text     = if (gameState.totalCount == 0) "" else "${gameState.scorePercent}%",
            color    = when {
                gameState.totalCount == 0   -> TextMuted
                gameState.scorePercent >= 80 -> CorrectGreen
                gameState.scorePercent >= 50 -> AccentGold
                else                         -> Color(0xFFE74C3C)
            },
            fontSize   = 12.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

// ---------------------------------------------------------------------------
// Prompt text
// ---------------------------------------------------------------------------

@Composable
private fun PromptText(gameState: GameState, useFlats: Boolean) {
    val text = when (gameState.gameMode) {
        GameMode.NAME_THE_NOTE    -> "What note is this?"
        GameMode.FIND_THE_FRET    -> "Find all  ${gameState.correctNote.displayName(useFlats)}  on the fretboard"
        GameMode.MEMORY_CHALLENGE -> when (gameState.memoryPhase) {
            MemoryPhase.FLASHING  -> "Memorize the positions…"
            MemoryPhase.RECALLING -> "Tap from memory!"
            MemoryPhase.COMPLETE  -> "Round complete!"
        }
    }

    Text(
        text       = text,
        color      = TextPrimary,
        fontSize   = 15.sp,
        fontWeight = FontWeight.SemiBold,
        textAlign  = TextAlign.Center,
        modifier   = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
    )
}

// ---------------------------------------------------------------------------
// Find It controls
// ---------------------------------------------------------------------------

@Composable
private fun FindItControls(gameState: GameState) {
    Row(
        modifier              = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.Center,
    ) {
        Button(
            onClick = { gameState.skipNote() },
            colors  = ButtonDefaults.buttonColors(containerColor = CardBg),
            shape   = RoundedCornerShape(8.dp),
        ) {
            Text("Skip  →", color = TextMuted, fontSize = 13.sp)
        }
    }
}

// ---------------------------------------------------------------------------
// Memory controls
// ---------------------------------------------------------------------------

@Composable
private fun MemoryControls(gameState: GameState) {
    val phase = gameState.memoryPhase
    Text(
        text = when (phase) {
            MemoryPhase.FLASHING  -> "Watch carefully…"
            MemoryPhase.RECALLING -> "Tap all ${gameState.required.size} positions from memory"
            MemoryPhase.COMPLETE  -> "✓ All positions found!"
        },
        color      = when (phase) {
            MemoryPhase.COMPLETE -> CorrectGreen
            MemoryPhase.FLASHING -> AccentGold
            else                 -> TextMuted
        },
        fontSize   = 13.sp,
        fontWeight = FontWeight.Medium,
        textAlign  = TextAlign.Center,
        modifier   = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
    )
}

// ---------------------------------------------------------------------------
// Difficulty selector
// ---------------------------------------------------------------------------

@Composable
private fun DifficultySelector(gameState: GameState) {
    Row(
        modifier              = Modifier.fillMaxWidth().padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Difficulty.entries.forEach { d ->
            val selected = d == gameState.difficulty
            Button(
                onClick  = { gameState.changeDifficulty(d) },
                modifier = Modifier.weight(1f).height(32.dp),
                colors   = ButtonDefaults.buttonColors(
                    containerColor = if (selected) Color(0xFF2A2A50) else CardBg,
                ),
                shape = RoundedCornerShape(6.dp),
            ) {
                Text(
                    text       = d.displayName,
                    fontSize   = 11.sp,
                    color      = if (selected) TextPrimary else TextMuted,
                    fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                )
            }
        }
    }
}
