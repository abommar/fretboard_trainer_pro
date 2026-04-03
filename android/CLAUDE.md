# FretTrainer EZ — Android Claude Context

## What This Is
Android port of the iOS FretTrainerEZ guitar fretboard trainer app. Built in Kotlin with Jetpack Compose.
All game logic and music theory models are direct ports of the Swift originals.
See `ios/CLAUDE.md` for the iOS-side context and shared design decisions.

## Hard Constraints (Never Violate)
- **No third-party dependencies.** Android SDK + Jetpack Compose + Kotlin stdlib only. No Retrofit, no Room, no third-party audio libs.
- **Fully offline.** No network calls, no analytics, no external APIs.
- **All UI drawn in code.** No image assets — fretboard, strings, inlays are all Canvas-drawn.

## Tech Stack
- Kotlin 2.0.0
- Jetpack Compose BOM 2024.05.00 (Compose UI, Material3, Foundation)
- AGP 8.4.2, Gradle 8.9
- compileSdk = 35, minSdk = 26 (Android 8.0+)
- ViewModel (`AndroidViewModel`) + `mutableStateOf` for state — no LiveData, no Flow
- `AudioTrack` (MODE_STATIC) for Karplus-Strong synthesis — no ExoPlayer, no MediaPlayer
- SharedPreferences for persistence — no DataStore, no Room
- `viewModelScope` + coroutines for timers and async audio

## Opening the Project
1. Open Android Studio
2. File → Open → select the `android/` folder
3. Click **Sync Now** when prompted (downloads Gradle dependencies, generates wrapper JAR)
4. Create an emulator via Device Manager if needed (Pixel 8, API 35 recommended)

## Project Structure
```
android/
├── settings.gradle.kts
├── build.gradle.kts               # Root: AGP 8.4.2, Kotlin 2.0.0
├── gradle.properties
├── gradle/wrapper/gradle-wrapper.properties  # Gradle 8.9
└── app/
    ├── build.gradle.kts           # compileSdk=35, minSdk=26, Compose BOM
    ├── src/main/
    │   ├── AndroidManifest.xml    # RECORD_AUDIO permission, fullSensor orientation
    │   ├── res/values/
    │   │   ├── strings.xml        # app_name = "FretTrainer EZ"
    │   │   └── themes.xml
    │   └── kotlin/.../frettrainerez/
    │       ├── MainActivity.kt    # Entry point; wires GameState VM + NoteAudioEngine + prefs
    │       ├── models/
    │       │   ├── Note.kt        # 12-note enum, sharpName, flatName, displayName(), advanced()
    │       │   ├── GuitarTuning.kt  # data class + 10 static presets (standard, dropD, openG, etc.)
    │       │   ├── Fretboard.kt   # FretPosition data class; Fretboard.note(), allPositionsFor()
    │       │   ├── ScaleLibrary.kt  # ScaleType enum, 10 scales, intervals, flavor, notes(root)
    │       │   ├── MusicTheory.kt # ChordFunction, DiatonicChord, Progression, circleOfFifths,
    │       │   │                  #   diatonicChords(keyPosition), diatonicCirclePositions(keyPosition),
    │       │   │                  #   commonProgressions, display helpers
    │       │   ├── ChordLibrary.kt  # ChordVoicing data class, ChordType enum (7 types), 70+ voicings
    │       │   └── FretboardStyle.kt  # 5 wood themes with Compose Color values
    │       ├── game/
    │       │   └── GameState.kt   # AndroidViewModel; all game modes, difficulty, scoring, streaks,
    │       │                      #   timed mode (coroutine countdown), Memory Challenge flash timer
    │       ├── audio/
    │       │   └── NoteAudioEngine.kt  # Karplus-Strong via AudioTrack MODE_STATIC, coroutine playback
    │       └── ui/
    │           ├── theme/
    │           │   ├── Color.kt   # BgColor, CardBg, AccentRed, AccentGold, CorrectGreen, WrongRed
    │           │   └── Theme.kt   # FretTrainerTheme (Material3 dark)
    │           ├── components/
    │           │   ├── FretboardView.kt     # Canvas fretboard, horizontal scroll, tap detection,
    │           │   │                        #   flash/found/wrong dot overlays
    │           │   └── NoteAnswerButtons.kt # 4-column LazyVerticalGrid of 12 note buttons
    │           └── screens/
    │               └── MainScreen.kt  # Portrait layout: TopBar, ModeSelector, ScoreRow,
    │                                  #   FretboardView, PromptText, game controls, DifficultySelector
```

## Key Design Decisions
- **String indexing**: `0 = low E, 5 = high E` — same as iOS, opposite of guitar "string 1" convention
- **Fret range**: 0 (open) through 22 inclusive; `difficulty.maxFret` gates both display and input
- **FretPosition** lives in `models/Fretboard.kt` — shared by GameState and FretboardView
- **GameState.fretboard** is `public val` (not private) so MainScreen can read `fretboard.tuning`
- **Tap zones** in FretboardView: fret 0 = nut zone (x < nutWidth); fret N = nutWidth + (N-1)*fretWidth to nutWidth + N*fretWidth. Same formula as iOS — do NOT offset by half fretWidth.
- **Audio**: `AudioTrack.MODE_STATIC` pre-renders all 1.5s of samples before play, matching iOS AVAudioPCMBuffer approach. Released after playback via coroutine delay.
- **No haptics**: Android vibration API differs enough from iOS CoreHaptics that it's deferred to Phase 2
- **questionIndex: Int** (not UUID) — incremented each `nextQuestion()`, drives `LaunchedEffect` in MainScreen for sound trigger

## SharedPreferences Keys
**`fret_trainer` (GameState — game data):**
- `bestStreak_<GameMode.name>` — Int, best streak per mode
- `best_<GameMode.name>_<timerDuration>` — Int, best timed score per mode+duration

**`fret_trainer_ui` (MainActivity — UI prefs):**
- `soundEnabled` — Boolean, default false
- `useFlats` — Boolean, default false
- `fretboardStyle` — String (FretboardStyle.name), default "ROSEWOOD"

## Game Modes
- **NAME_THE_NOTE**: fret highlighted on board, user taps correct note from 12-button grid; tone plays on new question (when sound on)
- **FIND_THE_FRET**: note name shown, user taps ALL positions of that note; correct taps stay green; wrong flash red 0.6s; round ends when `required ⊆ foundFrets`; Skip button available
- **MEMORY_CHALLENGE**: positions flash for `flashDuration` ms (4000/2500/1500 by difficulty), then board clears; user taps from memory; scoring per-round (1 correct/1 total when all found)

## Difficulty
- BEGINNER: frets 0–5
- INTERMEDIATE: frets 0–10
- ADVANCED: frets 0–22

## Audio — Karplus-Strong
Same algorithm as iOS:
1. Seed delay line of length `sampleRate/freq` with white noise
2. Each step: `avg = 0.498 * (line[i] + line[i+1])` (low-pass decay)
3. Hann fade-out on last 10% of output samples
4. Output: 44100 Hz, Mono, PCM 16-bit, ~1.5s = 66150 samples
- Open string MIDI: `[40, 45, 50, 55, 59, 64]` (low E → high E)
- `audioUnavailable: Boolean` set true if AudioTrack init fails

## Color Palette
All screens use:
- `BgColor = #1A1A2E` (deep navy)
- `CardBg = #16213E`
- `AccentRed = #E94560`
- `AccentGold = #FFD700` (streak HUD)
- `CorrectGreen = #2ECC71`
- `WrongRed = #E74C3C`

## What's NOT Built Yet (Android)
- Circle of Fifths screen
- Chord Charts + Chord Jam screen
- Chromatic Tuner screen (needs RECORD_AUDIO runtime permission flow)
- Scale Explorer screen
- Fretboard Style picker screen
- Settings screen (sound/flats toggles are currently hardcoded in MainActivity)
- Timed mode UI (GameState supports it fully — UI not wired yet)
- Haptics
- App icon / splash screen
- Google Play distribution setup
