# FretTrainerEZ

An iOS app for learning guitar fretboard notes through interactive game modes and music theory tools. Built with SwiftUI, targeting iOS 17+. No third-party dependencies — Apple frameworks only.

## Features

### Game Modes

- **Name That Note** — A fret position is highlighted; tap the correct note from 12 answer buttons. Wrong taps flash red and reveal the correct note in green before auto-advancing.
- **Find The Fret** — A note name is shown; tap every position of that note on the neck. Each correct tap stays green; wrong taps flash red. Shows "find all N positions" hint and remaining count as you progress.
- **Memory Challenge** — Positions flash gold for a few seconds, then clear. Recall every position from memory and tap them. Gold progress bar counts down during the flash phase.

### Practice vs. Timed Mode
All game modes support **Practice** (untimed, no pressure) and **Timed** (30s / 1m / 2m sessions). Timed sessions show a live countdown, per-game best score, and a summary sheet on completion with correct/wrong counts and streak stats.

### Study Mode
Toggle Study in the header to see all 12 notes color-coded on the fretboard as pill labels. Tap any note button to filter the board to only that note's positions. Tap a fret to hear its tone (when sound is on).

### Music Tools (hamburger menu)
- **Circle of Fifths** — Canvas-drawn circle; tap any key to highlight its tonic/subdominant/dominant neighbors. Detail card shows all 7 diatonic chords and 4 common progressions with real chord names. Orientation-aware layout.
- **Chord Charts** — Scrollable chord diagrams with theory panel (chord name, mood, notes, intervals). Tap the Play button to strum the chord with 80ms inter-string delay.
- **Chromatic Tuner** — Mic-based pitch detection with autocorrelation. Large note name + cents needle. Orientation-aware layout.
- **Scale Explorer** — 10 scale types, all 12 roots, fretboard dot overlay. Root dots in red, scale tones in blue. Landscape-optimized.
- **Fretboard Style** — 5 wood themes: rosewood, maple, ebony, walnut, midnight.
- **Settings** — Haptics toggle, sound effects toggle, fretboard tips toggle, sharps/flats picker with live preview.

### Sound Engine
Karplus-Strong plucked-string synthesis via `AVAudioEngine`. No audio files — every note is synthesized from scratch. Mixes with background music (`.ambient` session category).

### Onboarding
3-screen swipeable intro shown once on first launch. Each screen explains a game mode with a Canvas-drawn icon. Skippable from any screen.

## Requirements

- Xcode 26.3 (`/Applications/Xcode.app`)
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
├── NoteAudioEngine.swift            # Karplus-Strong synthesis via AVAudioEngine
├── Models/
│   ├── Note.swift                   # 12-note enum, sharp/flat names, chromatic math
│   ├── GuitarTuning.swift           # Tuning struct + 10 alternate tuning presets
│   ├── Fretboard.swift              # note(string:fret:), allPositions(for:)
│   ├── ChordLibrary.swift           # 70+ voicings across all 12 roots and 7 chord types
│   ├── ScaleLibrary.swift           # 10 scale types with intervals and flavor strings
│   ├── FretboardStyle.swift         # 5 wood themes with gradient color data
│   └── MusicTheory.swift            # Circle of Fifths, diatonic theory, chord functions
├── Game/
│   └── GameState.swift              # @Observable engine: scoring, streaks, haptics, timed mode
├── Views/
│   ├── FretboardView.swift          # Scrollable fretboard; wood theme; tap overlay
│   ├── NoteAnswerButtonsView.swift  # 12-button answer grid with wrong-reveal coloring
│   ├── DrawerMenuView.swift         # Slide-out hamburger drawer + AppScreen enum
│   ├── OnboardingView.swift         # 3-screen first-launch intro
│   ├── TimedResultView.swift        # Post-game sheet: score, streaks, best
│   ├── CircleOfFifthsView.swift     # Canvas circle + diatonic detail card
│   ├── ChordChartsView.swift        # Split-panel chord diagrams + theory + strum
│   ├── ChromaticTunerView.swift     # Mic pitch detection + cents meter
│   ├── ScalesView.swift             # Landscape scale explorer
│   ├── FretboardStyleView.swift     # Theme picker with mini-preview
│   └── SettingsView.swift           # App preferences
├── ContentView.swift                # Root layout, study mode, game mode routing
└── FretTrainerEZApp.swift           # App entry + onboarding gate

FretTrainerEZTests/
└── FretTrainerEZTests.swift         # 61+ unit tests (fretboard, music theory, tuner)
```

## How It Works

The `Fretboard` model uses simple chromatic math — take the open string note, advance by `fret` semitones, wrap at 12:

```swift
func note(string: Int, fret: Int) -> Note {
    tuning.strings[string].advanced(by: fret)
}
```

`GameState` (@Observable) drives all three game modes: picks questions, evaluates answers, manages streaks, runs the countdown timer, and persists best scores via `UserDefaults`.

## Architecture Notes

- String indexing: `0 = low E, 5 = high E`
- `@Observable` macro (Observation framework) — not `ObservableObject`
- All UI drawn in code — no image or audio assets
- `Color(hex:)` extension lives in `FretboardView.swift`, used across all views
- Orientation-aware full-screen views (`CircleOfFifthsView`, `ChromaticTunerView`, `ScalesView`) use `GeometryReader` as the body root — the only reliable way to get real dimensions inside `fullScreenCover`

## TestFlight Checklist

- [ ] App icon (1024×1024 + device sizes in `AppIcon.appiconset`)
- [ ] Bundle ID registered in Developer Portal (`com.dontfretaboutitai.frettrainerez`)
- [ ] Signing team configured in project settings
- [ ] Version / build numbers set in project settings
- [ ] Archive → Xcode Organizer → Distribute → App Store Connect → Upload
- [ ] App Store Connect app record + testers added

## Roadmap (Post-TestFlight)

- Portrait-compatible Scale Explorer (currently landscape-only, shows rotate prompt in portrait)
- Custom note drill mode — filter questions to a user-selected note subset
- Extended chord voicings (9th/11th/13th chord types)
