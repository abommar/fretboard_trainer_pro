# FretTrainerEZ — Claude Context

## What This Is
An iOS guitar fretboard trainer app built in Swift/SwiftUI. The user taps the correct note name for a highlighted fret position ("Name That Note" mode). Phase 1 is complete.

## Hard Constraints (Never Violate)
- **No third-party dependencies.** Apple frameworks only (SwiftUI, SwiftData, Foundation, CoreHaptics). No SPM packages, no CocoaPods.
- **Fully offline.** No network calls, no analytics, no external APIs.
- **All UI drawn in code.** No image assets — fretboard, strings, inlays are all SwiftUI shapes/paths.

## Tech Stack
- Swift 5.9, SwiftUI, iOS 17+ deployment target
- Xcode 15+
- `@Observable` (Observation framework) for state — not `ObservableObject`
- SwiftData imported but not yet used (reserved for future persistence)

## Project Structure
```
FretTrainerEZ/
├── Models/
│   ├── Note.swift             # 12-note enum, sharp/flat display, chromatic math
│   ├── GuitarTuning.swift     # Tuning struct, standard EADGBE preset
│   └── Fretboard.swift        # note(string:fret:), allPositions(for:)
├── Game/
│   └── GameState.swift        # @Observable, AnswerState enum, haptics, auto-advance
├── Views/
│   ├── FretboardView.swift         # Scrollable fretboard, wood theme, highlight circle
│   └── NoteAnswerButtonsView.swift # 12-button grid, correct/wrong animations
├── ContentView.swift
└── FretTrainerEZApp.swift

FretTrainerEZTests/
└── FretTrainerEZTests.swift   # XCTest: open strings, known positions, octave rule
```

## Key Design Decisions
- String indexing: `0 = low E, 5 = high E` (opposite of guitar "string 1" convention — be careful here)
- Fret range: 0 (open) through 22 inclusive
- `AnswerState` is `Equatable` so SwiftUI `.animation(value:)` works
- `Color(hex:)` extension lives in `FretboardView.swift`
- Haptics gracefully degrade if hardware doesn't support them

## Roadmap
- **Phase 2** — "Find The Fret" inverse mode
- **Phase 3** — Fretboard style picker
- **Phase 4** — Timed challenge modes
- **Phase 5** — Alternate tunings and instruments

## What's NOT Built Yet
No settings screen, no sound effects, no onboarding, no timed modes, no alternate tunings.
