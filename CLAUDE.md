# FretTrainerEZ — Claude Context

## What This Is
An iOS guitar fretboard trainer app built in Swift/SwiftUI. Phases 1 & 2 complete. Two game modes, study mode, and four music tool screens.

## Hard Constraints (Never Violate)
- **No third-party dependencies.** Apple frameworks only (SwiftUI, SwiftData, Foundation, CoreHaptics). No SPM packages, no CocoaPods.
- **Fully offline.** No network calls, no analytics, no external APIs.
- **All UI drawn in code.** No image assets — fretboard, strings, inlays, chord diagrams, and circle of fifths are all SwiftUI shapes/paths/Canvas.

## Tech Stack
- Swift 5.9, SwiftUI, iOS 17+ deployment target
- Xcode 26.3 at `/Applications/Xcode.app` (use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` prefix for all xcrun/xcodebuild — xcode-select may point to CLI tools)
- `@Observable` (Observation framework) for state — not `ObservableObject`
- SwiftData imported but not yet used (reserved for future persistence)
- Simulator bundle ID: `com.frettrainerez.app`

## Project Structure
```
FretTrainerEZ/
├── Models/
│   ├── Note.swift             # 12-note enum, sharp/flat display, chromatic math
│   ├── GuitarTuning.swift     # Tuning struct + 10 alternate tuning presets
│   ├── Fretboard.swift        # note(string:fret:), allPositions(for:)
│   ├── ChordLibrary.swift     # ChordVoicing struct, ChordType enum (7 types), 70+ voicings all 12 roots; chordTones computed
│   ├── ScaleLibrary.swift     # ScaleType enum, 10 scales with intervals + flavor strings
│   └── MusicTheory.swift      # Circle of Fifths data (KeyInfo: major, relative, sharpsOrFlats)
├── Game/
│   └── GameState.swift        # @Observable, Difficulty, AnswerState, FretAnswerState, FretPosition,
│                              #   timed mode, haptics, foundFrets Set, best score UserDefaults, skipNote()
├── Views/
│   ├── FretboardView.swift         # Scrollable fretboard, wood theme; params: highlightString/Fret/Color,
│   │                               #   foundPositions, showNoteLabels, studyFilterNote, scaleHighlights, onFretTap
│   ├── NoteAnswerButtonsView.swift # 12-button grid; study mode: onStudyTap + studySelectedNote
│   ├── DrawerMenuView.swift        # Slide-out hamburger drawer + AppScreen enum
│   ├── CircleOfFifthsView.swift    # Canvas-drawn color-coded circle, tap to see key info card
│   ├── ChordChartsView.swift       # Chord diagram grid, root/type filters, chord tone pills per card
│   ├── ChromaticTunerView.swift    # Chromatic tuner: PitchDetector struct + TunerEngine + UI
│   └── ScalesView.swift            # Scale Explorer (landscape-only): root grid + wheel picker + fretboard dots
├── ContentView.swift               # Root layout + SnapSlider; isStudyMode + studyHighlightNote state
└── FretTrainerEZApp.swift

FretTrainerEZTests/
└── FretTrainerEZTests.swift   # XCTest: fretboard tests + 15 PitchDetector tuner tests
```

## Key Design Decisions
- String indexing: `0 = low E, 5 = high E` (opposite of guitar "string 1" convention — be careful here)
- Fret range: 0 (open) through 22 inclusive
- `AnswerState` is `Equatable` so SwiftUI `.animation(value:)` works
- `Color(hex:)` extension lives in `FretboardView.swift` — used across all views
- Haptics gracefully degrade if hardware doesn't support them
- Root layout is a `VStack` with `.background(bg.ignoresSafeArea())` — NOT a ZStack — to keep header pinned to top
- `GeometryReader` in ContentView drives adaptive sizing: portrait uses 200pt fretboard / 44pt buttons; landscape (<500pt height) shrinks both
- FretboardView internal content is exactly 200pt tall (fretboardHeight+36); frame must match or use `.clipped()`
- Highlight dot uses `.id("\(string)-\(fret)")` to force recreation on new question, preventing position animation bugs
- All buttons use `.buttonStyle(.plain)` to remove SwiftUI's 44pt minimum tap height

## Difficulty & Timed Mode
- `Difficulty` enum: `.beginner` (frets 0–5), `.intermediate` (0–10), `.advanced` (0–22)
- `GameState` has `startTimedGame()` / `stopTimedGame()` using `Timer.scheduledTimer`
- Timed mode duration options: 30s, 1 min, 2 min
- `canAnswer` computed var gates submissions when timer not active
- `SnapSlider` (bottom of ContentView.swift): custom metallic 3-position slider with DragGesture and spring snap

## Game Modes
- **Name That Note**: fret is highlighted, user taps correct note name from 12-button grid
- **Find The Fret**: note name shown, user taps ALL positions of that note on the fretboard; each correct tap stays highlighted green; wrong taps flash red 0.6s; round advances when `required.isSubset(of: foundFrets)`; skip button skips to a different note
- `FretPosition: Hashable` struct used for multi-tap tracking; `foundFrets: Set<FretPosition>` in GameState
- Best timed scores persisted via UserDefaults, key: `"best_\(gameMode.rawValue)_\(timerDuration)"`

## Study Mode
- **Study toggle** in header: shows all note labels on fretboard as color-coded pills (12 hues, one per note)
- Tapping a note button in study mode filters the fretboard to show only that note's positions; tap again to show all
- Game mechanics are fully disabled in study mode (no scoring, no fret tap submission)
- `isStudyMode: Bool` + `studyHighlightNote: Note?` in ContentView; `studyFilterNote` passed to FretboardView

## Hamburger Menu & Music Tool Screens
- `AppScreen` enum (in DrawerMenuView.swift): `.circleOfFifths`, `.chordCharts`, `.chromaticTuner`, `.scales` — conforms to `Identifiable`
- Drawer slides in from left with spring animation; scrim tap-to-close
- ContentView presents screens via `.fullScreenCover(item: $activeScreen)`
- Navigation back from each screen uses `@Environment(\.dismiss)`
- **CircleOfFifthsView**: Canvas-drawn 12-wedge wheel (outer = major, inner = relative minor), tap segment to reveal detail card
- **ChordChartsView**: Root note chips + chord type chips; LazyVGrid of ChordDiagramView cards; each card shows chord name + color-coded chord tone pills + diagram
- **ChordDiagramView**: wood background, fret wires, string lines, red finger dots, X/O above nut; `baseFret` label for barre positions; chord tones derived from `ChordType.intervals`
- **ChromaticTunerView**: Mic-based pitch detection, large note name + cents meter needle, tuning reference row
- **ScalesView**: Landscape-only scale explorer; portrait shows rotate prompt; 4-column root grid + `.wheel` scale picker; fretboard with root (red) and scale tone (blue) dots

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

## Shared Color Palette
All views use the same dark theme colors:
- `bg = #1A1A2E` (deep navy)
- `cardBg = #16213E`
- `accent = #E94560` (red)
- Drawer bg: `#111128`

## Roadmap
- **Phase 3** — Fretboard style picker
- **Phase 4** — Sound effects / note playback
- **Phase 5** — Extended chord voicings (barre shapes, 9th/11th/13th)

## What's NOT Built Yet
No settings screen, no sound effects, no onboarding. Chord library has all 12 roots × 5 chord types; sus2/sus4 only for natural notes with practical open voicings. Tuner untested on simulator (no real mic). Scale Explorer landscape-only by design.
