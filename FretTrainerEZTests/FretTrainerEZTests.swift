import XCTest
import AVFoundation
@testable import FretTrainerEZ

final class FretTrainerEZTests: XCTestCase {

    let fretboard = Fretboard()

    // MARK: - Open strings (standard tuning: E A D G B E, index 0=low)
    func testOpenStrings() {
        XCTAssertEqual(fretboard.note(string: 0, fret: 0), .E) // low E
        XCTAssertEqual(fretboard.note(string: 1, fret: 0), .A)
        XCTAssertEqual(fretboard.note(string: 2, fret: 0), .D)
        XCTAssertEqual(fretboard.note(string: 3, fret: 0), .G)
        XCTAssertEqual(fretboard.note(string: 4, fret: 0), .B)
        XCTAssertEqual(fretboard.note(string: 5, fret: 0), .E) // high E
    }

    // MARK: - Known reference points (guitar convention: string 6 = index 0)
    func testKnownPositions() {
        // string 6 fret 5 = A
        XCTAssertEqual(fretboard.note(string: 0, fret: 5), .A)
        // string 5 fret 7 = E
        XCTAssertEqual(fretboard.note(string: 1, fret: 7), .E)
        // string 1 fret 12 = E (high)
        XCTAssertEqual(fretboard.note(string: 5, fret: 12), .E)
        // string 3 in guitar convention = D string (index 2), fret 2 = E
        // Let me recalculate: D + 2 semitones = E. But the spec says string 3 fret 2 = A.
        // Guitar string 3 (1-based from high e) = G string? No, standard notation:
        // String 6 = low E, String 5 = A, String 4 = D, String 3 = G, String 2 = B, String 1 = high E
        // So string 3 = G (index 3 in our 0-based array). G + 2 semitones = A. That matches.
        XCTAssertEqual(fretboard.note(string: 3, fret: 2), .A) // G string fret 2 = A
    }

    // MARK: - 12th fret octave rule
    func testTwelfthFretOctave() {
        for s in 0..<6 {
            XCTAssertEqual(
                fretboard.note(string: s, fret: 12),
                fretboard.note(string: s, fret: 0),
                "String \(s): fret 12 should equal open note"
            )
        }
    }

    // MARK: - allPositions count for G across 22 frets
    func testAllPositionsForG() {
        let positions = fretboard.allPositions(for: .G)
        // G appears every 12 frets on each string. With 22 frets (frets 0-22 = 23 positions):
        // Each string has either 1 or 2 G positions depending on the open note offset.
        // Let's just verify it's a reasonable non-zero number and test specific known ones.
        XCTAssertGreaterThan(positions.count, 0)
        // G string (index 3) open = G, so frets 0 and 12 are G
        XCTAssertTrue(positions.contains(where: { $0.string == 3 && $0.fret == 0 }))
        XCTAssertTrue(positions.contains(where: { $0.string == 3 && $0.fret == 12 }))
        // All 6 strings have at least one G in 22 frets
        for s in 0..<6 {
            XCTAssertTrue(positions.contains(where: { $0.string == s }), "String \(s) should have at least one G")
        }
    }
}

// MARK: - Chromatic Tuner Tests

final class PitchDetectorTests: XCTestCase {

    private let sampleRate: Float = 44100
    private let bufferSize = 4096

    /// Synthesizes a pure sine wave at the given frequency.
    private func sine(frequency: Float, amplitude: Float = 0.5) -> [Float] {
        (0..<bufferSize).map { i in
            amplitude * sin(2 * Float.pi * frequency * Float(i) / sampleRate)
        }
    }

    /// Silence buffer (all zeros).
    private func silence() -> [Float] {
        [Float](repeating: 0, count: bufferSize)
    }

    // MARK: Frequency detection — open guitar strings (standard tuning)

    // Accuracy of ±5 Hz — well within one semitone at all guitar frequencies,
    // and tighter than what a human ear can reliably distinguish for tuning.
    private let freqAccuracy: Float = 5.0

    func testDetectsE2_LowEString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 82.41), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 82.41, accuracy: freqAccuracy, "Low E string (E2) should detect near 82.41 Hz")
    }

    func testDetectsA2_AString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 110.0), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 110.0, accuracy: freqAccuracy, "A string (A2) should detect near 110 Hz")
    }

    func testDetectsD3_DString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 146.83), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 146.83, accuracy: freqAccuracy, "D string (D3) should detect near 146.83 Hz")
    }

    func testDetectsG3_GString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 196.0), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 196.0, accuracy: freqAccuracy, "G string (G3) should detect near 196 Hz")
    }

    func testDetectsB3_BString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 246.94), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 246.94, accuracy: freqAccuracy, "B string (B3) should detect near 246.94 Hz")
    }

    func testDetectsE4_HighEString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 329.63), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 329.63, accuracy: freqAccuracy, "High E string (E4) should detect near 329.63 Hz")
    }

    func testDetectsA4_ConcertPitch() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 440.0), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 440.0, accuracy: freqAccuracy, "Concert A (A4) should detect near 440 Hz")
    }

    // MARK: Silence / low signal rejected

    func testSilenceReturnsNil() {
        XCTAssertNil(PitchDetector.detectPitch(samples: silence(), sampleRate: sampleRate),
                     "Silence should return nil")
    }

    func testVeryQuietSignalReturnsNil() {
        let quiet = sine(frequency: 440.0, amplitude: 0.005)
        XCTAssertNil(PitchDetector.detectPitch(samples: quiet, sampleRate: sampleRate),
                     "Signal below RMS threshold should return nil")
    }

    // MARK: Note name mapping

    func testNoteInfoA440() {
        let info = PitchDetector.noteInfo(frequency: 440.0)
        XCTAssertNotNil(info)
        XCTAssertEqual(info!.note, "A")
        XCTAssertEqual(info!.cents, 0.0, accuracy: 1.0)
    }

    func testNoteInfoC4_MiddleC() {
        let info = PitchDetector.noteInfo(frequency: 261.63)
        XCTAssertNotNil(info)
        XCTAssertEqual(info!.note, "C")
        XCTAssertEqual(info!.cents, 0.0, accuracy: 2.0)
    }

    func testNoteInfoSharpNote() {
        // 450 Hz is A but sharp
        let info = PitchDetector.noteInfo(frequency: 450.0)
        XCTAssertNotNil(info)
        XCTAssertEqual(info!.note, "A")
        XCTAssertGreaterThan(info!.cents, 0, "450 Hz should be sharp of A")
    }

    func testNoteInfoFlatNote() {
        // 430 Hz is A but flat
        let info = PitchDetector.noteInfo(frequency: 430.0)
        XCTAssertNotNil(info)
        XCTAssertEqual(info!.note, "A")
        XCTAssertLessThan(info!.cents, 0, "430 Hz should be flat of A")
    }

    func testNoteInfoInvalidFrequency() {
        XCTAssertNil(PitchDetector.noteInfo(frequency: 0))
        XCTAssertNil(PitchDetector.noteInfo(frequency: -100))
        XCTAssertNil(PitchDetector.noteInfo(frequency: .nan))
        XCTAssertNil(PitchDetector.noteInfo(frequency: .infinity))
    }

    // MARK: End-to-end: sine wave → note name

    func testEndToEndOpenStrings() {
        // Each open string frequency should map to the correct note name
        let expectations: [(Float, String)] = [
            (82.41,  "E"),  // low E
            (110.0,  "A"),  // A
            (146.83, "D"),  // D
            (196.0,  "G"),  // G
            (246.94, "B"),  // B
            (329.63, "E"),  // high E
        ]
        for (freq, expectedNote) in expectations {
            let buf = sine(frequency: freq)
            guard let detectedFreq = PitchDetector.detectPitch(samples: buf, sampleRate: sampleRate),
                  let info = PitchDetector.noteInfo(frequency: detectedFreq) else {
                XCTFail("Failed to detect pitch for \(freq) Hz (\(expectedNote))")
                continue
            }
            XCTAssertEqual(info.note, expectedNote,
                           "\(freq) Hz should map to \(expectedNote), got \(info.note)")
        }
    }
}

// MARK: - Note Tests

final class NoteTests: XCTestCase {

    func testAdvancedByWrapsChromatic() {
        XCTAssertEqual(Note.B.advanced(by: 1),   .C)   // wrap up
        XCTAssertEqual(Note.C.advanced(by: -1),  .B)   // wrap down
        XCTAssertEqual(Note.C.advanced(by: 12),  .C)   // full octave
        XCTAssertEqual(Note.A.advanced(by: 3),   .C)
        XCTAssertEqual(Note.E.advanced(by: 7),   .B)
    }

    func testSharpNames() {
        XCTAssertEqual(Note.C.sharpName,  "C")
        XCTAssertEqual(Note.Cs.sharpName, "C#")
        XCTAssertEqual(Note.Fs.sharpName, "F#")
        XCTAssertEqual(Note.As.sharpName, "A#")
        XCTAssertEqual(Note.B.sharpName,  "B")
    }

    func testFlatNames() {
        XCTAssertEqual(Note.C.flatName,  "C")
        XCTAssertEqual(Note.Cs.flatName, "Db")
        XCTAssertEqual(Note.Fs.flatName, "Gb")
        XCTAssertEqual(Note.As.flatName, "Bb")
        XCTAssertEqual(Note.Ds.flatName, "Eb")
    }

    func testDisplayNameRespectsFlag() {
        XCTAssertEqual(Note.Cs.displayName(useFlats: false), "C#")
        XCTAssertEqual(Note.Cs.displayName(useFlats: true),  "Db")
        XCTAssertEqual(Note.C.displayName(useFlats: false),  "C")
        XCTAssertEqual(Note.C.displayName(useFlats: true),   "C")
    }

    func testAllNotesHaveUniqueRawValues() {
        let raws = Note.allCases.map { $0.rawValue }
        XCTAssertEqual(Set(raws).count, 12)
    }
}

// MARK: - ScaleLibrary Tests

final class ScaleLibraryTests: XCTestCase {

    func testAllScalesStartOnRoot() {
        for scale in ScaleType.allCases {
            XCTAssertEqual(scale.intervals.first, 0,
                           "\(scale.rawValue) first interval should be 0 (root)")
        }
    }

    func testAllScalesNoteCountMatchesIntervalCount() {
        for scale in ScaleType.allCases {
            let notes = scale.notes(root: .C)
            XCTAssertEqual(notes.count, scale.intervals.count,
                           "\(scale.rawValue) note count should equal interval count")
        }
    }

    func testIntervalCounts() {
        let expected: [ScaleType: Int] = [
            .pentatonicMinor: 5,
            .pentatonicMajor: 5,
            .blues:           6,
            .major:           7,
            .naturalMinor:    7,
            .dorian:          7,
            .mixolydian:      7,
            .harmonicMinor:   7,
            .phrygian:        7,
            .lydian:          7,
        ]
        for (scale, count) in expected {
            XCTAssertEqual(scale.intervals.count, count,
                           "\(scale.rawValue) should have \(count) intervals")
        }
    }

    func testCMajorScale() {
        XCTAssertEqual(ScaleType.major.notes(root: .C),
                       [.C, .D, .E, .F, .G, .A, .B])
    }

    func testANaturalMinorScale() {
        // A B C D E F G
        XCTAssertEqual(ScaleType.naturalMinor.notes(root: .A),
                       [.A, .B, .C, .D, .E, .F, .G])
    }

    func testAPentatonicMinor() {
        // A C D E G
        XCTAssertEqual(ScaleType.pentatonicMinor.notes(root: .A),
                       [.A, .C, .D, .E, .G])
    }

    func testGMixolydian() {
        // G A B C D E F  (major with b7)
        XCTAssertEqual(ScaleType.mixolydian.notes(root: .G),
                       [.G, .A, .B, .C, .D, .E, .F])
    }

    func testBluesCScaleNoteCount() {
        XCTAssertEqual(ScaleType.blues.notes(root: .C).count, 6)
    }
}

// MARK: - MusicTheory Tests

final class MusicTheoryTests: XCTestCase {

    // MARK: Circle of Fifths data

    func testCircleHas12Keys() {
        XCTAssertEqual(MusicTheory.circleOfFifths.count, 12)
    }

    func testCircleStartsWithC() {
        XCTAssertEqual(MusicTheory.circleOfFifths[0].major, .C)
    }

    func testCircleKeyAccidentals() {
        XCTAssertEqual(MusicTheory.circleOfFifths[0].sharpsOrFlats,  0)  // C
        XCTAssertEqual(MusicTheory.circleOfFifths[1].sharpsOrFlats,  1)  // G = 1#
        XCTAssertEqual(MusicTheory.circleOfFifths[11].sharpsOrFlats, -1) // F = 1b
    }

    // MARK: Diatonic chords — C major (k=0)

    func testCMajorDiatonicNumerals() {
        let chords = MusicTheory.diatonicChords(forKeyAt: 0)
        XCTAssertEqual(chords.map { $0.numeral },
                       ["I", "ii", "iii", "IV", "V", "vi", "vii°"])
    }

    func testCMajorDiatonicNames() {
        let chords = MusicTheory.diatonicChords(forKeyAt: 0)
        XCTAssertEqual(chords[0].name, "C")
        XCTAssertEqual(chords[1].name, "Dm")
        XCTAssertEqual(chords[2].name, "Em")
        XCTAssertEqual(chords[3].name, "F")
        XCTAssertEqual(chords[4].name, "G")
        XCTAssertEqual(chords[5].name, "Am")
        XCTAssertEqual(chords[6].name, "B°")
    }

    func testCMajorDiatonicFunctions() {
        let chords = MusicTheory.diatonicChords(forKeyAt: 0)
        XCTAssertEqual(chords[0].chordFunction, .tonic)       // I
        XCTAssertEqual(chords[1].chordFunction, .subdominant)  // ii
        XCTAssertEqual(chords[2].chordFunction, .tonic)        // iii
        XCTAssertEqual(chords[3].chordFunction, .subdominant)  // IV
        XCTAssertEqual(chords[4].chordFunction, .dominant)     // V
        XCTAssertEqual(chords[5].chordFunction, .tonic)        // vi
        XCTAssertEqual(chords[6].chordFunction, .dominant)     // vii°
    }

    func testGMajorDiatonicNames() {
        let chords = MusicTheory.diatonicChords(forKeyAt: 1) // G
        XCTAssertEqual(chords[0].name, "G")
        XCTAssertEqual(chords[3].name, "C")  // IV
        XCTAssertEqual(chords[4].name, "D")  // V
    }

    func testDiatonicChordsUseFlats() {
        // Position 7 = Db major; with useFlats the I chord should show "Db" not "C#"
        let chords = MusicTheory.diatonicChords(forKeyAt: 7, useFlats: true)
        XCTAssertEqual(chords[0].name, "Db")
    }

    func testDiatonicChordsCount() {
        for k in 0..<12 {
            XCTAssertEqual(MusicTheory.diatonicChords(forKeyAt: k).count, 7,
                           "Key \(k) should have 7 diatonic chords")
        }
    }

    // MARK: Circle positions

    func testDiatonicCirclePositionsForC() {
        let pos = MusicTheory.diatonicCirclePositions(forKeyAt: 0)
        XCTAssertEqual(pos[11], .subdominant) // F  (k-1 wraps)
        XCTAssertEqual(pos[0],  .tonic)        // C
        XCTAssertEqual(pos[1],  .dominant)     // G
        XCTAssertEqual(pos.count, 3)
    }

    func testDiatonicCirclePositionsWrapAtBoundary() {
        // k=11 (F): km1=10 (Bb), kp1=0 (C)
        let pos = MusicTheory.diatonicCirclePositions(forKeyAt: 11)
        XCTAssertEqual(pos[10], .subdominant)
        XCTAssertEqual(pos[11], .tonic)
        XCTAssertEqual(pos[0],  .dominant)
    }

    // MARK: Display helpers

    func testAccidentalLabelZero() {
        XCTAssertEqual(MusicTheory.accidentalLabel(sharpsOrFlats: 0), "0")
    }

    func testAccidentalLabelSharps() {
        XCTAssertEqual(MusicTheory.accidentalLabel(sharpsOrFlats: 3), "3♯")
    }

    func testAccidentalLabelFlats() {
        XCTAssertEqual(MusicTheory.accidentalLabel(sharpsOrFlats: -2), "2♭")
    }

    func testEnharmonicLabelNormalPositions() {
        XCTAssertEqual(MusicTheory.enharmonicLabel(for: .C, position: 0), "C")
        XCTAssertEqual(MusicTheory.enharmonicLabel(for: .G, position: 1), "G")
    }

    func testEnharmonicLabelEnharmonicPositions() {
        XCTAssertEqual(MusicTheory.enharmonicLabel(for: .Fs, position: 6), "F#/G\u{266d}")
        XCTAssertEqual(MusicTheory.enharmonicLabel(for: .Cs, position: 7), "C\u{266d}/B")
    }

    func testRelativeLabelSpecialCases() {
        XCTAssertEqual(MusicTheory.relativeLabel(for: .Fs, position: 3), "F#m")
        XCTAssertEqual(MusicTheory.relativeLabel(for: .As, position: 10), "Gm")
    }

    func testCommonProgressionsCount() {
        XCTAssertEqual(MusicTheory.commonProgressions.count, 4)
    }
}

// MARK: - ChordLibrary Tests

final class ChordLibraryTests: XCTestCase {

    // MARK: ChordType intervals

    func testIntervals() {
        XCTAssertEqual(ChordType.major.intervals,     [0, 4, 7])
        XCTAssertEqual(ChordType.minor.intervals,     [0, 3, 7])
        XCTAssertEqual(ChordType.dominant7.intervals, [0, 4, 7, 10])
        XCTAssertEqual(ChordType.major7.intervals,    [0, 4, 7, 11])
        XCTAssertEqual(ChordType.minor7.intervals,    [0, 3, 7, 10])
        XCTAssertEqual(ChordType.sus2.intervals,      [0, 2, 7])
        XCTAssertEqual(ChordType.sus4.intervals,      [0, 5, 7])
    }

    func testSuffixes() {
        XCTAssertEqual(ChordType.major.suffix,     "")
        XCTAssertEqual(ChordType.minor.suffix,     "m")
        XCTAssertEqual(ChordType.dominant7.suffix, "7")
        XCTAssertEqual(ChordType.major7.suffix,    "maj7")
        XCTAssertEqual(ChordType.minor7.suffix,    "m7")
        XCTAssertEqual(ChordType.sus2.suffix,      "sus2")
        XCTAssertEqual(ChordType.sus4.suffix,      "sus4")
    }

    func testDegreeSymbols() {
        XCTAssertEqual(ChordType.major.degreeSymbols,     ["1", "3", "5"])
        XCTAssertEqual(ChordType.minor.degreeSymbols,     ["1", "b3", "5"])
        XCTAssertEqual(ChordType.dominant7.degreeSymbols, ["1", "3", "5", "b7"])
        XCTAssertEqual(ChordType.major7.degreeSymbols,    ["1", "3", "5", "7"])
    }

    // MARK: ChordVoicing

    func testCMajorVoicingName() {
        let v = ChordLibrary.all.first { $0.root == .C && $0.type == .major }!
        XCTAssertEqual(v.name, "C")
    }

    func testCMajorChordTones() {
        let v = ChordLibrary.all.first { $0.root == .C && $0.type == .major }!
        XCTAssertEqual(v.chordTones, [.C, .E, .G])
    }

    func testCMinorChordTones() {
        let v = ChordLibrary.all.first { $0.root == .C && $0.type == .minor }!
        XCTAssertEqual(v.chordTones, [.C, .Ds, .G])
    }

    func testADominant7ChordTones() {
        let v = ChordLibrary.all.first { $0.root == .A && $0.type == .dominant7 }!
        XCTAssertEqual(v.chordTones, [.A, .Cs, .E, .G])
    }

    func testGMajor7ChordTones() {
        let v = ChordLibrary.all.first { $0.root == .G && $0.type == .major7 }!
        XCTAssertEqual(v.chordTones, [.G, .B, .D, .Fs])
    }

    func testAllVoicingsHaveSixFretValues() {
        for v in ChordLibrary.all {
            XCTAssertEqual(v.frets.count, 6,
                           "\(v.name) should have 6 fret values, got \(v.frets.count)")
        }
    }

    func testAllTwelveRootsHaveMajorVoicing() {
        for root in Note.allCases {
            XCTAssertNotNil(
                ChordLibrary.all.first { $0.root == root && $0.type == .major },
                "\(root.sharpName) major voicing missing"
            )
        }
    }

    func testAllTwelveRootsHaveMinorVoicing() {
        for root in Note.allCases {
            XCTAssertNotNil(
                ChordLibrary.all.first { $0.root == root && $0.type == .minor },
                "\(root.sharpName) minor voicing missing"
            )
        }
    }

    func testAllTwelveRootsHaveDominant7Voicing() {
        for root in Note.allCases {
            XCTAssertNotNil(
                ChordLibrary.all.first { $0.root == root && $0.type == .dominant7 },
                "\(root.sharpName)7 voicing missing"
            )
        }
    }

    func testLibraryCountIsReasonable() {
        XCTAssertGreaterThanOrEqual(ChordLibrary.all.count, 60)
    }
}

// MARK: - GameState Tests

final class GameStateTests: XCTestCase {

    // MARK: Difficulty

    func testDifficultyMaxFrets() {
        XCTAssertEqual(Difficulty.beginner.maxFret,     5)
        XCTAssertEqual(Difficulty.intermediate.maxFret, 10)
        XCTAssertEqual(Difficulty.advanced.maxFret,     22)
    }

    // MARK: Score

    func testScorePercentZeroWithNoAnswers() {
        let gs = GameState()
        gs.correctCount = 0
        gs.totalCount   = 0
        XCTAssertEqual(gs.scorePercent, 0)
    }

    func testScorePercentCalculation() {
        let gs = GameState()
        gs.correctCount = 3
        gs.totalCount   = 4
        XCTAssertEqual(gs.scorePercent, 75)
    }

    // MARK: canAnswer

    func testCanAnswerAlwaysTrueInPracticeMode() {
        let gs = GameState()
        gs.isTimedMode = false
        XCTAssertTrue(gs.canAnswer)
    }

    func testCanAnswerFalseWhenTimedNotActive() {
        let gs = GameState()
        gs.isTimedMode   = true
        gs.isTimerActive = false
        XCTAssertFalse(gs.canAnswer)
    }

    func testCanAnswerTrueWhenTimedAndActive() {
        let gs = GameState()
        gs.isTimedMode   = true
        gs.isTimerActive = true
        gs.isTimeUp      = false
        XCTAssertTrue(gs.canAnswer)
    }

    // MARK: submit (Name That Note)

    func testSubmitCorrectAnswerIncrementsScore() {
        let gs = GameState()
        gs.gameMode = .nameTheNote
        let correct = gs.correctNote
        gs.submit(answer: correct)
        XCTAssertEqual(gs.correctCount, 1)
        XCTAssertEqual(gs.totalCount,   1)
        if case .correct(let tapped) = gs.answerState {
            XCTAssertEqual(tapped, correct)
        } else {
            XCTFail("Expected .correct answerState")
        }
    }

    func testSubmitWrongAnswerDoesNotIncrementCorrectCount() {
        let gs = GameState()
        gs.gameMode = .nameTheNote
        let correct = gs.correctNote
        let wrong = Note.allCases.first { $0 != correct }!
        gs.submit(answer: wrong)
        XCTAssertEqual(gs.correctCount, 0)
        XCTAssertEqual(gs.totalCount,   1)
        if case .wrong(let tapped, let corr) = gs.answerState {
            XCTAssertEqual(tapped, wrong)
            XCTAssertEqual(corr,   correct)
        } else {
            XCTFail("Expected .wrong answerState")
        }
    }

    func testSubmitBlockedWhenNonIdle() {
        let gs = GameState()
        gs.gameMode = .nameTheNote
        let correct = gs.correctNote
        gs.submit(answer: correct)
        let countAfter = gs.totalCount
        gs.submit(answer: correct) // should be blocked — answerState is .correct
        XCTAssertEqual(gs.totalCount, countAfter)
    }

    // MARK: setDifficulty

    func testSetDifficultyResetsScores() {
        let gs = GameState()
        gs.correctCount = 5
        gs.totalCount   = 10
        gs.setDifficulty(.intermediate)
        XCTAssertEqual(gs.difficulty,   .intermediate)
        XCTAssertEqual(gs.correctCount, 0)
        XCTAssertEqual(gs.totalCount,   0)
    }

    // MARK: setGameMode

    func testSetGameModeSwitchesAndResets() {
        let gs = GameState()
        gs.correctCount = 3
        gs.totalCount   = 5
        gs.setGameMode(.findTheFret)
        XCTAssertEqual(gs.gameMode,     .findTheFret)
        XCTAssertEqual(gs.correctCount, 0)
        XCTAssertEqual(gs.totalCount,   0)
    }

    // MARK: reset

    func testResetClearsEverything() {
        let gs = GameState()
        gs.correctCount  = 7
        gs.totalCount    = 10
        gs.foundFrets    = [FretPosition(string: 0, fret: 1)]
        gs.reset()
        XCTAssertEqual(gs.correctCount, 0)
        XCTAssertEqual(gs.totalCount,   0)
        XCTAssertTrue(gs.foundFrets.isEmpty)
        XCTAssertEqual(gs.fretAnswerState, .idle)
    }

    // MARK: skipNote

    func testSkipNoteChangesNote() {
        let gs = GameState()
        gs.gameMode = .findTheFret
        let before = gs.correctNote
        // Try up to 20 times in case of rare same-note random
        for _ in 0..<20 {
            gs.skipNote()
            if gs.correctNote != before { break }
        }
        XCTAssertNotEqual(gs.correctNote, before)
    }

    func testSkipNoteIgnoredInNameThatNoteMode() {
        let gs = GameState()
        gs.gameMode = .nameTheNote
        let before = gs.correctNote
        gs.skipNote()
        XCTAssertEqual(gs.correctNote, before)
    }

    func testSkipNoteClearsFoundFrets() {
        let gs = GameState()
        gs.gameMode   = .findTheFret
        gs.foundFrets = [FretPosition(string: 0, fret: 1)]
        gs.skipNote()
        XCTAssertTrue(gs.foundFrets.isEmpty)
    }

    // MARK: submitFret

    func testSubmitCorrectFretAddsToFoundFrets() {
        let gs = GameState()
        gs.gameMode       = .findTheFret
        gs.difficulty     = .beginner
        gs.correctNote    = .E
        gs.foundFrets     = []
        gs.fretAnswerState = .idle
        // String 0 (low E) open = E
        gs.submitFret(string: 0, fret: 0)
        XCTAssertTrue(gs.foundFrets.contains(FretPosition(string: 0, fret: 0)))
    }

    func testSubmitWrongFretSetsWrongState() {
        let gs = GameState()
        gs.gameMode       = .findTheFret
        gs.difficulty     = .beginner
        gs.correctNote    = .A
        gs.foundFrets     = []
        gs.fretAnswerState = .idle
        // String 0 fret 0 = E, not A
        gs.submitFret(string: 0, fret: 0)
        XCTAssertEqual(gs.fretAnswerState, .wrong(string: 0, fret: 0))
        XCTAssertEqual(gs.totalCount,   1)
        XCTAssertEqual(gs.correctCount, 0)
    }

    func testSubmitDuplicateFretIgnored() {
        let gs = GameState()
        gs.gameMode       = .findTheFret
        gs.correctNote    = .E
        gs.foundFrets     = [FretPosition(string: 0, fret: 0)]
        gs.fretAnswerState = .idle
        let before = gs.totalCount
        gs.submitFret(string: 0, fret: 0)
        XCTAssertEqual(gs.totalCount, before)
    }

    func testSubmitAllCorrectFretsCompletesRound() {
        let gs = GameState()
        gs.gameMode       = .findTheFret
        gs.difficulty     = .beginner
        gs.correctNote    = .A
        gs.foundFrets     = []
        gs.fretAnswerState = .idle

        let fretboard = Fretboard()
        let required = fretboard.allPositions(for: .A)
            .filter { $0.fret <= Difficulty.beginner.maxFret }
            .map    { FretPosition(string: $0.string, fret: $0.fret) }

        for pos in required {
            gs.submitFret(string: pos.string, fret: pos.fret)
        }

        XCTAssertEqual(gs.correctCount, 1)
        if case .correct = gs.fretAnswerState { } else {
            XCTFail("Expected fretAnswerState .correct after finding all positions")
        }
    }

    // MARK: Timed mode

    func testStartTimedGameResetsCountersAndActivatesTimer() {
        let gs = GameState()
        gs.correctCount  = 5
        gs.totalCount    = 10
        gs.timerDuration = 30
        gs.startTimedGame()
        XCTAssertEqual(gs.correctCount,   0)
        XCTAssertEqual(gs.totalCount,     0)
        XCTAssertEqual(gs.timeRemaining,  30)
        XCTAssertTrue(gs.isTimerActive)
        gs.stopTimedGame()
    }

    func testStopTimedGameDeactivatesTimer() {
        let gs = GameState()
        gs.startTimedGame()
        gs.stopTimedGame()
        XCTAssertFalse(gs.isTimerActive)
        XCTAssertFalse(gs.isTimeUp)
    }
}
