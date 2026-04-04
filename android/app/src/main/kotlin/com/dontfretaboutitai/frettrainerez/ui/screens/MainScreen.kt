package com.dontfretaboutitai.frettrainerez.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontFamily
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
import com.dontfretaboutitai.frettrainerez.models.Note
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

// ---------------------------------------------------------------------------
// Layout constants (mirrors iOS ContentView fixed-zone approach)
// ---------------------------------------------------------------------------

private val LANDSCAPE_TOP_BAR_H = 64.dp   // two-row control bar
private val LANDSCAPE_FRETBOARD_H = 148.dp // full-height fretboard in landscape
private val LANDSCAPE_PROMPT_H    = 20.dp  // fixed — prevents fretboard shift
private val LANDSCAPE_GAME_H      = 72.dp  // fixed — prevents fretboard shift

private val PORTRAIT_FRETBOARD_H = 168.dp

private fun formatTime(s: Int): String = "${s / 60}:${(s % 60).toString().padStart(2, '0')}"

// ---------------------------------------------------------------------------
// MainScreen
// ---------------------------------------------------------------------------

@Composable
fun MainScreen(
    gameState: GameState,
    audioEngine: NoteAudioEngine,
    soundEnabled: Boolean,
    useFlats: Boolean,
    fretboardStyle: FretboardStyle,
    onNavigate: (AppScreen) -> Unit = {},
    modifier: Modifier = Modifier,
) {
    val drawerState = rememberDrawerState(DrawerValue.Closed)
    val scope       = rememberCoroutineScope()
    val isLandscape = LocalConfiguration.current.orientation ==
        android.content.res.Configuration.ORIENTATION_LANDSCAPE

    var isStudyMode     by rememberSaveable { mutableStateOf(false) }
    var studyFilterNote by rememberSaveable { mutableStateOf<Note?>(null) }

    LaunchedEffect(gameState.questionIndex) {
        if (gameState.gameMode == GameMode.NAME_THE_NOTE && soundEnabled && !isStudyMode) {
            audioEngine.play(gameState.currentString, gameState.currentFret)
        }
    }

    // Shared fret tap handler
    val onFretTap: (Int, Int) -> Unit = { s, f ->
        if (isStudyMode) {
            if (soundEnabled) audioEngine.play(s, f)
        } else {
            when (gameState.gameMode) {
                GameMode.FIND_THE_FRET -> {
                    if (soundEnabled) audioEngine.play(s, f)
                    gameState.submitFret(s, f)
                }
                GameMode.MEMORY_CHALLENGE -> {
                    if (soundEnabled) audioEngine.play(s, f)
                    gameState.submitMemoryTap(s, f)
                }
                else -> {}
            }
        }
    }

    val onStudyToggle: () -> Unit = {
        isStudyMode = !isStudyMode
        if (!isStudyMode) studyFilterNote = null
    }

    ModalNavigationDrawer(
        drawerState   = drawerState,
        scrimColor    = Color.Black.copy(alpha = 0.55f),
        drawerContent = {
            ModalDrawerSheet(drawerContainerColor = DrawerBg, windowInsets = WindowInsets(0)) {
                AppDrawer(
                    onNavigate = { screen ->
                        scope.launch { drawerState.close() }
                        onNavigate(screen)
                    },
                    onClose = { scope.launch { drawerState.close() } }
                )
            }
        },
    ) {
        Box(modifier = modifier.fillMaxSize()) {
            if (isLandscape) {
                LandscapeLayout(
                    gameState       = gameState,
                    audioEngine     = audioEngine,
                    soundEnabled    = soundEnabled,
                    useFlats        = useFlats,
                    fretboardStyle  = fretboardStyle,
                    isStudyMode     = isStudyMode,
                    studyFilterNote = studyFilterNote,
                    onMenuOpen      = { scope.launch { drawerState.open() } },
                    onStudyToggle   = onStudyToggle,
                    onNoteSelected  = { note ->
                        studyFilterNote = if (studyFilterNote == note) null else note
                    },
                    onFretTap = onFretTap,
                )
            } else {
                PortraitLayout(
                    gameState       = gameState,
                    audioEngine     = audioEngine,
                    soundEnabled    = soundEnabled,
                    useFlats        = useFlats,
                    fretboardStyle  = fretboardStyle,
                    isStudyMode     = isStudyMode,
                    studyFilterNote = studyFilterNote,
                    onMenuOpen      = { scope.launch { drawerState.open() } },
                    onStudyToggle   = onStudyToggle,
                    onNoteSelected  = { note ->
                        studyFilterNote = if (studyFilterNote == note) null else note
                    },
                    onFretTap = onFretTap,
                )
            }

            if (gameState.showTimedResult) {
                TimedResultOverlay(
                    gameState   = gameState,
                    onPlayAgain = { gameState.startTimedGame() },
                    onExit      = {
                        gameState.isTimedMode = false
                        gameState.reset()
                    }
                )
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Landscape layout
// ---------------------------------------------------------------------------
// Mirrors iOS landscape design:
//   • Pinned 2-row top bar (64dp) contains ALL controls
//   • Fretboard + prompt + game zone centered vertically in remaining space
//   • Fixed-height game zone — switching modes never shifts the fretboard

@Composable
private fun LandscapeLayout(
    gameState: GameState,
    audioEngine: NoteAudioEngine,
    soundEnabled: Boolean,
    useFlats: Boolean,
    fretboardStyle: FretboardStyle,
    isStudyMode: Boolean,
    studyFilterNote: Note?,
    onMenuOpen: () -> Unit,
    onStudyToggle: () -> Unit,
    onNoteSelected: (Note) -> Unit,
    onFretTap: (Int, Int) -> Unit,
) {
    val wrongPos = buildSet {
        val fas = gameState.fretAnswerState
        if (fas is FretAnswerState.Wrong) add(FretPosition(fas.string, fas.fret))
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BgColor)
            .statusBarsPadding()
            .navigationBarsPadding(),
    ) {
        // ── Centered content (fretboard + prompt + game zone) ─────────────
        Column(
            modifier            = Modifier
                .fillMaxSize()
                .padding(top = LANDSCAPE_TOP_BAR_H),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            FretboardView(
                style           = fretboardStyle,
                highlightString = if (!isStudyMode && gameState.gameMode == GameMode.NAME_THE_NOTE)
                    gameState.currentString else null,
                highlightFret   = if (!isStudyMode && gameState.gameMode == GameMode.NAME_THE_NOTE)
                    gameState.currentFret else null,
                foundPositions  = if (isStudyMode) emptySet() else gameState.foundFrets,
                wrongPositions  = if (isStudyMode) emptySet() else wrongPos,
                flashPositions  = if (!isStudyMode &&
                    gameState.gameMode == GameMode.MEMORY_CHALLENGE &&
                    gameState.memoryPhase == MemoryPhase.FLASHING) gameState.required else emptySet(),
                useFlats        = useFlats,
                maxFret         = gameState.difficulty.maxFret,
                tuning          = gameState.fretboard.tuning,
                showNoteLabels  = isStudyMode,
                studyFilterNote = studyFilterNote,
                boardHeightDp   = LANDSCAPE_FRETBOARD_H,
                onFretTap       = onFretTap,
            )

            // Prompt — fixed height so nothing below can shift the fretboard
            Box(
                modifier         = Modifier.fillMaxWidth().height(LANDSCAPE_PROMPT_H),
                contentAlignment = Alignment.Center,
            ) {
                PromptText(
                    gameState   = gameState,
                    useFlats    = useFlats,
                    isStudyMode = isStudyMode,
                    compact     = true,
                )
            }

            // Game zone — fixed height, all 3 mode UIs swap inside it
            Box(
                modifier = Modifier.fillMaxWidth().height(LANDSCAPE_GAME_H),
            ) {
                if (isStudyMode) {
                    StudyFilterButtons(
                        useFlats        = useFlats,
                        studyFilterNote = studyFilterNote,
                        compact         = true,
                        onNoteSelected  = onNoteSelected,
                    )
                } else {
                    when (gameState.gameMode) {
                        GameMode.NAME_THE_NOTE    -> NoteAnswerButtons(
                            answerState     = gameState.answerState,
                            correctNote     = gameState.correctNote,
                            useFlats        = useFlats,
                            columns         = 6,
                            buttonHeight    = 28.dp,
                            containerHeight = LANDSCAPE_GAME_H,
                            onAnswer        = { gameState.submit(it) },
                        )
                        GameMode.FIND_THE_FRET    ->
                            FindItControls(gameState, useFlats, compact = true)
                        GameMode.MEMORY_CHALLENGE ->
                            MemoryControls(gameState, useFlats, compact = true)
                    }
                }
            }
        }

        // ── Pinned top bar ─────────────────────────────────────────────────
        LandscapeTopBar(
            modifier      = Modifier
                .fillMaxWidth()
                .height(LANDSCAPE_TOP_BAR_H)
                .background(BgColor.copy(alpha = 0.97f)),
            gameState     = gameState,
            isStudyMode   = isStudyMode,
            onMenuOpen    = onMenuOpen,
            onStudyToggle = onStudyToggle,
        )
    }
}

// ---------------------------------------------------------------------------
// Landscape top bar — 2-row control strip
// ---------------------------------------------------------------------------

@Composable
private fun LandscapeTopBar(
    gameState: GameState,
    isStudyMode: Boolean,
    onMenuOpen: () -> Unit,
    onStudyToggle: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier) {

        // Row 1: hamburger | title | spacer | score | streak | study
        Row(
            modifier              = Modifier
                .fillMaxWidth()
                .weight(1f)
                .padding(horizontal = 16.dp),
            verticalAlignment     = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            IconButton(
                onClick  = onMenuOpen,
                modifier = Modifier.size(32.dp),
            ) {
                Icon(
                    imageVector        = Icons.Default.Menu,
                    contentDescription = "Menu",
                    tint               = TextPrimary,
                    modifier           = Modifier.size(18.dp),
                )
            }

            Text(
                text       = "FretTrainer EZ",
                color      = TextPrimary,
                fontSize   = 15.sp,
                fontWeight = FontWeight.Black,
            )

            Spacer(Modifier.weight(1f))

            // Score (practice mode only)
            if (!gameState.isTimedMode) {
                Text(
                    text       = if (gameState.totalCount == 0) "Ready"
                                 else "${gameState.correctCount}/${gameState.totalCount}",
                    color      = TextMuted,
                    fontSize   = 11.sp,
                    fontFamily = FontFamily.Monospace,
                )
            }

            // Streak
            if (gameState.currentStreak >= 2) {
                Text(
                    text       = "\uD83D\uDD25 ${gameState.currentStreak}",
                    color      = AccentGold,
                    fontSize   = 12.sp,
                    fontWeight = FontWeight.Bold,
                )
            }

            // Study button (hidden in Memory mode)
            if (gameState.gameMode != GameMode.MEMORY_CHALLENGE) {
                Button(
                    onClick  = onStudyToggle,
                    modifier = Modifier.height(24.dp),
                    colors   = ButtonDefaults.buttonColors(
                        containerColor = if (isStudyMode) AccentGold else Color.Transparent,
                    ),
                    shape          = RoundedCornerShape(6.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 0.dp),
                    border         = BorderStroke(1.dp, AccentGold.copy(alpha = 0.7f)),
                ) {
                    Text(
                        text       = "Study",
                        fontSize   = 10.sp,
                        fontWeight = FontWeight.SemiBold,
                        color      = if (isStudyMode) Color.Black else AccentGold,
                    )
                }
            }
        }

        // Row 2: mode picker | practice/timed toggle | right zone
        Row(
            modifier              = Modifier
                .fillMaxWidth()
                .weight(1f)
                .padding(horizontal = 16.dp),
            verticalAlignment     = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            // Mode picker
            LandscapeModeSelector(
                gameState = gameState,
                modifier  = Modifier.width(220.dp),
            )

            // Practice / Timed toggle — kept in layout but invisible in Memory mode
            Row(
                modifier = Modifier
                    .alpha(if (gameState.gameMode == GameMode.MEMORY_CHALLENGE) 0f else 1f)
                    .background(Color(0xFF1E1E3A), RoundedCornerShape(6.dp))
                    .padding(2.dp),
            ) {
                listOf(false, true).forEach { timed ->
                    val selected = gameState.isTimedMode == timed
                    Button(
                        onClick = {
                            if (gameState.gameMode != GameMode.MEMORY_CHALLENGE &&
                                gameState.isTimedMode != timed) {
                                if (timed) {
                                    gameState.stopTimedGame()
                                    gameState.isTimedMode = true
                                } else {
                                    gameState.stopTimedGame()
                                    gameState.isTimedMode = false
                                    gameState.reset()
                                }
                            }
                        },
                        modifier       = Modifier.height(20.dp),
                        colors         = ButtonDefaults.buttonColors(
                            containerColor = if (selected) Color(0xFF3A3A5C) else Color.Transparent,
                        ),
                        shape          = RoundedCornerShape(4.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 0.dp),
                        elevation      = ButtonDefaults.buttonElevation(0.dp),
                    ) {
                        Text(
                            text       = if (timed) "Timed" else "Practice",
                            fontSize   = 11.sp,
                            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                            color      = if (selected) TextPrimary else TextMuted,
                        )
                    }
                }
            }

            // Right zone: difficulty buttons | active timer | duration picker
            LandscapeRightZone(
                gameState = gameState,
                modifier  = Modifier.weight(1f),
            )
        }
    }
}

// ---------------------------------------------------------------------------
// Landscape right zone (mirrors iOS ZStack approach — stable size)
// ---------------------------------------------------------------------------

@Composable
private fun LandscapeRightZone(gameState: GameState, modifier: Modifier = Modifier) {
    val showDifficulty  = !gameState.isTimedMode || gameState.gameMode == GameMode.MEMORY_CHALLENGE
    val showTimerActive = gameState.gameMode != GameMode.MEMORY_CHALLENGE &&
        gameState.isTimedMode && gameState.isTimerActive
    val showDuration    = gameState.gameMode != GameMode.MEMORY_CHALLENGE &&
        gameState.isTimedMode && !gameState.isTimerActive && !gameState.isTimeUp

    Box(modifier = modifier) {
        // Difficulty buttons
        if (showDifficulty) {
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Difficulty.entries.forEach { d ->
                    val selected = d == gameState.difficulty
                    Button(
                        onClick        = { gameState.changeDifficulty(d) },
                        modifier       = Modifier.weight(1f).height(22.dp),
                        colors         = ButtonDefaults.buttonColors(
                            containerColor = if (selected) Color(0xFF2A2A50) else CardBg,
                        ),
                        shape          = RoundedCornerShape(5.dp),
                        contentPadding = PaddingValues(0.dp),
                    ) {
                        Text(
                            text       = d.displayName,
                            fontSize   = 10.sp,
                            color      = if (selected) TextPrimary else TextMuted,
                            fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                        )
                    }
                }
            }
        }

        // Active timer
        if (showTimerActive) {
            Row(
                modifier              = Modifier.fillMaxWidth(),
                verticalAlignment     = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text(
                    text       = formatTime(gameState.timeRemaining),
                    color      = if (gameState.timeRemaining <= 10) AccentRed else TextPrimary,
                    fontSize   = 18.sp,
                    fontWeight = FontWeight.Black,
                    fontFamily = FontFamily.Monospace,
                )
                Spacer(Modifier.weight(1f))
                Text(
                    text       = "\u2713 ${gameState.correctCount}",
                    color      = CorrectGreen,
                    fontSize   = 13.sp,
                    fontWeight = FontWeight.Bold,
                )
                Button(
                    onClick        = {
                        gameState.stopTimedGame()
                        gameState.isTimedMode = false
                    },
                    modifier       = Modifier.height(24.dp),
                    colors         = ButtonDefaults.buttonColors(containerColor = Color(0xFFE67E22)),
                    shape          = RoundedCornerShape(5.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 0.dp),
                ) {
                    Text("Stop", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                }
            }
        }

        // Duration picker + Start
        if (showDuration) {
            Row(
                modifier              = Modifier.fillMaxWidth(),
                verticalAlignment     = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Row(
                    modifier = Modifier
                        .background(Color(0xFF1E1E3A), RoundedCornerShape(6.dp))
                        .padding(2.dp),
                ) {
                    listOf(30, 60, 120).forEach { dur ->
                        val selected = gameState.timerDuration == dur
                        Button(
                            onClick = {
                                gameState.timerDuration = dur
                                gameState.timeRemaining = dur
                            },
                            modifier       = Modifier.height(20.dp),
                            colors         = ButtonDefaults.buttonColors(
                                containerColor = if (selected) Color(0xFF3A3A5C) else Color.Transparent,
                            ),
                            shape          = RoundedCornerShape(4.dp),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp),
                            elevation      = ButtonDefaults.buttonElevation(0.dp),
                        ) {
                            Text(
                                text       = when (dur) { 30 -> "30s"; 60 -> "1m"; else -> "2m" },
                                fontSize   = 11.sp,
                                fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                                color      = if (selected) TextPrimary else TextMuted,
                            )
                        }
                    }
                }
                val best = gameState.bestScoreFor(gameState.timerDuration)
                if (best > 0) {
                    Text(
                        text     = "Best: $best",
                        fontSize = 9.sp,
                        color    = AccentGold.copy(alpha = 0.8f),
                    )
                }
                Spacer(Modifier.weight(1f))
                Button(
                    onClick        = { gameState.startTimedGame() },
                    modifier       = Modifier.height(24.dp),
                    colors         = ButtonDefaults.buttonColors(containerColor = AccentRed),
                    shape          = RoundedCornerShape(5.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp),
                ) {
                    Text("Start", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Portrait layout (scrollable column — unchanged from original design)
// ---------------------------------------------------------------------------

@Composable
private fun PortraitLayout(
    gameState: GameState,
    audioEngine: NoteAudioEngine,
    soundEnabled: Boolean,
    useFlats: Boolean,
    fretboardStyle: FretboardStyle,
    isStudyMode: Boolean,
    studyFilterNote: Note?,
    onMenuOpen: () -> Unit,
    onStudyToggle: () -> Unit,
    onNoteSelected: (Note) -> Unit,
    onFretTap: (Int, Int) -> Unit,
) {
    val wrongPos = buildSet {
        val fas = gameState.fretAnswerState
        if (fas is FretAnswerState.Wrong) add(FretPosition(fas.string, fas.fret))
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .background(BgColor)
            .statusBarsPadding()
            .navigationBarsPadding(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        TopBar(
            gameState     = gameState,
            isStudyMode   = isStudyMode,
            onMenuOpen    = onMenuOpen,
            onStudyToggle = onStudyToggle,
        )

        ModeSelector(gameState = gameState, modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp))

        if (gameState.gameMode != GameMode.MEMORY_CHALLENGE) {
            PracticeTimedToggle(gameState = gameState)
        }

        if (gameState.isTimedMode && gameState.isTimerActive) {
            TimerActiveRow(gameState = gameState)
        } else if (!gameState.isTimedMode) {
            ScoreRow(gameState = gameState)
        }

        FretboardView(
            style           = fretboardStyle,
            highlightString = if (!isStudyMode && gameState.gameMode == GameMode.NAME_THE_NOTE)
                gameState.currentString else null,
            highlightFret   = if (!isStudyMode && gameState.gameMode == GameMode.NAME_THE_NOTE)
                gameState.currentFret else null,
            foundPositions  = if (isStudyMode) emptySet() else gameState.foundFrets,
            wrongPositions  = if (isStudyMode) emptySet() else wrongPos,
            flashPositions  = if (!isStudyMode &&
                gameState.gameMode == GameMode.MEMORY_CHALLENGE &&
                gameState.memoryPhase == MemoryPhase.FLASHING) gameState.required else emptySet(),
            useFlats        = useFlats,
            maxFret         = gameState.difficulty.maxFret,
            tuning          = gameState.fretboard.tuning,
            showNoteLabels  = isStudyMode,
            studyFilterNote = studyFilterNote,
            boardHeightDp   = PORTRAIT_FRETBOARD_H,
            onFretTap       = onFretTap,
        )

        Spacer(Modifier.height(8.dp))
        PromptText(gameState = gameState, useFlats = useFlats, isStudyMode = isStudyMode)
        Spacer(Modifier.height(8.dp))

        if (isStudyMode) {
            StudyFilterButtons(
                useFlats        = useFlats,
                studyFilterNote = studyFilterNote,
                compact         = false,
                onNoteSelected  = onNoteSelected,
            )
        } else {
            when (gameState.gameMode) {
                GameMode.NAME_THE_NOTE    -> NoteAnswerButtons(
                    answerState     = gameState.answerState,
                    correctNote     = gameState.correctNote,
                    useFlats        = useFlats,
                    columns         = 4,
                    buttonHeight    = 38.dp,
                    containerHeight = 130.dp,
                    onAnswer        = { gameState.submit(it) },
                )
                GameMode.FIND_THE_FRET    -> FindItControls(gameState, useFlats, compact = false)
                GameMode.MEMORY_CHALLENGE -> MemoryControls(gameState, useFlats, compact = false)
            }
        }

        Spacer(Modifier.height(8.dp))

        if (gameState.isTimedMode && !gameState.isTimerActive && !gameState.isTimeUp) {
            TimedSetupUI(gameState = gameState, compact = false)
        } else if (!gameState.isTimedMode) {
            DifficultySelector(gameState = gameState)
        }

        Spacer(Modifier.height(16.dp))
    }
}

// ---------------------------------------------------------------------------
// Top bar (portrait)
// ---------------------------------------------------------------------------

@Composable
private fun TopBar(
    gameState: GameState,
    isStudyMode: Boolean,
    onMenuOpen: () -> Unit,
    onStudyToggle: () -> Unit,
) {
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

        Row(
            verticalAlignment     = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            modifier              = Modifier.padding(end = 8.dp),
        ) {
            if (gameState.gameMode != GameMode.MEMORY_CHALLENGE) {
                Button(
                    onClick  = onStudyToggle,
                    modifier = Modifier.height(28.dp),
                    colors   = ButtonDefaults.buttonColors(
                        containerColor = if (isStudyMode) AccentGold else Color.Transparent,
                    ),
                    shape          = RoundedCornerShape(7.dp),
                    contentPadding = PaddingValues(horizontal = 9.dp, vertical = 0.dp),
                    border         = BorderStroke(1.5.dp, AccentGold.copy(alpha = 0.7f)),
                ) {
                    Text(
                        text       = "Study",
                        fontSize   = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        color      = if (isStudyMode) Color.Black else AccentGold,
                    )
                }
            }

            if (gameState.currentStreak >= 2) {
                Text(
                    text       = "\uD83D\uDD25 ${gameState.currentStreak}",
                    color      = AccentGold,
                    fontSize   = 13.sp,
                    fontWeight = FontWeight.Bold,
                )
            } else if (gameState.gameMode == GameMode.MEMORY_CHALLENGE) {
                Spacer(Modifier.size(40.dp))
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Mode selector (used in both portrait and landscape)
// ---------------------------------------------------------------------------

@Composable
private fun ModeSelector(gameState: GameState, modifier: Modifier = Modifier) {
    Row(
        modifier              = modifier,
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

// Compact version used in landscape top bar
@Composable
private fun LandscapeModeSelector(gameState: GameState, modifier: Modifier = Modifier) {
    Row(
        modifier              = modifier
            .background(Color(0xFF1A1A30), RoundedCornerShape(7.dp))
            .padding(2.dp),
        horizontalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        GameMode.entries.forEach { mode ->
            val selected = mode == gameState.gameMode
            Button(
                onClick  = { gameState.changeMode(mode) },
                modifier = Modifier.weight(1f).height(20.dp),
                colors   = ButtonDefaults.buttonColors(
                    containerColor = if (selected) AccentRed else Color.Transparent,
                ),
                shape          = RoundedCornerShape(5.dp),
                contentPadding = PaddingValues(horizontal = 4.dp, vertical = 0.dp),
                elevation      = ButtonDefaults.buttonElevation(0.dp),
            ) {
                Text(
                    text       = mode.shortName,
                    fontSize   = 11.sp,
                    fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                    color      = if (selected) TextPrimary else TextMuted,
                )
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Practice / Timed toggle (portrait only)
// ---------------------------------------------------------------------------

@Composable
private fun PracticeTimedToggle(gameState: GameState) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        Row(
            modifier = Modifier
                .background(Color(0xFF1E1E3A), RoundedCornerShape(7.dp))
                .padding(2.dp),
        ) {
            listOf(false, true).forEach { timed ->
                val selected = gameState.isTimedMode == timed
                Button(
                    onClick = {
                        if (gameState.isTimedMode != timed) {
                            if (timed) {
                                gameState.stopTimedGame()
                                gameState.isTimedMode = true
                            } else {
                                gameState.stopTimedGame()
                                gameState.isTimedMode = false
                                gameState.reset()
                            }
                        }
                    },
                    modifier       = Modifier.height(28.dp),
                    colors         = ButtonDefaults.buttonColors(
                        containerColor = if (selected) Color(0xFF3A3A5C) else Color.Transparent,
                    ),
                    shape          = RoundedCornerShape(5.dp),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 0.dp),
                    elevation      = ButtonDefaults.buttonElevation(defaultElevation = 0.dp),
                ) {
                    Text(
                        text       = if (timed) "Timed" else "Practice",
                        fontSize   = 12.sp,
                        fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                        color      = if (selected) TextPrimary else TextMuted,
                    )
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Score row (portrait)
// ---------------------------------------------------------------------------

@Composable
private fun ScoreRow(gameState: GameState) {
    Row(
        modifier              = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(
            text     = if (gameState.totalCount == 0) "Ready"
                       else "${gameState.correctCount}/${gameState.totalCount}",
            color    = TextMuted,
            fontSize = 12.sp,
        )
        Text(
            text       = if (gameState.totalCount == 0) ""
                         else "${gameState.scorePercent}%",
            color      = when {
                gameState.totalCount == 0    -> TextMuted
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
// Active timer row (portrait)
// ---------------------------------------------------------------------------

@Composable
private fun TimerActiveRow(gameState: GameState) {
    Row(
        modifier              = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment     = Alignment.CenterVertically,
    ) {
        Text(
            text       = formatTime(gameState.timeRemaining),
            color      = if (gameState.timeRemaining <= 10) AccentRed else TextPrimary,
            fontSize   = 22.sp,
            fontWeight = FontWeight.Black,
            fontFamily = FontFamily.Monospace,
        )
        Text(
            text       = "\u2713 ${gameState.correctCount}",
            color      = CorrectGreen,
            fontSize   = 15.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.Monospace,
        )
        Button(
            onClick = {
                gameState.stopTimedGame()
                gameState.isTimedMode = false
            },
            modifier       = Modifier.height(32.dp),
            colors         = ButtonDefaults.buttonColors(containerColor = Color(0xFFE67E22)),
            shape          = RoundedCornerShape(6.dp),
            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 0.dp),
        ) {
            Text("Stop", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
        }
    }
}

// ---------------------------------------------------------------------------
// Timed setup UI (portrait)
// ---------------------------------------------------------------------------

@Composable
private fun TimedSetupUI(gameState: GameState, compact: Boolean = false) {
    Column(
        modifier            = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            listOf(30, 60, 120).forEach { duration ->
                val selected  = gameState.timerDuration == duration
                val label     = when (duration) { 30 -> "30s"; 60 -> "1 min"; else -> "2 min" }
                val bestScore = gameState.bestScoreFor(duration)

                Column(
                    modifier            = Modifier.weight(1f),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Button(
                        onClick  = {
                            gameState.timerDuration = duration
                            gameState.timeRemaining = duration
                        },
                        modifier = Modifier.fillMaxWidth().height(if (compact) 28.dp else 38.dp),
                        colors   = ButtonDefaults.buttonColors(
                            containerColor = if (selected) Color(0xFF2A2A50) else CardBg,
                        ),
                        shape = RoundedCornerShape(8.dp),
                    ) {
                        Text(
                            text       = label,
                            fontSize   = 13.sp,
                            fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                            color      = if (selected) TextPrimary else TextMuted,
                        )
                    }
                    Spacer(Modifier.height(3.dp))
                    Text(
                        text       = if (bestScore > 0) "Best: $bestScore" else "Best: –",
                        fontSize   = 10.sp,
                        color      = AccentGold.copy(alpha = if (bestScore > 0) 0.85f else 0.4f),
                        fontWeight = FontWeight.Medium,
                    )
                }
            }
        }

        Spacer(Modifier.height(8.dp))

        Button(
            onClick        = { gameState.startTimedGame() },
            modifier       = Modifier.fillMaxWidth().height(if (compact) 30.dp else 40.dp),
            colors         = ButtonDefaults.buttonColors(containerColor = AccentRed),
            shape          = RoundedCornerShape(10.dp),
            contentPadding = if (compact) PaddingValues(0.dp) else ButtonDefaults.ContentPadding,
        ) {
            Text(
                text       = "Start",
                fontSize   = if (compact) 12.sp else 14.sp,
                fontWeight = FontWeight.Bold,
                color      = TextPrimary,
            )
        }
    }
}

// ---------------------------------------------------------------------------
// Timed result overlay
// ---------------------------------------------------------------------------

@Composable
private fun TimedResultOverlay(
    gameState: GameState,
    onPlayAgain: () -> Unit,
    onExit: () -> Unit,
) {
    Box(
        modifier         = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.82f)),
        contentAlignment = Alignment.Center,
    ) {
        Card(
            modifier = Modifier.fillMaxWidth(0.82f).padding(16.dp),
            shape    = RoundedCornerShape(20.dp),
            colors   = CardDefaults.cardColors(containerColor = Color(0xFF16213E)),
        ) {
            Column(
                modifier            = Modifier.padding(28.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text("Time's Up!", fontSize = 24.sp, fontWeight = FontWeight.Black, color = AccentRed)
                Spacer(Modifier.height(16.dp))
                Text(
                    text       = "${gameState.correctCount}",
                    fontSize   = 68.sp,
                    fontWeight = FontWeight.Black,
                    color      = TextPrimary,
                    lineHeight = 68.sp,
                )
                Text("correct answers", fontSize = 14.sp, color = TextMuted)
                if (gameState.isNewBest) {
                    Spacer(Modifier.height(8.dp))
                    Text("\uD83C\uDFC6 New Best!", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = AccentGold)
                }
                Spacer(Modifier.height(24.dp))
                Button(
                    onClick  = onPlayAgain,
                    modifier = Modifier.fillMaxWidth().height(46.dp),
                    colors   = ButtonDefaults.buttonColors(containerColor = AccentRed),
                    shape    = RoundedCornerShape(12.dp),
                ) {
                    Text("Play Again", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                }
                Spacer(Modifier.height(8.dp))
                TextButton(onClick = onExit) {
                    Text("Exit", fontSize = 14.sp, color = TextMuted)
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Study filter buttons
// ---------------------------------------------------------------------------

@Composable
private fun StudyFilterButtons(
    useFlats: Boolean,
    studyFilterNote: Note?,
    compact: Boolean = false,
    onNoteSelected: (Note) -> Unit,
) {
    LazyVerticalGrid(
        columns               = GridCells.Fixed(if (compact) 6 else 4),
        modifier              = Modifier
            .fillMaxWidth()
            .height(if (compact) 70.dp else 130.dp)
            .padding(horizontal = 12.dp),
        contentPadding        = PaddingValues(vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalArrangement   = Arrangement.spacedBy(5.dp),
        userScrollEnabled     = false,
    ) {
        items(Note.entries) { note ->
            val isSelected = note == studyFilterNote
            val noteHue    = note.ordinal / 12f * 360f
            val noteColor  = Color.hsv(noteHue, 0.7f, 0.9f)

            Button(
                onClick        = { onNoteSelected(note) },
                modifier       = Modifier.height(if (compact) 28.dp else 38.dp),
                colors         = ButtonDefaults.buttonColors(
                    containerColor = if (isSelected) noteColor else noteColor.copy(alpha = 0.18f),
                ),
                shape          = RoundedCornerShape(8.dp),
                contentPadding = PaddingValues(0.dp),
                elevation      = ButtonDefaults.buttonElevation(
                    defaultElevation = if (isSelected) 0.dp else 2.dp
                ),
                border = if (isSelected) BorderStroke(1.5.dp, noteColor) else null,
            ) {
                Text(
                    text       = note.displayName(useFlats),
                    fontSize   = 13.sp,
                    fontWeight = if (isSelected) FontWeight.Black else FontWeight.SemiBold,
                    color      = if (isSelected) Color.Black else TextPrimary,
                )
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Prompt text
// ---------------------------------------------------------------------------

@Composable
private fun PromptText(
    gameState: GameState,
    useFlats: Boolean,
    isStudyMode: Boolean,
    compact: Boolean = false,
) {
    val text = when {
        isStudyMode -> "Tap a note to filter · tap any fret to hear it"
        else -> when (gameState.gameMode) {
            GameMode.NAME_THE_NOTE    -> "What note is this?"
            GameMode.FIND_THE_FRET    -> "Tap every position on the fretboard"
            GameMode.MEMORY_CHALLENGE -> when (gameState.memoryPhase) {
                MemoryPhase.FLASHING  -> "Memorize the positions…"
                MemoryPhase.RECALLING -> "Tap from memory!"
                MemoryPhase.COMPLETE  -> "Round complete!"
            }
        }
    }

    Text(
        text       = text,
        color      = TextPrimary.copy(alpha = 0.75f),
        fontSize   = if (compact) 12.sp else 15.sp,
        fontWeight = FontWeight.Medium,
        textAlign  = TextAlign.Center,
        modifier   = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
    )
}

// ---------------------------------------------------------------------------
// Find It controls
// ---------------------------------------------------------------------------

@Composable
private fun FindItControls(gameState: GameState, useFlats: Boolean, compact: Boolean = false) {
    val noteColor = when (gameState.fretAnswerState) {
        is FretAnswerState.Correct -> CorrectGreen
        is FretAnswerState.Wrong   -> AccentRed
        else                       -> TextPrimary
    }
    val total        = gameState.required.size
    val found        = gameState.foundFrets.size
    val feedbackText = when (gameState.fretAnswerState) {
        is FretAnswerState.Correct -> "found them all!"
        is FretAnswerState.Wrong   -> "wrong — keep looking"
        else -> if (found == 0) {
            val range = when (gameState.difficulty) {
                Difficulty.BEGINNER     -> " · frets 0–5"
                Difficulty.INTERMEDIATE -> " · frets 0–10"
                Difficulty.ADVANCED     -> ""
            }
            "find all $total position${if (total == 1) "" else "s"}$range"
        } else {
            "${total - found} remaining"
        }
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp)
            .background(CardBg, RoundedCornerShape(12.dp))
            .padding(vertical = if (compact) 4.dp else 10.dp),
    ) {
        Column(
            modifier            = Modifier.align(Alignment.Center),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text       = gameState.correctNote.displayName(useFlats),
                color      = noteColor,
                fontSize   = if (compact) 32.sp else 48.sp,
                fontWeight = FontWeight.Black,
                lineHeight = if (compact) 32.sp else 48.sp,
            )
            Text(
                text       = feedbackText,
                color      = noteColor.copy(alpha = 0.80f),
                fontSize   = 11.sp,
                fontWeight = FontWeight.Medium,
            )
        }

        Button(
            onClick  = { gameState.skipNote() },
            colors   = ButtonDefaults.buttonColors(containerColor = Color.Transparent),
            shape    = RoundedCornerShape(8.dp),
            modifier = Modifier.align(Alignment.CenterEnd).padding(end = 4.dp),
            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp),
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    imageVector        = Icons.Default.SkipNext,
                    contentDescription = "Skip",
                    tint               = TextMuted,
                    modifier           = Modifier.size(20.dp),
                )
                Text("Skip", color = TextMuted, fontSize = 9.sp, fontWeight = FontWeight.Medium)
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Memory controls
// ---------------------------------------------------------------------------

@Composable
private fun MemoryControls(gameState: GameState, useFlats: Boolean, compact: Boolean = false) {
    val phase     = gameState.memoryPhase
    val noteColor = when (phase) {
        MemoryPhase.FLASHING  -> AccentGold
        MemoryPhase.RECALLING -> TextPrimary
        MemoryPhase.COMPLETE  -> CorrectGreen
    }
    val remaining    = gameState.required.size - gameState.foundFrets.size
    val feedbackText = when (phase) {
        MemoryPhase.FLASHING  -> "memorize these positions…"
        MemoryPhase.RECALLING -> "$remaining position${if (remaining == 1) "" else "s"} remaining"
        MemoryPhase.COMPLETE  -> "all positions found!"
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp)
            .background(CardBg, RoundedCornerShape(12.dp))
            .padding(vertical = if (compact) 4.dp else 10.dp),
    ) {
        Column(
            modifier            = Modifier.align(Alignment.Center),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text       = gameState.correctNote.displayName(useFlats),
                color      = noteColor,
                fontSize   = if (compact) 32.sp else 48.sp,
                fontWeight = FontWeight.Black,
                lineHeight = if (compact) 32.sp else 48.sp,
            )
            Text(
                text       = feedbackText,
                color      = noteColor.copy(alpha = 0.80f),
                fontSize   = 11.sp,
                fontWeight = FontWeight.Medium,
            )
        }
    }
}

// ---------------------------------------------------------------------------
// Difficulty selector (portrait only)
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
