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

Phases 1–4 are complete and shipping. See CLAUDE.md for full feature details.

---

### Phase 2 — UX & Engagement (post-TestFlight v1)

Driven by simulator UX testing. Five targeted improvements addressing onboarding gaps, learning feedback, and engagement loops.

#### R1 · Onboarding (3-screen intro)
- Swipeable `OnboardingView` shown once on first launch (gated by `"hasSeenOnboarding"` `AppStorage` bool)
- Screen 1: Name That Note — "We highlight a fret. You name the note."
- Screen 2: Find The Fret — "We name the note. You tap every position on the neck."
- Screen 3: Study Mode — "Tap Study to see all notes color-coded. Tap any note to filter."
- Each screen: large icon (drawn in Canvas), one headline, one body line, Next / Get Started buttons
- Skippable from any screen. No networking, no permissions.
- **Files:** `Views/OnboardingView.swift` (new) + `FretTrainerEZApp.swift` (launch gate)

#### R2 · Wrong-answer correction in Name That Note
- When user taps wrong note, flash the tapped button red AND briefly highlight the correct button green before auto-advancing
- Requires a new `AnswerState` case: `.wrongReveal(correct: Note)` (or carry correct note in existing `.wrong`)
- `NoteAnswerButtonsView` reads the new state to color the correct button green for the reveal window
- No new delay logic needed — plugs into the existing 0.6 s `.wrong` → `.none` cycle
- **Files:** `Game/GameState.swift`, `Views/NoteAnswerButtonsView.swift`

#### R3 · Position count hint in Find The Fret
- Below the large note name display, show: "Find all N positions" where N = `gameState.required.count`
- `required: Set<FretPosition>` is already computed in `GameState` — just expose its count to the UI
- As positions are found, update to "N remaining" (use `required.count - foundFrets.count`)
- **Files:** `ContentView.swift` (add `Text` below note display in Find The Fret layout)

#### R4 · Streak counter + timed-mode session summary
- Add `currentStreak: Int` and `bestStreak: Int` to `GameState`; reset streak on wrong answer, increment on correct
- Persist `bestStreak` to `UserDefaults` keyed per mode (same pattern as `best_\(mode)_\(duration)`)
- After timed game ends, show a `TimedResultView` sheet: correct count, wrong count, best streak this session, personal best streak
- **Files:** `Game/GameState.swift`, `Views/TimedResultView.swift` (new)

#### R5 · Chord strum playback in Chord Charts
- Add a "▶ Play" button to `ChordChartsView`'s right panel
- On tap, iterate non-nil frets in the selected `ChordVoicing.frets` array (index = string), call `audioEngine.play(string: i, fret: frets[i]!)` with 80 ms inter-string delay using `DispatchQueue.main.asyncAfter`
- Gate behind `soundEnabled` `@AppStorage` (same as everywhere else); show button as disabled with `.opacity(0.4)` when sound is off
- `NoteAudioEngine` is already a final class passed down — pass it into `ChordChartsView` as a parameter
- **Files:** `Views/ChordChartsView.swift`, `ContentView.swift` (pass `audioEngine`)

---

### Phase 3 (future)
- Portrait-compatible Scale Explorer layout
- Custom note drill mode (focus on specific notes)
- Extended chord voicings (9th/11th/13th)
