# FretTrainerEZ — Claude Context

## What This Is
An iOS guitar fretboard trainer app built in Swift/SwiftUI. All feature phases complete. Two game modes, study mode, sound effects, and six music tool screens. Next step: TestFlight.

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
│   └── MusicTheory.swift      # Circle of Fifths data + diatonic theory helpers:
│                              #   KeyInfo (major, relative, sharpsOrFlats); ChordFunction enum
│                              #   (tonic/subdominant/dominant); DiatonicChord struct; Progression struct;
│                              #   diatonicChords(forKeyAt:useFlats:); diatonicCirclePositions(forKeyAt:);
│                              #   commonProgressions (I-IV-V, I-V-vi-IV, I-vi-IV-V, ii-V-I)
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
│   ├── CircleOfFifthsView.swift    # Canvas-drawn circle; orientation-aware (GeometryReader as body root):
│   │                               #   portrait = circle + detail card stacked; landscape = circle left / card right.
│   │                               #   Tap a key → 3 adjacent wedges highlight by chord function (green=tonic,
│   │                               #   blue=subdominant, orange=dominant); other 9 wedges dim.
│   │                               #   Detail card: diatonic chord pills (I–vii°) + 4 common progressions with
│   │                               #   actual chord names for the selected key.
│   ├── ChordChartsView.swift       # Left/right split: left=scrollable chord diagrams, right=theory panel
│   │                               #   (chord name + mood subtitle, NOTES pills, INTERVALS side-by-side)
│   ├── ChromaticTunerView.swift    # Chromatic tuner: PitchDetector struct + TunerEngine @Observable + UI.
│   │                               #   Orientation-aware (GeometryReader as body root): portrait=stacked,
│   │                               #   landscape=two-column. TunerEngine: all private audio vars are
│   │                               #   @ObservationIgnored; stop() is idempotent (guard isListening).
│   ├── ScalesView.swift            # Scale Explorer (landscape-only): root grid + wheel picker + fretboard dots
│   ├── FretboardStyleView.swift    # Full-screen style picker with Canvas mini-preview per style
│   └── SettingsView.swift          # Haptics toggle, Sound Effects toggle, Note Names sharps/flats picker + live preview
├── ContentView.swift               # Root layout + SnapSlider; isStudyMode, studyHighlightNote, audioEngine,
│                                   #   fretboard (stored), soundEnabled, useFlats, fretboardStyle @AppStorage
└── FretTrainerEZApp.swift

FretTrainerEZTests/
└── FretTrainerEZTests.swift   # XCTest: fretboard tests + 15 PitchDetector tuner tests (19 total)
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
- **Orientation-aware fullScreenCover views** use `GeometryReader` as the body root (same pattern in CircleOfFifthsView, ChromaticTunerView, ScalesView). This is the only reliable way to get real screen dimensions inside fullScreenCover. Simulator always shows portrait content rotated; real device correctly switches layout.

## AppStorage Keys
- `"fretboardStyle"` — String raw value of `FretboardStyle`
- `"hapticsEnabled"` — Bool, default true (read via UserDefaults in GameState)
- `"soundEnabled"` — Bool, default false
- `"useFlats"` — Bool, default false — propagated to: NoteAnswerButtonsView, ContentView prompts, ScalesView, ChordChartsView, CircleOfFifthsView

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

## Sound Engine
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
- **CircleOfFifthsView**: Diatonic chord highlighting — tap a key to highlight IV/I/V (outer) and ii/vi/iii (inner) by chord function color. Detail card shows all 7 diatonic chords as color-coded pills + 4 common progressions with real chord names. Orientation-aware layout.
- **ChordChartsView**: Split layout — left panel (44% width, max 175pt) scrollable chord diagrams; right panel theory breakdown: chord name + mood subtitle, NOTES pills + INTERVALS list side-by-side
- **ChordDiagramView**: wood background, fret wires, string lines, red finger dots, X/O above nut; `baseFret` label for barre positions
- **ChromaticTunerView**: Mic-based pitch detection, large note name + cents meter needle, tuning reference row. Orientation-aware (portrait=stacked, landscape=two-column). Back button uses dismiss only; cleanup via `.onDisappear { engine.stop() }`.
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
- All private audio properties are `@ObservationIgnored` (prevents `@Observable` macro from interfering with audio callbacks)
- `stop()` is idempotent: `guard isListening else { return }` — prevents crash if called before `start()`
- **Note confirmation**: requires 3 consecutive frames agreeing on a note before display updates — prevents single-frame glitches
- **Cents smoothing**: exponential moving average (α = 0.25) on the needle
- Requires `NSMicrophoneUsageDescription` — set in build settings via `INFOPLIST_KEY_NSMicrophoneUsageDescription`

**`CentsMeterView`**: Canvas-drawn horizontal meter, ±50 cent range, green/yellow/red zones, moving needle

## Circle of Fifths — Diatonic Theory Logic
```swift
// In MusicTheory.swift (Foundation only — no SwiftUI)
enum ChordFunction { case tonic, subdominant, dominant }
struct DiatonicChord { let numeral: String; let name: String; let chordFunction: ChordFunction }
struct Progression { let name: String; let style: String; let indices: [Int] }

// For key at circle position k:
// Adjacent positions: km1=(k-1+12)%12, kp1=(k+1)%12
// Outer ring: IV@km1(subdominant), I@k(tonic), V@kp1(dominant)
// Inner ring: ii@km1(subdominant), vi@k(tonic), iii@kp1(tonic)
// vii° computed as root.advanced(by: 11) — not on circle
```
Function colors in CircleOfFifthsView: tonic=#2ECC71(green), subdominant=#4499FF(blue), dominant=#FF8C00(orange)

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

## TestFlight Checklist
These items are needed before the first TestFlight build:
- [ ] **App icon** — all required sizes in `Assets.xcassets/AppIcon.appiconset` (1024×1024 + all device sizes, or use a single 1024×1024 with "Single Size" option in Xcode 15+)
- [ ] **Bundle ID registered** — `com.frettrainerez.app` must be registered in App Store Connect / Developer Portal
- [ ] **Signing team** — set Development Team in project signing settings (requires paid Apple Developer account)
- [ ] **Version & build** — CFBundleShortVersionString (e.g. "1.0") and CFBundleVersion (e.g. "1") set in Info.plist / project settings
- [ ] **Privacy descriptions** — NSMicrophoneUsageDescription already set ✓
- [ ] **No export compliance issues** — app uses no encryption ✓
- [ ] **Archive** — Product → Archive in Xcode (use a real device destination, not simulator)
- [ ] **Upload** — Xcode Organizer → Distribute App → App Store Connect → Upload
- [ ] **App Store Connect** — create app record, add internal testers (no review needed for internal), or add external testers (requires Beta App Review)

## Roadmap / What's NOT Built Yet

### Phase 2 — UX & Engagement (next up, post-TestFlight v1)
Derived from simulator UX testing session (2026-03-25). Five items in priority order:

**R1 · Onboarding** — `Views/OnboardingView.swift` (new) + `FretTrainerEZApp.swift` (launch gate)
- 3-screen swipeable intro, shown once via `"hasSeenOnboarding"` `@AppStorage` bool
- Screen 1: Name That Note explanation. Screen 2: Find The Fret explanation. Screen 3: Study Mode tip.
- Each screen: Canvas-drawn icon, headline, body, Next/Get Started buttons. Skippable from any screen.
- No networking, no permissions required.

**R2 · Wrong-answer correction** — `Game/GameState.swift` + `Views/NoteAnswerButtonsView.swift`
- Add `.wrongReveal(correct: Note)` case to `AnswerState` (or carry correct note in existing `.wrong`)
- On wrong tap: flash tapped button red AND highlight correct button green during reveal window (0.6 s)
- Plugs into existing auto-advance timing — no new delay logic needed

**R3 · Position count hint in Find The Fret** — `ContentView.swift`
- `required: Set<FretPosition>` is already computed in `GameState`
- Add `Text("Find all \(gameState.required.count) positions")` below note name; update to "N remaining" as frets are found
- One-line addition to the Find The Fret note display section of ContentView

**R4 · Streak counter + timed session summary** — `Game/GameState.swift` + `Views/TimedResultView.swift` (new)
- Add `currentStreak: Int` and `bestStreak: Int` to `GameState`; increment on correct, reset on wrong
- Persist `bestStreak` per mode+duration in `UserDefaults` (same pattern as `best_\(mode)_\(duration)`)
- After timed game ends, show `TimedResultView` sheet: correct count, wrong count, session best streak, all-time best streak

**R5 · Chord strum playback in Chord Charts** — `Views/ChordChartsView.swift` + `ContentView.swift`
- Add "▶ Play" button to right theory panel; disabled + `.opacity(0.4)` when `soundEnabled` is false
- On tap: iterate `ChordVoicing.frets`, call `audioEngine.play(string: i, fret: frets[i]!)` with 80 ms inter-string delay via `DispatchQueue.main.asyncAfter`
- Pass `audioEngine: NoteAudioEngine` into `ChordChartsView` as a parameter from `ContentView`

### Phase 3 (future, no implementation date)
- Portrait-compatible Scale Explorer (currently landscape-only — the rotate prompt blocks most users)
- Custom note drill mode — filter `GameState.nextQuestion()` to a user-selected note subset
- Extended chord voicings (9th/11th/13th chord types in `ChordLibrary`)
- Chord library currently: all 12 roots × 5 types + limited sus2/sus4

### Known simulator limitations
- Tuner untested on simulator (no real mic) — test on device only
- Sound synthesis untestable on simulator (AVAudioEngine buffers) — test on device only
