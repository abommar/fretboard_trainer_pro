# FretTrainerEZ

An iOS app for learning guitar fretboard notes through interactive gameplay and built-in music tools. Built with SwiftUI, targeting iOS 17+.

## Features

- **Visual fretboard** — Scrollable 22-fret guitar neck drawn entirely in code, with multiple wood themes.
- **Three game modes** — Name That Note, Find The Fret, and Memory Challenge.
- **Timed + practice play** — Difficulty ranges, timer durations, and score tracking.
- **Study mode** — Tap/preview notes directly on the fretboard with optional sound.
- **Music tools drawer** — Circle of Fifths, Chord Charts, Chord Jam, Chromatic Tuner, Scale Explorer, Fretboard Style, Settings.
- **Chord Jam** — Tap to add from 20 common chords, arrange progressions, and tap chords to hear strummed playback.
- **Fully offline** — No network calls or third-party dependencies.

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

## Project Structure (High Level)

```
FretTrainerEZ/
├── Models/                   # Notes, tunings, fretboard math, chord/scale/music theory libs
├── Game/                     # Core game state + modes + timer + memory logic
├── Views/                    # Main gameplay + all drawer tool screens
├── NoteAudioEngine.swift     # Synthesized plucked-string playback
├── ContentView.swift         # Root gameplay + drawer routing
└── FretTrainerEZApp.swift    # App entry point

FretTrainerEZTests/
└── ...                       # Unit tests for gameplay, pitch detection, and theory models
```

## How It Works

The `Fretboard` model uses simple chromatic math — take the open string note, advance by `fret` semitones, wrap at 12:

```swift
func note(string: Int, fret: Int) -> Note {
    tuning.strings[string].advanced(by: fret)
}
```

`GameState` picks a random string/fret, computes the correct note, handles answer submission, and auto-advances to the next question after a short delay.

## Next

- Expand advanced chord vocabulary (9th/11th/13th voicings)
- Add deeper progression/song practice workflows
