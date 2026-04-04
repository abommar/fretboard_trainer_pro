package com.dontfretaboutitai.frettrainerez.game

import android.app.Application
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.dontfretaboutitai.frettrainerez.models.Fretboard
import com.dontfretaboutitai.frettrainerez.models.FretPosition
import com.dontfretaboutitai.frettrainerez.models.Note
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// ---------------------------------------------------------------------------
// Supporting enums
// ---------------------------------------------------------------------------

enum class GameMode(val displayName: String, val shortName: String) {
    NAME_THE_NOTE("Name That Note", "Name It"),
    FIND_THE_FRET("Find The Fret", "Find It"),
    MEMORY_CHALLENGE("Memory Challenge", "Memory"),
}

enum class Difficulty(val displayName: String, val maxFret: Int) {
    BEGINNER("Beginner", 5),
    INTERMEDIATE("Intermediate", 10),
    ADVANCED("Advanced", 22),
}

enum class MemoryPhase { FLASHING, RECALLING, COMPLETE }

sealed class AnswerState {
    object Idle : AnswerState()
    data class Correct(val tapped: Note) : AnswerState()
    data class Wrong(val tapped: Note, val correct: Note) : AnswerState()
}

sealed class FretAnswerState {
    object Idle : FretAnswerState()
    data class Correct(val string: Int, val fret: Int) : FretAnswerState()
    data class Wrong(val string: Int, val fret: Int) : FretAnswerState()
}

// ---------------------------------------------------------------------------
// GameState ViewModel
// ---------------------------------------------------------------------------

class GameState(application: Application) : AndroidViewModel(application) {

    val fretboard = Fretboard()
    private val prefs = application.getSharedPreferences("fret_trainer", Context.MODE_PRIVATE)

    // -- Mode & difficulty --
    var gameMode by mutableStateOf(GameMode.NAME_THE_NOTE)
    var difficulty by mutableStateOf(Difficulty.BEGINNER)

    // -- Current question --
    var currentString by mutableStateOf(0)
    var currentFret   by mutableStateOf(0)
    var correctNote   by mutableStateOf(Note.C)
    var questionIndex by mutableStateOf(0)   // incremented on each new question (drives sound trigger)

    // -- Score --
    var correctCount by mutableStateOf(0)
    var totalCount   by mutableStateOf(0)
    val scorePercent: Int get() = if (totalCount > 0) correctCount * 100 / totalCount else 0

    // -- Streak --
    var currentStreak        by mutableStateOf(0)
    var bestStreakThisSession by mutableStateOf(0)

    val bestStreak: Int get() = prefs.getInt(bestStreakKey, 0)
    private val bestStreakKey: String get() = "bestStreak_${gameMode.name}"

    // -- Answer states --
    var answerState     by mutableStateOf<AnswerState>(AnswerState.Idle)
    var fretAnswerState by mutableStateOf<FretAnswerState>(FretAnswerState.Idle)

    // -- Multi-tap tracking (Find The Fret + Memory) --
    var foundFrets by mutableStateOf(emptySet<FretPosition>())

    // -- Memory Challenge --
    var memoryPhase by mutableStateOf(MemoryPhase.FLASHING)

    val flashDuration: Long get() = when (difficulty) {
        Difficulty.BEGINNER     -> 4000L
        Difficulty.INTERMEDIATE -> 2500L
        Difficulty.ADVANCED     -> 1500L
    }

    /** All valid positions for the current note within the active difficulty range. */
    val required: Set<FretPosition> get() =
        fretboard.allPositionsFor(correctNote)
            .filter { it.fret <= difficulty.maxFret }
            .toSet()

    // -- Timed mode --
    var isTimedMode     by mutableStateOf(false)
    var timerDuration   by mutableStateOf(60)
    var timeRemaining   by mutableStateOf(60)
    var isTimerActive   by mutableStateOf(false)
    var isTimeUp        by mutableStateOf(false)
    var isNewBest       by mutableStateOf(false)
    var showTimedResult by mutableStateOf(false)

    val canAnswer: Boolean get() = if (isTimedMode) (isTimerActive && !isTimeUp) else true

    val bestTimedScore: Int get() = prefs.getInt(timedScoreKey, 0)
    private val timedScoreKey: String get() = "best_${gameMode.name}_$timerDuration"

    /** Returns the best timed score for the given duration in the current game mode. */
    fun bestScoreFor(duration: Int): Int = prefs.getInt("best_${gameMode.name}_$duration", 0)

    private var countdownJob:   Job? = null
    private var memoryFlashJob: Job? = null

    // ---------------------------------------------------------------------------
    // Init
    // ---------------------------------------------------------------------------

    init {
        nextQuestion()
    }

    // ---------------------------------------------------------------------------
    // Mode & Difficulty
    // ---------------------------------------------------------------------------

    fun changeMode(mode: GameMode) {
        gameMode = mode
        reset()
    }

    fun changeDifficulty(d: Difficulty) {
        difficulty   = d
        correctCount = 0
        totalCount   = 0
        nextQuestion()
    }

    // ---------------------------------------------------------------------------
    // Question Generation
    // ---------------------------------------------------------------------------

    fun nextQuestion() {
        answerState     = AnswerState.Idle
        fretAnswerState = FretAnswerState.Idle
        foundFrets      = emptySet()
        questionIndex  += 1

        when (gameMode) {
            GameMode.NAME_THE_NOTE -> {
                currentString = (0 until fretboard.tuning.stringCount).random()
                currentFret   = (0..difficulty.maxFret).random()
                correctNote   = fretboard.note(currentString, currentFret)
            }
            GameMode.FIND_THE_FRET -> {
                correctNote   = Note.entries.random()
                currentString = 0
                currentFret   = 0
            }
            GameMode.MEMORY_CHALLENGE -> {
                val others  = Note.entries.filter { it != correctNote }
                correctNote = others.random()
                currentString = 0
                currentFret   = 0
                scheduleMemoryFlash()
            }
        }
    }

    private fun scheduleMemoryFlash() {
        memoryPhase = MemoryPhase.FLASHING
        memoryFlashJob?.cancel()
        memoryFlashJob = viewModelScope.launch {
            delay(flashDuration)
            memoryPhase    = MemoryPhase.RECALLING
            memoryFlashJob = null
        }
    }

    // ---------------------------------------------------------------------------
    // Name That Note
    // ---------------------------------------------------------------------------

    fun submit(answer: Note) {
        if (answerState != AnswerState.Idle || !canAnswer) return
        totalCount += 1

        if (answer == correctNote) {
            correctCount  += 1
            currentStreak += 1
            if (currentStreak > bestStreakThisSession) bestStreakThisSession = currentStreak
            answerState = AnswerState.Correct(tapped = answer)
            val delay = if (isTimedMode) 500L else 800L
            viewModelScope.launch {
                delay(delay)
                if (!isTimeUp) nextQuestion()
            }
        } else {
            currentStreak = 0
            answerState   = AnswerState.Wrong(tapped = answer, correct = correctNote)
            val delay = if (isTimedMode) 700L else 1500L
            viewModelScope.launch {
                delay(delay)
                if (!isTimeUp) nextQuestion()
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Find The Fret
    // ---------------------------------------------------------------------------

    fun submitFret(string: Int, fret: Int) {
        if (!canAnswer || fret > difficulty.maxFret) return
        val pos = FretPosition(string, fret)
        if (foundFrets.contains(pos) || fretAnswerState !is FretAnswerState.Idle) return

        if (fretboard.note(string, fret) == correctNote) {
            foundFrets = foundFrets + pos
            if (required.isSubset(foundFrets)) {
                correctCount  += 1
                totalCount    += 1
                currentStreak += 1
                if (currentStreak > bestStreakThisSession) bestStreakThisSession = currentStreak
                fretAnswerState = FretAnswerState.Correct(string, fret)
                val delay = if (isTimedMode) 500L else 800L
                viewModelScope.launch {
                    delay(delay)
                    if (!isTimeUp) nextQuestion()
                }
            }
        } else {
            totalCount      += 1
            currentStreak    = 0
            fretAnswerState  = FretAnswerState.Wrong(string, fret)
            viewModelScope.launch {
                delay(600L)
                if (fretAnswerState is FretAnswerState.Wrong) fretAnswerState = FretAnswerState.Idle
            }
        }
    }

    fun skipNote() {
        if (gameMode != GameMode.FIND_THE_FRET) return
        val others  = Note.entries.filter { it != correctNote }
        correctNote     = others.random()
        answerState     = AnswerState.Idle
        fretAnswerState = FretAnswerState.Idle
        foundFrets      = emptySet()
        questionIndex  += 1
    }

    // ---------------------------------------------------------------------------
    // Memory Challenge
    // ---------------------------------------------------------------------------

    fun submitMemoryTap(string: Int, fret: Int) {
        if (memoryPhase != MemoryPhase.RECALLING || fret > difficulty.maxFret) return
        val pos = FretPosition(string, fret)
        if (foundFrets.contains(pos) || fretAnswerState !is FretAnswerState.Idle) return

        if (fretboard.note(string, fret) == correctNote) {
            foundFrets = foundFrets + pos
            if (required.isSubset(foundFrets)) {
                correctCount  += 1
                totalCount    += 1
                currentStreak += 1
                if (currentStreak > bestStreakThisSession) bestStreakThisSession = currentStreak
                memoryPhase = MemoryPhase.COMPLETE
                viewModelScope.launch {
                    delay(1200L)
                    nextQuestion()
                }
            }
        } else {
            totalCount      += 1
            currentStreak    = 0
            fretAnswerState  = FretAnswerState.Wrong(string, fret)
            viewModelScope.launch {
                delay(600L)
                if (fretAnswerState is FretAnswerState.Wrong) fretAnswerState = FretAnswerState.Idle
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Reset
    // ---------------------------------------------------------------------------

    fun reset() {
        memoryFlashJob?.cancel()
        memoryFlashJob        = null
        memoryPhase           = MemoryPhase.FLASHING
        answerState           = AnswerState.Idle
        fretAnswerState       = FretAnswerState.Idle
        foundFrets            = emptySet()
        correctCount          = 0
        totalCount            = 0
        currentStreak         = 0
        bestStreakThisSession  = 0
        isNewBest             = false
        showTimedResult       = false
        stopTimedGame()
        nextQuestion()
    }

    // ---------------------------------------------------------------------------
    // Timed Mode
    // ---------------------------------------------------------------------------

    fun startTimedGame() {
        correctCount         = 0
        totalCount           = 0
        currentStreak        = 0
        bestStreakThisSession = 0
        foundFrets           = emptySet()
        isNewBest            = false
        showTimedResult      = false
        timeRemaining        = timerDuration
        isTimeUp             = false
        isTimerActive        = true
        nextQuestion()
        countdownJob?.cancel()
        countdownJob = viewModelScope.launch {
            while (timeRemaining > 1) {
                delay(1000L)
                timeRemaining -= 1
            }
            delay(1000L)
            timeRemaining = 0
            isTimerActive = false
            isTimeUp      = true
            answerState   = AnswerState.Idle
            countdownJob  = null
            saveTimedScore()
        }
    }

    fun stopTimedGame() {
        countdownJob?.cancel()
        countdownJob  = null
        isTimerActive = false
        isTimeUp      = false
        timeRemaining = timerDuration
    }

    private fun saveTimedScore() {
        if (correctCount > bestTimedScore) {
            prefs.edit().putInt(timedScoreKey, correctCount).apply()
            isNewBest = true
        }
        if (bestStreakThisSession > bestStreak) {
            prefs.edit().putInt(bestStreakKey, bestStreakThisSession).apply()
        }
        showTimedResult = true
    }

    // ---------------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------------

    private fun Set<FretPosition>.isSubset(other: Set<FretPosition>) = other.containsAll(this)
}
