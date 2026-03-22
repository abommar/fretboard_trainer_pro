# FretTrainerEZ — Claude Context

## What This Is
An iOS guitar fretboard trainer app built in Swift/SwiftUI. Phases 1–4 complete. Two game modes, study mode, sound effects, and five music tool screens.

## Hard Constraints (Never Violate)
- **No third-party dependencies.** Apple frameworks only (SwiftUI, SwiftData, Foundation, CoreHaptics, AVFoundation). No SPM packages, no CocoaPods.
- **Fully offline.** No network calls, no analytics, no external APIs.
- **All UI drawn in code.** No image or audio assets — fretboard, strings, inlays, chord diagrams, circle of fifths, and note audio are all generated in code.

## Tech Stack
- Swift 5.9, SwiftUI, iOS 17+ deployment target
- Xcode 26.3 at `/Applications/Xcode.app` (use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` prefix for all xcrun/xcodebuild — xcode-select may point to CLI tools)
- `@Observable` (Observation framework) for state — not `ObservableObject`
- SwiftData imported but not yet used (reserved for future persistence)
- Simulator bundle ID: `com.frettrainerez.app`

## Project Structure
```
FretTrainerEZ/
├── NoteAudioEngine.swift       # Karplus-Strong plucked-string synthesis via AVAudioEngine
├── Models/
│   ├── Note.swift             # 12-note enum, sharp/flat display, chromatic math
│   ├── GuitarTuning.swift     # Tuning struct + 10 alternate tuning presets
│   ├── Fretboard.swift        # note(string:fret:), allPositions(for:)
│   ├── ChordLibrary.swift     # ChordVoicing struct, ChordType enum (7 types), 70+ voicings all 12 roots;
│   │                          #   chordTones computed; degreeSymbols, degreeNames, mood on ChordType
│   ├── ScaleLibrary.swift     # ScaleType enum, 10 scales with intervals + flavor strings
│   ├── FretboardStyle.swift   # 5 wood themes (rosewood/maple/ebony/walnut/midnight); boardColors,
│   │                          #   nutColor, fretColors, stringColors, descriptor
│   └── MusicTheory.swift      # Circle of Fifths data (KeyInfo: major, relative, sharpsOrFlats)
├── Game/
│   └── GameState.swift        # @Observable, Difficulty, AnswerState, FretAnswerState, FretPosition,
│                              #   timed mode, haptics (UserDefaults-gated), foundFrets Set,
│                              #   best score UserDefaults, skipNote(), questionID UUID
├── Views/
│   ├── FretboardView.swift         # Scrollable fretboard, wood theme; params: highlightString/Fret/Color,
│   │                               #   foundPositions, showNoteLabels, studyFilterNote, scaleHighlights,
│   │                               #   style: FretboardStyle, onFretTap
│   ├── NoteAnswerButtonsView.swift # 12-button grid; useFlats @AppStorage; study mode: onStudyTap + studySelectedNote
│   ├── DrawerMenuView.swift        # Slide-out hamburger drawer + AppScreen enum
│   │                               #   (.circleOfFifths, .chordCharts, .chromaticTuner, .scales, .fretboardStyle, .settings)
│   ├── CircleOfFifthsView.swift    # Canvas-drawn color-coded circle, tap to see key info card
│   ├── ChordChartsView.swift       # Left/right split: left=scrollable chord diagrams, right=theory panel
│   │                               #   (chord name + mood subtitle, NOTES pills, INTERVALS side-by-side)
│   ├── ChromaticTunerView.swift    # Chromatic tuner: PitchDetector struct + TunerEngine + UI
│   ├── ScalesView.swift            # Scale Explorer (landscape-only): root grid + wheel picker + fretboard dots
│   ├── FretboardStyleView.swift    # Full-screen style picker with Canvas mini-preview per style
│   └── SettingsView.swift          # Haptics toggle, Sound Effects toggle, Note Names sharps/flats picker + live preview
├── ContentView.swift               # Root layout + SnapSlider; isStudyMode, studyHighlightNote, audioEngine,
│                                   #   fretboard (stored), soundEnabled, useFlats, fretboardStyle @AppStorage
└── FretTrainerEZApp.swift

FretTrainerEZTests/
└── FretTrainerEZTests.swift   # XCTest: fretboard tests + 15 PitchDetector tuner tests
```

## Key Design Decisions
- String indexing: `0 = low E, 5 = high E` (opposite of guitar "string 1" convention — be careful here)
- Fret range: 0 (open) through 22 inclusive
- `AnswerState` is `Equatable` so SwiftUI `.animation(value:)` works
- `Color(hex:)` extension lives in `FretboardView.swift` — used across all views
- Haptics gracefully degrade if hardware doesn't support them; `hapticsEnabled` read directly from `UserDefaults.standard` in `GameState.playHaptic()` (not @AppStorage — GameState is not a View)
- Root layout is a `VStack` with `.background(bg.ignoresSafeArea())` — NOT a ZStack — to keep header pinned to top
- `GeometryReader` in ContentView drives adaptive sizing: portrait uses 200pt fretboard / 44pt buttons; landscape (<500pt height) shrinks both
- FretboardView internal content is exactly 200pt tall (fretboardHeight+36); frame must match or use `.clipped()`
- Highlight dot uses `.id("\(string)-\(fret)")` to force recreation on new question, preventing position animation bugs
- All buttons use `.buttonStyle(.plain)` to remove SwiftUI's 44pt minimum tap height
- `fretboard` is a stored `let` property in ContentView (not created inline) so the same instance is shared between FretboardView and the onFretTap closure

## AppStorage Keys
- `"fretboardStyle"` — String raw value of `FretboardStyle`
- `"hapticsEnabled"` — Bool, default true (read via UserDefaults in GameState)
- `"soundEnabled"` — Bool, default false
- `"useFlats"` — Bool, default false — propagated to: NoteAnswerButtonsView, ContentView prompts, ScalesView, ChordChartsView

## Difficulty & Timed Mode
- `Difficulty` enum: `.beginner` (frets 0–5), `.intermediate` (0–10), `.advanced` (0–22)
- `GameState` has `startTimedGame()` / `stopTimedGame()` using `Timer.scheduledTimer`
- Timed mode duration options: 30s, 1 min, 2 min
- `canAnswer` computed var gates submissions when timer not active
- `SnapSlider` (bottom of ContentView.swift): custom metallic 3-position slider with DragGesture and spring snap

## Game Modes
- **Name That Note**: fret is highlighted, user taps correct note name from 12-button grid; note tone plays on each new question (when sound on)
- **Find The Fret**: note name shown, user taps ALL positions of that note on the fretboard; each correct tap stays highlighted green and plays its tone (when sound on); wrong taps flash red 0.6s; round advances when `required.isSubset(of: foundFrets)`; skip button skips to a different note
- `FretPosition: Hashable` struct used for multi-tap tracking; `foundFrets: Set<FretPosition>` in GameState
- `questionID: UUID` on GameState regenerated each `nextQuestion()` — ContentView uses `.onChange(of: gameState.questionID)` to trigger audio in Name That Note
- Best timed scores persisted via UserDefaults, key: `"best_\(gameMode.rawValue)_\(timerDuration)"`

## Study Mode
- **Study toggle** in header: shows all note labels on fretboard as color-coded pills (12 hues, one per note)
- Tapping a note button in study mode filters the fretboard to show only that note's positions; tap again to show all
- Tapping a fret position in study mode plays that note's tone (when sound on)
- Game mechanics are fully disabled in study mode (no scoring, no fret tap submission)
- `isStudyMode: Bool` + `studyHighlightNote: Note?` in ContentView; `studyFilterNote` passed to FretboardView

## Sound Engine (Phase 4)
`NoteAudioEngine` — standalone final class, no @Observable needed:
- `play(string: Int, fret: Int)` — computes MIDI note from open-string table + fret offset, synthesizes via Karplus-Strong
- **Karplus-Strong**: pre-renders 1.5s of samples into AVAudioPCMBuffer, schedules on AVAudioPlayerNode with `.interrupts`; fade-out on last 10% prevents click
- Open string MIDI: `[40, 45, 50, 55, 59, 64]` (low E to high E)
- Audio session: `.ambient` — mixes with background music
- Gated by `soundEnabled` @AppStorage in ContentView before calling `audioEngine.play()`

## Hamburger Menu & Music Tool Screens
- `AppScreen` enum (in DrawerMenuView.swift): `.circleOfFifths`, `.chordCharts`, `.chromaticTuner`, `.scales`, `.fretboardStyle`, `.settings` — conforms to `Identifiable`
- Drawer slides in from left with spring animation; scrim tap-to-close; items compacted (10pt vertical padding, 13pt font)
- ContentView presents screens via `.fullScreenCover(item: $activeScreen)`
- Navigation back from each screen uses `@Environment(\.dismiss)`
- **CircleOfFifthsView**: Canvas-drawn 12-wedge wheel (outer = major, inner = relative minor), tap segment to reveal detail card
- **ChordChartsView**: Split layout — left panel (44% width, max 175pt) scrollable chord diagrams; right panel theory breakdown: chord name + mood subtitle, NOTES pills + INTERVALS list side-by-side
- **ChordDiagramView**: wood background, fret wires, string lines, red finger dots, X/O above nut; `baseFret` label for barre positions
- **ChromaticTunerView**: Mic-based pitch detection, large note name + cents meter needle, tuning reference row
- **ScalesView**: Landscape-only scale explorer; portrait shows rotate prompt; 4-column root grid + `.wheel` scale picker; fretboard with root (red) and scale tone (blue) dots; respects `useFlats`
- **FretboardStyleView**: Full-screen picker, each row has Canvas mini-preview (board gradient, nut, frets, strings, pearl dots at frets 2 & 4)
- **SettingsView**: Three sections — Gameplay (haptics), Sound (effects), Display (note names + live accidental preview)

## Chromatic Tuner Architecture
All pitch logic lives in `ChromaticTunerView.swift` — no external dependencies.

**`PitchDetector` (internal struct — fully unit-tested):**
- `detectPitch(samples: [Float], sampleRate: Float) -> Float?` — Hann-windowed normalized autocorrelation with McLeod "first significant peak" (threshold 0.85 × global max). Detects 50–2000 Hz.
- `noteInfo(frequency: Float) -> NoteInfo?` — maps frequency to nearest note name + cents deviation via MIDI math

**`TunerEngine` (@Observable class):**
- Uses `AVAudioEngine` + `installTap` for mic input (4096-sample buffers)
- **Note confirmation**: requires 3 consecutive frames agreeing on a note before display updates — prevents single-frame glitches
- **Cents smoothing**: exponential moving average (α = 0.25) on the needle — tune `centsAlpha` (higher = snappier) and `confirmationFrames` (lower = faster response)
- Requires `NSMicrophoneUsageDescription` — set in build settings via `INFOPLIST_KEY_NSMicrophoneUsageDescription`

**`CentsMeterView`**: Canvas-drawn horizontal meter, ±50 cent range, green/yellow/red zones, moving needle

## ChordLibrary Data Model
```swift
struct ChordVoicing {
    let root: Note
    let type: ChordType        // .major, .minor, .dominant7, .major7, .minor7, .sus2, .sus4
    let frets: [Int?]          // 6 values: nil=muted, 0=open, 1+=fret number; index 0=low E
    let baseFret: Int          // diagram starts here (usually 1); dot position = fret - baseFret + 1
    var chordTones: [Note]     // computed from ChordType.intervals mapped over root
}
// ChordType also exposes: degreeSymbols ["1","3","5"], degreeNames ["Root","Major 3rd","Perfect 5th"], mood String
```
All 12 roots have major, minor, dom7, maj7, m7. Natural notes also have sus2/sus4 where practical. 70+ voicings total. Sharps/flats use barre shapes (E-shape for F#/G#, A-shape for Bb/C#/Eb).

## ScaleLibrary Data Model
```swift
enum ScaleType: String, CaseIterable {
    // pentatonicMinor, pentatonicMajor, blues, major, naturalMinor,
    // dorian, mixolydian, harmonicMinor, phrygian, lydian
    var intervals: [Int]   // semitone offsets from root
    var flavor: String     // one-line mood description
    func notes(root: Note) -> [Note]
}
```

## FretboardStyle Data Model
```swift
enum FretboardStyle: String, CaseIterable, Identifiable {
    case rosewood, maple, ebony, walnut, midnight
    var boardColors: [Color]   // 3-stop gradient
    var nutColor: Color
    var fretColors: [Color]    // 3-stop gradient (silver, gold for ebony, blue for midnight)
    var stringColors: [Color]  // 3-stop gradient
    var descriptor: String     // one-line description shown in picker
}
// Pearl inlay dots are universal across all styles (cream + iridescent RadialGradient + specular + rim)
```

## Shared Color Palette
All views use the same dark theme colors:
- `bg = #1A1A2E` (deep navy)
- `cardBg = #16213E`
- `accent = #E94560` (red)
- Drawer bg: `#111128`

## Roadmap
- ~~Phase 3 — Fretboard style picker~~ ✅
- ~~Phase 4 — Sound effects / note playback~~ ✅
- **Phase 5** — Extended chord voicings (barre shapes, 9th/11th/13th)

## What's NOT Built Yet
No onboarding. Chord library has all 12 roots × 5 chord types; sus2/sus4 only for natural notes with practical open voicings. Tuner untested on simulator (no real mic). Scale Explorer landscape-only by design. Sound synthesis untestable on simulator (no speaker output for AVAudioEngine buffers — test on device).
