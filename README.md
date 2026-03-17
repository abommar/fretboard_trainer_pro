# FretTrainerEZ

An iOS app for learning guitar fretboard notes through interactive quizzes. Built with SwiftUI, targeting iOS 17+.

## Features

- **Visual fretboard** — Scrollable 22-fret guitar neck drawn entirely in code. Wood-toned background, graduated string thicknesses, pearl inlay dots, and metallic fret wires.
- **Name That Note** — A random position is highlighted on the fretboard; tap the correct note from 12 answer buttons.
- **Instant feedback** — Green/red flash on answer, correct note revealed on wrong guesses, CoreHaptics feedback.
- **Session score** — Running correct/total/percentage tally with a reset button.
- **Fully offline** — No network access, no third-party dependencies. Works in airplane mode from first launch.

## Requirements

- Xcode 15+
- iOS 17.0+ deployment target
- Swift 5.9

## Getting Started

```bash
git clone https://github.com/abommar/fretboard_trainer_pro.git
cd fretboard_trainer_pro
open FretTrainerEZ.xcodeproj
```

Build and run on a simulator or device with **Cmd + R**. Run unit tests with **Cmd + U**.

## Project Structure

```
FretTrainerEZ/
├── Models/
│   ├── Note.swift           # 12-note chromatic enum with sharp/flat display
│   ├── GuitarTuning.swift   # Tuning struct (default: standard EADGBE)
│   └── Fretboard.swift      # Note lookup and position search logic
├── Game/
│   └── GameState.swift      # @Observable game engine, scoring, haptics
├── Views/
│   ├── FretboardView.swift       # Rendered fretboard with highlight circle
│   └── NoteAnswerButtonsView.swift  # 12-button answer grid
├── ContentView.swift         # Root view
└── FretTrainerEZApp.swift    # App entry point

FretTrainerEZTests/
└── FretTrainerEZTests.swift  # Unit tests for music theory logic
```

## How It Works

The `Fretboard` model uses simple chromatic math — take the open string note, advance by `fret` semitones, wrap at 12:

```swift
func note(string: Int, fret: Int) -> Note {
    tuning.strings[string].advanced(by: fret)
}
```

`GameState` picks a random string/fret, computes the correct note, handles answer submission, and auto-advances to the next question after a short delay.

## Roadmap

- **Phase 2** — "Find The Fret" inverse mode (given a note, tap its location)
- **Phase 3** — Fretboard style picker (Les Paul, Strat, etc.)
- **Phase 4** — Timed challenge modes
- **Phase 5** — Alternate tunings and instruments
