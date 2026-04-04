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
    │   ├── AndroidManifest.xml    # RECORD_AUDIO permission, fullSensor orientation, icon attrs
    │   ├── res/
    │   │   ├── values/
    │   │   │   ├── strings.xml               # app_name = "FretTrainer EZ"
    │   │   │   ├── themes.xml
    │   │   │   └── ic_launcher_background.xml # #1A1A2E
    │   │   ├── mipmap-anydpi-v26/
    │   │   │   ├── ic_launcher.xml            # adaptive icon: bg color + fg PNG
    │   │   │   └── ic_launcher_round.xml
    │   │   └── mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/
    │   │       ├── ic_launcher.png            # 48/72/96/144/192px — from iOS AppIcon-1024
    │   │       ├── ic_launcher_round.png
    │   │       └── ic_launcher_fg.png         # fretboard crop (foreground layer)
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
    │       │                      #   timed mode (coroutine countdown), Memory Challenge flash timer,
    │       │                      #   bestScoreFor(duration) per mode+duration
    │       ├── audio/
    │       │   └── NoteAudioEngine.kt  # Karplus-Strong via AudioTrack MODE_STATIC, coroutine playback
    │       └── ui/
    │           ├── theme/
    │           │   ├── Color.kt   # BgColor, CardBg, AccentRed, AccentGold, CorrectGreen, WrongRed
    │           │   └── Theme.kt   # FretTrainerTheme (Material3 dark)
    │           ├── components/
    │           │   ├── FretboardView.kt     # Canvas fretboard (22 frets), horizontal scroll,
    │           │   │                        #   tap detection, flash/found/wrong overlays,
    │           │   │                        #   study mode note-label pills (hue-colored),
    │           │   │                        #   gold wire at difficulty maxFret boundary
    │           │   └── NoteAnswerButtons.kt # 4-column LazyVerticalGrid of 12 note buttons
    │           └── screens/
    │               ├── MainScreen.kt        # Vertically scrollable layout: TopBar (Study toggle),
    │               │                        #   ModeSelector, PracticeTimedToggle, ScoreRow /
    │               │                        #   TimerActiveRow, FretboardView, PromptText,
    │               │                        #   game controls (NoteAnswerButtons / FindItControls /
    │               │                        #   MemoryControls / StudyFilterButtons),
    │               │                        #   DifficultySelector / TimedSetupUI,
    │               │                        #   TimedResultOverlay (fullscreen)
    │               ├── ChordChartsScreen.kt # Root picker + voicing list + fretboard diagram +
    │               │                        #   theory panel (chord tones + intervals); scrollable
    │               ├── ChordJamScreen.kt    # 20-chord palette + progression builder (4-col grid);
    │               │                        #   tap to add + strum, × to remove
    │               ├── CircleOfFifthsScreen.kt # Interactive circle canvas + KeyDetailCard
    │               │                            #   (diatonic chord pills + common progressions)
    │               └── ChromaticTunerScreen.kt  # ACF pitch detection, cents meter, open-string
    │                                             #   reference row, tuning preset selector
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
- **Scrollable main layout**: MainScreen Column uses `verticalScroll(rememberScrollState())` + `fillMaxWidth()` (not `fillMaxSize`) so all controls are reachable in landscape. No `Spacer(weight(1f))` — use fixed-height spacers only.
- **Study state survives rotation**: `isStudyMode` and `studyFilterNote` use `rememberSaveable` (enums are java.io.Serializable → Bundle-safe).
- **Gold fret wire**: `FretboardView` draws a single gold wire exactly at `maxFret` when `maxFret < FRET_COUNT` — one boundary per difficulty, no wire in Advanced mode.
- **Note label pills**: hue-colored pills drawn via `canvas.nativeCanvas.drawRoundRect`; `Color.hsv(note.ordinal/12f*360f, 0.7f, 0.9f)`. Non-matching notes dim to 15% opacity when a study filter is active.
- **FindItControls / MemoryControls**: 48sp bold note name centered in card, color-coded by answer state; Skip button pinned to `Alignment.CenterEnd`.
- **Drawer insets**: `ModalDrawerSheet` is called with `windowInsets = WindowInsets(0)` in MainScreen so `AppDrawer`'s own `statusBarsPadding()` is the sole insets handler. Without this, status-bar insets are applied twice (once by ModalDrawerSheet, once by AppDrawer), eating ~48dp of drawer height in landscape and hiding bottom menu items.
- **Tuner auto-start**: `isListening` initializes to `hasPermission` so the tuner starts recording immediately when the screen opens (no manual "Start Tuning" tap needed if permission was already granted). The permission-result callback also sets `isListening = true` on grant.

## SharedPreferences Keys
**`fret_trainer` (GameState — game data):**
- `bestStreak_<GameMode.name>` — Int, best streak per mode
- `best_<GameMode.name>_<timerDuration>` — Int, best timed score per mode+duration

**`fret_trainer_ui` (MainActivity — UI prefs):**
- `soundEnabled` — Boolean, default false
- `useFlats` — Boolean, default false
- `hapticsEnabled` — Boolean, default false
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

## What's Built (Android) — as of 2026-04-04
- All 3 game modes: Name It, Find It, Memory Challenge
- Study Mode (Name It + Find It; hidden in Memory)
- Timed Mode (duration picker, countdown, results overlay, best-score persistence)
- Difficulty selector (Beginner/Intermediate/Advanced)
- Circle of Fifths screen with interactive circle + KeyDetailCard (diatonic chords + progressions)
- Chord Charts screen (root picker, voicing list, diagram, chord tones + intervals panel)
- Chord Jam screen (20-chord palette, 4-col progression grid, tap-to-add, tap-to-play, × remove)
- Chromatic Tuner screen (ACF pitch detection, cents EMA smoothing, open-string reference, tuning selector; auto-starts on open if permission granted)
- Scale Explorer screen (ScalesScreen.kt — root picker, 10 scale types, fretboard overlay, note-pill row)
- Fretboard Style picker screen (FretboardStyleScreen.kt — Canvas wood-theme previews, 5 themes, persisted)
- Settings screen (SettingsScreen.kt — sound, haptics, flats toggles; all wired to SharedPreferences in MainActivity)
- App icon (adaptive icon from iOS AppIcon-1024.png, navy background, fretboard foreground)
- Landscape-safe scrollable layout
- Drawer landscape scroll fix (ModalDrawerSheet windowInsets=0 prevents double status-bar padding)

## What's NOT Built Yet (Android)
- Haptics (hapticsEnabled pref exists and is toggled in Settings, but no vibration implementation)
- Google Play distribution setup
