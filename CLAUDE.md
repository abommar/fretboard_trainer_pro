# FretTrainerEZ — Claude Context

## What This Is
An iOS guitar fretboard trainer app built in Swift/SwiftUI. The user taps the correct note name for a highlighted fret position ("Name That Note" mode). Phase 1 complete, hamburger menu + music tools screens added.

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
│   ├── GuitarTuning.swift     # Tuning struct, standard EADGBE preset
│   ├── Fretboard.swift        # note(string:fret:), allPositions(for:)
│   ├── ChordLibrary.swift     # ChordVoicing struct, ChordType enum, 40+ static voicings
│   └── MusicTheory.swift      # Circle of Fifths data (KeyInfo: major, relative, sharpsOrFlats)
├── Game/
│   └── GameState.swift        # @Observable, Difficulty enum, AnswerState, timed mode, haptics
├── Views/
│   ├── FretboardView.swift         # Scrollable fretboard, wood theme, highlight circle
│   ├── NoteAnswerButtonsView.swift # 12-button grid, correct/wrong animations, adaptive buttonHeight
│   ├── DrawerMenuView.swift        # Slide-out hamburger drawer + AppScreen enum
│   ├── CircleOfFifthsView.swift    # Canvas-drawn color-coded circle, tap to see key info card
│   ├── ChordChartsView.swift       # Chord diagram grid, scrollable root/type filters
│   └── ChromaticTunerView.swift    # Chromatic tuner: PitchDetector struct + TunerEngine + UI
├── ContentView.swift               # Root layout + SnapSlider custom component
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

## Hamburger Menu & Music Tool Screens
- `AppScreen` enum (in DrawerMenuView.swift): `.circleOfFifths`, `.chordCharts`, `.chromaticTuner` — conforms to `Identifiable`
- Drawer slides in from left with spring animation; scrim tap-to-close
- ContentView presents screens via `.fullScreenCover(item: $activeScreen)`
- Navigation back from each screen uses `@Environment(\.dismiss)`
- **CircleOfFifthsView**: Canvas-drawn 12-wedge wheel (outer = major, inner = relative minor), tap segment to reveal detail card showing key sig and relative minor
- **ChordChartsView**: Horizontally scrollable root note chips + chord type chips; LazyVGrid of ChordDiagramView cards
- **ChordDiagramView**: Drawn with Path/ZStack — wood background, fret wires, string lines, red finger dots, X/O above nut; `baseFret` label for barre positions
- **ChromaticTunerView**: Mic-based pitch detection, large note name + cents meter needle, standard tuning reference row

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
    let baseFret: Int          // diagram starts here (usually 1)
}
```
Static library has 40+ voicings. Add more to `ChordLibrary.all` array.

## Shared Color Palette
All views use the same dark theme colors:
- `bg = #1A1A2E` (deep navy)
- `cardBg = #16213E`
- `accent = #E94560` (red)
- Drawer bg: `#111128`

## Roadmap
- **Phase 2** — "Find The Fret" inverse mode ← NEXT
- **Phase 3** — Fretboard style picker
- **Phase 5** — Alternate tunings and instruments

## What's NOT Built Yet
No settings screen, no sound effects, no onboarding, no alternate tunings. Chord library only covers open/first-position voicings for common chord types — barre chord shapes and extended voicings not yet added. Tuner only tested on device (simulator has no real mic).
